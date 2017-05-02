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
  <div id="app">
    <startOverlay v-show="gameState === 'start'" v-on:startGame="startGame"></startOverlay>
    <battleships v-show="gameState === 'battleships'"></battleships>
    <div id="footer">
      <a href="https://github.com/wzwright/GroupDesignBattleship">
        <img src="./components/assets/GitHub-Mark-32px.png" alt="github logo" width="16" height="16" />
        <span>Find us on GitHub!</span>
      </a>
    </div>
  </div>
</template>

<script>
import startOverlay from './components/start-overlay.vue'
import battleships from './components/battleships.vue'

export default {
  name: 'app',
  components: {
    startOverlay,
    battleships,
  },
  data() {
    return {
      gameState: 'start',
    }
  },
  methods: {
    startGame() {
      this.gameState = 'battleships'
    },
  },
}
</script>

<style lang="scss">
#app {
  height: 100%;
  width: 100%;
}

html, body {
  padding: 0;
  margin: 0;

  font-family: 'Roboto', 'Helvetica Neue', 'Calibri Light', sans-serif;
}

$footer-height: 30px;

body {
  /* so that the footer doesn't obscure text */
  padding-bottom: $footer-height;
}

#footer {
  position: fixed;
  bottom: 0;
  padding: 10px;
  border-top: 1px solid #777;
  background-color: white;
  width: 100%;
  /* for padding */
  height: calc($footer-height - 20px);

  a {
    display: flex;
    align-items: center;
    text-decoration: none;
    color: #777;
    font-size: 0.8em;

    span {
      padding-left: 5px;
    }

    &:hover, &:focus, &:active {
      color: #444;
    }
  }
}
</style>
