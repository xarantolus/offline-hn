#!/usr/bin/env bash
# Prepare the workspace after the container starts. Non-fatal by design.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# settings.gradle.kts reads flutter.sdk from here.
if [ -d android ] && ! grep -qs '^flutter.sdk=' android/local.properties; then
    echo "flutter.sdk=${FLUTTER_ROOT:-/opt/flutter}" >> android/local.properties
fi

if command -v claude >/dev/null && command -v mcp-server-mobile >/dev/null; then
    mcps=$(claude mcp list 2>/dev/null)
    [[ $mcps == *mobile:* ]] || claude mcp add mobile --scope user -- mcp-server-mobile || true
fi

flutter pub get || echo "==> 'flutter pub get' failed"
