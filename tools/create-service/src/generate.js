'use strict';
// L10 · implement the three functions below until `node --test tools/create-service/test` passes.
// The tests in ../test/generate.test.js are the specification. Read them first.

/**
 * Checks a service name.
 * Rules: 2–40 characters; lowercase letters, digits and "-"; starts with a letter; ends with a letter or digit.
 * @returns {{ ok: boolean, reason?: string }}  reason explains the first rule that failed.
 */
function validateName(name) {
  throw new Error('TODO: implement validateName');
}

/**
 * Replaces {{key}} placeholders (spaces inside the braces allowed) with values from `vars`.
 * - GitHub expressions like ${{ github.sha }} must be left untouched.
 * - A placeholder whose key is not in `vars` throws an Error that names the key.
 */
function renderTemplate(text, vars) {
  throw new Error('TODO: implement renderTemplate');
}

/**
 * Renders every *.tmpl file of templatesDir into outDir/<name>/ and returns the created paths,
 * relative to outDir/<name>, sorted. Mapping from template to output path:
 *   Dockerfile.tmpl          -> Dockerfile
 *   values.yaml.tmpl         -> chart-values.yaml
 *   workflow.yml.tmpl        -> .github/workflows/<name>.yml
 *   catalog-info.yaml.tmpl   -> catalog-info.yaml
 *   README.md.tmpl           -> README.md
 * Throws (and writes nothing) when: the name is invalid, the port is not an integer 1024–65535,
 * the team is empty, or outDir/<name> already exists.
 */
function generateService({ name, port, team, outDir, templatesDir }) {
  throw new Error('TODO: implement generateService');
}

module.exports = { validateName, renderTemplate, generateService };
