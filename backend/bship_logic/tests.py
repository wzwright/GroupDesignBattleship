import bship_logic as b
import unittest

# These are the only "important" tests. Other tests only test internal
# stuff
class ApiTests(unittest.TestCase):
    "Test the behaviour of the public API"
    def setUp(self):
        "Clear the state of the game"
        b.games = {}
        b.players = {}

    def test_new_game(self):
        "new_game generates a valid gid and pid"
        (gid, pid) = b.new_game()
        self.assertTrue(gid in b.games)
        self.assertTrue(pid in b.players)

    def test_join_full(self):
        "join_game fails when full"
        (gid, pid) = b.new_game()
        b.join_game(gid)
        b.join_game(gid)
        self.assertEqual(b.join_game(gid), b.Error.ALREADY_STARTED)

    def test_join_invalid(self):
        "join_game fails with invalid gid"
        (gid, pid) = b.new_game()
        self.assertEqual(b.join_game(gid+1), b.Error.NO_SUCH_GAME)

    def test_submit_invalid(self):
        "submit_grid fails with some bad grids, pids"
        # game starts, other player joins, we place first
        (gid, pid) = b.new_game()
        otherpid = b.join_game(gid)
        # empty grid
        self.assertEqual(b.submit_grid(pid, []), b.Error.INVALID_GRID)
        # too few ships
        self.assertEqual(b.submit_grid(pid, [[0,0,1,0]
                                            ,[0,1,0,3]]), b.Error.INVALID_GRID)
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
                                            ,[0,4,4,4]]), b.Error.INVALID_GRID)
        


        


    
