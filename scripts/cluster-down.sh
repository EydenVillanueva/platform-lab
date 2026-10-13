#!/usr/bin/env bash
# Deletes the local cluster. Everything in it is gone; your manifests in k8s/ stay.
set -euo pipefail
kind delete cluster --name platform-lab
