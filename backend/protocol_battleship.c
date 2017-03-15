#include <Python.h>
#include <assert.h>
#include <stdarg.h>
#include <stdlib.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-to-int-cast"
#define STB_DEFINE
#include "stb/stb.h"
#pragma GCC diagnostic pop
#pragma GCC diagnostic warning "-Wall"
#pragma GCC diagnostic ignored "-Wunused-function"

#define LWS_DLL
#include <jansson.h>
#include "libwebsockets/lib/libwebsockets.h"

#define BSHIP_LOGIC
#include "game_logic.h"
#include "bship_logic.h"

struct per_session_data__battleship {
	json_t *pending_replies[100];
	int pending_replies_count;
};

struct notification_user_data {
	struct lws *wsi;
	struct per_session_data__battleship *pss;
	json_t *id;
};

/* Set of [struct per_session_data__battleship*] that are valid.
 * A pointer is inserted here when a connection is established, and
 * removed when a connection is closed. This is used when a
 * notification comes in to enable us to ignore notifications coming
 * on closed connections */
stb_ps *valid_pss = NULL;

/** Like json_pack(fmt, ...) in Jansson, but halts program on error */
static json_t *croaking_json_pack(const char* fmt, ...) {
	json_error_t err;
	va_list ap;
	json_t *result;

	va_start(ap, fmt);
	result = json_vpack_ex(&err, 0, fmt, ap);
	va_end(ap);

	if(result == NULL) {
		lwsl_err("Error in json_vpack_ex: %s", err.text);
		exit(1);
	}
	return result;
}

static void send_json_rpc(struct lws *wsi, struct per_session_data__battleship *pss, json_t *payload) {
	assert(payload != NULL);
	assert(json_object_set_new(payload, "jsonrpc", json_string("2.0")) == 0);
	pss->pending_replies[pss->pending_replies_count++] = payload;
	lws_callback_on_writable(wsi);
}

static json_t *make_json_rpc_error(json_t *id, int code, const char* message, json_t *data) {
	return croaking_json_pack("{s: O?, s: {s: i, s: s, s: o?}}", "id", id, "error", "code", code, "message", message, "data", data);
}

static json_t *make_json_rpc_result(json_t *id, json_t *result) {
	return croaking_json_pack("{s: O, s: o}", "id", id, "result", result);
}

#define DIE(...) send_json_rpc(wsi, pss, make_json_rpc_error(__VA_ARGS__))
#define DIE_IF(condition, ...) if(condition) { \
	DIE(__VA_ARGS__);                          \
	return;                                    \
	}
#define DIE_ON_ERROR(error) DIE_IF(error < 0, id, error, error_to_string(error), NULL)
#define EXPECT_PARAMS(N) DIE_IF(paramN != N, id, -32602, "Invalid params", json_string("Expected " #N " param(s)"))
#define REPLY(result) send_json_rpc(wsi, pss, make_json_rpc_result(id, result))

#define PARAM_ID json_integer_value(json_array_get(params, 0))

static void handle_request(struct lws *wsi, struct per_session_data__battleship *pss, json_t *request) {
	int paramN, result, x, y, N;
	int8_t *bombs;
	char *jsonrpc = "", *method = "", *nickname;
	const char *nick;
	json_t *params = NULL, *id = NULL, *grid_param, *bombsJ;
	json_error_t error;
	grid grd;
	ship shp;

	new_game_result ng_result;
	get_game_end_result gge_result;
	plyr_id pid;
	plyr_state pstate;
	struct notification_user_data *notify_user;

	result = json_unpack_ex(request, &error, JSON_STRICT, "{s: s, s: s, s: o, s?: o}",
	               "jsonrpc", &jsonrpc, "method", &method, "id", &id, "params", &params);

	DIE_IF(result, id, -32600, "Invalid Request", json_string(error.text));
	DIE_IF(strcmp(jsonrpc, "2.0"), id, -32600, "Invalid Request", json_string("JSON-RPC version not 2.0"));

	paramN = json_array_size(params);
	if(strcmp(method, "newGame") == 0) {
		EXPECT_PARAMS(1);
		nick = json_string_value(json_array_get(params, 0));
		if(nick == NULL)
			nick = "";
		if(strlen(nick) > 100)
			DIE_ON_ERROR(ERR_NICKNAME_TOO_LONG);
		ng_result = bship_logic_new_game(nick);
		REPLY(croaking_json_pack("[ii]", ng_result.gid, ng_result.pid));
	} else if(strcmp(method, "joinGame") == 0) {
		EXPECT_PARAMS(2);
		nick = json_string_value(json_array_get(params, 1));
		if(nick == NULL)
			nick = "";
		if(strlen(nick) > 100)
			DIE_ON_ERROR(ERR_NICKNAME_TOO_LONG);
		pid = bship_logic_join_game((game_id)PARAM_ID, nick);
		DIE_ON_ERROR(pid);
		REPLY(json_integer(pid));
	} else if(strcmp(method, "getOpponentNickname") == 0) {
		EXPECT_PARAMS(1);
		result = bship_logic_get_opponent_nickname((plyr_id)PARAM_ID, &nickname);
		DIE_ON_ERROR(result);
		REPLY(json_string(nickname));
	} else if(strcmp(method, "submitGrid") == 0) {
		EXPECT_PARAMS(2);
		grid_param = json_array_get(params, 1);
		DIE_IF(json_array_size(grid_param) != 5, id, -32602, "Invalid params", json_string("Second parameter must be a 5-element array"));
		for(x = 0 ; x < 5 ; x++) {
			result = json_unpack_ex(json_array_get(grid_param, x), &error, JSON_STRICT, "[iiii]",
			                        &grd.s[x].x1, &grd.s[x].y1, &grd.s[x].x2, &grd.s[x].y2);
			DIE_IF(result, id, -32602, "Invalid params", json_string(error.text));
		}
		result = bship_logic_submit_grid((plyr_id)PARAM_ID, grd);
		DIE_ON_ERROR(result);
		REPLY(json_null());
	} else if(strcmp(method, "getBombedPositions") == 0) {
		EXPECT_PARAMS(1);
		result = bship_logic_get_bombed_positions((plyr_id)PARAM_ID, &N, &bombs);
		DIE_ON_ERROR(result);
		bombsJ = json_array();
		for(x = 0 ; x < N ; x++)
			json_array_append_new(bombsJ, croaking_json_pack("[ii]", bombs[2 * x], bombs[2 * x + 1]));
		free(bombs);
		REPLY(bombsJ);
	} else if(strcmp(method, "bombPosition") == 0) {
		EXPECT_PARAMS(3);
		pid = (plyr_id) PARAM_ID;
		x = json_integer_value(json_array_get(params, 1));
		y = json_integer_value(json_array_get(params, 2));
		result = bship_logic_bomb_position(pid, x, y);
		DIE_ON_ERROR(result);
		REPLY(json_boolean(result));
	} else if(strcmp(method, "getGameEnd") == 0) {
		EXPECT_PARAMS(1);
		gge_result = bship_logic_get_game_end((plyr_id)PARAM_ID);
		/* Can't error, returns game_over = false on error */
		if(gge_result.game_over) {
			grid_param = json_array();
			for(x = 0 ; x < 5 ; x++) {
				shp = gge_result.grid.s[x];
				json_array_append_new(grid_param, json_pack("[iiii]", shp.x1, shp.y1, shp.x2, shp.y2));
			}
		} else /* grid contains junk on game_over = false, send a NULL instead */
			grid_param = json_null();
		REPLY(croaking_json_pack("{s: b, s: b, s: o}", "game_over", gge_result.game_over, "won", gge_result.won, "grid", grid_param));
	} else if(strncmp(method, "waitFor", 7) == 0) {
		EXPECT_PARAMS(1);
		if(strcmp(method, "waitForPlayer") == 0)
			pstate = SUBMIT_GRID;
		else if(strcmp(method, "waitForYourTurn") == 0)
			pstate = BOMB;
		else if(strcmp(method, "waitForGameEnd") == 0)
			pstate = GAME_OVER;
		else {
			DIE(id, -32601, "Method not found", NULL);
			return;
		}
		notify_user = malloc(sizeof (struct notification_user_data));
		notify_user->wsi = wsi;
		notify_user->pss = pss;
		notify_user->id  = id;
		json_incref(id);
		result = bship_logic_request_notify((plyr_id)PARAM_ID, pstate, notify_user);
		if(result < 0) {
			json_decref(id);
			free(notify_user);
			DIE_ON_ERROR(result);
		}
	} else {
		DIE(id, -32601, "Method not found", NULL);
	}
	return;
}

static int callback_bship(struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len) {
	struct per_session_data__battleship *pss =
		(struct per_session_data__battleship *) user;
	char buf[LWS_PRE + 1024];
	char *p = &buf[LWS_PRE], *q;
	int i, m, n;
	json_t *request, *tmp;
	json_error_t error;
	size_t idx;

	switch(reason) {
	case LWS_CALLBACK_PROTOCOL_INIT:
		lwsl_notice("Initialized battleship for a vhost");
		break;

	case LWS_CALLBACK_ESTABLISHED:
		valid_pss = stb_ps_add(valid_pss, pss);
		pss->pending_replies_count = 0;
		break;

	case LWS_CALLBACK_CLOSED:
		valid_pss = stb_ps_remove(valid_pss, pss);
		for(i = 0; i < pss->pending_replies_count ; i++)
			json_decref(pss->pending_replies[i]);
		break;

	case LWS_CALLBACK_SERVER_WRITEABLE:
		/* If multiple replies available, send them in reverse order
		 * for simplicty */
		if(pss->pending_replies_count == 0)
			break;
		q = json_dumps(pss->pending_replies[--pss->pending_replies_count], 0);
		json_decref(pss->pending_replies[pss->pending_replies_count]);
		strncpy(p, q, 1024);
		free(q);
		n = strlen(p);
		m = lws_write(wsi, (unsigned char*)p, n, LWS_WRITE_TEXT);

		if (m < n) {
			lwsl_err("ERROR %d writing to socket\n", n);
			return -1;
		}

		if(pss->pending_replies_count)
			lws_callback_on_writable(wsi);
		break;

	case LWS_CALLBACK_RECEIVE:
		request = json_loads(in, 0, &error);
		if(request == NULL) {
			lwsl_err("ERROR decoding response: '%s'\n", error.text);
			DIE(NULL, -32700, "JSON parse error", json_string(error.text));
			return 0;
		}

		if(json_is_array(request)) { /* Batch request */
			json_array_foreach(request, idx, tmp) {
				handle_request(wsi, pss, tmp);
			}
		} else
			handle_request(wsi, pss, request);
		json_decref(request);
		break;
	default:
		break;
	}
	return 0;
}

void bship_logic_notification(plyr_id pid, plyr_state state, void *user, _Bool success) {
	struct notification_user_data *notify_data = (struct notification_user_data*) user;
	struct lws *wsi = notify_data->wsi;
	struct per_session_data__battleship *pss = notify_data->pss;
	json_t *id = notify_data->id;

	if(stb_ps_find(valid_pss, pss)) { /* Connection still alive */
		if(success)
			REPLY(json_null());
		else
			DIE(id, -100, "Notification timed out", NULL);
	}

	json_decref(id);
	free(user);
}

static const struct lws_protocols protocols[] = {
	{
		"battleship-protocol",
		callback_bship,
		(sizeof (struct per_session_data__battleship)),
		1024,
	},
};

LWS_VISIBLE int
init_protocol_battleship(struct lws_context *context, struct lws_plugin_capability *c) {
	if (c->api_magic != LWS_PLUGIN_API_MAGIC) {
		lwsl_err("Plugin API %d, library API %d", LWS_PLUGIN_API_MAGIC,
			 c->api_magic);
		return 1;
	}

	c->protocols = protocols;
	c->count_protocols = 1;
	c->extensions = NULL;
	c->count_extensions = 0;
	// Initialize the Python interpreter and the bship_logic module
	Py_Initialize();
	PyInit_bship_logic();
	return 0;
}

LWS_VISIBLE int
destroy_protocol_battleship(struct lws_context *context) {
	Py_Finalize();
	return 0;
}
