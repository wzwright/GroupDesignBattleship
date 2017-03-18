<template>
  <div id="start-screen">
    <button v-on:click="newGame">New Game</button>
    <button v-on:click="joinGame">Join Existing Game</button>
  </div>
</template>

<script>
export default {
  name: 'startScreen',
  methods: {
    newGame() {
      this.$store.dispatch('newGame', {
        okCallback: () => {
          this.$emit('changeScreen', 'newGame')
        },
      })
    },
    joinGame() {
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
