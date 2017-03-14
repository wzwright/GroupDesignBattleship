# :rocket: Setup

1. [Download](https://nodejs.org/en/download/) and install npm
2. Clone the repo and navigate to this directory
3. run `npm install`. This should install all the needed npm packages to frontend/node_modules. You can see which packages will be downloaded by looking at `package.json`.

# :sunglasses: Previewing changes

## development mode
run `npm run dev`. You can see what this command does by reading `package.json`.

This will run a local server and should automatically open a browser window pointing to localhost:8080, where you will be able to see a preview of the game. Errors can be seen by opening up the [browser console](http://webmasters.stackexchange.com/questions/8525/how-to-open-the-javascript-console-in-different-browsers).

`npm run d` does a similar thing except it doesn't open a browser window.

## production mode
run `npm run build`

This builds the files to the `dist/` directory. However, you won't be able to go straight to the file path in browser -- you have to run a local webserver (e.g. via `python -m http.server 8080` and opening up localhost:8080). This will likely only be used in production on our live server.

## vue-devtools

If you use the chrome extension [vue-devtools](https://chrome.google.com/webstore/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd), when you open up the console (<kbd>F12</kbd>) you can find a Vue tab. Here you can select components to see their current data and props, as well as events and Vuex state.

# :wrench: Tooling

## Vue

[Vue](https://vuejs.org/v2/guide/) is the framework we're using. It allows us to separate parts of the app into separate components and other neat things.

## Vuex

[Vuex](https://vuex.vuejs.org/en/intro.html) is a state manager for Vue.

## Webpack

[Webpack](https://webpack.js.org/) be thought of as a compiler. It allows us to use features that aren't necessarily supported on all browsers yet and compiles it into something that does (and other neat features).

The project uses the following with webpack:

### Babel

[Babel](https://babeljs.io/) is a javascript compiler. We're using it so that we can use [ES6/ES2015](es6-features.org) features which include modules and functional syntax.

### Sass (Scss)

[Scss](http://sass-lang.com/guide) transpiles down to normal css. It makes css less annoying.

## ESLint (optional)

[ESLint](http://eslint.org/) is a linter for javascript which checks code for style errors.

I've provided a `.eslintrc.yml` file if you want to lint your javascript. Information about the errors can be found by searching the docs. You may also need to install npm packages like so:

`npm install eslint eslint-plugin-import eslint-plugin-vue eslint-config-airbnb-base eslint-config-vue`

Then, while in `frontend`, run `./node_modules/.bin/eslint ./path/to/file` to use it, or install an eslint plugin in your text editor.

# :notebook: File Structure

`index.html`: Entry point. Loads `dist/build.js`, which is the result of our webpack compilation.  
`src/main.js`: Entry point for webpack.  
`src/app.vue`: Main vue component.  
`src/components/`: Contains all the other components.  
`src/api.js`: Server communication.  
`src/store.js`: Game state (Vuex object) and game logic  


`package.json`: Contains project metadata like npm dependencies and scripts.  
`.babelrc`: Settings for babel.  
`.eslintrc`: Settings for eslint.  
`webpack.config.js`: Configuration for webpack. Based off <https://github.com/vuejs-templates/webpack-simple>.  
`.gitignore`: Things for git to ignore.  

`dist/`: Location for production files.  
`node_modules`: Location of project dependencies.  
