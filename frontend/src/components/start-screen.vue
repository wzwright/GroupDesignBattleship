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
  <div id="start-screen">
    <textInput
      inputID="nickname"
      ref="nickname"
      label="Nickname:"
      placeholder="Anonymous"
      v-on:input="updateNickname"
    ></textInput>
    <button v-on:click="newGame">New Game</button>
    <button v-on:click="joinGame">Join Existing Game</button>
    <button v-on:click="serverGame">Play against the server</button>
    <button v-on:click="joinRandomGame" ref="random">Join Random Game</button>
  </div>
</template>

<script>
import textInput from './text-input.vue'

export default {
  name: 'startScreen',
  components: {
    textInput,
  },
  data() {
    return {
      nickname: '',
    }
  },
  mounted() {
    this.$refs.nickname.focus()
  },
  methods: {
    updateNickname(nickname) {
      this.nickname = nickname
    },
    newGame() {
      this.$store.commit('setPlayerNickname', this.nickname)
      this.$store.dispatch('newGame', {
        okCallback: () => {
          this.$emit('changeScreen', 'newGame')
        },
      })
    },
    joinGame() {
      this.$store.commit('setPlayerNickname', this.nickname)
      this.$emit('changeScreen', 'joinGame')
    },
    serverGame() {
      this.$store.commit('setPlayerNickname', this.nickname)
      this.$emit('changeScreen', 'serverGame')
    },
    joinRandomGame() {
      this.$store.commit('setPlayerNickname', this.nickname)
      this.$store.dispatch('joinRandomGame', {
        okCallback: () => {
          this.$refs.random.innerText = 'Waiting...'
          this.$store.dispatch('waitForPlayer', {
            okCallback: () => {
              this.$store.dispatch('getOpponentNickname', {})
              this.$emit('changeScreen', 'noOverlay')
            },
          })
        },
      })
    },
  },
}
</script>

<style lang="scss">
#start-screen {
  display: flex;
  flex-direction: column;

  button {
    width: 100%;
    margin: 3px auto;
  }
}
</style>
