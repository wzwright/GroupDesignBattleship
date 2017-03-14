<template>
  <div>
    <div class="shipContainer">
      <p>Opponent's ships</p>
      <opponentCanvas
         v-on:keyup.enter.native="bombSubmit"
         v-bind:bombsOK="bombsOK"
         v-bind:bombsFailed="bombsFailed"
         v-bind:bombTarget="bombTarget"
         v-on:gridClicked="bombSelect"
      ></opponentCanvas>
      <button
        v-if="phase === 'bomb'"
        v-on:click="bombSubmit"
      >Bomb!</button>
    </div>
    <div class="shipContainer">
      <p>Your ships</p>
      <playerCanvas
         v-bind:ships="playerShips"
         v-bind:bombsOK="playerBombs"
      ></playerCanvas>
    </div>
    <p v-if="phase === 'bomb'">Click on a place on your opponent's board and click 'bomb' to bomb them!</p>
    <p v-if="phase === 'wait'">Wait for your opponent to make a move.</p>
    <p v-if="phase === 'gameOver' && won">You win!</p>
    <p v-if="phase === 'gameOver' && !won">You lose!</p>
  </div>
</template>

<script>
import canvas from './ship-canvas.vue'

export default {
  name: 'bombingScreen',
  components: {
    opponentCanvas: canvas,
    playerCanvas: canvas,
  },
  data() {
    return {
      // phase is either 'bomb', 'wait' or 'gameOver'
      phase: 'wait',
      bombsOK: [],
      bombsFailed: [],
      bombTarget: [],
      won: false,
    }
  },
  computed: {
    playerShips() {
      return this.$store.state.player.ships
    },
    playerBombs() {
      return this.$store.state.player.bombs
    },
  },
  mounted() {
    this.wait()
  },
  methods: {
    bombSelect({ x, y }) {
      this.bombTarget = [x, y]
    },
    bombSubmit() {
      this.$store.dispatch('bombPosition', {
        pos: this.bombTarget,
        okCallback: (bombSucceeded) => {
          if (bombSucceeded) {
            this.bombsOK.push(this.bombTarget)
            this.$store.dispatch('getGameEnd', {
              okCallback: ({ gameOver, won }) => {
                if (gameOver) {
                  this.won = won
                  this.phase = 'gameOver'
                } else {
                  this.wait()
                }
              },
            })
          } else {
            this.bombsFailed.push(this.bombTarget)
            this.wait()
          }
        },
      })
    },
    wait() {
      this.phase = 'wait'
      this.bombTarget = []
      this.$store.dispatch('waitForYourTurn', {
        okCallback: () => {
          console.log('getting game end');
          this.$store.dispatch('getGameEnd', {
            okCallback: ({ gameOver, won }) => {
              console.log(`go: ${gameOver}`);
              if (gameOver) {
                this.won = won
                this.phase = 'gameOver'
              } else {
                console.log('getting bomb positions');
                this.$store.dispatch('getBombedPositions', {
                  okCallback: () => {
                    this.phase = 'bomb'
                  },
                })
              }
            },
          })
        },
      })
    },
  },
}
</script>

<style lang="scss">
.shipContainer {
  display: inline-flex;
  flex-direction: column;
  margin-top: 1em;

  button {
    display: block;
    margin: 1em auto;
  }

  p {
    text-align: center;
  }
}
</style>
