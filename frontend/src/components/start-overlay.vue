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

<template>
  <div id="overlay">
    <div id="container">
      <startScreen v-if="show === 'start'" v-on:changeScreen="changeScreen"></startScreen>
      <newGameScreen v-if="show === 'newGame'" v-on:changeScreen="changeScreen"></newGameScreen>
      <joinGameScreen v-if="show === 'joinGame'" v-on:changeScreen="changeScreen"></joinGameScreen>
      <serverGameScreen v-if="show === 'serverGame'" v-on:changeScreen="changeScreen"></serverGameScreen>
      <randomGameScreen v-if="show === 'randomGame'" v-on:changeScreen="changeScreen"></randomGameScreen>
    </div>
  </div>
</template>

<script>
import startScreen from './start-screen.vue'
import newGameScreen from './new-game-screen.vue'
import joinGameScreen from './join-game-screen.vue'
import serverGameScreen from './server-game-screen.vue'
import randomGameScreen from './random-game-screen.vue'

export default {
  name: 'overlay',
  data() {
    return {
      show: 'start',
    }
  },
  components: {
    startScreen,
    newGameScreen,
    joinGameScreen,
    serverGameScreen,
    randomGameScreen,
  },
  methods: {
    changeScreen(screen) {
      if (screen === 'game') {
        this.$emit('startGame')
      } else {
        this.show = screen
      }
    },
  },
}
</script>

<style lang="scss">
#overlay {
  position: absolute;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
}

#container {
  align-self: center;
  width: 50%;
  max-width: 300px;
  padding: 1em;
  border: 1px solid #777;
  box-shadow: 0 0 5px rgba(0,0,0,0.5);
  background-color: white;
}
</style>
