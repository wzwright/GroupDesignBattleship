<template>
  <p>Waiting for your opponent...</p>
</template>

<script>
export default {
  name: 'waitingScreen',
  mounted() {
    this.$store.dispatch('waitForYourTurn', {
      okCallback: () => {
        this.$emit('changeScreen', 'bombingScreen')
      },
    })
  },
}
</script>

<style lang="scss">
</style>
