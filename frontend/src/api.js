/**
 * Copyright (C) 2017 by Oxford 2017 Group Design Practical Team 9
 *
 * This file is part of GroupDesignBattleship.
 *
 * GroupDesignBattleship is free software: you can redistribute it
 * and/or modify it under the terms of the GNU Affero General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * GroupDesignBattleship is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with GroupDesignBattleship. If not, see
 * <http://www.gnu.org/licenses/>.
 */

const JRPC = require('jrpc')
const LongWebSocket = require('longwebsocket')

const remote = new JRPC({ client: true })
const ws = new LongWebSocket({
  // defined in webpack
  url: API_URL,
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

// Takes a nickname, result is an array like [gameID, playerID]
export function newGame(nickname, okCallback, errorCallback) {
  doRPC('newGame', [nickname], okCallback, errorCallback)
}

// Takes a gameID and nickname, result is a playerID
export function joinGame(gameID, nickname, okCallback, errorCallback) {
  doRPC('joinGame', [gameID, nickname], okCallback, errorCallback)
}

// Takes a nickname, result is a playerID
export function joinRandomGame(nickname, okCallback, errorCallback) {
  doRPC('joinRandomGame', [nickname], okCallback, errorCallback)
}

// Takes a playerID, result is the opponent's nickname
export function getOpponentNickname(playerID, okCallback, errorCallback) {
  doRPC('getOpponentNickname', [playerID], okCallback, errorCallback)
}

// Takes a nickname, result is a playerID
export function joinAIGame(nickname, AILevel, okCallback, errorCallback) {
  doRPC('joinAIGame', [nickname, AILevel], okCallback, errorCallback)
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

// Takes a playerID, returns when the game has died.
export function waitForGameDied(playerID, okCallback, errorCallback) {
  doRPC('waitForGameDied', [playerID], okCallback, errorCallback)
}
