<template>
  <div id="ships-container">
    <div id="ships">
      <button v-on:click="setActiveShip('carrier')">Carrier (5)</button>
      <button v-on:click="setActiveShip('battleship')">Battleship (4)</button>
      <button v-on:click="setActiveShip('cruiser')">Cruiser (3)</button>
      <button v-on:click="setActiveShip('submarine')">Submarine (3)</button>
      <button v-on:click="setActiveShip('destroyer')">Destroyer (2)</button>
      <button v-on:click="setActiveRotation()">rotate</button>
      <button id="submit" v-on:click="submitGrid">Submit</button>
    </div>
    <shipCanvas
      ref="shipCanvas"
      v-on:click.native="clickAction"
      v-bind:ships="ships"
      v-bind:bombs="bombs"
    ></shipCanvas>
  </div>
</template>

<script>
import shipCanvas from './ship-canvas.vue'

export default {
  name: 'shipSelector',
  components: {
    shipCanvas,
  },
  data() {
    return {
      activeShip: 'carrier',
      activeRotation: 'h',
      bombs: [],
    }
  },
  computed: {
    ships() {
      return this.$store.state.player.ships
    },
  },
  methods: {
    clickAction(event) {
      const pos = this.$refs.shipCanvas.getCoordinate(event.clientX, event.clientY)
      this.$store.commit('setShip',
        {
          shipName: this.activeShip,
          position: pos,
          rotation: this.activeRotation,
        },
      )
    },
    submitGrid() {
      let grid = []
      for (const key in this.ships) {
        const ship = this.ships[key]
        if (typeof ship.start !== 'undefined') {
          const { x: x1, y: y1 } = ship.start
          const { x: x2, y: y2 } = ship.end

          grid.push([x1, y1, x2, y2])
        }
      }

      // TODO: FIX: This is giving an "Invalid Grid" error
      this.$store.dispatch('submitGrid', {
        grid,
        okCallback: () => {
          this.$emit('changeScreen', 'bombingScreen')
        },
      })
    },
    setActiveRotation() {
      if (this.activeRotation === 'h') this.activeRotation = 'v'
      else this.activeRotation = 'h'
    },
    setActiveShip(ship) {
      this.activeShip = ship
    },
  },
}
</script>

<style lang="scss">
#ships-container {
  display: flex;
  flex-direction: row;
}

#ships {
  width: 200px - 10px;
  padding: 10px;
  display: flex;
  flex-direction: column;

  button {
    width: 100%;
    margin: 3px auto;
  }
}
</style>
