#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "==> Building Docker image..."
docker build -t my-java-app1:latest -f "$APP_DIR/docker/Dockerfile" "$APP_DIR"
echo "==> Running container..."
docker run --rm -p 8080:8080 my-java-app1:latest