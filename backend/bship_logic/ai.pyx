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
        elif difficulty == 1:
            return RandomAIPlayer(pid)
        elif difficulty >= 2:
            return ImprovedAIPlayer(pid)

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

class RandomAIPlayer(AIPlayer):
    "Bombs random positions"
    def ai_submit_grid(self):
        mygrid = []
        ships = [5, 4, 3, 3, 2]
        for length in ships:
            while True:
                newgrid = list(mygrid)
                start = (random.randint(0,9),
                         random.randint(0,9))
                vertical = bool(random.getrandbits(1))
                if vertical:
                    end = (start[0], start[1]+length-1)
                else:
                    end = (start[0]+length-1, start[1])
                ship = [start[0], start[1], end[0], end[1]]
                newgrid.append(ship)
                if not inside_grid(ship):
                    continue
                if not no_overlaps(newgrid):
                    continue
                mygrid = list(newgrid)
                break
        bship_logic_submit_grid(self.pid, python_to_grid(mygrid))

    def ai_bomb(self):
        to_bomb = (random.randint(0,9), random.randint(0,9))
        opp = self.opponent()
        # we don't want to repeat positions
        while to_bomb in opp.bomb_history:
            to_bomb = (random.randint(0,9), random.randint(0,9))
        bship_logic_bomb_position(self.pid, to_bomb[0], to_bomb[1])

class ImprovedAIPlayer(AIPlayer):
    "Board colouring and following"

    def __init__(self, pid):
        super(ImprovedAIPlayer, self).__init__(pid)
        self.DIRECTIONS = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        self.favourite_colour = random.randint(0, 3)
        self.initial_moves = [(x,y) for x in range(10) for y in range(10) if (x+y) % 4 == self.favourite_colour]
        random.shuffle(self.initial_moves)

        self.found4 = False
        self.found5 = False
        self.added_extra_moves = False
        self.following = False
        self.base = (0, 0)
        self.index = (0, 0)
        self.hits = [0, 0, 0, 0]
        self.direction = 0

    def ai_submit_grid(self):
        # Use the Random AI placing "algorithm"
        RandomAIPlayer.ai_submit_grid(self)

    def advance_direction(self):
        if self.direction == 3:
            self.following = False
            length = max(self.hits[0] + self.hits[1], self.hits[2] + self.hits[3])
            if length + 1 == 4: self.found4 = True
            if length + 1 == 5: self.found5 = True
            if self.found4 and self.found5 and not self.added_extra_moves:
                self.initial_moves.append([(x,y) for x in range(10) for y in range(10) if (x+y) % 4 == (self.favourite_colour + 2) % 4])
                random.shuffle(self.initial_moves)
                self.added_extra_moves = True
        else:
            self.direction += 1
            print("Direction is not 3. After increment direction is " + str(self.direction))
            self.index = self.DIRECTIONS[self.direction]

    def ai_bomb(self):
        bombed = False
        opp = self.opponent()
        def maybe_bomb(target):
            nonlocal bombed
            if target in opp.bomb_history:
                # If we bombed this cell before, recall the result
                hit = target in opp.ship_points
            else:
                # Otherwise we actually bomb it
                hit = bship_logic_bomb_position(self.pid, target[0], target[1])
                print("Actually bombing " + str(target[0]) + ", " + str(target[1]))
                bombed = True
            return hit
        while not bombed:
            if self.following:
                target = (self.base[0] + self.index[0], self.base[1] + self.index[1])
                print("Following! Target is " + str(target[0]) + "," + str(target[1]) + " (dir " + str(self.direction) + ")")
                if bad_target(target[0], target[1]):
                    self.advance_direction()
                else:
                    hit = maybe_bomb(target)
                    print("Bomb is " + str(hit))
                    if hit:
                        self.index = (self.index[0] + self.DIRECTIONS[self.direction][0], self.index[1] + self.DIRECTIONS[self.direction][1])
                        self.hits[self.direction] = self.hits[self.direction] + 1
                    else:
                        print("Advancing direction!")
                        self.advance_direction()
            else:
                target = self.initial_moves.pop()
                print(self.initial_moves)
                if maybe_bomb(target):
                    self.following = True
                    self.base = target
                    self.index = (0, 0)
                    self.hits = [0, 0, 0, 0]
                    self.direction = 0
