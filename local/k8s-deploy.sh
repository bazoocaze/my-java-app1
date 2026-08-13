#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KIND_DIR="$(cd "${APP_DIR}/../../kind" && pwd)"
CLUSTER_NAME="${1:-kind}"
IMAGE="my-java-app1:latest"

echo "==> Step 1: Building JAR..."
"${APP_DIR}/local/build.sh"

echo ""
echo "==> Step 2: Building Docker image..."
docker build -t "${IMAGE}" -f "${APP_DIR}/docker/Dockerfile" "${APP_DIR}"

echo ""
echo "==> Step 3: Creating kind cluster (if not exists)..."
"${KIND_DIR}/kind-create.sh" "${CLUSTER_NAME}"

echo ""
echo "==> Step 4: Loading image into kind..."
"${KIND_DIR}/kind-load-image.sh" "${IMAGE}" "${CLUSTER_NAME}"

echo ""
echo "==> Step 5: Deploying via Helm..."
kubectl config use-context "kind-${CLUSTER_NAME}" 2>/dev/null || true
helm upgrade --install my-java-app1 "${APP_DIR}/helm/" --namespace default --create-namespace

echo ""
echo "==> Deploy complete! Run ./k8s-test.sh to verify."