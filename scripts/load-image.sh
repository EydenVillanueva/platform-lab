#!/usr/bin/env bash
# Builds app/ and copies the image into the kind nodes (kind cannot see your local Docker images otherwise).
# Usage: scripts/load-image.sh [tag]     default tag: dev
set -euo pipefail
. "$(dirname "$0")/lib.sh"
TAG="${1:-dev}"
docker build -t "launchpad-api:$TAG" --build-arg "APP_VERSION=$TAG" "$ROOT/app"
kind load docker-image "launchpad-api:$TAG" --name "$CLUSTER"
echo "Loaded launchpad-api:$TAG into the kind cluster."
