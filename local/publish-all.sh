#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

APP_VERSION="${1:-1.1.0}"
CHART_VERSION="${2:-0.2.0}"

echo "==> Publishing all artifacts for my-java-app"
echo "    App version: ${APP_VERSION}"
echo "    Chart version: ${CHART_VERSION}"
echo ""

echo "==> Step 1: Building JAR..."
"${APP_DIR}/local/build.sh"

echo ""
echo "==> Step 2: Building and pushing Docker image..."
"${APP_DIR}/local/publish-image.sh" "${APP_VERSION}"

echo ""
echo "==> Step 3: Packaging and pushing Helm chart..."
"${APP_DIR}/local/publish-chart.sh" "${APP_VERSION}" "${CHART_VERSION}"

echo ""
echo "==> All artifacts published!"
echo "    Image: ghcr.io/bazoocaze/my-java-app:${APP_VERSION}"
echo "    Chart: oci://ghcr.io/bazoocaze/charts/my-java-app:${CHART_VERSION}"
echo ""
echo "==> Next step: update gitops-config with image tag ${APP_VERSION}"