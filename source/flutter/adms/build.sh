#!/bin/bash
set -e

echo "=== ADMS Vercel Build ==="

# Install Flutter SDK if not present
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found — installing..."
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"
  flutter config --enable-web --disable-analytics
else
  echo "Flutter found: $(flutter --version | head -1)"
fi

echo "=== Flutter pub get ==="
flutter pub get

echo "=== Build Web ==="
flutter build web --release

echo "=== Done ==="
