import random, enum, types, sys, importlib
cimport cython, cpython
from libc.stdint cimport int8_t
from libc.stdlib cimport malloc, free

cdef extern:
    void bship_logic_notification(int pid, int state, void* data, bint success)
cdef public:
    ctypedef struct new_game_result:
        int gid
        int pid

    ctypedef struct ship:
        int8_t x1, y1, x2, y2

    ctypedef struct grid:
        ship[5] s

    ctypedef struct get_game_end_result:
        grid grid
        bint game_over
        bint won

class Error(enum.IntEnum):
    NO_SUCH_GAME = -1
    ALREADY_STARTED = -2
    INVALID_GRID = -3
    INVALID_PLYR_ID = -4
    INVALID_BOMB_TARGET = -5
    NO_OPPONENT = -6
    OUT_OF_TURN = -7

class PlayerState(enum.IntEnum):
    WAIT_FOR_JOIN = 0
    SUBMIT_GRID = 1
    WAIT_FOR_SUBMIT = 2
    BOMB = 3
    WAIT_FOR_BOMB = 4
    GAME_OVER = 5

class GameFullException(Exception):
    pass

class InvalidShipException(Exception):
    pass

class Game:
    def __init__(self, gid):
        self.gid = gid
        self.pid1 = None
        self.pid2 = None

    def full(self):
        return (self.pid1 is not None) and (self.pid2 is not None)

# pid -> list of (state, user_data)
pending_notifications = {} 

games = {} # gid -> game
players = {} # pid -> player


class Player:
    def __init__(self, pid, game, nickname):
        self.pid = pid
        self.gid = game.gid
        self.grid = None # The "grid" is the set of ships, essentially
        self.nickname = nickname
        self.set_state(PlayerState.WAIT_FOR_JOIN)
        self.ship_points = None # This is where we keep the positions
                                # of the points of ships
        self.bomb_history = [] # list of positions we have been bombed
                               # (including repeats, successes and
                               # failures)
        self.join(game)

    def opponent(self):
        "Finds the other player in this player's game"
        try:
            game = games[self.gid]
            if game.pid1 == self.pid:
                return players[game.pid2]
            elif game.pid2 == self.pid:
                return players[game.pid1]
            else:
                return None
        except KeyError:
            return None

    def join(self, game):
        # When a player is created, we try to join its associated game
        if (game.pid1 is not None) and (game.pid2 is None):
            # We were the second player. Both players can now submit
            # their grids.
            game.pid2 = self.pid
            self.set_state(PlayerState.SUBMIT_GRID)
            players[game.pid1].set_state(PlayerState.SUBMIT_GRID)
        elif (game.pid1 is None):
            # this means we were the first player, so we should wait
            # for the other player
            game.pid1 = self.pid
            self.set_state(PlayerState.WAIT_FOR_JOIN)
        else:
            # should never get here
            raise GameFullException

    def set_grid(self, grid):
        self.grid = grid
        l = [points_occupied(ship) for ship in self.grid]
        self.ship_points = set([item for sublist in l for item in sublist])

    def bomb(self, x, y):
        self.bomb_history.append((x,y))
        return ((x,y) in self.ship_points)

    def dead(self):
        return self.ship_points.issubset(set(self.bomb_history))

    def set_state(self, state):
        "Changes state and notifies all waiting players"
        self.state_code = state
        if self.pid not in pending_notifications:
            # we weren't waiting for anything
            return None
        new_notifications = []
        for (waitstate, waitdata) in pending_notifications[self.pid]:
            if waitstate == state:
                # if we were waiting for this, notify
                notification(self.pid, state, waitdata, True)
            else:
                new_notifications.append((waitstate, waitdata))

        pending_notifications[self.pid] = new_notifications

def points_occupied(ship):
    x1,y1,x2,y2 = ship
    if x1 == x2: # we have a vertical ship
        return [(x1,y) for y in range(min(y1,y2), max(y1,y2)+1)]
    if y1 == y2: # we have a horizontal ship
        return [(x,y1) for x in range(min(x1,x2), max(x1,x2)+1)]
    # else we have an illegal rectangle
    raise InvalidShipException

def ship_length(ship):
    x1,y1,x2,y2 = ship
    if x1 == x2:
        return abs(y1-y2)+1
    if y1 == y2:
        return abs(x1-x2)+1
    raise InvalidShipException

def no_overlaps(grid):
    # Here, we check no ships overlap by checking there are no
    # duplicates when we consider all points occupied by ships
    occupied = []
    try:
        occupied = [points_occupied(ship) for ship in grid]
    except:
        return False
    occupied = [item for sublist in occupied for item in sublist] # flatten
    return len(occupied) == len(set(occupied)) # set removes duplicates

def correct_lengths(left, grid):
    for ship in grid:
        try:
            l = ship_length(ship)
        except:
            return False
        # if invalid ship size or none left to place
        if (l not in left) or (left[l] <= 0):
            return False
        else:
            left[l] = left[l]-1
    return (sum(left.values()) == 0) # need to have placed all the ships

def valid_grid(grid):
    # The rules of battleship (according to Wikipedia) allow:
    # Ship       Length
    # Carrier    5
    # Battleship 4
    # Cruiser    3
    # Submarine  3
    # Destroyer  2
    ships = { 5:1, 4:1, 3:2, 2:1 }
    return (no_overlaps(grid) and correct_lengths(ships, grid))

def bad_target(x,y):
    # It's probably fine to hardcode the board size
    return (x not in range(10)) or (y not in range(10))

# C API starts here

cdef public new_game_result bship_logic_new_game(const char *nickname):
    newgid = random.randint(0, 2**31 -1)
    newpid = random.randint(0, 2**31 -1)
    while newgid in games:
        newgid = random.randint(0, 2**31 -1)
    while newpid in players:
        newpid = random.randint(0, 2**31 -1)
    newgame = Game(newgid)
    games[newgid] = newgame
    players[newpid] = Player(newpid, newgame, <bytes> nickname)
    cdef new_game_result res
    res.gid = newgid
    res.pid = newpid
    return res

# After each C function, we add a Python version that we can use for
# non-Cython unit testing
def new_game(nickname):
    cdef new_game_result res
    res = bship_logic_new_game(nickname)
    return (res.gid, res.pid)

cdef public int bship_logic_join_game(int gid, const char *nickname):
    if gid not in games:
        return Error.NO_SUCH_GAME
    if games[gid].full():
        return Error.ALREADY_STARTED
    newpid = random.randint(0, 2**31-1)
    while newpid in players:
        newpid = random.randint(0, 2**31 -1)
    players[newpid] = Player(newpid, games[gid], <bytes> nickname)
    return newpid

def join_game(gid, nickname):
    return bship_logic_join_game(gid, nickname)

cdef public int bship_logic_get_opponent_nickname(int pid, char** nickname):
    nickname[0] = NULL
    if pid not in players:
        return Error.INVALID_PLYR_ID
    opp = players[pid].opponent()
    if opp is None:
        return Error.NO_OPPONENT
    nickname[0] = <char*> opp.nickname
    return 0

cdef grid_to_python(grid grid):
    pygrid = []
    cdef ship ship
    for i in range(5):
        ship = grid.s[i]
        pygrid.append([ship.x1, ship.y1, ship.x2, ship.y2])
    return pygrid

cdef grid python_to_grid(pygrid):
    cdef grid grid
    cdef ship[5] newships
    cdef ship ship
    for i in range(min(5, len(pygrid))):
        [x1, y1, x2, y2] = pygrid[i]
        ship.x1 = x1
        ship.y1 = y1
        ship.x2 = x2
        ship.y2 = y2
        newships[i] = ship
    grid.s = newships
    return grid

cdef public int bship_logic_submit_grid(int pid, grid rgrid):
    grid = grid_to_python(rgrid)
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    if me.opponent() is None:
        return Error.NO_OPPONENT
    if (me.grid is not None) or (me.state_code != PlayerState.SUBMIT_GRID):
        # the player has tried to submit a grid twice, or after the
        # game is over
        return Error.OUT_OF_TURN
    if not valid_grid(grid):
        return Error.INVALID_GRID
    me.set_grid(grid)
    opponentstate = me.opponent().state_code
    if opponentstate == PlayerState.WAIT_FOR_SUBMIT:
        # if they were waiting for us, tell them to proceed
        me.opponent().set_state(PlayerState.BOMB)
        # we will wait for them to bomb now
        me.set_state(PlayerState.WAIT_FOR_BOMB)
    else:
        # if they are not waiting for us, this means they are still
        # submitting, so we should wait for them
        me.set_state(PlayerState.WAIT_FOR_SUBMIT)
    return 0

def submit_grid(pid, grid):
    return bship_logic_submit_grid(pid, python_to_grid(grid))

cdef public int bship_logic_bomb_position(int pid, int x, int y):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    if bad_target(x,y):
        return Error.INVALID_BOMB_TARGET
    if me.opponent() is None:
        return Error.NO_OPPONENT
    if me.state_code != PlayerState.BOMB:
        # trying to bomb out of turn or the game has ended
        return Error.OUT_OF_TURN
    # bomb our opponent, let the other player bomb
    res = int(me.opponent().bomb(x,y))
    me.set_state(PlayerState.WAIT_FOR_BOMB)
    me.opponent().set_state(PlayerState.BOMB)

    if me.dead() or me.opponent().dead():
        me.set_state(PlayerState.GAME_OVER)
        me.opponent().set_state(PlayerState.GAME_OVER)

    return res

def bomb_position(pid, x, y):
    return bship_logic_bomb_position(pid, x, y)

cdef public int bship_logic_get_plyr_state(int pid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    return players[pid].state_code

def get_plyr_state(pid):
    return bship_logic_get_plyr_state(pid)

cdef public get_game_end_result bship_logic_get_game_end(int pid):
    cdef get_game_end_result res
    if pid not in players:
        # there's no way to signal an error here other than returning
        # garbage
        res.game_over = False
        res.won = False
        return res
    me = players[pid]
    other = me.opponent()
    if other is None:
        res.game_over = False
        res.won = False
        return res
    null = [[0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0]]

    over = me.dead() or other.dead()
    res.grid = python_to_grid(null if not over else other.grid)
    res.game_over = over
    res.won = not me.dead()
    return res

def get_game_end(pid):
    cdef get_game_end_result res
    res = bship_logic_get_game_end(pid)
    return (grid_to_python(res.grid),
            res.game_over,
            res.won)

cdef int8_t* python_to_array(li, n):
    cdef int8_t* res
    res = <int8_t*>malloc(n*cython.sizeof(int8_t))
    for i in range(n):
        res[i] = li[i]
    return res

cdef array_to_python(int8_t* arr, int n):
    res = []
    for i in range(n):
        res.append(arr[i])
    return res

cdef public int bship_logic_get_bombed_positions(int pid, int* N, int8_t** bombs):
    "Get pid's opponent's bombed positions, in order"
    if pid not in players:
        N[0] = 0
        bombs[0] = NULL
        return Error.INVALID_PLYR_ID
    # we want where *they* have bombed *us*, which is stored in our
    # object
    history = players[pid].bomb_history
    # need to convert to lists then flatten
    history = [[x,y] for (x,y) in history]
    l = len(history)
    history = [item for sublist in history for item in sublist]
    N[0] = l
    bombs[0] = python_to_array(history, 2*l)
    return 0

def get_bombed_positions(pid):
    cdef int N
    cdef int8_t* bombs
    res = bship_logic_get_bombed_positions(pid, &N, &bombs)
    return (res, N, [] if N==0 else array_to_python(bombs, 2*N))
    

def notification(pid, state, data_capsule, success):
    bship_logic_notification(pid, state, cpython.PyCapsule_GetPointer(data_capsule, "user_data"), success)
        

cdef public int bship_logic_request_notify(int pid, int state, void* rdata):
    "Register that pid is waiting for their opponent to enter state"
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    data = cpython.PyCapsule_New(rdata, "user_data", NULL) 
    if me.state_code == state:
        # then we notify immediately
        notification(pid, state, data, True)
    else:
        if pid in pending_notifications:
            pending_notifications[pid].append((state, data))
        else:
            pending_notifications[pid] = [(state, data)]
    return 0

def request_notify(pid, state, data_capsule):
    # Note: the unit tests never actually pass in anything as a
    # data_capsule, this is solely a websockets thing, the unit tests
    # don't need to care about it
    return bship_logic_request_notify(pid, state, malloc(1))
    
