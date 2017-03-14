<template>
  <div id="overlay" v-if="show !== 'noOverlay'">
    <div id="container">
      <startScreen v-if="show === 'start'" v-on:changeScreen="changeScreen"></startScreen>
      <newGameScreen v-if="show === 'newGame'" v-on:changeScreen="changeScreen"></newGameScreen>
      <joinGameScreen v-if="show === 'joinGame'" v-on:changeScreen="changeScreen"></joinGameScreen>
    </div>
  </div>
</template>

<script>
import startScreen from './start-screen.vue'
import newGameScreen from './new-game-screen.vue'
import joinGameScreen from './join-game-screen.vue'

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
  },
  methods: {
    changeScreen(screen) {
      this.show = screen
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
