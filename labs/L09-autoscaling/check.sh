#!/usr/bin/env bash
# L09 · checks the HPA template and that the HPA in launchpad-helm has scaled.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need helm kubectl jq
need_cluster
C="$ROOT/chart/launchpad"
HNS="launchpad-helm"

title "Chart"
if [ -f "$C/templates/hpa.yaml" ]; then pass "templates/hpa.yaml exists"; else fail "templates/hpa.yaml not found"; summary; fi
off="$(helm template launchpad "$C" -f "$C/values-dev.yaml" 2>/dev/null)"
on="$(helm template launchpad "$C" -f "$C/values-dev.yaml" --set autoscaling.enabled=true 2>/dev/null)"
if ! printf '%s' "$off" | grep -q '^kind: HorizontalPodAutoscaler'; then pass "no HPA when autoscaling.enabled=false"; else fail "the HPA renders even when disabled"; fi
if printf '%s' "$on" | grep -q '^kind: HorizontalPodAutoscaler'; then pass "HPA renders when enabled"; else fail "the HPA does not render with --set autoscaling.enabled=true"; fi
if printf '%s' "$on" | grep -q 'autoscaling/v2'; then pass "uses autoscaling/v2"; else fail "use apiVersion: autoscaling/v2"; fi
dep_on="$(printf '%s\n' "$on" | awk '/^kind: Deployment/{d=1} /^---/{d=0} d')"
if printf '%s' "$dep_on" | grep -qE '^[[:space:]]+replicas:'; then fail "the Deployment still sets replicas while the HPA is enabled" "wrap replicas in {{- if not .Values.autoscaling.enabled }}"; else pass "Deployment omits replicas when the HPA is enabled"; fi

title "Cluster"
if kubectl top pods -n "$HNS" >/dev/null 2>&1; then pass "metrics are available (kubectl top works)"; else fail "kubectl top does not work yet" "scripts/install-metrics-server.sh, then wait a minute"; fi
hpa="$(kget -n "$HNS" get hpa launchpad -o json)"
if [ -z "$hpa" ]; then fail "HPA launchpad not found in $HNS" "helm upgrade ... --set autoscaling.enabled=true"; summary; fi
pass "HPA launchpad exists"
cur="$(printf '%s' "$hpa" | jq -r '.status.currentMetrics[0].resource.current.averageUtilization // empty')"
if [ -n "$cur" ]; then pass "HPA reads CPU: ${cur}% of requests"; else warn "HPA has no CPU reading yet (TARGETS shows <unknown>): are CPU requests set?"; fi
last="$(printf '%s' "$hpa" | jq -r '.status.lastScaleTime // empty')"
reps="$(printf '%s' "$hpa" | jq -r '.status.currentReplicas // 0')"
if [ -n "$last" ]; then pass "HPA has scaled (last at $last, now $reps replicas)"; else fail "HPA has not scaled yet" "scripts/load.sh 180 and watch: kubectl -n $HNS get hpa -w"; fi

summary
