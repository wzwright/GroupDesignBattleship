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
  <div>
    <div class="rightGridNumbers">
      <span v-for="n in 10">{{n}}</span>
    </div>
    <canvas ref="canvas" v-on:click="sendCoordToParent">
      {{ships}}
      {{bombsHit}}
      {{bombsMissed}}
      {{bombTarget}}
    </canvas>
    <div class="bottomGridChars">
      <span v-for="n in 10">{{"ABCDEFGHIJ"[n-1]}}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'shipCanvas',
  data() {
    return {
      canvas: null,
      ctx: null,
      grid: {
        cellSize: 32,
        cells: 10,
        ocean: Array.from({ length: 100 }, () => Math.floor(Math.random() * 4)),
      },
      sprites: new Image(),
    }
  },
  props: {
    ships: {
      type: Array,
      default: () => [],
    },
    bombsHit: {
      type: Array,
      default: () => [],
    },
    bombsMissed: {
      type: Array,
      default: () => [],
    },
    bombTarget: {
      type: Array,
      default: () => [],
    },
  },
  updated() {
    this.drawGrid()
    this.drawAll()
  },
  mounted() {
    this.canvas = this.$refs.canvas
    this.ctx = this.canvas.getContext('2d')
    this.ctx.imageSmoothingEnabled = false
    this.preloadSprites()
      .then(this.setSize)
      .catch(() => { console.error('Unable to load sprites') })
      // TODO: use the old method of coloured squares when sprites are unable to load
    window.addEventListener('resize', this.setSize)
  },
  methods: {
    // component methods
    setSize() {
      const width = (this.grid.cellSize * this.grid.cells) + 1
      const height = (this.grid.cellSize * this.grid.cells) + 1
      const ratio = window.devicePixelRatio || 1
      this.canvas.width = width * ratio
      this.canvas.height = height * ratio
      this.canvas.style.width = `${width}px`
      this.canvas.style.height = `${height}px`
      this.ctx.scale(ratio, ratio)

      this.drawGrid()
      this.drawAll()
    },
    sendCoordToParent(event) {
      const pos = this.getCoordinate(event.clientX, event.clientY)
      this.$emit('gridClicked', pos)
    },
    getCoordinate(posX, posY) {
      // posX and posY are client coordinates (e.g. from event.clientX)
      // coordinates will be 0-indexed
      // x goes left to right
      // y goes top to bottom (like the canvas coordinates)
      const rect = this.canvas.getBoundingClientRect()
      const x = Math.floor((posX - rect.left) / this.grid.cellSize)
      const y = Math.floor((posY - rect.top) / this.grid.cellSize)
      return { x, y }
    },
    // drawing methods
    preloadSprites() {
      return new Promise((resolve, reject) => {
        const img = new Image()
        img.onload = () => {
          this.sprites = img
          resolve()
        }
        img.onerror = () => reject()
        img.src = require('./assets/sprites.png')
      })
    },
    drawAll() {
      this.drawOcean()
      this.drawShips()
      // draw ocean again before drawing hit ships
      this.drawImageCells(this.bombsHit, 0, 0)
      this.drawImageCells(this.bombsHit, 1, 1)
      this.drawImageCells(this.bombsMissed, 2, 1)
      if (this.bombTarget.length === 2) {
        const [x, y] = this.bombTarget
        this.drawCell(x, y, 'rgba(255, 255, 0, 0.7)')
      }

      this.drawGrid()
    },
    drawOcean() {
      for (let x = 0; x < 10; x++) {
        for (let y = 0; y < 10; y++) {
          const num = this.grid.ocean[(x * 10) + y]
          this.drawImageCell(x, y, num, 0)
        }
      }
    },
    drawShips() {
      this.ships.forEach(([x1, y1, x2, y2]) => {
        if (x1 === x2) {
          // horizontal ship
          for (let y = y1; y <= y2; y++) {
            this.drawImageCell(x1, y, 0, 1)
          }
        } else {
          // vertical ship
          for (let x = x1; x <= x2; x++) {
            this.drawImageCell(x, y1, 0, 1)
          }
        }
      })
    },
    drawImageCells(cells, spritesX, spritesY) {
      for (let i = 0; i < cells.length; i++) {
        const [x, y] = cells[i]
        this.drawImageCell(x, y, spritesX, spritesY)
      }
    },
    drawImageCell(x, y, spritesX, spritesY) {
      // x, y -- target coordinates in grid
      // spritesX, spritesY -- coordinates in spritesheet
      const cellSize = this.grid.cellSize
      this.ctx.drawImage(
        this.sprites,
        spritesX * 32, spritesY * 32, 32, 32,
        x * cellSize, y * cellSize, cellSize, cellSize,
      )
    },
    drawCells(cells, colour) {
      for (let i = 0; i < cells.length; i++) {
        const [x, y] = cells[i]
        this.drawCell(x, y, colour)
      }
    },
    drawCell(x, y, colour) {
      if (x < 0 || x >= 10 || y < 0 || y >= 10) return
      // offset by 1 to factor in gridlines
      this.drawRect(
        (x * this.grid.cellSize) + 1,
        (y * this.grid.cellSize) + 1,
        this.grid.cellSize - 1,
        this.grid.cellSize - 1,
        colour,
      )
    },
    drawRect(x, y, w, h, colour) {
      this.ctx.fillStyle = colour
      this.ctx.fillRect(x, y, w, h)
    },
    drawGrid() {
      const { cellSize, cells } = this.grid

      this.ctx.strokeStyle = 'white'
      this.ctx.lineWidth = 1
      for (let i = 0; i <= cells; i++) {
        this.ctx.beginPath()
        this.ctx.moveTo(0.5, (i * cellSize) + 0.5)
        this.ctx.lineTo((cellSize * cells) + 0.5, (i * cellSize) + 0.5)
        this.ctx.stroke()
      }
      for (let i = 0; i <= cells; i++) {
        this.ctx.beginPath()
        this.ctx.moveTo((i * cellSize) + 0.5, 0.5)
        this.ctx.lineTo((i * cellSize) + 0.5, (cellSize * cells) + 0.5)
        this.ctx.stroke()
      }
    },
  },
}
</script>

<style lang="scss">
canvas {
  border: 1px solid black;
}

$canvasSize: 10*32px;
.rightGridNumbers {
  text-indent: 8px;
  float: right;
  height: $canvasSize;
  display: flex;
  flex-direction: column;
  span {
    flex-grow: 1;
    display: flex;
    align-items: center;
  }
}

.bottomGridChars {
  width: $canvasSize;
  display: flex;
  flex-direction: row;
  span {
    flex-grow: 1;
    text-align: center;
  }
}
</style>
