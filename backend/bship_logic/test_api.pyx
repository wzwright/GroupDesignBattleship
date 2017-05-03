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

# This file contains Python versions of the functions in c_api.pyx,
# for use in Python tests

def new_game(nickname):
    cdef new_game_result res
    res = bship_logic_new_game(nickname)
    return (res.gid, res.pid)

def join_ai_game(nickname, difficulty):
    return bship_logic_join_ai_game(nickname, difficulty)

def join_random_game(nickname):
    return bship_logic_join_random_game(nickname)

def join_game(gid, nickname):
    return bship_logic_join_game(gid, nickname)

def get_opponent_nickname(pid):
    cdef char* nickname
    bship_logic_get_opponent_nickname(pid, &nickname)
    return nickname

def submit_grid(pid, grid):
    return bship_logic_submit_grid(pid, python_to_grid(grid))

def bomb_position(pid, x, y):
    return bship_logic_bomb_position(pid, x, y)

def get_plyr_state(pid):
    return bship_logic_get_plyr_state(pid)

def get_game_end(pid):
    cdef get_game_end_result res
    res = bship_logic_get_game_end(pid)
    return (grid_to_python(res.grid),
            res.game_over,
            res.won)

def get_bombed_positions(pid):
    cdef int N
    cdef int8_t* bombs
    res = bship_logic_get_bombed_positions(pid, &N, &bombs)
    return (res, N, [] if N==0 else array_to_python(bombs, 2*N))

def notification(pid, state, data_capsule, success):
    bship_logic_notification(pid, state, cpython.PyCapsule_GetPointer(data_capsule, "user_data"), success)

def request_notify(pid, state, data_capsule):
    # Note: the unit tests never actually pass in anything as a
    # data_capsule, this is solely a websockets thing, the unit tests
    # don't need to care about it
    return bship_logic_request_notify(pid, state, malloc(1))

def disconnect(pid):
    return bship_logic_disconnect(pid)

def reset_state():
    "Resets the internal state of the game server (used before running a test)"
    pending_notifications = {}
    pending_games = {}
    games = {}
    players = {}
