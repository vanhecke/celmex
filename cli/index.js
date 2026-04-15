#!/usr/bin/env node
global.XMLHttpRequest = require('xhr2');
const crypto = require('crypto');
const { Elm } = require('./dist/elm.js');

const app = Elm.Cli.Main.init({
    flags: {
        argv: process.argv.slice(2),
        tenant: process.env.CORTEX_TENANT_URL || '',
        apiKeyId: process.env.CORTEX_API_KEY_ID || '',
        apiKey: process.env.CORTEX_API_KEY || '',
        timestamp: Date.now(),
        nonce: crypto.randomBytes(32).toString('hex'),
    },
});

// When stdout/stderr are pipes, process.stdout.write is asynchronous — if we
// exit immediately the OS may drop the unflushed tail of a large response.
// Track pending writes via the drain callback and only exit once every queued
// chunk has been written. Using setImmediate also gives the Elm runtime a
// chance to deliver every subscribe in a Cmd.batch before we decide to exit,
// regardless of dispatch order.
let pendingWrites = 0;
let exitCode = null;

const maybeExit = () => {
    if (exitCode !== null && pendingWrites === 0) {
        process.exit(exitCode);
    }
};

const safeWrite = (stream, s) => {
    pendingWrites++;
    stream.write(s, () => {
        pendingWrites--;
        maybeExit();
    });
};

app.ports.stdout.subscribe(s => safeWrite(process.stdout, s));
app.ports.stderr.subscribe(s => safeWrite(process.stderr, s));
app.ports.exit.subscribe(code => {
    exitCode = code;
    process.exitCode = code;
    setImmediate(maybeExit);
});
