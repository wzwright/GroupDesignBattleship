import Vue from 'vue'
import Vuex from 'vuex'
import * as api from './api'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    player: {
      ID: undefined,
      ships: {
        carrier: {
          size: 5,
        },
        battleship: {
          size: 4,
        },
        cruiser: {
          size: 3,
        },
        submarine: {
          size: 3,
        },
        destroyer: {
          size: 2,
        },
      },
    },
    opponent: {
      ID: undefined,
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
    setShip(state, payload) {
      // TODO: don't allow invalid ships to be committed
      const ship = state.player.ships[payload.shipName]
      if (ship !== undefined) {
        Vue.set(ship, 'start', payload.position)
        let { x, y } = payload.position
        if (payload.rotation === 'h') {
          x += ship.size - 1
        } else {
          y += ship.size - 1
        }
        Vue.set(ship, 'end', { x, y })
      }
    },
  },
  actions: {
    newGame({ commit, state }, { okCallback, errorCallback }) {
      api.newGame(
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
    waitForPlayer({ state }, { okCallback, errorCallback }) {
      api.waitForPlayer(
        state.player.ID,
        () => {
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error waiting for player: ${e.message}`)
          if (typeof errorCallback === 'function') errorCallback()
        },
      )
    },
    joinGame({ commit }, { gameID, okCallback, errorCallback }) {
      api.joinGame(
        gameID,
        (playerID) => {
          commit('setGameID', gameID)
          commit('setPlayerID', playerID)
          if (typeof okCallback === 'function') okCallback()
        },
        (e) => {
          console.error(`Error joining game: ${e.message}`)
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
  },
})
