const crypto = require('crypto');

global.XMLHttpRequest = require('xhr2');

// Wire the given Elm Platform.worker app to stdout/stderr/exit ports and the
// standard set of Cortex CLI flags (tenant URL + credentials from env, a
// timestamp + crypto.randomBytes nonce for auth signing, and argv).
//
// Both cli/bin/cortex (raw JSON passthrough) and cli/bin/cortex-test (typed
// decoder integration runner) share this bootstrap — the only difference is
// which compiled Elm module name they hand in.
module.exports = function bootstrap(elmModule) {
    const app = elmModule.init({
        flags: {
            argv: process.argv.slice(2),
            tenant: process.env.CORTEX_TENANT_URL || '',
            apiKeyId: process.env.CORTEX_API_KEY_ID || '',
            apiKey: process.env.CORTEX_API_KEY || '',
            timestamp: Date.now(),
            nonce: crypto.randomBytes(32).toString('hex'),
        },
    });

    // Each outgoing port has its own effect manager, and Elm chains those
    // managers through `Process.sleep(0)` (i.e. setTimeout(0)) — so the
    // subscribers for `Cmd.batch [stderr, exit]` are not invoked in the same
    // JS turn, and their order is not even fixed. Calling `process.exit`
    // from the exit subscriber would forcibly kill any setTimeouts still
    // queued for sibling ports, dropping their stderr/stdout writes.
    //
    // Instead, just set `process.exitCode` and let Node exit naturally once
    // the event loop drains. Pending stdio writes keep the loop alive, so
    // every `Ports.stderr` queued in the same Cmd.batch is guaranteed to
    // run and flush before exit.
    app.ports.stdout.subscribe(s => process.stdout.write(s));
    app.ports.stderr.subscribe(s => process.stderr.write(s));
    app.ports.exit.subscribe(code => {
        process.exitCode = code;
    });
};
