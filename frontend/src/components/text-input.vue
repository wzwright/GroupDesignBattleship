<template>
  <div class="textInput">
    <label :for="inputID">{{label}}</label>
    <input :id="inputID" type="text" :placeholder="placeholder"
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
  },
}
</script>

<style lang="scss">
.textInput {
  margin-bottom: 1em;

  label {
    font-size: 0.8em;
    color: #444;
    font-weight: bold;
    margin-left: 0.4em;
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
