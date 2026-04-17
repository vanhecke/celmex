#!/usr/bin/env node
const bootstrap = require('./bootstrap');
const { Elm } = require('./dist/elm-test.js');
bootstrap(Elm.Cli.TestMain);
