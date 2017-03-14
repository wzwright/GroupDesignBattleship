import Vue from 'vue'
import app from './app.vue'
import store from './store'

new Vue({
  el: '#app',
  store,
  render: h => h(app),
})
