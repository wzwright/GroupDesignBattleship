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
        bship_logic_bomb_position(self.pid, random.randint(0,9), random.randint(0,9))

    def ai_cleanup(self):
        pass
