# brewery 2차 — 설치 목록 / 검색·설치 / 선택 삭제

날짜: 2026-09-13. 1차 설계(`2026-09-13-brewery-design.md`)에 덧붙인다.

## 목적

설치된 formula·cask를 보고, brew에서 검색해 설치하고, 설치된 것을 골라 삭제한다.

## 화면

`NavigationSplitView` 사이드바 3항목: 업그레이드 / 설치된 패키지 / 검색. 로그 패널은 detail 영역 하단에 공통.

- **업그레이드**: 1차 화면 그대로(히어로, 단계 카드, 업데이트 가능 목록).
- **설치된 패키지**: 필터 입력창, Formulae/Casks 섹션(이름, 버전), 다중 선택, "선택 삭제" → confirmationDialog → `brew uninstall [--cask] <names…>`. 새로고침 버튼. 사이드바에 설치 개수 배지.
- **검색**: 검색창 Enter → `brew search --formula <q>`, `brew search --cask <q>` 두 섹션. 설치된 항목 "설치됨" 표시. 항목 선택 시 `brew info --json=v2 [--cask] <name>`으로 설명·버전·홈페이지를 오른쪽에 표시, "설치" 버튼 → `brew install [--cask] <name>`.

## 엔진

- `BrewListParser.parseFormulaVersions(String) -> [InstalledPackage]` — `brew list --formula --versions` ("name v1 v2", 버전은 마지막 토큰들).
- cask: `brew list --cask`(이름) + `<prefix>/Caskroom/<name>/` 하위 디렉터리명(버전, `.metadata` 제외). `--versions`는 untrusted tap cask가 있으면 실패하므로 쓰지 않는다.
- `BrewSearchParser.parse(String) -> [String]` — 빈 줄·`==>` 헤더 제외.
- `BrewInfoParser.parse(Data, kind) -> PackageInfo?` — formulae[0] 또는 casks[0].
- `PackageStore` (@MainActor @Observable): `installed`, `searchResults`, `selectedInfo`, 로딩 플래그, `refreshInstalled()`, `search(_:)`, `loadInfo(name:kind:)`. 읽기 전용이라 별도 `BrewRunner` 인스턴스 사용(업그레이드와 동시 실행 가능).
- `UpgradePipeline` 확장(`PackageActions.swift`): `install(name:kind:)`, `uninstall(_ items:)`. 실행 중 `isRunning`으로 다른 버튼 잠금, 로그 공통. 완료 후 `onPackagesChanged` 콜백 → 설치 목록·업데이트 가능 목록 갱신.

## 모델

`InstalledPackage { name, version, kind }`, `SearchResult { name, kind, isInstalled }`, `PackageInfo { name, kind, description, homepage, version, isInstalled }`. `PackageKind = OutdatedPackage.Kind` 재사용.

## 안전장치

삭제는 확인창 필수. 강제 삭제(`--force`, `--ignore-dependencies`) 없음. brew 경고는 로그로.

## 테스트

파서 3종, `PackageStore`(가짜 러너 + 임시 Caskroom), 설치·삭제 흐름(가짜 러너, 명령 순서·콜백 호출).
