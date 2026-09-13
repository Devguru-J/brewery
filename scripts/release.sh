#!/bin/sh
# 사용법: scripts/release.sh <버전>
# Release 구성으로 빌드해 build/release/brewery-<버전>.zip 과 sha256 을 만든다.
set -eu
VERSION="${1:?버전을 지정하세요 (예: 1.0.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/release"
cd "$ROOT"
xcodegen generate >/dev/null
xcodebuild -scheme brewery -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$VERSION" build -quiet
rm -rf "$OUT" && mkdir -p "$OUT"
APP="build/Build/Products/Release/brewery.app"
ditto -c -k --keepParent "$APP" "$OUT/brewery-$VERSION.zip"
shasum -a 256 "$OUT/brewery-$VERSION.zip" | tee "$OUT/brewery-$VERSION.zip.sha256"
