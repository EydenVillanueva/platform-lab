#!/usr/bin/env bash
# Starts one broken scenario in the "drills" namespace.  Usage: drills/run.sh d3
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
d="${1:-}"
if [ -z "$d" ] || [ ! -f "$DIR/$d.yaml" ]; then echo "usage: drills/run.sh d1|d2|d3|d4|d5|d6|d7"; exit 1; fi
kubectl create namespace drills --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f "$DIR/$d.yaml"
echo
echo "Started $d. Do NOT open $d.yaml yet: investigate it the way you would in production."
echo "Start with: kubectl -n drills get pods"
