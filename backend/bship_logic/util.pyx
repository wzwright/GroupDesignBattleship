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

import random

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

def gen_uniq_key(dictionary):
    "Generates a random integer key not in dictionary"
    newkey = random.randint(0, 2**31-1)
    while newkey in dictionary.keys():
        newkey = random.randint(0, 2**31-1)
    return newkey
