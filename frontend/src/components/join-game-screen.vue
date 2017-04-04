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
            this.$emit('changeScreen', 'noOverlay')
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
