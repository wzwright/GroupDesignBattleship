<template>
  <div>
    <shipSelector v-if="show === 'shipSelector'"
      v-on:changeScreen="changeScreen"></shipSelector>
    <waitingScreen v-if="show === 'waitingScreen'"
      v-on:changeScreen="changeScreen"></waitingScreen>
    <bombingScreen v-if="show === 'bombingScreen'"
      v-on:changeScreen="changeScreen"></bombingScreen>
  </div>
</template>

<script>
import shipSelector from './ship-selector.vue'
import waitingScreen from './waiting-screen.vue'
import bombingScreen from './bombing-screen.vue'

export default {
  name: 'battleships',
  components: {
    shipSelector,
    waitingScreen,
    bombingScreen,
  },
  data() {
    return {
      show: 'shipSelector',
    }
  },
  methods: {
    changeScreen(screen) {
      this.show = screen
    },
  },
}
</script>

<style lang="scss">
canvas {
  width: 100vw;
  height: 100vh;
}
</style>
