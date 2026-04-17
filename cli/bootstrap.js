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

    // When stdout/stderr are pipes, process.stdout.write is asynchronous — if
    // we exit immediately the OS may drop the unflushed tail of a large
    // response. Track pending writes via the drain callback and only exit
    // once every queued chunk has been written. Using setImmediate also
    // gives the Elm runtime a chance to deliver every subscribe in a
    // Cmd.batch before we decide to exit, regardless of dispatch order.
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
};
