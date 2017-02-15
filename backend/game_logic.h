#ifndef GAME_LOGIC_H
#define GAME_LOGIC_H

/*** TYPES ***/
/** Valid IDs are strictly positive */
typedef int game_id;
typedef int plyr_id;

/** Represents an initial positioning of one's ships */
typedef void* grid; /* XXX: Replace void* with a struct later */

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
extern int ERR_NO_SUCH_GAME;
/** Tried to submit a grid for a game that has already started */
extern int ERR_ALREADY_STARTED;
/** Tried to submit a grid that does not make sense */
extern int ERR_INVALID_GRID;
/** Used a nonexistent or invalid plyr_id */
extern int ERR_INVALID_PLYR_ID;
/** Tried to bomb an invalid position */
extern int ERR_INVALID_BOMB_TARGET;

/*** FUNCTIONS ***/
/* All functions with an integer result type return an error value in
 * case of error */

/** Create a new game. Returns a pair of (game_id, plyr_id)
 * representing the public ID of the game used to join it and the
 * private ID used by this player to send further commands */
new_game_result bship_logic_new_game(void);

/** Joins a game identified by a game_id. Returns the private ID used
 * by the joining player to send further commands about this game. */
plyr_id bship_logic_join_game(game_id);

/** Submits the initial positions of a player's ships. */
int bship_logic_submit_grid(plyr_id,grid);

/** Bombs a position, returning 1 on a hit and 0 on a miss */
int bship_logic_bomb_position(plyr_id,int,int);

/** Returns whether the game is over, and if true also returns the
 * other player's grid and an indication of who won the game */
get_game_end_result bship_logic_get_game_end(plyr_id);

/** Returns the current state of a player */
plyr_state bship_logic_get_plyr_state(plyr_id);

/** Asks the game logic engine to notify when a given player enters a
 * given state. If player is already in that state, game logic engine
 * notifies right away. */
int bship_logic_request_notify(plyr_id, plyr_state);

/** Used by the game logic engine to notify that a player entered a
 * state. This function is the only one in this file not implemented
 * by the game logic engine. */
void bship_logic_notification(plyr_id, plyr_state);

#endif /* GAME_LOGIC_H */
