import random, enum, types, sys, importlib

# if bship doesn't exist, we're running it outside the C code, I'll
# just make a dummy module
if importlib.find_loader("bship") is None:
    bship = types.ModuleType("bship")
    notification = compile("def notification(id, state, data, success): pass", "<string>", "exec")
    exec(notification, bship.__dict__)
    sys.modules["bship"] = bship

import bship

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
    def __init__(self, pid, game):
        self.pid = pid
        self.gid = game.gid
        self.grid = None # The "grid" is the set of ships, essentially
        self.set_state(PlayerState.WAIT_FOR_JOIN)
        self.ship_points = None # This is where we keep the positions
                                # of the points of ships
        self.bomb_history = [] # list of positions we have been bombed
                               # (including repeats, successes and
                               # failures)
        self.join(game)

    def opponent(self):
        "Finds the other player in this player's game"
        game = games[self.gid]
        try:
            if game.pid1 == self.pid:
                return players[game.pid2]
            else:
                return players[game.pid1]
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

    def bomb(self, x, y):
        if self.ship_points is None:
            l = [points_occupied(ship) for ship in self.grid]
            self.ship_points = set([item for sublist in l for item in sublist])
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
                bship.notification(self.pid, state, waitdata, 1)
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

def new_game():
    newgid = random.randint(0, 2**31 -1)
    newpid = random.randint(0, 2**31 -1)
    while newgid in games:
        newgid = random.randint(0, 2**31 -1)
    while newpid in players:
        newpid = random.randint(0, 2**31 -1)
    newgame = Game(newgid)
    games[newgid] = newgame
    players[newpid] = Player(newpid, newgame)
    return (newgid, newpid)

def join_game(gid):
    if gid not in games:
        return Error.NO_SUCH_GAME
    if games[gid].full():
        return Error.ALREADY_STARTED
    newpid = random.randint(0, 2**31-1)
    while newpid in players:
        newpid = random.randint(0, 2**31 -1)
    players[newpid] = Player(newpid, games[gid])
    return newpid

def submit_grid(pid, grid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    if (me.grid is not None) or (me.state_code is not PlayerState.SUBMIT_GRID):
        # the player has tried to submit a grid twice, or after the
        # game is over
        return Error.OUT_OF_TURN
    if me.opponent() is None:
        return Error.NO_OPPONENT
    if not valid_grid(grid):
        return Error.INVALID_GRID
    me.grid = grid
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

def bad_target(x,y):
    # It's probably fine to hardcode the board size
    return (x not in range(10)) or (y not in range(10))

def bomb_position(pid, x, y):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    if bad_target(x,y):
        return Error.INVALID_BOMB_TARGET
    if me.opponent() is None:
        return Error.NO_OPPONENT
    if me.state_code is not PlayerState.BOMB:
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

def get_plyr_state(pid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    return players[pid].state_code

def get_game_end(pid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    other = me.opponent()
    if other is None:
        return Error.NO_OPPONENT
    null = [[0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0]]

    over = me.dead() or other.dead()
    return (
        null if not over else other.grid,
        1 if over else 0,
        1 if not me.dead() else 0
    )


def get_bombed_positions(pid):
    "Get pid's opponents bombed positions, in order"
    if pid not in platers:
        return (Error.INVALID_PLYR_ID, 0, [])
    # we want where *they* have bombed *us*, which is stored in our
    # object
    history = players[pid].bomb_history
    # need to convert to lists then flatten
    history = [[x,y] for (x,y) in history]
    history = [item for item in sublist for sublist in history]
    return (0, len(history), history)

def request_notify(pid, state, data):
    "Register that pid is waiting for their opponent to enter state"
    if pid not in players:
        return Error.INVALID_PLYR_ID
    me = players[pid]
    if me.state_code == state:
        # then we notify immediately
        bship.notification(pid, state, data, 1)
    else:
        if pid in pending_notifications:
            pending_notifications[pid].append((state, data))
        else:
            pending_notifications[pid] = [(state, data)]
    return 0
