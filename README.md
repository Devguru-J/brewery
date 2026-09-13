# brewery

`brew update` → `brew upgrade` → `brew upgrade --greedy` 를 버튼 하나로 실행하는 macOS 앱.

## 설치 (Homebrew)

```bash
brew install --cask devguru-j/tap/brewery
```

아직 Apple 공증을 거치지 않은 빌드라 처음 열 때 macOS가 막을 수 있다. 그 경우 시스템 설정 → 개인정보 보호 및 보안에서 "그래도 열기"를 누르거나, 아래처럼 격리 속성을 지운다.

```bash
xattr -dr com.apple.quarantine /Applications/brewery.app
```

## 빌드

```bash
brew install xcodegen        # 없으면
xcodegen generate
xcodebuild -scheme brewery -destination 'platform=macOS' -derivedDataPath build build
open build/Build/Products/Debug/brewery.app
```

## 설치

```bash
cp -R build/Build/Products/Debug/brewery.app /Applications/
```

## 테스트

```bash
xcodebuild -scheme brewery -destination 'platform=macOS' -derivedDataPath build test
```

## 기능

- 전체 실행 버튼: 세 명령을 순서대로 실행, 실패 시 중단
- 단계별 개별 실행 버튼
- 업데이트 가능 패키지 목록 (`brew outdated --greedy` 기준)
- 실시간 로그, 복사·지우기
- 메뉴바 아이콘: 업데이트 가능 개수 표시, 팝업에서 바로 실행
- 설치된 패키지: formula/cask 목록(cask는 실제 앱 아이콘), 이름 필터, "업데이트만" 필터, 상세(설명·버전·홈페이지), 여러 개 선택 후 업그레이드 또는 삭제(확인창)
- 업데이트 가능 항목은 "업데이트" 배지와 `현재 → 새 버전` 표시. 변경 내역은 brew가 제공하지 않아 홈페이지 링크로 대신한다
- 검색: `brew search` 결과에서 골라 설명·버전·홈페이지 확인 후 설치
- 선택 업그레이드: 설치 목록에서 골라서, 상세 패널에서 하나만, 업그레이드 화면의 업데이트 가능 목록에서 항목별로
- 테마 3종: macOS 순정(기본) / 다크 터미널 / 맥주집. 툴바 팔레트 버튼, 사이드바 하단 "모양 · 언어", 설정(⌘,) 어디서든 바꿀 수 있다
- 언어: 기본은 Mac 시스템 언어. 한국어, English, 日本語, 简体中文, Español, Deutsch, Français 중 골라 즉시 전환(재시작 불필요)

## 번역 추가·수정

문자열은 `Resources/Localizable.xcstrings` 한 곳에 있다. 코드에서는 `L("키")`로 읽는다.
새 언어를 추가하려면 xcstrings에 언어를 넣고 `Sources/Theme/Localization.swift`의 `options`와 `project.yml`의 `CFBundleLocalizations`에 코드를 추가한다.

관리자 비밀번호가 필요한 cask는 GUI에서 입력받을 수 없어 실패로 표시됩니다. 그 항목은 터미널에서 직접 실행하세요.

## 릴리스 만들기

```bash
scripts/release.sh 1.0.0      # Release 빌드 → build/release/brewery-1.0.0.zip + sha256
```

## 앱 아이콘

원본은 `assets/brewery_app_icon.png`. 바꾸려면 새 이미지를 같은 자리에 두고 아래를 실행한다.

```bash
swift scripts/fit-icon.swift assets/brewery_app_icon.png /tmp/icon-1024.png
for s in 16 32 64 128 256 512 1024; do
  sips -z $s $s /tmp/icon-1024.png --out Resources/Assets.xcassets/AppIcon.appiconset/icon_$s.png
done
```

## 라이선스

MIT. Made by Memory(기억) · https://bymemory.dev
