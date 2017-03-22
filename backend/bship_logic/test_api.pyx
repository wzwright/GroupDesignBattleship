# This file contains Python versions of the functions in c_api.pyx,
# for use in Python tests

def new_game(nickname):
    cdef new_game_result res
    res = bship_logic_new_game(nickname)
    return (res.gid, res.pid)

def join_game(gid, nickname):
    return bship_logic_join_game(gid, nickname)

def get_opponent_nickname(pid):
    cdef char* nickname
    bship_logic_get_opponent_nickname(pid, &nickname)
    return nickname

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
