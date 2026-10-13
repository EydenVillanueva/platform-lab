#!/usr/bin/env bash
# L04 · checks probes, resources, rollout strategy, shutdown and rollout history.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need kubectl jq
need_cluster

dep="$(kget -n "$NS" get deployment launchpad-api -o json)"
if [ -z "$dep" ]; then fail "deployment launchpad-api not found"; summary; fi
c='.spec.template.spec.containers[0]'
q() { printf '%s' "$dep" | jq -r "$1"; }

title "Probes"
rp="$(q "$c.readinessProbe.httpGet.path // empty")"
lp="$(q "$c.livenessProbe.httpGet.path // empty")"
sp="$(q "$c.startupProbe.httpGet.path // empty")"
if [ "$rp" = "/readyz" ]; then pass "readinessProbe -> /readyz"; else fail "readinessProbe path is '$rp', expected /readyz"; fi
if [ "$lp" = "/healthz" ]; then pass "livenessProbe -> /healthz"; else fail "livenessProbe path is '$lp', expected /healthz" "liveness must not depend on readiness or on other systems"; fi
if [ -n "$sp" ]; then pass "startupProbe -> $sp"; else warn "no startupProbe: fine for fast apps, risky for slow starters"; fi
if [ "$(q "$c.env[]? | select(.name==\"STARTUP_DELAY_MS\") | .value")" = "5000" ]; then pass "STARTUP_DELAY_MS=5000 (slow start on purpose)"; else warn "STARTUP_DELAY_MS is not 5000; you will not see readiness at work"; fi

title "Resources"
rcpu="$(q "$c.resources.requests.cpu // empty")"
rmem="$(q "$c.resources.requests.memory // empty")"
lmem="$(q "$c.resources.limits.memory // empty")"
lcpu="$(q "$c.resources.limits.cpu // empty")"
if [ -n "$rcpu" ] && [ -n "$rmem" ]; then pass "requests: cpu=$rcpu memory=$rmem"; else fail "set resources.requests for cpu and memory"; fi
if [ -n "$lmem" ]; then pass "memory limit: $lmem"; else fail "set resources.limits.memory"; fi
if [ -n "$lcpu" ]; then info "cpu limit: $lcpu (be ready to explain CPU throttling)"; else info "no cpu limit (be ready to explain why: no throttling, requests still guarantee a share)"; fi
qos="$(kget -n "$NS" get pods -l app=launchpad-api -o jsonpath='{.items[0].status.qosClass}')"
if [ -n "$qos" ] && [ "$qos" != "BestEffort" ]; then pass "pod QoS class: $qos"; else fail "pod QoS class is '${qos:-unknown}'"; fi

title "Rollout strategy and shutdown"
mu="$(q '.spec.strategy.rollingUpdate.maxUnavailable // empty')"
ms="$(q '.spec.strategy.rollingUpdate.maxSurge // empty')"
case "$mu" in 0 | "0%") pass "maxUnavailable: $mu" ;; *) fail "maxUnavailable is '$mu', expected 0" ;; esac
if [ -n "$ms" ] && [ "$ms" != "0" ] && [ "$ms" != "0%" ]; then pass "maxSurge: $ms"; else fail "maxSurge must be above 0 when maxUnavailable is 0"; fi
pre="$(q "$c.lifecycle.preStop // empty")"
if [ -n "$pre" ]; then pass "preStop hook present"; else warn "no preStop hook: pods may get traffic for a moment after they start shutting down"; fi
tgp="$(q '.spec.template.spec.terminationGracePeriodSeconds // 30')"
info "terminationGracePeriodSeconds: $tgp"

title "Rollout history"
images="$(kget -n "$NS" get replicasets -o jsonpath='{.items[*].spec.template.spec.containers[0].image}')"
current="$(q "$c.image")"
if printf '%s' "$images" | grep -q 'launchpad-api:v2'; then pass "you rolled out launchpad-api:v2 at least once"; else fail "no ReplicaSet ever ran launchpad-api:v2" "scripts/load-image.sh v2, then kubectl set image (see README step 6)"; fi
if [ "$current" = "launchpad-api:dev" ] && printf '%s' "$images" | grep -q 'launchpad-api:v2'; then
  pass "current image is :dev again: you rolled back"
else
  warn "current image is $current; practice: kubectl -n $NS rollout undo deployment/launchpad-api"
fi
ready="$(q '.status.readyReplicas // 0')"
want="$(q '.spec.replicas')"
if [ "$ready" = "$want" ]; then pass "$ready of $want pods are ready"; else fail "$ready of $want pods are ready"; fi

summary
