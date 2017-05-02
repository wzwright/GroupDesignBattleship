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
  <div>
    <textInput
      inputID="code"
      ref="code"
      label="Code:"
      v-on:input="updateUserInput"
      v-on:keyup.enter.native="joinGame"
    ></textInput>
    <button id="joinGame" v-on:click="joinGame">Join Game</button>
  </div>
</template>

<script>
import textInput from './text-input.vue'

export default {
  name: 'joinScreen',
  components: {
    textInput,
  },
  data() {
    return {
      gameCode: '',
    }
  },
  methods: {
    updateUserInput(code) {
      this.gameCode = code
    },
    joinGame() {
      // convert gameID into a code made of numbers and letters
      const code = parseInt(this.gameCode, 10 + 26)
      if (!isNaN(code)) {
        this.$store.dispatch('joinGame', {
          gameID: code,
          okCallback: () => {
            this.$emit('changeScreen', 'game')
          },
          errorCallback: () => {
            // TODO: tell the user something went wrong
          },
        })
      }
    },
  },
  mounted() {
    this.$refs.code.focus()
  },
}
</script>

<style lang="scss">
</style>
