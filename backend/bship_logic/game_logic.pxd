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

from libc.stdint cimport int8_t

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
