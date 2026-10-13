'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { validateName, renderTemplate, generateService } = require('../src/generate');

const TEMPLATES = path.join(__dirname, '..', 'templates');
const tmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'create-service-'));

test('validateName accepts good names', () => {
  for (const n of ['orders-api', 'a1', 'payments', 'x-2-y']) {
    assert.deepEqual(validateName(n), { ok: true }, n);
  }
});

test('validateName rejects bad names with a reason', () => {
  for (const n of ['', 'a', 'Orders', '1orders', '-orders', 'orders-', 'orders_api', 'orders api', 'x'.repeat(41)]) {
    const r = validateName(n);
    assert.equal(r.ok, false, `"${n}" should be rejected`);
    assert.equal(typeof r.reason, 'string');
    assert.ok(r.reason.length > 0);
  }
});

test('renderTemplate replaces every placeholder, with or without spaces', () => {
  assert.equal(renderTemplate('{{name}} on {{ port }} by {{name}}', { name: 'svc', port: 8080 }), 'svc on 8080 by svc');
});

test('renderTemplate leaves GitHub expressions alone', () => {
  const out = renderTemplate('echo ${{ github.sha }} for {{name}}', { name: 'svc' });
  assert.equal(out, 'echo ${{ github.sha }} for svc');
});

test('renderTemplate throws on an unknown placeholder and names it', () => {
  assert.throws(() => renderTemplate('hello {{owner}}', { name: 'svc' }), /owner/);
});

test('generateService writes the golden-path files', () => {
  const out = tmp();
  const files = generateService({ name: 'orders-api', port: 8081, team: 'payments', outDir: out, templatesDir: TEMPLATES });
  assert.deepEqual(files, [
    '.github/workflows/orders-api.yml',
    'Dockerfile',
    'README.md',
    'catalog-info.yaml',
    'chart-values.yaml',
  ]);
  const dir = path.join(out, 'orders-api');
  assert.match(fs.readFileSync(path.join(dir, 'Dockerfile'), 'utf8'), /EXPOSE 8081/);
  assert.match(fs.readFileSync(path.join(dir, 'catalog-info.yaml'), 'utf8'), /owner: payments/);
  const wf = fs.readFileSync(path.join(dir, '.github/workflows/orders-api.yml'), 'utf8');
  assert.match(wf, /\$\{\{ github\.sha \}\}/);
  assert.doesNotMatch(wf, /\{\{name\}\}/);
});

test('generateService refuses bad input and never overwrites', () => {
  const out = tmp();
  const base = { port: 8080, team: 'payments', outDir: out, templatesDir: TEMPLATES };
  assert.throws(() => generateService({ ...base, name: 'Bad_Name' }), /name/i);
  assert.throws(() => generateService({ ...base, name: 'ok-svc', port: 80 }), /port/i);
  assert.throws(() => generateService({ ...base, name: 'ok-svc', port: 'abc' }), /port/i);
  assert.throws(() => generateService({ ...base, name: 'ok-svc', team: '' }), /team/i);
  assert.equal(fs.existsSync(path.join(out, 'ok-svc')), false, 'nothing may be written when input is invalid');
  generateService({ ...base, name: 'ok-svc' });
  assert.throws(() => generateService({ ...base, name: 'ok-svc' }), /exists/i);
});

test('the CLI prints usage and exits 1 without arguments, exits 0 on success', () => {
  const cli = path.join(__dirname, '..', 'index.js');
  const bad = spawnSync(process.execPath, [cli], { encoding: 'utf8' });
  assert.equal(bad.status, 1);
  assert.match(bad.stderr, /usage/);
  const out = tmp();
  const ok = spawnSync(process.execPath, [cli, '--name', 'cli-svc', '--port', '9000', '--team', 'core', '--out', out], { encoding: 'utf8' });
  assert.equal(ok.status, 0, ok.stderr);
  assert.ok(fs.existsSync(path.join(out, 'cli-svc', 'Dockerfile')));
});
