<template>
  <div id="bombingScreen">
    <div class="shipContainer">
      <p>{{opponentNickname}}'s ships</p>
      <opponentCanvas class="bombingCanvas"
         v-on:keyup.enter.native="bombSubmit"
         v-bind:bombsOK="bombsOK"
         v-bind:bombsFailed="bombsFailed"
         v-bind:bombTarget="bombTarget"
         v-on:gridClicked="bombSelect"
      ></opponentCanvas>
      <button
        v-show="phase === 'bomb'"
        v-on:click="bombSubmit"
      >Bomb!</button>
    </div>
    <div class="shipContainer playerShipContainer">
      <p>{{playerNickname}}'s ships</p>
      <playerCanvas class="bombingCanvas"
         v-bind:ships="playerShips"
         v-bind:bombsOK="playerBombs"
      ></playerCanvas>
    </div>

    <div class="message">
      <p v-if="phase === 'bomb'">Click on a place on your opponent's board and click 'bomb' to bomb them!</p>
      <p v-if="phase === 'bomb'">Red means a successful attack, blue means you missed.</p>
      <p v-if="phase === 'wait'">Waiting for your opponent to make a move.</p>
      <p v-if="phase === 'gameOver' && won">You win!</p>
      <p v-if="phase === 'gameOver' && !won">You lose!</p>
    </div>
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
    playerNickname() {
      return this.$store.state.player.nickname
    },
    opponentNickname() {
      return this.$store.state.opponent.nickname
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
          this.$store.dispatch('getBombedPositions', {
            okCallback: () => {
              this.$store.dispatch('getGameEnd', {
                okCallback: ({ gameOver, won }) => {
                  if (gameOver) {
                    this.won = won
                    this.phase = 'gameOver'
                  } else {
                    this.phase = 'bomb'
                  }
                },
              })
            },
          })
        },
      })
    },
  },
}
</script>

<style lang="scss">
#bombingScreen {
  text-align: center;
}

.shipContainer {
  display: inline-flex;
  flex-direction: column;
  margin: 1em 3em;

  button {
    display: block;
    width: 100%;
    font-size: 1.3em;
    padding: 0.5em;
    margin: 1em auto;
  }

  p {
    margin: 1em;
    text-align: center;
  }
}

.message {
  text-align: center;

  p {
    margin: 0.5em auto;
  }
}

.playerShipContainer {
  padding-bottom: 6em;
}
</style>
