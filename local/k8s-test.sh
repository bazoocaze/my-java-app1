#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-default}"
APP="my-java-app"
LOCAL_PORT="${2:-8080}"

echo "==> Waiting for deployment to be ready..."
kubectl wait --namespace "${NAMESPACE}" \
  --for=condition=available \
  --timeout=120s \
  "deployment/${APP}"

echo ""
echo "==> Starting port-forward in background (PID: $$)..."
kubectl port-forward --namespace "${NAMESPACE}" \
  "svc/${APP}" "${LOCAL_PORT}:8080" &
PF_PID=$!
trap "kill ${PF_PID} 2>/dev/null; exit" EXIT INT TERM

sleep 3

echo ""
echo "==> Testing /hello..."
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:${LOCAL_PORT}/hello
echo ""

echo "==> Testing /actuator/health..."
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:${LOCAL_PORT}/actuator/health
echo ""

echo ""
echo "==> Response from /hello:"
curl -s http://localhost:${LOCAL_PORT}/hello
echo ""

echo ""
echo "==> All tests passed! Press Ctrl+C to stop port-forward."