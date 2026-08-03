#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  VERSION=$(grep '^appVersion:' "${APP_DIR}/helm/Chart.yaml" | sed 's/appVersion: "//;s/"//')
  IFS='.' read -r major minor patch <<< "$VERSION"
  patch=$((patch + 1))
  VERSION="${major}.${minor}.${patch}"
  echo "==> No version given. Auto-bumped to ${VERSION}"
fi

echo "==> Publishing all artifacts for my-java-app"
echo "    Version: ${VERSION}"
echo ""

echo "==> Step 1: Building JAR..."
"${APP_DIR}/local/build.sh"

echo ""
echo "==> Step 2: Building and pushing Docker image..."
"${APP_DIR}/local/publish-image.sh" "${VERSION}"

echo ""
echo "==> Step 3: Packaging and pushing Helm chart..."
"${APP_DIR}/local/publish-chart.sh" "${VERSION}"

echo ""
echo "==> All artifacts published!"
echo "    Image: ghcr.io/bazoocaze/my-java-app:${VERSION}"
echo "    Chart: oci://ghcr.io/bazoocaze/charts/my-java-app:${VERSION}"
echo ""
echo "==> Next step: update gitops-config with image tag ${VERSION}"