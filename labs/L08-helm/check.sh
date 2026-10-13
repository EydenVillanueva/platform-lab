#!/usr/bin/env bash
# L08 · checks the chart (lint, renders per environment) and the installed release.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need helm jq
C="$ROOT/chart/launchpad"
HNS="launchpad-helm"

title "Chart"
if [ -f "$C/Chart.yaml" ]; then pass "chart/launchpad/Chart.yaml exists"; else fail "chart/launchpad not found" "helm create chart/launchpad"; summary; fi
for f in values-dev.yaml values-prod.yaml templates/configmap.yaml; do
  if [ -f "$C/$f" ]; then pass "$f exists"; else fail "$f not found"; fi
done
if out="$(helm lint "$C" 2>&1)"; then pass "helm lint"; else fail "helm lint failed"; printf '%s\n' "$out" | tail -10 | sed 's/^/        /'; fi

render() { helm template launchpad "$C" -n "$HNS" -f "$C/$1" 2>/dev/null; }
dev="$(render values-dev.yaml)"
prod="$(render values-prod.yaml)"
if [ -n "$dev" ] && [ -n "$prod" ]; then pass "renders with dev and prod values"; else fail "helm template failed" "helm template launchpad chart/launchpad -f chart/launchpad/values-dev.yaml"; summary; fi

# The replicas line of the Deployment in each render.
replicas() { printf '%s\n' "$1" | awk '/^kind: Deployment/{d=1} d && /^[[:space:]]+replicas:/{print $2; exit}'; }
rd="$(replicas "$dev")"; rp="$(replicas "$prod")"
if [ "$rd" = "1" ]; then pass "dev renders 1 replica"; else fail "dev renders replicas '$rd', expected 1"; fi
if [ "$rp" = "3" ]; then pass "prod renders 3 replicas"; else fail "prod renders replicas '$rp', expected 3"; fi
if printf '%s' "$dev" | grep -q 'APP_ENV: "*dev' && printf '%s' "$prod" | grep -q 'APP_ENV: "*prod'; then pass "APP_ENV differs per environment"; else fail "APP_ENV should be dev in values-dev and prod in values-prod"; fi
if printf '%s' "$dev" | grep -q 'checksum/config'; then pass "checksum/config annotation present"; else fail "add the checksum/config annotation to the pod template" "sha256sum of the rendered configmap template"; fi
if printf '%s' "$dev" | grep -q '/readyz' && printf '%s' "$dev" | grep -q '/healthz'; then pass "probes rendered"; else fail "the rendered Deployment has no /readyz and /healthz probes"; fi
if printf '%s' "$dev" | awk '/^kind: (Deployment|Service)/{k=1} k && /^  name:/{print $2; k=0}' | sort -u | grep -qx 'launchpad'; then pass "resources are named after the release (launchpad)"; else fail "with release name 'launchpad' the Deployment and Service should be named 'launchpad'"; fi
if have kubeconform; then
  if printf '%s\n' "$prod" | kubeconform -strict -summary - >/dev/null 2>&1; then pass "kubeconform: rendered prod manifests are valid"; else fail "kubeconform rejected the rendered manifests"; fi
fi

title "Release in the cluster"
if have kubectl && [ "$(kubectl config current-context 2>/dev/null)" = "kind-$CLUSTER" ]; then
  status="$(helm status launchpad -n "$HNS" -o json 2>/dev/null | jq -r '.info.status // empty')"
  if [ "$status" = "deployed" ]; then pass "release launchpad is deployed in $HNS"; else fail "release launchpad not deployed in $HNS (status: '${status:-none}')"; fi
  revs="$(helm history launchpad -n "$HNS" -o json 2>/dev/null | jq 'length' 2>/dev/null || echo 0)"
  if [ "$revs" -ge 3 ]; then pass "$revs revisions: you upgraded and rolled back"; elif [ "$revs" -ge 2 ]; then warn "$revs revisions: now practice helm rollback"; else fail "only $revs revision(s): do the upgrade in step 5"; fi
  ready="$(kget -n "$HNS" get deployment launchpad -o jsonpath='{.status.readyReplicas}')"
  if [ -n "$ready" ] && [ "$ready" -ge 1 ]; then pass "$ready pod(s) ready"; else fail "no ready pods in $HNS" "is the secret launchpad-secret created in $HNS?"; fi
else
  warn "kind cluster not selected: release checks skipped"
fi

summary
