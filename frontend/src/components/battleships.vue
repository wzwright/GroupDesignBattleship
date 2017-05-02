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
  <div id="battleships">
    <shipSelector v-if="show === 'shipSelector'"
      v-on:changeScreen="changeScreen"></shipSelector>
    <bombingScreen v-if="show === 'bombingScreen'"
      v-on:changeScreen="changeScreen"></bombingScreen>
  </div>
</template>

<script>
import shipSelector from './ship-selector.vue'
import bombingScreen from './bombing-screen.vue'

export default {
  name: 'battleships',
  components: {
    shipSelector,
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
#battleships {
  height: 100%;
}
</style>
