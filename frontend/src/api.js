const JRPC = require('jrpc')
const LongWebSocket = require('longwebsocket')

const remote = new JRPC({ client: true })
const ws = new LongWebSocket({
  url: 'wss://bship.ieval.ro:8080/',
  protocols: [],
  onopen() {
    remote.setTransmitter((msg, next) => {
      try {
        ws.send(msg)
        return next(false)
      } catch (e) {
        console.error(e)
        return next(true)
      }
    })
  },
  onmessage(data) {
    remote.receive(data)
  },
})

function doRPC(method, args, okCallback, errorCallback) {
  remote.call(method, args, (error, result) => {
    if (error) errorCallback(error)
    else okCallback(result)
  })
}

// Takes no arguments, result is an array like [gameID, playerID]
export function newGame(okCallback, errorCallback) {
  doRPC('newGame', null, okCallback, errorCallback)
}

// Takes a gameID, result is a playerID
export function joinGame(gameID, okCallback, errorCallback) {
  doRPC('joinGame', [gameID], okCallback, errorCallback)
}

/*
 * Takes a playerID and an array like [[0,2,3,2], [3,7,3,9], ...] of 5
 * elements (for 5 ships). Result is null.
 */
export function submitGrid(playerID, grid, okCallback, errorCallback) {
  doRPC('submitGrid', [playerID, grid], okCallback, errorCallback)
}

// Takes a playerID, result is an array like [[0,3], [5,1], ...]
export function getBombedPositions(playerID, okCallback, errorCallback) {
  doRPC('getBombedPositions', [playerID], okCallback, errorCallback)
}

/*
 * Takes a playerID and two coordinates, returns a boolean indicating
 * whether the bomb hit.
 */
export function bombPosition(playerID, x, y, okCallback, errorCallback) {
  doRPC('bombPosition', [playerID, x, y], okCallback, errorCallback)
}

/*
 * Takes a playerID, returns an object with keys game_over, won, grid.
 * First two are booleans, last is either null or a 5-element array
 * like the one given to submitGrid.
 */
export function getGameEnd(playerID, okCallback, errorCallback) {
  doRPC('getGameEnd', [playerID], okCallback, errorCallback)
}

// Takes a playerID, returns when the other player has joined the game.
export function waitForPlayer(playerID, okCallback, errorCallback) {
  doRPC('waitForPlayer', [playerID], okCallback, errorCallback)
}

// Takes a playerID, returns when it is your turn to bomb.
export function waitForYourTurn(playerID, okCallback, errorCallback) {
  doRPC('waitForYourTurn', [playerID], okCallback, errorCallback)
}

// Takes a playerID, returns when the game has ended.
export function waitForGameEnd(playerID, okCallback, errorCallback) {
  doRPC('waitForGameEnd', [playerID], okCallback, errorCallback)
}
