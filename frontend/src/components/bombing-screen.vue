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
  <div id="bombingScreen">
    <div class="shipContainer">
      <p>{{opponentNickname}}'s ships</p>
      <opponentCanvas class="bombingCanvas"
         v-on:keyup.enter.native="bombSubmit"
         v-bind:ships="opponentShips"
         v-bind:bombsHit="bombsHitByPlayer"
         v-bind:bombsMissed="bombsMissedByPlayer"
         v-bind:bombTarget="bombTarget"
         v-on:gridClicked="bombSelect"
      ></opponentCanvas>
      <p>You have hit {{playerSuccessfulBombs}}/{{playerTries}} squares ({{playerHitRate}}%)</p>
      <button
        v-show="phase === 'bomb'"
        v-on:click="bombSubmit"
      >Bomb!</button>
    </div>
    <div class="shipContainer playerShipContainer">
      <p>{{playerNickname}}'s ships</p>
      <playerCanvas class="bombingCanvas"
         v-bind:ships="playerShips"
         v-bind:bombsHit="bombsHitByOpponent"
         v-bind:bombsMissed="bombsMissedByOpponent"
      ></playerCanvas>
      <p>{{opponentNickname}} has hit {{opponentSuccessfulBombs}}/{{opponentTries}} squares ({{opponentHitRate}}%)</p>
    </div>
    <div class="message">
      <p>Turn: {{turnNumber}}</p>
      <p v-if="phase === 'bomb'">Click on a place on your opponent's board and click 'bomb' to bomb them!</p>
      <p v-if="phase === 'wait'">Waiting for your opponent...</p>
      <p v-if="phase === 'gameOver' && won">You win!</p>
      <p v-if="phase === 'gameOver' && !won">You lose!</p>
      <a v-if="phase === 'gameOver'" href="/" id="playAgain">Play again</a>
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
      bombsHitByPlayer: [],
      bombsMissedByPlayer: [],
      bombTarget: [],
      bombsHitByOpponent: [],
      bombsMissedByOpponent: [],
      won: false,
      turnNumber: 0,
    }
  },
  computed: {
    // Player information
    playerShips() {
      return this.$store.state.player.grid
    },
    playerNickname() {
      return this.$store.state.player.nickname
    },
    playerSuccessfulBombs() {
      return this.bombsHitByPlayer.length
    },
    playerTries() {
      return this.playerSuccessfulBombs + this.bombsMissedByPlayer.length
    },
    playerHitRate() {
      if (this.playerTries === 0) return 100

      const hitrate = (this.playerSuccessfulBombs / this.playerTries)
      return (hitrate * 100).toFixed()
    },
    // opponent information
    opponentShips() {
      return this.$store.state.opponent.grid
    },
    opponentNickname() {
      return this.$store.state.opponent.nickname
    },
    opponentSuccessfulBombs() {
      return this.bombsHitByOpponent.length
    },
    opponentTries() {
      return this.opponentSuccessfulBombs + this.bombsMissedByOpponent.length
    },
    opponentHitRate() {
      if (this.opponentTries === 0) return 100

      const hitrate = (this.opponentSuccessfulBombs / this.opponentTries)
      return (hitrate * 100).toFixed()
    },
    bombsByOpponent: {
      get() {
        return this.bombsHitByOpponent.concat(this.bombsMissedByOpponent)
      },
      set(bombs) {
        let bombsHit = []
        let bombsMissed = []
        bombs.forEach((bomb) => {
          const [x, y] = bomb
          const hitAShip = this.playerShips.reduce((acc, [x1, y1, x2, y2]) =>
            acc || (x1 <= x && x <= x2 && y1 <= y && y <= y2), false)

          if (hitAShip) {
            bombsHit.push(bomb)
          } else {
            bombsMissed.push(bomb)
          }
        })

        this.bombsHitByOpponent = bombsHit
        this.bombsMissedByOpponent = bombsMissed
      },
    },
  },
  mounted() {
    this.waitForYourTurn()
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
            this.bombsHitByPlayer.push(this.bombTarget)
            this.$store.dispatch('getGameEnd', {
              okCallback: ({ gameOver, won }) => {
                if (gameOver) {
                  this.won = won
                  this.phase = 'gameOver'
                } else {
                  this.waitForYourTurn()
                }
              },
            })
          } else {
            this.bombsMissedByPlayer.push(this.bombTarget)
            this.waitForYourTurn()
          }
        },
      })
    },
    waitForYourTurn() {
      this.phase = 'wait'
      this.bombTarget = []
      this.$store.dispatch('waitForYourTurn', {
        okCallback: () => {
          this.$store.dispatch('getBombedPositions', {
            okCallback: () => {
              this.bombsByOpponent = this.$store.state.player.bombs
              this.$store.dispatch('getGameEnd', {
                okCallback: ({ gameOver, won }) => {
                  if (gameOver) {
                    this.won = won
                    this.phase = 'gameOver'
                  } else {
                    this.phase = 'bomb'
                    this.turnNumber += 1
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
  margin: 1em;

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
  position: fixed;
  bottom: 0;
  border-top: 1px solid #444;
  background-color: white;
  width: 100%;

  p {
    margin: 0.5em auto;
  }
}

.playerShipContainer {
  padding-bottom: 6em;
}

#playAgain {
  border: 1px solid #173d7a;
  background: linear-gradient(0deg, #5f91e2, #156faf);
  color: #eee;
  padding: 0.5em 1em;
  font-size: 1.3em;
  border-radius: 3px;
  text-decoration: none;
  margin: 1em;
  display: inline-block;
}

/* progressive media queries */
@media (min-width: 765px) {
  .message {
    position: relative;
    border: none;
  }
}
</style>
