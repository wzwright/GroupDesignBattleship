#include "game_logic.h"
new_game_result bship_logic_new_game(void){
	new_game_result r;
	r.gid = 5;
	r.pid = 7;
	return r;
}

plyr_id bship_logic_join_game(game_id gid) {
	if(gid != 5)
		return ERR_NO_SUCH_GAME;
	return 8;
}

int bship_logic_submit_grid(plyr_id pid, grid _g) {
	if(pid < 7 || pid > 8)
		return ERR_INVALID_PLYR_ID;
	return 0;
}

int bship_logic_bomb_position(plyr_id pid, int x, int y) {
	if(pid < 7 || pid > 8)
		return ERR_INVALID_PLYR_ID;
	if(x < 0 || y < 0)
		return ERR_INVALID_BOMB_TARGET;
	return 0;
}

get_game_end_result bship_logic_get_game_end(plyr_id pid) {
	get_game_end_result g;
	g.won = 0;
	g.game_over = 0;
	return g;
}

static plyr_id stored_pid = 0;
static plyr_state stored_state;
static void* stored_user;

int bship_logic_request_notify(plyr_id pid, plyr_state state, void *user) {
	if(stored_pid > 0)
		bship_logic_notification(stored_pid, stored_state, stored_user, 1);
	stored_pid = pid;
	stored_state = state;
	stored_user = user;
	return 0;
}
