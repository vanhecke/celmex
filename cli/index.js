#!/usr/bin/env node
const bootstrap = require('./bootstrap');
const { Elm } = require('./dist/elm.js');
bootstrap(Elm.Cli.Main);
