#!/usr/bin/env bash
# Removes every drill.
set -euo pipefail
kubectl delete namespace drills --ignore-not-found
