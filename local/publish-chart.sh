#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_VERSION="${1:-}"
CHART_VERSION="${2:-}"

if [ -z "$APP_VERSION" ] || [ -z "$CHART_VERSION" ]; then
  echo "Usage: $0 <app-version> <chart-version>"
  echo "Example: $0 1.1.0 0.2.0"
  exit 1
fi

CHART_DIR="${APP_DIR}/helm"
CHART_NAME="my-java-app"

echo "==> Updating Chart.yaml with appVersion=${APP_VERSION} and version=${CHART_VERSION}"
sed -i "s/^version: .*/version: ${CHART_VERSION}/" "${CHART_DIR}/Chart.yaml"
sed -i "s/^appVersion: .*/appVersion: \"${APP_VERSION}\"/" "${CHART_DIR}/Chart.yaml"

echo "==> Packaging chart..."
helm package "${CHART_DIR}" --destination /tmp

echo "==> Pushing chart to OCI registry..."
helm push "/tmp/${CHART_NAME}-${CHART_VERSION}.tgz" oci://ghcr.io/bazoocaze/charts

echo "==> Done! Chart published: oci://ghcr.io/bazoocaze/charts/${CHART_NAME}:${CHART_VERSION}"