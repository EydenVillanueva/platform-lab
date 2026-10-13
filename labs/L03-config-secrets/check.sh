#!/usr/bin/env bash
# L03 · checks the ConfigMap, the Secret and how the Deployment consumes them.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need kubectl jq curl
need_cluster

title "ConfigMap and Secret"
cm="$(kget -n "$NS" get configmap launchpad-config -o json)"
if [ -n "$cm" ]; then pass "configmap launchpad-config exists"; else fail "configmap launchpad-config not found" "kubectl apply -f k8s/configmap.yaml"; summary; fi
cm_env="$(printf '%s' "$cm" | jq -r '.data.APP_ENV // empty')"
cm_greet="$(printf '%s' "$cm" | jq -r '.data.GREETING // empty')"
if [ "$cm_env" = "dev" ]; then pass "APP_ENV=dev"; else fail "APP_ENV is '$cm_env', expected dev"; fi
if [ -n "$cm_greet" ]; then pass "GREETING is set"; else fail "GREETING is missing from the ConfigMap"; fi

if kget -n "$NS" get secret launchpad-secret -o jsonpath='{.data.API_KEY}' | grep -q .; then
  pass "secret launchpad-secret has an API_KEY"
else
  fail "secret launchpad-secret with key API_KEY not found" "kubectl -n $NS create secret generic launchpad-secret --from-literal=API_KEY=..."
fi

if grep -lE '^[[:space:]]*kind:[[:space:]]*Secret' "$ROOT"/k8s/*.yaml >/dev/null 2>&1; then
  warn "a Secret manifest is in k8s/: real teams keep secret values out of git (External Secrets, Sealed Secrets, SOPS)"
else
  pass "no secret values committed in k8s/"
fi

title "Deployment wiring"
dep="$(kget -n "$NS" get deployment launchpad-api -o json)"
if [ -z "$dep" ]; then fail "deployment launchpad-api not found"; summary; fi
c='.spec.template.spec.containers[0]'
if printf '%s' "$dep" | jq -e "$c.envFrom[]? | select(.configMapRef.name == \"launchpad-config\")" >/dev/null; then
  pass "envFrom uses the ConfigMap"
else
  fail "the container does not use envFrom with configMapRef launchpad-config"
fi
if printf '%s' "$dep" | jq -e "$c.env[]? | select(.name == \"API_KEY\" and .valueFrom.secretKeyRef.name == \"launchpad-secret\")" >/dev/null; then
  pass "API_KEY comes from the Secret"
else
  fail "API_KEY is not read from secret launchpad-secret (valueFrom.secretKeyRef)"
fi
if printf '%s' "$dep" | jq -e "$c.env[]? | select(.name == \"REQUIRE_API_KEY\" and .value == \"true\")" >/dev/null; then
  pass "REQUIRE_API_KEY=true"
else
  fail "set REQUIRE_API_KEY to \"true\" (quoted: env values are strings)"
fi
ready="$(printf '%s' "$dep" | jq -r '.status.readyReplicas // 0')"
want="$(printf '%s' "$dep" | jq -r '.spec.replicas')"
if [ "$ready" = "$want" ]; then pass "$ready of $want pods are ready"; else fail "$ready of $want pods are ready" "kubectl -n $NS logs deploy/launchpad-api"; fi

title "What reached the container"
body="$(pf_get "$NS" launchpad-api /config)"
if [ -z "$body" ]; then fail "could not read /config through the Service"; summary; fi
info "GET /config -> $body"
if [ "$(printf '%s' "$body" | jq -r '.appEnv')" = "$cm_env" ]; then pass "appEnv matches the ConfigMap"; else fail "appEnv does not match the ConfigMap" "did you restart the pods after changing it?"; fi
if [ "$(printf '%s' "$body" | jq -r '.greeting')" = "$cm_greet" ]; then pass "greeting matches the ConfigMap"; else warn "greeting differs from the ConfigMap: env vars are read at start, try kubectl rollout restart"; fi
if [ "$(printf '%s' "$body" | jq -r '.apiKeyConfigured')" = "true" ]; then pass "the app sees an API key"; else fail "the app does not see an API key"; fi

summary
