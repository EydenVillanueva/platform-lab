'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { createApp } = require('../src/app');
const { loadConfig } = require('../src/config');

function startApp(env = {}, state = { ready: true }) {
  const app = createApp(loadConfig(env), state);
  return new Promise((resolve) => {
    const server = app.listen(0, () => {
      const base = `http://127.0.0.1:${server.address().port}`;
      resolve({ server, base });
    });
  });
}

test('config uses defaults and rejects bad numbers', () => {
  const c = loadConfig({});
  assert.equal(c.port, 8080);
  assert.equal(c.appEnv, 'local');
  assert.throws(() => loadConfig({ PORT: 'abc' }), /PORT/);
});

test('health, version and config endpoints', async (t) => {
  const { server, base } = await startApp({ APP_ENV: 'dev', GREETING: 'Hola', API_KEY: 's3cr3t', GIT_SHA: 'abc123' });
  t.after(() => server.close());

  assert.equal((await fetch(`${base}/healthz`)).status, 200);
  assert.deepEqual(await (await fetch(`${base}/version`)).json(), { version: '1.0.0', commit: 'abc123' });

  const cfg = await (await fetch(`${base}/config`)).json();
  assert.deepEqual(cfg, { appEnv: 'dev', greeting: 'Hola', apiKeyConfigured: true });
  assert.ok(!JSON.stringify(cfg).includes('s3cr3t'), 'the secret must never be returned');
});

test('readiness follows the shared state', async (t) => {
  const state = { ready: false };
  const { server, base } = await startApp({}, state);
  t.after(() => server.close());

  assert.equal((await fetch(`${base}/readyz`)).status, 503);
  state.ready = true;
  assert.equal((await fetch(`${base}/readyz`)).status, 200);
});

test('launches can be created and listed', async (t) => {
  const { server, base } = await startApp();
  t.after(() => server.close());

  const bad = await fetch(`${base}/launches`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}' });
  assert.equal(bad.status, 400);

  const ok = await fetch(`${base}/launches`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ mission: 'Artemis' }),
  });
  assert.equal(ok.status, 201);
  const list = await (await fetch(`${base}/launches`)).json();
  assert.equal(list.items.length, 1);
});

test('the process exits 0 quickly on SIGTERM (graceful shutdown)', async () => {
  const child = spawn(process.execPath, [path.join(__dirname, '..', 'src', 'server.js')], {
    env: { ...process.env, PORT: '0' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  await new Promise((resolve) => child.stdout.once('data', resolve)); // first log line = listening
  const started = Date.now();
  child.kill('SIGTERM');
  const code = await new Promise((resolve) => child.on('exit', resolve));
  assert.equal(code, 0);
  assert.ok(Date.now() - started < 3000, 'shutdown should take well under 3 seconds');
});

test('missing required API key makes the process exit 1', async () => {
  const child = spawn(process.execPath, [path.join(__dirname, '..', 'src', 'server.js')], {
    env: { ...process.env, PORT: '0', REQUIRE_API_KEY: 'true', API_KEY: '' },
    stdio: 'ignore',
  });
  const code = await new Promise((resolve) => child.on('exit', resolve));
  assert.equal(code, 1);
});
