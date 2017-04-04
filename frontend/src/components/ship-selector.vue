/**
 * Copyright (C) 2017 by Oxford 2017 Group Design Practical Team 9
 *
 * This file is part of GroupDesignBattleship.
 *
 * GroupDesignBattleship is free software: you can redistribute it
 * and/or modify it under the terms of the GNU Affero General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * GroupDesignBattleship is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with GroupDesignBattleship. If not, see
 * <http://www.gnu.org/licenses/>.
 */

<template>
  <div id="ships-container">
    <div id="ships">
      <button v-on:click="setActiveShip('carrier')" v-bind:class="selectionClass('carrier')">Carrier (5)</button>
      <button v-on:click="setActiveShip('battleship')" v-bind:class="selectionClass('battleship')">Battleship (4)</button>
      <button v-on:click="setActiveShip('cruiser')" v-bind:class="selectionClass('cruiser')">Cruiser (3)</button>
      <button v-on:click="setActiveShip('submarine')" v-bind:class="selectionClass('submarine')">Submarine (3)</button>
      <button v-on:click="setActiveShip('destroyer')" v-bind:class="selectionClass('destroyer')">Destroyer (2)</button>
      <button v-on:click="setActiveRotation()">rotate</button>
      <button id="submit" v-on:click="submitGrid">Submit</button>
    </div>
    <shipCanvas id="ship-canvas"
      v-on:gridClicked="selectShip"
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
      const ships = this.$store.state.player.ships
      let grid = []
      for (const key in ships) {
        const ship = ships[key]
        if (typeof ship.start !== 'undefined') {
          const { x: x1, y: y1 } = ship.start
          const { x: x2, y: y2 } = ship.end

          grid.push([x1, y1, x2, y2])
        }
      }

      return grid
    },
  },
  methods: {
    selectShip(pos) {
      this.$store.commit('setShip',
        {
          shipName: this.activeShip,
          position: pos,
          rotation: this.activeRotation,
        },
      )
    },
    submitGrid() {
      this.$store.dispatch('submitGrid', {
        grid: this.ships,
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
    selectionClass(s){
      return this.$store.state.player.ships[s].placed?"placed":"notPlaced"
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

#ship-canvas {
  /*
   * using margin rather than padding is important
   * since 'getBoundingClientRect' is affected
   */
  margin: 20px;
}

.placed {
  color:green;
}
.notPlaced{
  color:red;
}
</style>
