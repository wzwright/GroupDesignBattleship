import unittest
import bship_logic as b

b.TEST = True

class ApiTests(unittest.TestCase):
    "Test the behaviour of the public API"
    def setUp(self):
        "Clear the state of the game"
        b.games = {}
        b.players = {}

    def test_invalid_pid(self):
        "All API functions fail correctly if given a bad pid"
        self.assertEqual(b.get_plyr_state(100), b.Error.INVALID_PLYR_ID)
        self.assertEqual(b.get_game_end(1000), b.Error.INVALID_PLYR_ID)
        self.assertEqual(b.request_notify(12, b.PlayerState.SUBMIT_GRID, None), b.Error.INVALID_PLYR_ID)

    def test_new_game(self):
        "new_game generates a valid gid and pid"
        (gid, pid) = b.new_game()
        self.assertTrue(gid in b.games)
        self.assertTrue(pid in b.players)

    def test_join_twice(self):
        "join_game fails when you try to join twice"
        (gid, pid) = b.new_game()
        b.join_game(gid)
        b.join_game(gid)
        self.assertEqual(b.join_game(gid), b.Error.ALREADY_STARTED)

    def test_join_invalid(self):
        "join_game fails with invalid gid"
        (gid, pid) = b.new_game()
        self.assertEqual(b.join_game(gid+1), b.Error.NO_SUCH_GAME)

    def test_get_plyr_state(self):
        "get_plyr_state succeeds if pid is valid"
        (gid, pid) = b.new_game()
        self.assertEqual(b.get_plyr_state(pid), b.players[pid].state_code)

    def test_get_game_end(self):
        "get_game_end fails when called inappropriately"
        # before opponent joins (but we have)
        (gid, pid) = b.new_game()
        self.assertEqual(b.get_game_end(pid), b.Error.NO_OPPONENT)

    def test_submit_invalid(self):
        "submit_grid fails with bad grids, when called too early"
        # game starts, other player joins, we place first
        (gid, pid) = b.new_game()

        # submit before join
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,2,1]
                                            ,[0,2,2,2]
                                            ,[0,3,3,3]
                                            ,[0,4,4,4]]), b.Error.NO_OPPONENT)
        otherpid = b.join_game(gid)
        # empty grid
        self.assertEqual(b.submit_grid(pid, []), b.Error.INVALID_GRID)
        # too few ships
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,0,3]]), b.Error.INVALID_GRID)
        # too many ships
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,2,1]
                                            ,[0,2,2,2]
                                            ,[0,3,3,3]
                                            ,[0,4,4,4]
                                            ,[0,5,4,5]]), b.Error.INVALID_GRID)
        # ships overlap but otherwise valid
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,0,2,0]
                                            ,[0,0,2,0]
                                            ,[0,0,3,0]
                                            ,[0,0,4,0]]), b.Error.INVALID_GRID)
        # ship is rectangle, not line
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,2,1]
                                            ,[0,2,2,2]
                                            ,[0,3,3,3]
                                            ,[0,4,4,5]]), b.Error.INVALID_GRID)
        # ok grid, bad pid
        self.assertEqual(b.submit_grid(pid+100, [[0,0,1,0]
                                                ,[0,1,2,1]
                                                ,[0,2,2,2]
                                                ,[0,3,3,3]
                                                ,[0,4,4,4]]), b.Error.INVALID_PLYR_ID)
        # this should work
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,2,1]
                                            ,[0,2,2,2]
                                            ,[0,3,3,3]
                                            ,[0,4,4,4]]), 0)
        # but you can't submit twice
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,2,1]
                                            ,[0,2,2,2]
                                            ,[0,3,3,3]
                                            ,[0,4,4,4]]), b.Error.OUT_OF_TURN)

class PlayerTests(unittest.TestCase):
    "Test how player responds to {well,mal}formed environments"
    def setUp(self):
        b.players = {}
        b.games = {}

    def test_join_full(self):
        "Player.join fails if game is full"
        # note: this should never happen if the user uses the API
        # provided. join_game checks and returns an error before the
        # join call reaches the player.
        (gid, pid) = b.new_game()
        b.join_game(gid)
        with self.assertRaises(b.GameFullException):
            b.players[pid].join(b.games[gid])


    def test_wrong_game_pids(self):
        "Player.opponent doesn't assume game has correct pids"
        badgame = b.Game(1234)
        b.games[1234] = badgame
        me = b.Player(1, badgame)
        b.players[1] = me
        # a hacker (or something) then changes the pids so they refer
        # to no player
        badgame.pid1 = 54
        badgame.pid2 = 256
        # but the player should not assume the game's pids are correct
        # (no exceptions should be thrown). This is because we want
        # the server to be as resilient to hackers as possible: no-one
        # should be able to provoke an uncaught exception.

        # this is also checking that it's safe to just run
        # Player.opponent whenever: there is no precondition
        self.assertEqual(me.opponent(), None)

class NotificationTests(unittest.TestCase):
    "Test that notifications 'block' correctly"
    # the notification system is inherently tied to the C code, so
    # to test it we have to assume that if the notification is
    # pending one second then gone the next, it was replied to by
    # the C code, so everything is fine.
    def setUp(self):
        b.players = {}
        b.games = {}

    def test_notify_delayed_join(self):
        "Player gets notified when other player joins after some time"
        (gid, pid) = b.new_game()
        b.request_notify(pid, b.PlayerState.SUBMIT_GRID, None)
        # notification has been registered as waiting
        self.assertTrue(pid in b.pending_notifications and (b.PlayerState.SUBMIT_GRID, None) in b.pending_notifications[pid])
        b.join_game(gid)
        # now the notification should be gone. As per above, we assume
        # it was responded to
        self.assertFalse(pid in b.pending_notifications and (b.PlayerState.SUBMIT_GRID, None) in b.pending_notifications[pid])

    def test_notify_immediate_join(self):
        "Player gets notified immediately when other player is already in game"
        (gid, pid) = b.new_game()
        b.join_game(gid)
        b.request_notify(pid, b.PlayerState.SUBMIT_GRID, None)
        # the notification should never have been registered at all
        self.assertFalse(pid in b.pending_notifications and (b.PlayerState.SUBMIT_GRID, None) in b.pending_notifications[pid])

    def test_multiple_notifications(self):
        "Player waiting for multiple states is notified correctly"
        (gid, pid) = b.new_game()
        # we wait for the same thing twice: both should be responded
        # to at the same time
        b.request_notify(pid, b.PlayerState.SUBMIT_GRID, None)
        b.request_notify(pid, b.PlayerState.SUBMIT_GRID, None)
        self.assertTrue(pid in b.pending_notifications)
        self.assertEqual(2, b.pending_notifications[pid].count((b.PlayerState.SUBMIT_GRID, None)))
        # we also wait for something else: this should not be
        # responded to at the same time as the others
        b.request_notify(pid, b.PlayerState.BOMB, None)
        self.assertTrue((b.PlayerState.BOMB, None) in b.pending_notifications[pid])
        b.join_game(gid)
        # wait for join notifications should be gone
        self.assertFalse(pid in b.pending_notifications and (b.PlayerState.SUBMIT_GRID, None) in b.pending_notifications[pid])
        # bomb notifications should still be here
        self.assertTrue((b.PlayerState.BOMB, None) in b.pending_notifications[pid])

class StateTests(unittest.TestCase):
    "Test that the player's states are correct at all stages of the game"
    def setUp(self):
        "Clear the state of the game"
        b.games = {}
        b.players = {}

    def test_normal_game(self):
        "state_codes are correct during a normal game, where one player wins"
        (gid, pid1) = b.new_game()
        me = b.players[pid1]
        self.assertEqual(me.state_code, b.PlayerState.WAIT_FOR_JOIN)
        pid2 = b.join_game(gid)
        other = b.players[pid2]
        self.assertEqual(me.state_code, b.PlayerState.SUBMIT_GRID)
        self.assertEqual(other.state_code, b.PlayerState.SUBMIT_GRID)

        # they both submit the same grid, for simplicity
        b.submit_grid(pid1, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        self.assertEqual(me.state_code, b.PlayerState.WAIT_FOR_SUBMIT)
        b.submit_grid(pid2, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        self.assertEqual(me.state_code, b.PlayerState.BOMB)
        self.assertEqual(other.state_code, b.PlayerState.WAIT_FOR_BOMB)

        # here, we just play out some turns, with me bombing each of
        # their ships while they bomb an empty space
        for ship in other.grid:
            for (x,y) in b.points_occupied(ship):
                b.bomb_position(pid1, x, y)
                b.bomb_position(pid2, 5, 5)

        # game should be over
        self.assertEqual(me.state_code, b.PlayerState.GAME_OVER)
        self.assertEqual(other.state_code, b.PlayerState.GAME_OVER)

        # we should have won
        self.assertEqual(b.get_game_end(pid1), (other.grid, 1, 1))

        # they should have lost
        self.assertEqual(b.get_game_end(pid2), (me.grid, 1, 0))

    # TODO: add some tests simulating a player trying to do something
    # weird

class BombTests(unittest.TestCase):
    "Test that bomb history and bomb errors are correct"
    def setUp(self):
        b.players = {}
        b.games = {}

    def test_bomb_pos_invalid(self):
        "bomb_position fails with bad arguments or if called too early"
        # bad pid
        self.assertEqual(b.bomb_position(123,0,0), b.Error.INVALID_PLYR_ID)
        (gid, pid1) = b.new_game()
        # before opponent joins
        self.assertEqual(b.bomb_position(pid1,0,0), b.Error.NO_OPPONENT)
        pid2 = b.join_game(gid)
        # before the bombing phase starts
        self.assertEqual(b.bomb_position(pid1,0,0), b.Error.OUT_OF_TURN)
        # players submit grid
        b.submit_grid(pid1, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        b.submit_grid(pid2, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        # bad position
        self.assertEqual(b.bomb_position(pid1,100,100), b.Error.INVALID_BOMB_TARGET)
        # this should work and hit
        self.assertEqual(b.bomb_position(pid1,0,0), 1)

    def test_bomb_history(self):
        "get_bomb_history fails with bad args but is correct otherwise"
        self.assertEqual(b.get_bombed_positions(123), (b.Error.INVALID_PLYR_ID, 0, []))
        (gid, pid1) = b.new_game()
        pid2 = b.join_game(gid)
        b.submit_grid(pid1, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        b.submit_grid(pid2, [[0,0,1,0]
                             ,[0,1,2,1]
                             ,[0,2,2,2]
                             ,[0,3,3,3]
                             ,[0,4,4,4]])
        b.bomb_position(pid1, 0, 0)
        b.bomb_position(pid2, 0, 4)
        b.bomb_position(pid1, 0, 1)

        self.assertEqual(b.get_bombed_positions(pid1), (0, 1, [0,4]))
        self.assertEqual(b.get_bombed_positions(pid2), (0, 2, [0,0,0,1]))


