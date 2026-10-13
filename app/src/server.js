'use strict';

const { loadConfig } = require('./config');
const { createApp, log } = require('./app');

let config;
try {
  config = loadConfig();
} catch (err) {
  log('error', 'invalid configuration', { error: err.message });
  process.exit(1);
}

if (config.requireApiKey && !config.apiKey) {
  // Fail fast and loudly: a crash at start is easier to see than a broken feature later.
  log('error', 'API_KEY is required (REQUIRE_API_KEY=true) but it is empty');
  process.exit(1);
}

// Used by one debugging drill: holds memory on purpose.
const ballast = config.startupAllocateMb > 0 ? Buffer.alloc(config.startupAllocateMb * 1024 * 1024, 1) : null;
if (ballast) log('warn', 'allocated startup memory', { mb: config.startupAllocateMb });

const state = { ready: false };
const app = createApp(config, state);

const server = app.listen(config.port, () => {
  log('info', 'listening', { port: config.port, env: config.appEnv, version: config.version, commit: config.commit });
  setTimeout(() => {
    state.ready = true;
    log('info', 'ready to receive traffic', { startupDelayMs: config.startupDelayMs });
  }, config.startupDelayMs);
});

let shuttingDown = false;
function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  state.ready = false; // stop receiving new traffic first
  log('info', 'shutdown started', { signal });

  server.close(() => {
    log('info', 'shutdown complete');
    process.exit(0);
  });
  server.closeIdleConnections();

  setTimeout(() => {
    log('error', 'shutdown timed out, forcing exit', { timeoutMs: config.shutdownTimeoutMs });
    process.exit(1);
  }, config.shutdownTimeoutMs).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
