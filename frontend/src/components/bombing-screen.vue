<template>
  <div id="bombingScreen">
    <div class="shipContainer">
      <p>{{opponentNickname}}'s ships</p>
      <opponentCanvas class="bombingCanvas"
         v-on:keyup.enter.native="bombSubmit"
         v-bind:ships="opponentShips"
         v-bind:bombsOK="bombsOK"
         v-bind:bombsFailed="bombsFailed"
         v-bind:bombTarget="bombTarget"
         v-on:gridClicked="bombSelect"
      ></opponentCanvas>
      <button
        v-show="phase === 'bomb'"
        v-on:click="bombSubmit"
      >Bomb!</button>
      <p>Turn Number: {{turnNumber}}</p>
      <p>Successful hits: {{playerSuccessfulBombs}}</p>
      <p>Hit Rate: {{playerHitRate}}%</p>
      <p>Left to hit: {{17-playerSuccessfulBombs}}</p>
    </div>
    <div class="shipContainer playerShipContainer">
      <p>{{playerNickname}}'s ships</p>
      <playerCanvas class="bombingCanvas"
         v-bind:ships="playerShips"
         v-bind:bombsOK="playerBombsOK"
         v-bind:bombsFailed="playerBombsFailed"
      ></playerCanvas>
      <p>Successful hits: {{opponentSuccessfulBombs}}</p>
      <p>Hit Rate: {{opponentHitRate}}%</p>
      <p>Left to hit: {{17-opponentSuccessfulBombs}}</p>
    </div>
    <div class="message">
      <p v-if="phase === 'bomb'">Click on a place on your opponent's board and click 'bomb' to bomb them!</p>
      <p v-if="phase === 'wait'">Waiting for your opponent...</p>
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
      playerBombsOK: [],
      playerBombsFailed: [],
      won: false,
      turnNumber: 0,
      playerSuccessfulBombs: 0,
      opponentSuccessfulBombs: 0,
      playerHitRate: 100,
      opponentHitRate: 100,
    }
  },
  computed: {
    playerShips() {
      return this.$store.state.player.grid
    },
    playerNickname() {
      return this.$store.state.player.nickname
    },
    opponentShips() {
      return this.$store.state.opponent.grid
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
          	this.playerSuccessfulBombs++
          	this.playerHitRate = (this.playerSuccessfulBombs/this.turnNumber)*100
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
            this.playerHitRate = (this.playerSuccessfulBombs/this.turnNumber)*100
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
              this.calculateBombTypes()
              this.$store.dispatch('getGameEnd', {
                okCallback: ({ gameOver, won }) => {
                  if (gameOver) {
                    this.won = won
                    this.phase = 'gameOver'
                  } else {
                    this.phase = 'bomb'
                    this.opponentSuccessfulBombs = this.playerBombsOK.length
                    this.turnNumber++
                    if ((this.opponentSuccessfulBombs !== 0) || (this.playerBombsFailed.length !== 0)){
                    	this.opponentHitRate = (this.opponentSuccessfulBombs/(this.playerBombsFailed.length+this.opponentSuccessfulBombs))*100
                    }
                  }
                },
              })
            },
          })
        },
      })
    },
    calculateBombTypes() {
      const bombs = this.$store.state.player.bombs
      let bombsOK = []
      let bombsFailed = []
      bombs.forEach((bomb) => {
        let [x, y] = bomb
        let hitAShip = this.playerShips.reduce(
          (acc, [x1, y1, x2, y2]) => acc || (x1 <= x && x <= x2 && y1 <= y && y <= y2)
        , false)

        if (hitAShip) {
          bombsOK.push(bomb)
        } else {
          bombsFailed.push(bomb)
        }
      })

      this.playerBombsOK = bombsOK
      this.playerBombsFailed = bombsFailed
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
