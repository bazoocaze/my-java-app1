#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_VERSION="${1:-}"

if [ -z "$APP_VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.1.0"
  exit 1
fi

IMAGE="ghcr.io/bazoocaze/my-java-app1:${APP_VERSION}"

echo "==> Building Docker image: ${IMAGE}"
docker build -t "${IMAGE}" -f "${APP_DIR}/docker/Dockerfile" "${APP_DIR}"

echo "==> Pushing ${IMAGE}"
docker push "${IMAGE}"

echo "==> Done! Image published: ${IMAGE}"