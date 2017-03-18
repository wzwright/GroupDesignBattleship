<template>
  <div id="start-screen">
    <textInput
      inputID="nickname"
      label="Nickname:"
      placeholder="Anonymous"
      v-on:input="updateNickname"
    ></textInput>
    <button v-on:click="newGame">New Game</button>
    <button v-on:click="joinGame">Join Existing Game</button>
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
