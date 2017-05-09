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
  <div class="textInput">
    <label :for="inputID">{{label}}</label>
    <input ref="inputID" :id="inputID" type="text" :placeholder="placeholder"
      :value="userInput"
      v-on:input="updateValue($event.target.value)">
    <p v-if="errorMessage !== ''">{{errorMessage}}</p>
  </div>
</template>

<script>
export default {
  name: 'textInput',
  props: [
    'label',
    'placeholder',
    'inputID',
    'errorMessage',
    'userInput',
  ],
  methods: {
    updateValue(value) {
      this.$emit('input', value)
    },
    focus() {
      this.$refs.inputID.focus()
    },
  },
}
</script>

<style lang="scss">
.textInput {
  margin-bottom: 1em;
  display: flex;
  align-items: center;

  label {
    font-size: 0.8em;
    color: #444;
    font-weight: bold;
    margin-left: 0.4em;
    padding-right: 5px;
  }

  input {
    padding: 2px;
    flex-grow: 1;
    flex-shrink: 1;
    width: 50px;
  }

  p {
    color: red;
    font-size: 0.7em;
    font-style: italic;
    text-align: center;
    margin: 0.2em 0 0 0;
  }
}
</style>
