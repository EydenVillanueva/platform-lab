#!/usr/bin/env bash
# Creates the local cluster (idempotent) and points kubectl at it.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "Cluster '$CLUSTER' already exists."
else
  kind create cluster --config "$ROOT/kind/cluster.yaml"
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null
kubectl get nodes
