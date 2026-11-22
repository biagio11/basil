#!/usr/bin/env bash
# Netlify build script: Netlify's build image has no Flutter, so we fetch it.
# Override the version in Netlify (Site settings > Environment variables):
#   FLUTTER_VERSION = stable   (default)   or a tag such as 3.35.0
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.0}"
FLUTTER_DIR="${HOME}/flutter"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

git config --global --add safe.directory "${FLUTTER_DIR}" || true
export PATH="${FLUTTER_DIR}/bin:${PATH}"
export FLUTTER_SUPPRESS_ANALYTICS=true

flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true
flutter precache --web
flutter pub get
dart run tool/gen_legal.dart
flutter build web --release --csp --no-web-resources-cdn --no-source-maps --no-wasm-dry-run
