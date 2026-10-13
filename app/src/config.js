'use strict';

const pkg = require('../package.json');

// Every setting comes from an environment variable, so the same image runs in
// every environment. Kubernetes injects these from ConfigMaps and Secrets.
function loadConfig(env = process.env) {
  const int = (name, fallback) => {
    const raw = env[name];
    if (raw === undefined || raw === '') return fallback;
    const n = Number.parseInt(raw, 10);
    if (Number.isNaN(n) || n < 0) {
      throw new Error(`${name} must be a non-negative integer, got "${raw}"`);
    }
    return n;
  };

  return {
    port: int('PORT', 8080),
    appEnv: env.APP_ENV || 'local',
    greeting: env.GREETING || 'Hello from launchpad',
    apiKey: env.API_KEY || '',
    requireApiKey: env.REQUIRE_API_KEY === 'true',
    startupDelayMs: int('STARTUP_DELAY_MS', 0),
    startupAllocateMb: int('STARTUP_ALLOCATE_MB', 0),
    shutdownTimeoutMs: int('SHUTDOWN_TIMEOUT_MS', 10000),
    version: env.APP_VERSION || pkg.version,
    commit: env.GIT_SHA || 'unknown',
  };
}

module.exports = { loadConfig };
