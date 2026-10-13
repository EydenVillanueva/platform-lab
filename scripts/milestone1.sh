#!/usr/bin/env bash
# Week 1 milestone: runs the checks of L01–L05 plus a quick look at the drills, and prints one line per lab.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
labs="L01-dockerfile L02-first-deploy L03-config-secrets L04-probes-rollouts L05-ci"
ok=0
total=0
results=""
for lab in $labs; do
  total=$((total + 1))
  log="$(mktemp)"
  if bash "$ROOT/labs/$lab/check.sh" >"$log" 2>&1; then
    ok=$((ok + 1)); results="$results\n  PASS  $lab"
  else
    results="$results\n  FAIL  $lab   (details: bash labs/$lab/check.sh)"
  fi
  rm -f "$log"
done
printf '\nWeek 1 milestone%b\n\n%s of %s labs passing.\n' "$results" "$ok" "$total"
if [ "$ok" -eq "$total" ]; then
  printf 'Milestone reached: the image your CI built runs in your cluster.\n'
  exit 0
fi
exit 1
