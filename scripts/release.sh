#!/bin/sh
# 사용법: scripts/release.sh <버전>
# Release 빌드 → Developer ID 서명 → 공증 → 스테이플 → build/release/brewery-<버전>.zip + sha256
#
# 필요한 것 (없으면 서명·공증 단계는 건너뛰고 ad-hoc 빌드만 만든다):
#   - 키체인의 "Developer ID Application: …" 인증서
#   - 공증 프로필: xcrun notarytool store-credentials brewery-notary --apple-id <Apple ID> --team-id <팀 ID> --password <앱 암호>
set -eu
VERSION="${1:?버전을 지정하세요 (예: 1.0.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/release"
PROFILE="${NOTARY_PROFILE:-brewery-notary}"
IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | grep -o '"Developer ID Application: [^"]*"' | head -1 | tr -d '"')}"
cd "$ROOT"

xcodegen generate >/dev/null
xcodebuild -scheme brewery -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$VERSION" build -quiet
rm -rf "$OUT" && mkdir -p "$OUT"
APP="build/Build/Products/Release/brewery.app"
ZIP="$OUT/brewery-$VERSION.zip"

if [ -n "$IDENTITY" ]; then
  echo "==> 서명: $IDENTITY"
  codesign --force --deep --options runtime --timestamp \
    --entitlements Sources/brewery.entitlements --sign "$IDENTITY" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"

  ditto -c -k --keepParent "$APP" "$ZIP"
  echo "==> 공증 제출 (프로필: $PROFILE)"
  xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
  echo "==> 스테이플"
  xcrun stapler staple "$APP"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  spctl --assess --type execute --verbose=2 "$APP" || true
else
  echo "!! Developer ID Application 인증서가 없어 서명·공증을 건너뜁니다 (ad-hoc 빌드)."
  ditto -c -k --keepParent "$APP" "$ZIP"
fi

shasum -a 256 "$ZIP" | tee "$ZIP.sha256"
