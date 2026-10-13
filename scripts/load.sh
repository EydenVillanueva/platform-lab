#!/usr/bin/env bash
# Generates CPU-heavy load against the Helm release from inside the cluster.
# Usage: scripts/load.sh [seconds] [namespace] [service]     defaults: 180 launchpad-helm launchpad
set -euo pipefail
SECS="${1:-180}"
NS="${2:-launchpad-helm}"
SVC="${3:-launchpad}"
echo "Sending load to http://$SVC.$NS/work for ${SECS}s (Ctrl+C to stop early)..."
kubectl -n "$NS" run load-generator --rm -i --restart=Never --image=curlimages/curl:8.11.1 -- \
  sh -c "end=\$((\$(date +%s) + $SECS)); for w in 1 2 3 4; do (while [ \$(date +%s) -lt \$end ]; do curl -s -o /dev/null 'http://$SVC.$NS/work?ms=200'; done) & done; wait; echo done"
