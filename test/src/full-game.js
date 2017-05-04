const api = require('../dist/api')

const actions = []
let step = 0

function next() {
  console.log('starting tests for full game...')
  console.log(`executing step ${step}`)
  actions[step]()
  step += 1
}

let game = -1
let player1 = -2
let player2 = -3
actions.push(() => {
  api.newGame(
    'p1',
    ([gameID, playerID]) => {
      game = gameID
      player1 = playerID      
    },
    (e) => {
      console.error(`Error creating new game: ${e.message}`)
    },
  )
  next()
})
actions.push(() => {
  api.joinGame(
    game,
    'p2',
    (playerID) => {
      player2 = playerID
      api.getOpponentNickname(
        player2,
        (nickname) => {
          console.assert(nickname === 'p1', `Incorrect nickname for p1: ${nickname}`)
          next()
        },
        (e) => {
          console.error(`Error getting nickname: ${e.message}`)
        },
)
    },
    (e) => {
      console.error(`Error joining game: ${e.message}`)
      if (typeof errorCallback === 'function') errorCallback()
    },
      )
})
actions.push(() => {
  api.waitForPlayer(
    player1,
    () => {
      api.getOpponentNickname(
        player1,
        (nickname) => {
          console.assert(nickname === 'p2', `Incorrect nickname for p2: ${nickname}`)
          next()
        },
        (e) => {
          console.error(`Error getting nickname: ${e.message}`)
        },
    )
    },
    (e) => {
      if (e.code === -1000) {
      // timed out
        console.error('timed out waiting for player')
      } else {
        console.error(`Error waiting for player: ${e.message}`)
      }
    },
)
})
actions.push(() => {
  api.submitGrid(
    player1,
    [[2, 1, 6, 1], [0, 2, 3, 2], [1, 3, 3, 3], [2, 4, 4, 4], [2, 5, 2, 6]],
    () => { next() },
    (e) => {
      console.error(`Error submitting grid: ${e.message}`)
    },
)
})
actions.push(() => {
  api.submitGrid(
    player2,
    [[3, 0, 3, 4], [4, 1, 4, 4], [7, 1, 7, 3], [2, 3, 2, 5], [1, 5, 1, 6]],
    () => { next() },
    (e) => {
      console.error(`Error submitting grid: ${e.message}`)
    },
)
})
actions.push(() => {
  api.bombPosition(
    player1,
    3,
    0,
    (hit) => {
      console.assert(hit, 'incorrect hit response')
      next()
    },
    (e) => {
      console.error(`Error bombing: ${e.message}`)
    },
)
})
actions.push(() => {
  api.waitForYourTurn(
    player2,
    () => { next() },
    (e) => {
      console.error(`Error waiting for turn: ${e.message}`)
    },
)
})
actions.push(() => {
  api.bombPosition(
    player2,
    0,
    0,
    (hit) => {
      console.assert(!hit, 'incorrect hit response')
      next()
    },
    (e) => {
      console.error(`Error bombing: ${e.message}`)
    },
)
})
actions.push(() => {
  api.waitForYourTurn(
    player1,
    () => { next() },
    (e) => {
      console.error(`Error waiting for turn: ${e.message}`)
    },
)
})

// Finish bombing
for (let j = 0; j < 7; j++) {
  for (let i = 0; i < 10; i++) {
    if (i !== 3 || j !== 0) {
      actions.push(() => {
        api.bombPosition(
          player1,
          i,
          j,
          (hit) => { next() },
          (e) => {
            console.error(`Error bombing: ${e.message}`)
          },
)
      })
    }
    if (i === 3 && j === 0) {
      actions.push(() => {
        api.bombPosition(
          player1,
          9,
          9,
          (hit) => { next() },
          (e) => {
            console.error(`Error bombing: ${e.message}`)
          },
)
      })
    }
    if (i === 1 && j === 6) {
      break
    }
    if (i !== 0 || j !== 0) {
      actions.push(() => {
        api.bombPosition(
          player2,
          i,
          j,
          (hit) => { next() },
          (e) => {
            console.error(`Error bombing: ${e.message}`)
            next()
          },
)
      })
    }
    if (i === 0 && j === 0) {
      actions.push(() => {
        api.bombPosition(
          player2,
          9,
          9,
          (hit) => { next() },
          (e) => {
            console.error(`Error bombing: ${e.message}`)
          },
      )
      })
    }
  }
}
actions.push(() => {
  api.getGameEnd(
    player1,
    (res) => {
      console.assert(res.game_over, 'Game was not finished when bombing ended')
      console.assert(res.won, 'Player one improperly marked as losing')
      next()
    },
    (e) => {
      console.error(`Error getting game end: ${e.message}`)
    },
)
})
actions.push(() => {
  api.getGameEnd(
    player2,
    (res) => {
      console.assert(res.game_over, 'Game was not finished when bombing ended')
      console.assert(!res.won, 'Player two improperly marked as winning')
      console.log('full-game passed');
    },
    (e) => {
      console.error(`Error getting game end: ${e.message}`)
    },
)
})

module.exports = next
