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
