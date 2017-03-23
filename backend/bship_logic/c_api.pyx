cimport cython, cpython
from libc.stdint cimport int8_t
from libc.stdlib cimport malloc, free

cdef public new_game_result bship_logic_new_game(const char *nickname):
    newgid = gen_uniq_key(games)
    newpid = gen_uniq_key(players)
    newgame = Game(newgid)
    games[newgid] = newgame
    players[newpid] = Player(newpid, <bytes> nickname)
    players[newpid].join(newgame)
    cdef new_game_result res
    res.gid = newgid
    res.pid = newpid
    return res

cdef public int bship_logic_join_ai_game(const char *nickname, int difficulty):
    cdef new_game_result ng_res
    pid = gen_uniq_key(players)
    ai = AIPlayer.make(difficulty, pid)
    players[pid] = ai
    gid = gen_uniq_key(games)
    newgame = Game(gid)
    games[gid] = newgame
    ai.join(newgame)
    return bship_logic_join_game(gid, nickname)

cdef public int bship_logic_join_random_game(const char *nickname):
    cdef new_game_result ng_res
    if len(pending_games) == 0:
        ng_res = bship_logic_new_game(nickname)
        # this added the game to games, we want it in pending_games
        pending_games[ng_res.gid] = games[ng_res.gid]
        del games[ng_res.gid]
        return ng_res.pid
    else:
        # there is a game available for us to join
        (gid, game) = pending_games.popitem()
        games[gid] = game
        return bship_logic_join_game(gid, nickname)

cdef public int bship_logic_join_game(int gid, const char *nickname):
    if gid not in games:
        return Error.NO_SUCH_GAME
    if games[gid].full():
        return Error.ALREADY_STARTED
    newpid = gen_uniq_key(players)
    players[newpid] = Player(newpid, <bytes> nickname)
    players[newpid].join(games[gid])
    return newpid

cdef public int bship_logic_get_opponent_nickname(int pid, char** nickname):
    nickname[0] = NULL
    if pid not in players:
        return Error.INVALID_PLYR_ID
    opp = players[pid].opponent()
    if opp is None:
        return Error.NO_OPPONENT
    nickname[0] = <char*> opp.nickname
    return 0

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
        # we will wait for them to bomb now
        me.set_state(PlayerState.WAIT_FOR_BOMB)

        # Note: it is important that we set our state before the
        # opponent's because if the opponent is an AI, setting their
        # state will immediately cause them to try to execute their
        # action. If we don't set our state first, the game will be 
        # in an invalid state when the AI sees it, so it will behave 
        # unexpectedly.
        me.opponent().set_state(PlayerState.BOMB)
    else:
        # if they are not waiting for us, this means they are still
        # submitting, so we should wait for them
        me.set_state(PlayerState.WAIT_FOR_SUBMIT)
    return 0

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

cdef public int bship_logic_get_plyr_state(int pid):
    if pid not in players:
        return Error.INVALID_PLYR_ID
    return players[pid].state_code

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
