<template>
  <div id="app">
    <startOverlay></startOverlay>
    <battleships></battleships>
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
}
</script>

<style>
#app {
  height: 100%;
  width: 100%;
}

html, body {
  padding: 0;
  margin: 0;

  font-family: 'Roboto', 'Helvetica Neue', 'Calibri Light', sans-serif;
}
</style>
