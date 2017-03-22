#ifndef GAME_LOGIC_H
#define GAME_LOGIC_H
#include <stdint.h>

/*** TYPES ***/
/** Valid IDs are strictly positive */
typedef int game_id;
typedef int plyr_id;

#ifndef BSHIP_LOGIC /* These structs are defined again by Cython in
					 * the bship_logic module */
/** Represents a ship by its start and end coordinates.
 * Invariant: x1 <= x2 && y1 <= y2. */
typedef struct {
	int8_t x1, y1, x2, y2;
} ship;

/** Represents an initial positioning of one's ships */
typedef struct {
	ship s[5];
} grid;

typedef struct {
	game_id gid;
	plyr_id pid;
} new_game_result;

typedef struct {
	/** The other player's grid. NULL if the game is not over. */
	grid grid;
	/** True if the game is over, false otherwise */
	_Bool game_over;
	/** True if the game was won by this player, false if lost or game
	 * is not over */
	_Bool won;
} get_game_end_result;

#endif /* BSHIP_LOGIC */

/** The state of the game, from the perspective of a player */
typedef enum {
	/** Waiting for another player to join my game */
	WAIT_FOR_JOIN,
	/** Deciding where to place my ships */
	SUBMIT_GRID,
	/** Waiting for other player to place ships */
	WAIT_FOR_SUBMIT,
	/** Deciding what position to bomb */
	BOMB,
	/** Waiting for other player to bomb */
	WAIT_FOR_BOMB,
	/** Someone won the game */
	GAME_OVER
} plyr_state;


/*** ERRORS ***/
/* All errors are guaranteed to be negative */

/** Tried to join a nonexistent game, or a game in progress */
#define ERR_NO_SUCH_GAME -1
/** Tried to submit a grid for a game that has already started */
#define ERR_ALREADY_STARTED -2
/** Tried to submit a grid that does not make sense */
#define ERR_INVALID_GRID -3
/** Used a nonexistent or invalid plyr_id */
#define ERR_INVALID_PLYR_ID -4
/** Tried to bomb an invalid position */
#define ERR_INVALID_BOMB_TARGET -5
/** Tried to execute an action before opponent joined */
#define ERR_NO_OPPONENT -6
/** Tried to execute an action out of turn */
#define ERR_OUT_OF_TURN -7
/** Nickname is longer than 100 bytes */
#define ERR_NICKNAME_TOO_LONG -8

static inline const char* error_to_string(int error) {
	switch(error) {
	case 0:                       return "Success";
	case ERR_NO_SUCH_GAME:        return "No such game";
	case ERR_ALREADY_STARTED:     return "Already started";
	case ERR_INVALID_GRID:        return "Invalid grid";
	case ERR_INVALID_PLYR_ID:     return "Invalid player ID";
	case ERR_INVALID_BOMB_TARGET: return "Invalid bomb target";
	case ERR_NO_OPPONENT:         return "No opponent";
	case ERR_OUT_OF_TURN:         return "Out of turn";
	case ERR_NICKNAME_TOO_LONG:   return "Nickname longer than 100 bytes";
	default:                      return "Unknown error";
	}
}

#ifndef BSHIP_LOGIC /* These functions are defined again by Cython in
					 * the bship_logic module */
/*** FUNCTIONS ***/
/* All functions with an integer result type return an error value in
 * case of error */

/** Create a new game. The nickname is copied. Returns a pair of
 * (game_id, plyr_id) representing the public ID of the game used to
 * join it and the private ID used by this player to send further
 * commands. */
new_game_result bship_logic_new_game(const char *nickname);

/** Joins a game identified by a game_id. The nickname is copied.
 * Returns the private ID used by the joining player to send further
 * commands about this game. */
int bship_logic_join_game(game_id,const char *nickname);

/** Joins a game where your opponent is an AI. A higher difficulty is
 * harder. <=0 is the AI that bombs (0,0), 1 bombs randomly. Higher
 * AIs implement actual strategies, see ai.pyx for more
 * details. Returns the player ID.
 */
int bship_logic_join_ai_game(const char* nickname, int difficulty);

/** Either creates a game and puts you in it, waiting for an opponent
 * to join or joins a game if someone is waiting for an
 * opponent. Returns your player ID.
 */
int bship_logic_join_random_game(const char* nickname);

/** Get the opponent's nickname. Returns 0 on sucess, negative on
 * error. Nickname must not be modified or freed by caller. */
int bship_logic_get_opponent_nickname(plyr_id, char **nickname);

/** Submits the initial positions of a player's ships. */
int bship_logic_submit_grid(plyr_id,grid);

/** Bombs a position, returning 1 on a hit and 0 on a miss */
int bship_logic_bomb_position(plyr_id,int,int);

/** Returns the list of positions bombed by this player's opponent,
 * with N being the number of bombed positions, and bombs being an
 * array of 2*N coordinates, with the ith bombed position in
 * chronological order being (bombs[2*i], bombs[2*i+1]). bombs must be
 * freed by the caller. Returns 0 on success, negative on error.
 * bombs must be set to NULL on error. */
int bship_logic_get_bombed_positions(plyr_id,int* N,int8_t** bombs);

/** Returns whether the game is over, and if true also returns the
 * other player's grid and an indication of who won the game */
get_game_end_result bship_logic_get_game_end(plyr_id);

/** Returns the current state of a player */
plyr_state bship_logic_get_plyr_state(plyr_id);

/** Asks the game logic engine to notify when a given player enters a
 * given state. If player is already in that state, game logic engine
 * notifies right away.
 *
 * If the state change does not happen in a reasonable time (or the
 * game finishes/is deleted due to inactivity), the game logic engine
 * must still call [bship_logic_notification] (with [success] set to
 * false) so that the user data can be cleaned up */
int bship_logic_request_notify(plyr_id, plyr_state, void *user_data);

/** Used by the game logic engine to notify that a player entered a
 * state. This function is the only one in this file not implemented
 * by the game logic engine. The [user_data] is the same pointer
 * previously passed to [bship_logic_request_notify].
 *
 * [success]is true if the player entered the state, and false if the
 * notification timed out. */
void bship_logic_notification(plyr_id, plyr_state, void *user_data, _Bool success);
#endif /* BSHIP_LOGIC */

#endif /* GAME_LOGIC_H */
