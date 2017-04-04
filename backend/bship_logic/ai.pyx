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

from abc import ABC, abstractmethod

class AIPlayer(Player, ABC):
    def make(difficulty, pid):
        if difficulty <= 0:
            return ExampleAIPlayer(pid)
        elif difficulty >= 1:
            return RandomAIPlayer(pid)

    def __init__(self, pid):
        super(AIPlayer, self).__init__(pid, "AI Player")

    def set_state(self, state):
        super(AIPlayer, self).set_state(state)
        # in addition to setting the state, we also actually do the
        # action our new state allows us to perform
        if state == PlayerState.SUBMIT_GRID:
            self.ai_submit_grid()
        elif state == PlayerState.BOMB:
            self.ai_bomb()
        elif state == PlayerState.GAME_OVER:
            self.ai_cleanup()

    @abstractmethod
    def ai_submit_grid(self):
        pass

    @abstractmethod
    def ai_bomb(self):
        pass

    @abstractmethod
    def ai_cleanup(self):
        pass

class ExampleAIPlayer(AIPlayer):
    "Example AI that just bombs (0,0) repeatedly"
    def ai_submit_grid(self):
        # A real AI would pick a harder grid here
        mygrid = [[0,0,1,0]
                 ,[0,1,2,1]
                 ,[0,2,2,2]
                 ,[0,3,3,3]
                 ,[0,4,4,4]]
        bship_logic_submit_grid(self.pid, python_to_grid(mygrid))

    def ai_bomb(self):
        # bombs (0,0) every time
        bship_logic_bomb_position(self.pid, 0, 0)

    def ai_cleanup(self):
        pass

class RandomAIPlayer(AIPlayer):
    "Bombs random positions"
    def ai_submit_grid(self):
        # TODO: Make this actually random
        mygrid = [[0,0,1,0]
                 ,[0,1,2,1]
                 ,[0,2,2,2]
                 ,[0,3,3,3]
                 ,[0,4,4,4]]
        bship_logic_submit_grid(self.pid, python_to_grid(mygrid))

    def ai_bomb(self):
        to_bomb = (random.randint(0,9), random.randint(0,9))
        opp = self.opponent()
        # we don't want to repeat positions
        while to_bomb in opp.bomb_history:
            to_bomb = (random.randint(0,9), random.randint(0,9))
        bship_logic_bomb_position(self.pid, to_bomb[0], to_bomb[1])

    def ai_cleanup(self):
        pass

