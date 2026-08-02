#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Linting Helm chart..."
helm lint "$APP_DIR/helm/"

echo "==> Rendering template (dry-run)..."
helm template my-java-app "$APP_DIR/helm/"

echo "==> Helm validation passed!"