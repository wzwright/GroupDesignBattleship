from enum import Enum

class Error(Enum):
    NO_SUCH_GAME = -1
    ALREADY_STARTED = -2
    INVALID_GRID = -3
    INVALID_PLYR_ID = -5
    INVALID_BOMB_TARGET = -6

def new_game():
    return (5,7)

def join_game(gid):
    if gid != 5:
        return Error.NO_SUCH_GAME
    return 8

def submit_grid(pid, grid):
    if pid < 7 or pid > 8:
        return Error.INVALID_PLYR_ID
    return 0

def bomb_position(pid, x, y):
    if pid < 7 or pid > 8:
        return Error.INVALID_PLYR_ID
    if x < 0 or y < 0:
        return Error.INVALID_BOMB_TARGET
    return 0

def get_game_end(pid):
    return ([([0,0,0,0]),
             ([0,0,0,0]),
             ([0,0,0,0]),
             ([0,0,0,0]),
             ([0,0,0,0])], False, False)
