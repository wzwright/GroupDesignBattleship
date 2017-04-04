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
      nickname: 'Anonymous',
      ships: {
        carrier: {},
        battleship: {},
        cruiser: {},
        submarine: {},
        destroyer: {},
      },
      localgrid: [],
      grid: [],
      bombs: [],
    },
    opponent: {
      nickname: 'Anonymous',
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
      if (nickname === '') {
        Vue.set(state.player, 'nickname', 'Anonymous')
      } else {
        Vue.set(state.player, 'nickname', nickname)
      }
    },
    setOpponentNickname(state, nickname) {
      if (nickname === '') {
        Vue.set(state.opponent, 'nickname', 'Anonymous')
      } else {
        Vue.set(state.opponent, 'nickname', nickname)
      }
    },
    setShip(state, payload) {
    	const ship = state.player.ships[payload.shipName]
      	if (ship !== undefined) {
      		let { x, y } = payload.position
      		let initialx = x
      		let initialy = y
      		let maxX = x + shipSizes[payload.shipName] - 1
      		let maxY = y + shipSizes[payload.shipName] - 1
        	function checkOverlap() {
          		let takenCoords = []
         		if (payload.rotation === 'h'){
            		for (let i = x; i <= maxX; i++){
              			takenCoords.push({x:i,y})
            		}
          		} else {
            		for (let i = y; i <= maxY; i++){
              			takenCoords.push({x,y:i})
            		}
          		}
          		return (takenCoords.every(function(takenelement){
          			return (state.player.localgrid.every(function(gridelement){
          				return ((gridelement.x !== takenelement.x) || (gridelement.y !== takenelement.y) || (gridelement.ship === ship))
          			}))
          		}))	 
      		}
        	function cleanLocalGrid() {
        		let i = 0
        		state.player.localgrid.forEach(function(gridelement){
        			if (gridelement.ship === ship){
      					state.player.localgrid.splice(i,shipSizes[payload.shipName])
      				}
      				i++
        		})	
        	}
  	    	if ((payload.rotation === 'h') && (maxX <= 9) && checkOverlap()) {
  	      		x = maxX
  	      		Vue.set(ship, 'start', payload.position)
  	      		Vue.set(ship, 'end', { x, y })
	  	  		cleanLocalGrid()
  	      		for (let i = initialx; i <= x; i++){
  	      			state.player.localgrid.push({ship,x:i,y})
  	      		}
              ship.placed=true
  	    	} else if ((payload.rotation !== 'h') && (maxY <= 9) && checkOverlap()) {
  	      		y = maxY
  	      		Vue.set(ship, 'start', payload.position)
  	      		Vue.set(ship, 'end', { x, y })
  	      		cleanLocalGrid()
  	      		for (let i = initialy; i <= y; i++){
  	      			state.player.localgrid.push({ship,x,y:i})
  	      		}
              ship.placed=true  
  	  		}
      	}
    },
    setBombedPositions(state, bombs) {
      Vue.set(state.player, 'bombs', bombs)
    },
    setPlayerShips(state, grid) {
      Vue.set(state.player, 'grid', grid)
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
    joinGame({ dispatch, commit, state }, { gameID, okCallback, errorCallback }) {
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
    submitGrid({ commit, state }, { grid, okCallback, errorCallback }) {
      commit('setPlayerShips', grid)
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
