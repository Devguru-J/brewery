#!/bin/sh
# 사용법: scripts/bump-cask.sh <버전>  — tap 저장소의 Casks/brewery.rb 버전과 sha256을 갱신하고 푸시한다.
set -eu
VERSION="${1:?버전}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHA="$(cut -d' ' -f1 "$ROOT/build/release/brewery-$VERSION.zip.sha256")"
TAP="${TAP_DIR:-/opt/homebrew/Library/Taps/devguru-j/homebrew-tap}"
cd "$TAP"
git pull -q
sed -i '' -E "s/^  version \".*\"/  version \"$VERSION\"/; s/^  sha256 \".*\"/  sha256 \"$SHA\"/" Casks/brewery.rb
git commit -qam "brewery $VERSION" && git push -q
echo "tap 갱신: $VERSION $SHA"
