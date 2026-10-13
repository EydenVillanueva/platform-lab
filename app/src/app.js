'use strict';

const express = require('express');

function log(level, msg, fields = {}) {
  // One JSON object per line on stdout: what log collectors expect.
  process.stdout.write(JSON.stringify({ time: new Date().toISOString(), level, msg, ...fields }) + '\n');
}

// state.ready is flipped by server.js: false while starting and while shutting down.
function createApp(config, state = { ready: true }) {
  const app = express();
  app.use(express.json());

  app.use((req, res, next) => {
    const started = process.hrtime.bigint();
    res.on('finish', () => {
      if (req.path === '/healthz' || req.path === '/readyz') return; // probes are noisy
      const ms = Number(process.hrtime.bigint() - started) / 1e6;
      log('info', 'request', { method: req.method, path: req.path, status: res.statusCode, ms: Math.round(ms) });
    });
    next();
  });

  app.get('/', (req, res) => {
    res.json({ service: 'launchpad-api', greeting: config.greeting, env: config.appEnv });
  });

  // Liveness: "is the process able to answer at all?" Never depends on other systems.
  app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

  // Readiness: "should the load balancer send me traffic right now?"
  app.get('/readyz', (req, res) => {
    if (state.ready) return res.json({ status: 'ready' });
    return res.status(503).json({ status: 'not-ready' });
  });

  app.get('/version', (req, res) => res.json({ version: config.version, commit: config.commit }));

  // Shows which configuration reached the container. Never echoes the secret itself.
  app.get('/config', (req, res) => {
    res.json({ appEnv: config.appEnv, greeting: config.greeting, apiKeyConfigured: config.apiKey.length > 0 });
  });

  const launches = [];
  app.get('/launches', (req, res) => res.json({ items: launches }));
  app.post('/launches', (req, res) => {
    const mission = req.body && typeof req.body.mission === 'string' ? req.body.mission.trim() : '';
    if (!mission) return res.status(400).json({ error: 'mission is required' });
    const launch = { id: launches.length + 1, mission, createdAt: new Date().toISOString() };
    launches.push(launch);
    return res.status(201).json(launch);
  });

  // Burns CPU on purpose so the autoscaling lab has something to react to.
  app.get('/work', (req, res) => {
    const ms = Math.min(Number.parseInt(req.query.ms, 10) || 100, 2000);
    const end = Date.now() + ms;
    let x = 0;
    while (Date.now() < end) x += Math.sqrt(Math.random());
    res.json({ workedMs: ms, checksum: Math.round(x) % 1000 });
  });

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp, log };
