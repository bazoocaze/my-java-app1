#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.1.0"
  exit 1
fi

CHART_DIR="${APP_DIR}/helm"
CHART_NAME="my-java-app"

echo "==> Updating Chart.yaml with version=${VERSION} and appVersion=${VERSION}"
sed -i "s/^version: .*/version: ${VERSION}/" "${CHART_DIR}/Chart.yaml"
sed -i "s/^appVersion: .*/appVersion: \"${VERSION}\"/" "${CHART_DIR}/Chart.yaml"

echo "==> Packaging chart..."
helm package "${CHART_DIR}" --destination /tmp

echo "==> Pushing chart to OCI registry..."
helm push "/tmp/${CHART_NAME}-${VERSION}.tgz" oci://ghcr.io/bazoocaze/charts

echo "==> Done! Chart published: oci://ghcr.io/bazoocaze/charts/${CHART_NAME}:${VERSION}"