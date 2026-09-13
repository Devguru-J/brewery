# brewery

`brew update` → `brew upgrade` → `brew upgrade --greedy` 를 버튼 하나로 실행하는 macOS 앱.

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
- 설정(⌘,)에서 테마 선택: macOS 순정(기본) / 다크 터미널 / 맥주집

관리자 비밀번호가 필요한 cask는 GUI에서 입력받을 수 없어 실패로 표시됩니다. 그 항목은 터미널에서 직접 실행하세요.

## 앱 아이콘

원본은 `Resources/AppIcon/brewery_app_icon.png`. 바꾸려면 새 이미지를 같은 자리에 두고 아래를 실행한다.

```bash
swift scripts/fit-icon.swift Resources/AppIcon/brewery_app_icon.png /tmp/icon-1024.png
for s in 16 32 64 128 256 512 1024; do
  sips -z $s $s /tmp/icon-1024.png --out Resources/Assets.xcassets/AppIcon.appiconset/icon_$s.png
done
```
