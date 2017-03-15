import Vue from 'vue'
import Vuex from 'vuex'
import * as api from './api'

Vue.use(Vuex)

const shipSizes = {
  carrier: 5,
  battleship: 4,
  cruiser: 3,
  submarine: 3,
  destroyer: 2,
}

export default new Vuex.Store({
  state: {
    player: {
      ID: undefined,
      nickname: 'anonymous',
      ships: {
        carrier: {},
        battleship: {},
        cruiser: {},
        submarine: {},
        destroyer: {},
      },
      bombs: [],
    },
    opponent: {
      nickname: 'anonymous',
      grid: [],
    },
    game: {
      ID: undefined,
    },
  },
  mutations: {
    setGameID(state, ID) {
      Vue.set(state.game, 'ID', ID)
    },
    setPlayerID(state, ID) {
      Vue.set(state.player, 'ID', ID)
    },
    setPlayerNickname(state, nickname) {
      Vue.set(state.player, 'nickname', nickname)
    },
    setOpponentNickname(state, nickname) {
      Vue.set(state.opponent, 'nickname', nickname)
    },
    setShip(state, payload) {
      // TODO: don't allow invalid ships to be committed
      const ship = state.player.ships[payload.shipName]
      if (ship !== undefined) {
        Vue.set(ship, 'start', payload.position)
        let { x, y } = payload.position
        if (payload.rotation === 'h') {
          x += shipSizes[payload.shipName] - 1
        } else {
          y += shipSizes[payload.shipName] - 1
        }
        Vue.set(ship, 'end', { x, y })
      }
    },
    setBombedPositions(state, bombs) {
      Vue.set(state.player, 'bombs', bombs)
    },
    setOpponentShips(state, grid) {
      Vue.set(state.opponent, 'grid', grid)
    },
  },
  actions: {
    newGame({ commit, state }, { okCallback, errorCallback }) {
      api.newGame(
        state.player.nickname,
        ([gameID, playerID]) => {
          commit('setGameID', gameID)
          commit('setPlayerID', playerID)
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error creating new game: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    waitForPlayer({ dispatch, state }, { okCallback, errorCallback }) {
      api.waitForPlayer(
        state.player.ID,
        () => {
          dispatch('getOpponentNickname', {})
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          if (e.code === -1000) {
            // timed out
            console.warn('Timed out waiting for player, trying again...')
            dispatch('waitForPlayer', { okCallback, errorCallback })
          } else {
            console.error(`Error waiting for player: ${e.message}`)
            if (typeof errorCallback === 'function') errorCallback()
          }
        },
      )
    },
    joinGame({ dispatch, commit, state }, { gameID, nickname, okCallback, errorCallback }) {
      api.joinGame(
        gameID,
        state.player.nickname,
        (playerID) => {
          commit('setGameID', gameID)
          commit('setPlayerID', playerID)
          dispatch('getOpponentNickname', {})
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error joining game: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    getOpponentNickname({ commit, state }, { okCallback, errorCallback }) {
      api.getOpponentNickname(
        state.player.ID,
        (nickname) => {
          commit('setOpponentNickname', nickname)
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error getting nickname: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    submitGrid({ state }, { grid, okCallback, errorCallback }) {
      api.submitGrid(
        state.player.ID,
        grid,
        () => {
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error submitting grid: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    waitForYourTurn({ dispatch, state }, { okCallback, errorCallback }) {
      api.waitForYourTurn(
        state.player.ID,
        () => {
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          if (e.code === -1000) {
            // timed out
            console.warn('Timed out waiting for turn, trying again...')
            dispatch('waitForYourTurn', { okCallback, errorCallback })
          } else {
            console.error(`Error waiting for turn: ${e.message}`)
            if (typeof errorCallback === 'function') errorCallback()
          }
        },
      )
    },
    bombPosition({ state }, { pos, okCallback, errorCallback }) {
      const [x, y] = pos
      api.bombPosition(
        state.player.ID,
        x,
        y,
        (bombSuccess) => {
          if (typeof okCallback === 'function') okCallback(bombSuccess)
        },
        (e) => {
          console.error(`Error bombing position [${x}, ${y}] : ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    getBombedPositions({ commit, state }, { okCallback, errorCallback }) {
      api.getBombedPositions(
        state.player.ID,
        (bombedPositions) => {
          commit('setBombedPositions', bombedPositions)
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error getting bombed positions: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    // Note: not actually used
    waitForGameEnd({ dispatch, state }, { okCallback, errorCallback }) {
      api.waitForGameEnd(
        state.player.ID,
        () => {
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          if (e.code === -1000) {
            // timed out
            console.warn('Timed out waiting for game end, trying again...')
            dispatch('waitForGameEnd', { okCallback, errorCallback })
          } else {
            console.error(`Error waiting for game end: ${e.message}`)
            if (typeof errorCallback === 'function') errorCallback()
          }
        },
      )
    },
    getGameEnd({ commit, state }, { okCallback, errorCallback }) {
      api.getGameEnd(
        state.player.ID,
        ({ game_over: gameOver, won, grid }) => {
          if (gameOver) {
            commit('setOpponentShips', grid)
          }
          if (typeof okCallback === 'function') okCallback({ gameOver, won })
        },
        (e) => {
          console.error(`Error getting game end: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
  },
})
