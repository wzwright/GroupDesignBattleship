<template>
  <div>
    <p>Your code is:</p>
    <p class="code">{{code}}</p>
    <p>Your opponent should click "Join Existing Game" and enter the code above.</p>
  </div>
</template>


<script>
export default {
  name: 'newGameScreen',
  computed: {
    code() {
      const gameID = this.$store.state.game.ID
      if (gameID !== undefined) {
        // convert gameID into a code made of numbers and letters
        return gameID.toString(10 + 26).toUpperCase()
      }
      return gameID
    },
  },
  mounted() {
    this.$store.dispatch('waitForPlayer', {
      okCallback: () => {
        this.$emit('changeScreen', 'noOverlay')
      },
    })
  },
}
</script>

<style lang="scss">
p {
  margin: 0;
}

.code {
  font-size: 3.5em;
  text-align: center;
}
</style>
