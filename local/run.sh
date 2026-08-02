#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "==> Starting application..."
mvn -f "$APP_DIR" spring-boot:run