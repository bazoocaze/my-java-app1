#!/usr/bin/env bash
set -euo pipefail

APP="my-java-app1"
NAMESPACE="${1:-default}"

echo "==> Uninstalling Helm release '${APP}'..."
helm uninstall "${APP}" --namespace "${NAMESPACE}" 2>/dev/null && \
  echo "Helm release '${APP}' uninstalled." || \
  echo "INFO: Helm release '${APP}' not found."

echo ""
echo "==> Checking remaining resources..."
kubectl get all --namespace "${NAMESPACE}" -l "app.kubernetes.io/instance=${APP}" 2>/dev/null || true

echo ""
echo "==> Cleanup complete."