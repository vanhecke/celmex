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

app.ports.stdout.subscribe(s => process.stdout.write(s));
app.ports.stderr.subscribe(s => process.stderr.write(s));
app.ports.exit.subscribe(code => {
    // Defer exit so stdout/stderr writes flush first
    process.exitCode = code;
    setTimeout(() => process.exit(code), 0);
});
