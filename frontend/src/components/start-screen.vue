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
    joinRandomGame() {
      this.$store.commit('setPlayerNickname', this.nickname)
      this.$store.dispatch('joinRandomGame', {
        okCallback: () => {
          this.$refs.random.innerText="Waiting..."
          this.$store.dispatch('waitForPlayer', {
            okCallback: () => {
              this.$store.dispatch('getOpponentNickname', {})
              this.$emit('changeScreen', 'noOverlay')
            },
          })
        },
      })
    }
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
