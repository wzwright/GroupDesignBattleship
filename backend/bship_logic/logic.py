# Copyright (C) 2017 by Oxford 2017 Group Design Practical Team 9
#
# This file is part of GroupDesignBattleship.
#
# GroupDesignBattleship is free software: you can redistribute it
# and/or modify it under the terms of the GNU Affero General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# GroupDesignBattleship is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with GroupDesignBattleship. If not, see
# <http://www.gnu.org/licenses/>.

import random, enum, types, sys, importlib, time

class Error(enum.IntEnum):
    NO_SUCH_GAME = -1
    ALREADY_STARTED = -2
    INVALID_GRID = -3
    INVALID_PLYR_ID = -4
    INVALID_BOMB_TARGET = -5
    NO_OPPONENT = -6
    OUT_OF_TURN = -7
    NICKNAME_TOO_LONG = -8

class PlayerState(enum.IntEnum):
    WAIT_FOR_JOIN = 0
    SUBMIT_GRID = 1
    WAIT_FOR_SUBMIT = 2
    BOMB = 3
    WAIT_FOR_BOMB = 4
    GAME_OVER = 5
    GAME_DIED = 6

class GameFullException(Exception):
    pass

class InvalidShipException(Exception):
    pass

class Game:
    def __init__(self, gid):
        self.gid = gid
        self.pid1 = None
        self.pid2 = None
        self.playersquit = 0

    def full(self):
        return (self.pid1 is not None) and (self.pid2 is not None)

    def last_active(self):
        def f(pid):
            if pid not in players:
                return 0
            else:
                return players[pid].last_active
        return max([f(pid) for pid in [self.pid1, self.pid2]])

_timeout = 300
_maxgames = 100

def cull_inactive():
    "Culls inactive and dead games"
    ngames = len(games)
    now = time.time()
    for gid, game in list(games.items()):
        # We want to delete inactive games only if there are too many
        # but we want to delete dead games regardless
        if (now - game.last_active() > _timeout and ngames > _maxgames) or (game.playersquit == 2):
            del games[gid]

    # We need to also cull players and respond to all of their
    # notifications
    for pid, player in list(players.items()):
        # If their game wasn't culled or they are active but just
        # haven't joined a game yet, do nothing
        if player.gid in games or now - player.last_active <= _timeout:
            continue
        if pid in pending_notifications:
            for (waitstate, waitdata) in pending_notifications[pid]:
                notification(pid, waitstate, waitdata, False)
            del pending_notifications[pid]
        del players[pid]

# pid -> list of (state, user_data)
pending_notifications = {}

# games managed by join_random_game, will be moved to games once full
pending_games = {}

games = {} # gid -> game
players = {} # pid -> player

class Player:
    def __init__(self, pid, nickname):
        self.pid = pid
        self.gid = None
        self.grid = None # The "grid" is the set of ships, essentially
        self.nickname = nickname
        self.state_code = PlayerState.WAIT_FOR_JOIN
        self.ship_points = None # This is where we keep the positions
                                # of the points of ships
        self.bomb_history = [] # list of positions we have been bombed
                               # (including repeats, successes and
                               # failures)
        self.last_active = time.time()

    def update_timestamp(self):
        self.last_active = time.time()

    def opponent(self):
        "Finds the other player in this player's game"
        self.update_timestamp()
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
        self.update_timestamp()
        self.gid = game.gid
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
        self.update_timestamp()
        self.grid = grid
        l = [points_occupied(ship) for ship in self.grid]
        self.ship_points = set([item for sublist in l for item in sublist])

    def bomb(self, x, y):
        self.update_timestamp()
        self.bomb_history.append((x,y))
        return ((x,y) in self.ship_points)

    def dead(self):
        self.update_timestamp()
        return self.ship_points.issubset(set(self.bomb_history))

    def set_state(self, state):
        "Changes state and notifies all waiting players"
        self.update_timestamp()
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
