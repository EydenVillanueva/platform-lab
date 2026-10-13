#!/usr/bin/env bash
# L02 · checks the namespace, Deployment and Service in k8s/ and in the cluster.
# shellcheck source=../../scripts/lib.sh
. "$(dirname "$0")/../../scripts/lib.sh"
need kubectl jq curl
need_cluster

title "Files"
for f in namespace deployment service; do
  if [ -f "$ROOT/k8s/$f.yaml" ]; then pass "k8s/$f.yaml exists"; else fail "k8s/$f.yaml not found"; fi
done
if have kubeconform; then
  if out="$(kubeconform -strict -summary "$ROOT"/k8s/*.yaml 2>&1)"; then pass "kubeconform: manifests are valid"; else fail "kubeconform found problems"; printf '%s\n' "$out" | sed 's/^/        /'; fi
else
  warn "kubeconform not installed, schema validation skipped"
fi

title "Deployment"
dep="$(kget -n "$NS" get deployment launchpad-api -o json)"
if [ -z "$dep" ]; then fail "deployment launchpad-api not found in namespace $NS" "kubectl apply -f k8s/"; summary; fi
pass "deployment launchpad-api exists"

want="$(printf '%s' "$dep" | jq -r '.spec.replicas')"
ready="$(printf '%s' "$dep" | jq -r '.status.readyReplicas // 0')"
if [ "$want" -ge 2 ]; then pass "replicas: $want"; else fail "replicas is $want, expected 2 or more"; fi
if [ "$ready" = "$want" ]; then pass "$ready of $want pods are ready"; else fail "$ready of $want pods are ready" "kubectl -n $NS get pods; kubectl -n $NS describe pod <name>"; fi

label="$(printf '%s' "$dep" | jq -r '.spec.template.metadata.labels.app // empty')"
if [ "$label" = "launchpad-api" ]; then pass "pods are labeled app=launchpad-api"; else fail "pod template label app is '$label'"; fi

image="$(printf '%s' "$dep" | jq -r '.spec.template.spec.containers[0].image')"
policy="$(printf '%s' "$dep" | jq -r '.spec.template.spec.containers[0].imagePullPolicy')"
info "image: $image   pull policy: $policy"
if printf '%s' "$image" | grep -q ':latest$' || ! printf '%s' "$image" | grep -q ':'; then
  fail "use an explicit tag, not latest (Kubernetes treats latest as 'always pull')"
else
  pass "image has an explicit tag"
fi
bad="$(kget -n "$NS" get pods -l app=launchpad-api -o json | jq -r '[.items[].status.containerStatuses[]?.state.waiting.reason // empty] | join(",")')"
if [ -n "$bad" ]; then fail "pods are waiting: $bad" "ErrImagePull/ImagePullBackOff here usually means you forgot scripts/load-image.sh"; fi

nodes="$(kget -n "$NS" get pods -l app=launchpad-api -o jsonpath='{.items[*].spec.nodeName}')"
info "pods run on: $nodes"

title "Service"
svc="$(kget -n "$NS" get service launchpad-api -o json)"
if [ -z "$svc" ]; then fail "service launchpad-api not found"; summary; fi
type="$(printf '%s' "$svc" | jq -r '.spec.type')"
port="$(printf '%s' "$svc" | jq -r '.spec.ports[0].port')"
target="$(printf '%s' "$svc" | jq -r '.spec.ports[0].targetPort')"
if [ "$type" = "ClusterIP" ]; then pass "type ClusterIP"; else fail "type is $type, expected ClusterIP"; fi
cport_name="$(printf '%s' "$dep" | jq -r '.spec.template.spec.containers[0].ports[]? | select(.containerPort == 8080) | .name // empty')"
if [ "$port" = "80" ] && { [ "$target" = "8080" ] || { [ -n "$cport_name" ] && [ "$target" = "$cport_name" ]; }; }; then
  pass "port 80 -> targetPort $target"
else
  fail "ports are $port -> $target, expected 80 -> 8080 (or the name of the container port)"
fi

eps="$(ready_endpoints "$NS" launchpad-api)"
if [ "$eps" -ge 1 ]; then pass "service has $eps ready endpoints"; else fail "service has no ready endpoints" "does the selector match the pod labels exactly?"; fi

body="$(pf_get "$NS" launchpad-api /healthz)"
if printf '%s' "$body" | grep -q '"ok"'; then pass "GET /healthz through the Service works"; else fail "could not reach /healthz through the Service (port-forward)"; fi

summary
