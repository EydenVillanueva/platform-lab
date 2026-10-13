#!/usr/bin/env bash
# Installs metrics-server (needed by kubectl top and the HPA). kind's kubelets use
# self-signed certificates, so the lab adds --kubelet-insecure-tls. Never do that in production.
set -euo pipefail
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
if ! kubectl -n kube-system get deployment metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q kubelet-insecure-tls; then
  kubectl -n kube-system patch deployment metrics-server --type=json \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
echo "metrics-server is ready. Try: kubectl top nodes"
