#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "==> Building application..."
mvn -f "$APP_DIR" clean package -DskipTests -B
echo "==> JAR built at $APP_DIR/target/my-java-app.jar"