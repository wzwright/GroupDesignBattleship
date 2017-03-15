<template>
  <canvas ref="canvas" v-on:click="sendCoordToParent">
    {{ships}}
    {{bombsOK}}
    {{bombsFailed}}
    {{bombTarget}}
  </canvas>
</template>

<script>
export default {
  name: 'shipCanvas',
  data() {
    return {
      canvas: null,
      ctx: null,
      grid: {
        cellSize: 30,
        cells: 10,
      },
    }
  },
  props: {
    ships: {
      type: Object,
      default: () => {},
    },
    bombsOK: {
      type: Array,
      default: () => [],
    },
    bombsFailed: {
      type: Array,
      default: () => [],
    },
    bombTarget: {
      type: Array,
      default: () => [],
    },
  },
  updated() {
    this.clearGrid()
    this.drawAll()
  },
  mounted() {
    this.canvas = this.$refs.canvas
    this.ctx = this.canvas.getContext('2d')
    this.setSize()
    this.drawGrid()
    this.drawAll()
    window.addEventListener('resize', this.setSize)
  },
  methods: {
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
    },
    sendCoordToParent(event) {
      let pos = this.getCoordinate(event.clientX, event.clientY)
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
    clearGrid() {
      for (let x = 0; x <= 10; x++) {
        for (let y = 0; y <= 10; y++) {
          this.drawCell(x, y, 'white')
        }
      }
    },
    clearAll() {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    },
    drawAll() {
      this.drawShips()
      this.drawCells(this.bombsOK, 'red')
      this.drawCells(this.bombsFailed, 'skyblue')
      if (this.bombTarget.length === 2) {
        const [x, y] = this.bombTarget
        this.drawCell(x, y, 'yellow')
      }
    },
    drawShips() {
      for (const key in this.ships) {
        const ship = this.ships[key]
        if (ship.start !== undefined) {
          const { x: x1, y: y1 } = ship.start
          const { x: x2, y: y2 } = ship.end

          if (x1 === x2) {
            // horizontal ship
            for (let y = y1; y <= y2; y++) {
              this.drawCell(x1, y, 'steelblue')
            }
          } else {
            // vertical ship
            for (let x = x1; x <= x2; x++) {
              this.drawCell(x, y1, 'steelblue')
            }
          }
        }
      }
    },
    drawCells(cells, colour) {
      for (let i = 0; i < cells.length; i++) {
        let [x, y] = cells[i]
        this.drawCell(x, y, colour)
      }
    },
    drawRect(x, y, w, h, colour) {
      this.ctx.fillStyle = colour
      this.ctx.fillRect(x, y, w, h)
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
    drawGrid() {
      this.ctx.fillStyle = 'black'
      this.ctx.lineWidth = 1
      const { cellSize, cells } = this.grid
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
</style>
