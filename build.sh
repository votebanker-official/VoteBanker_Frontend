#!/usr/bin/env bash
# Builds the Flutter web app on Vercel (which does not ship the Flutter SDK).
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
API_BASE_URL="${API_BASE_URL:-https://votebankerbackend-production.up.railway.app}"

if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version
flutter precache --web
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
