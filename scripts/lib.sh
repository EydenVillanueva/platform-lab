#!/usr/bin/env bash
# Shared helpers for every check.sh. Written for the bash 3.2 that ships with macOS.
# shellcheck disable=SC2034  # variables are used by the scripts that source this file

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="platform-lab"
NS="launchpad"
IMAGE="launchpad-api:dev"
PASSED=0
FAILED=0
WARNED=0

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'; else G=""; R=""; Y=""; B=""; N=""; fi

title() { printf '\n%s== %s ==%s\n' "$B" "$1" "$N"; }
pass()  { PASSED=$((PASSED + 1)); printf '  %sPASS%s  %s\n' "$G" "$N" "$1"; }
fail()  { FAILED=$((FAILED + 1)); printf '  %sFAIL%s  %s\n' "$R" "$N" "$1"; if [ -n "${2:-}" ]; then printf '        hint: %s\n' "$2"; fi; }
warn()  { WARNED=$((WARNED + 1)); printf '  %sWARN%s  %s\n' "$Y" "$N" "$1"; }
info()  { printf '        %s\n' "$1"; }

# check "description" command args...  -> PASS if the command succeeds
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }

have() { command -v "$1" >/dev/null 2>&1; }

need() {
  local missing=0 c
  for c in "$@"; do
    if ! have "$c"; then fail "required tool not found: $c" "run scripts/doctor.sh"; missing=1; fi
  done
  if [ "$missing" -eq 1 ]; then summary; fi
}

need_cluster() {
  need kubectl
  local ctx
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  if [ "$ctx" != "kind-$CLUSTER" ]; then
    fail "kubectl context is '$ctx', expected 'kind-$CLUSTER'" "run scripts/cluster-up.sh, or: kubectl config use-context kind-$CLUSTER"
    summary
  fi
}

# Prints the first value of a jsonpath query, or nothing.
kget() { kubectl "$@" 2>/dev/null || true; }

# Port-forwards a Service, GETs a path, prints the body. Usage: pf_get <namespace> <service> <path>
pf_get() {
  local ns="$1" svc="$2" path="$3" port=18081 pid body=""
  kubectl -n "$ns" port-forward "svc/$svc" "$port:80" >/dev/null 2>&1 &
  pid=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if body="$(curl -fsS --max-time 2 "http://127.0.0.1:$port$path" 2>/dev/null)"; then break; fi
    body=""; sleep 1
  done
  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" 2>/dev/null || true
  printf '%s' "$body"
}

# Number of ready endpoints behind a Service (uses EndpointSlices).
ready_endpoints() {
  kubectl -n "$1" get endpointslices -l "kubernetes.io/service-name=$2" -o json 2>/dev/null \
    | jq '[.items[].endpoints[]? | select(.conditions.ready == true)] | length' 2>/dev/null || echo 0
}

summary() {
  printf '\n%sResult:%s %s passed, %s failed, %s warnings\n' "$B" "$N" "$PASSED" "$FAILED" "$WARNED"
  if [ "$FAILED" -eq 0 ]; then printf '%sAll checks passed.%s\n' "$G" "$N"; exit 0; fi
  exit 1
}
