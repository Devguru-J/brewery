# brewery — 설계 문서

날짜: 2026-09-13

## 목적

매일 터미널에서 손으로 치는 `brew update` → `brew upgrade` → `brew upgrade --greedy`를
버튼 하나로 실행하는 macOS 네이티브 GUI 앱. 이름은 brewery.

## 기술 스택

- Swift 6 / SwiftUI, macOS 14 이상 타깃 (개발 환경은 macOS 26.6, Xcode 26.6)
- xcodegen `project.yml` → `brewery.xcodeproj` 생성
- App Sandbox 비활성 (brew 프로세스 실행 필요). 개발용 서명, 본인 Mac 사용 목적.
- 외부 의존성 없음.

## 구성 요소

```
brewery/
  project.yml
  Sources/
    App/            breweryApp.swift (창 + MenuBarExtra + Settings 씬)
    Engine/         BrewLocator, BrewRunner(Process 스트리밍), BrewOutdatedParser, UpgradePipeline
    Models/         Step, StepState, OutdatedPackage, RunLog
    Theme/          Theme 프로토콜, NativeTheme, TerminalTheme, TaproomTheme, ThemeStore
    Views/          MainWindow, HeroPanel, StepCards, OutdatedList, LogConsole, MenuBarPanel, SettingsView
  Tests/            BrewOutdatedParserTests, UpgradePipelineTests(가짜 러너)
  Resources/        Assets.xcassets (앱 아이콘)
```

### Engine

- `BrewLocator`: `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, `PATH` 순으로 탐색.
- `BrewRunner`: `Process` + `Pipe`로 brew를 실행하고 stdout/stderr를 줄 단위 `AsyncStream<LogLine>`으로 방출.
  종료 코드 반환. `terminate()`로 중단. `HOMEBREW_NO_AUTO_UPDATE=1`, `HOMEBREW_COLOR=0`, `NONINTERACTIVE=1` 환경 설정.
- `BrewOutdatedParser`: `brew outdated --json=v2` 출력 → `[OutdatedPackage]` (이름, 현재 버전, 새 버전, formula/cask 구분).
- `UpgradePipeline` (`@Observable`, MainActor): 단계 배열 `[update, upgrade, upgradeGreedy]`.
  `runAll()`은 순서대로 실행, 실패 시 중단. `run(step:)`은 단일 단계. 실행 중 `isRunning`으로 버튼 잠금.
  완료 후 `refreshOutdated()` 자동 호출. 마지막 실행 시각은 UserDefaults에 저장.
- 러너는 프로토콜(`CommandRunning`)로 추상화해 테스트에서 가짜로 대체.

### 상태 모델

- `Step`: id, title, arguments (`["update"]`, `["upgrade"]`, `["upgrade", "--greedy"]`).
- `StepState`: idle / running / succeeded / failed(exitCode) / skipped.
- `RunLog`: `[LogLine]` (텍스트, 스트림 종류, 단계 id). 최대 5,000줄 유지.

### 화면

메인 창 (기본 크기 820×640, 최소 680×520):

1. **HeroPanel** — 상태 문구, 마지막 실행 시각, "전체 실행" 큰 버튼 (실행 중엔 "중단"으로 바뀜).
2. **StepCards** — 세 단계 카드를 가로 배치. 각 카드에 아이콘, 제목, 명령어, 상태 표시, 개별 실행 버튼.
   진행 중 카드는 테마별 애니메이션(순정: 프로그레스 링, 터미널: 커서 깜빡임, 맥주집: 거품 차오름).
3. **OutdatedList** — formula/cask 섹션, 이름과 `현재 → 새 버전`. 비어 있으면 "모두 최신입니다" 빈 상태.
   앱 시작 시와 파이프라인 완료 후 자동 갱신, 수동 새로고침 버튼.
4. **LogConsole** — 하단 접이식 패널. 모노스페이스, 자동 스크롤, 복사·지우기 버튼. stderr는 구분색.

메뉴바 (`MenuBarExtra`, 맥주잔 SF Symbol `mug.fill`): 업데이트 가능 개수 텍스트 배지. 패널에
상태 한 줄, "전체 실행" 버튼, "창 열기", "종료".

설정 (`Settings` 씬): 테마 선택 3종 미리보기 카드, 로그인 시 메뉴바 자동 실행 여부는 범위 밖.

### 테마

`Theme` 프로토콜: 배경 스타일(재질/단색), 강조색, 카드 스타일, 로그 폰트·색, 진행 애니메이션 종류.
`ThemeStore`가 `@AppStorage("theme")`로 선택값 저장, 기본 `native`.
- `native`: 시스템 재질(`.regularMaterial`), 시스템 accent, SF Pro, 라이트/다크 자동.
- `terminal`: 검정 배경, 초록·호박 텍스트, SF Mono, 글로우.
- `taproom`: 호박·크림 팔레트, 둥근 카드, 거품 애니메이션.

### 오류 처리

- brew 미발견: 히어로 영역에 안내와 설치 링크, 버튼 비활성.
- 단계 실패: 카드 빨강, 파이프라인 중단, 로그 패널 자동 펼침.
- sudo 요구 cask: `NONINTERACTIVE=1` 덕에 즉시 실패. 로그에 "터미널에서 직접 실행 필요" 안내 줄 추가.
- 실행 중 창 닫기: 프로세스는 계속. 앱 종료 시 프로세스 terminate.

### 테스트

- `BrewOutdatedParserTests`: 정상 JSON, 빈 목록, 깨진 JSON.
- `UpgradePipelineTests`: 가짜 러너로 3단계 순차 실행, 2단계 실패 시 3단계 skipped, 개별 실행.
- UI: 빌드 후 실행해 스크린샷으로 확인.

## 범위 밖 (2차)

위젯(현황판), 예약 실행, 알림, 패키지 선택 업그레이드, 로그인 시 자동 시작.
