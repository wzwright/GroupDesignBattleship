#include "game_logic.h"

void bship_logic_notification(plyr_id a, plyr_state b, void *c, _Bool d) {
}

/* This is just a very trivial test to see if calling the logic
 * functions actually works */
int
main(int argc, char *argv[]) {
	bship_logic_new_game();
	bship_logic_join_game(5);
	grid mygrid = {{{0,0,0,0},
	                {0,0,0,0},
	                {0,0,0,0},
	                {0,0,0,0},
	                {0,0,0,0}}};
	bship_logic_submit_grid(7, mygrid);
	bship_logic_bomb_position(7, 0, 0);
	bship_logic_get_plyr_state(7);
	bship_logic_get_game_end(7);
	return 0;
}


