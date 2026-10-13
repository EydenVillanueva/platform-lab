#!/usr/bin/env node
'use strict';
// create-service: the golden path in one command.
//   node tools/create-service/index.js --name orders-api --port 8080 --team payments [--out services]
const path = require('node:path');
const { generateService } = require('./src/generate');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (!key.startsWith('--')) continue;
    args[key.slice(2)] = argv[i + 1];
    i += 1;
  }
  return args;
}

const USAGE = 'usage: create-service --name <name> --port <port> --team <team> [--out <dir>]';

function main(argv) {
  const args = parseArgs(argv);
  if (!args.name || !args.port || !args.team) {
    console.error(USAGE);
    return 1;
  }
  try {
    const files = generateService({
      name: args.name,
      port: Number(args.port),
      team: args.team,
      outDir: path.resolve(args.out || 'services'),
      templatesDir: path.join(__dirname, 'templates'),
    });
    console.log(`Created ${args.name}:`);
    for (const f of files) console.log(`  ${f}`);
    return 0;
  } catch (err) {
    console.error(`error: ${err.message}`);
    return 1;
  }
}

if (require.main === module) process.exitCode = main(process.argv.slice(2));
module.exports = { main, parseArgs };
