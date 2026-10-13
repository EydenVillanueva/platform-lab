#!/usr/bin/env bash
# L10 · runs the specification tests of the golden-path generator.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need node

title "Specification tests"
if out="$(node --test "$ROOT/tools/create-service/test/generate.test.js" 2>&1)"; then
  pass "all tests pass"
else
  fail "some tests fail"
  printf '%s\n' "$out" | grep -E '^not ok|# (pass|fail)' | sed 's/^/        /'
fi

title "Smoke run"
tmpdir="$(mktemp -d)"
if node "$ROOT/tools/create-service/index.js" --name smoke-svc --port 8090 --team platform --out "$tmpdir" >/dev/null 2>&1 && [ -f "$tmpdir/smoke-svc/catalog-info.yaml" ]; then
  pass "the CLI generated a service"
else
  fail "the CLI did not generate smoke-svc"
fi
rm -rf "$tmpdir"
summary
