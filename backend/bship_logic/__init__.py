from enum import Enum

class Error(Enum):
    NO_SUCH_GAME = -1
    ALREADY_STARTED = -2
    INVALID_GRID = -3
    INVALID_PLYR_ID = -5
    INVALID_BOMB_TARGET = -6

class PlayerState(Enum):
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

class Player:
    def __init__(self, pid, game):
        self.pid = pid
        self.gid = game.gid
        self.grid = None # The "grid" is the set of ships, essentially
        self.state_code = PlayerState.WAIT_FOR_JOIN
        self.ship_points = None # This is where we keep the positions
                                # of the points of ships
        self.bomb_attempts = set() # all bomb attempts including
                                   # successes and failures
        self.join()

    def opponent(self):
        "Finds the other player in this player's game"
        game = games[self.gid]
        if game.pid1 == self.pid:
            return game.pid2
        else:
            return game.pid1

    def join(self):
        # When a player is created, we try to join its associated game
        if (game.pid1 is not None) and (game.pid2 is None):
            # We were the second player. Both players can now submit
            # their grids. We'll let the other player go first.
            game.pid2 = pid
            self.state_code = PlayerState.WAIT_FOR_SUBMIT
            players[game.pid1].state_code = PlayerState.SUBMIT_GRID
        elif (game.pid1 is None):
            # this means we were the first player, so we should wait
            # for the other player
            game.pid1 = pid
            self.state_code = PlayerState.WAIT_FOR_JOIN
        else:
            # should never get here
            raise GameFullException

    def bomb(self, x, y):
        if self.ship_points is None:
            l = [points_occupied(ship) for ship in self.grid]
            self.ship_points = set([item for sublist in l for item in sublist])
        self.bomb_attempts.add((x,y))
        return ((x,y) in self.ship_points)

    def dead(self):
        return self.ship_points.issubset(self.bomb_attempts)
            

games = {} # gid -> game
players = {} # pid -> player

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
        if (l not in left) or (left[l] <= 0):
            return False
        else:
            left[l] = left[l]-1
    return True

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
    newgid = 0
    newpid = 0
    if bool(games):
        newgid = max(games.keys())+1
    if bool(players):
        newpid = max(players.keys())+1
    newgame = Game(newgid)
    games[newgid] = newgame
    players[newpid] = Player(newpid, newgame)
    return (newgid, newpid)

def join_game(gid):
    if gid not in games:
        return Error.NO_SUCH_GAME
    if games[gid].full():
        return Error.ALREADY_STARTED
    newpid = max(players.keys())+1
    players[newpid] = Player(newpid, games[gid])
    return newpid

def submit_grid(pid, grid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    if players[pid].grid is not None:
        # the player has tried to submit a grid twice
        return Error.INVALID_GRID
    if not valid_grid(grid):
        return Error.INVALID_GRID
    me = players[pid]
    me.grid = grid
    try:
        opponentstate = me.opponent()
        if opponentstate == PlayerState.WAIT_FOR_SUBMIT:
            # if they were waiting for us, tell them to proceed
            me.opponent().state_code = PlayerState.BOMB
            # we will wait for them to bomb now
            me.state_code = PlayerState.WAIT_FOR_BOMB
        else:
            # else, we are going first, so we'll wait for them and
            # they can now submit
            me.state_code = PlayerState.WAIT_FOR_SUBMIT
            me.opponent().state_code = PlayerState.SUBMIT_GRID
    except:
        # if we get to here, this means there was no opponent, this is
        # an illegal submission. should never happen
        return -10
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
        # no opponent is illegal, shouldn't happen
        return -10
    if me.state_code is not PlayerState.BOMB:
        # trying to bomb out of turn or the game has ended
        return -10
    # bomb our opponent, let the other player bomb
    res = int(me.opponent().bomb(x,y))
    me.state_code = PlayerState.WAIT_FOR_BOMB
    me.opponent().state_code = PlayerState.BOMB

    if me.dead() or me.opponent().dead():
        me.state_code = PlayerState.GAME_OVER
        me.opponent().state_code = PlayerState.GAME_OVER

    return res

def get_plyr_state(pid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    return players[pid].state_code

def get_game_end(pid):
    # we go to the pid's game, check if either player has died
    game = games[players[pid].gid]
    me = players[pid]
    other = me.opponent()
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
