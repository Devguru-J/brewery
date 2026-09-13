# brewery 2차(패키지 관리) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 설치 목록 보기, 검색·설치, 선택 삭제를 사이드바 화면으로 추가한다.

**Architecture:** 읽기(목록·검색·정보)는 `PackageStore`, 쓰기(설치·삭제)는 `UpgradePipeline` 확장. 파서는 순수 함수. 창은 `NavigationSplitView`로 재구성하고 로그는 detail 하단 공통.

**Tech Stack:** 1차와 동일.

**Spec:** `docs/superpowers/specs/2026-09-13-brewery-packages-design.md`

## Global Constraints

1차 계획과 동일. 추가: cask 버전은 Caskroom 디렉터리에서 읽는다. 삭제는 confirmationDialog 필수.

## File Structure

```
Sources/Models/InstalledPackage.swift       InstalledPackage, SearchResult, PackageInfo
Sources/Engine/BrewListParser.swift         formula 버전 파싱, cask 이름 파싱, Caskroom 버전 읽기
Sources/Engine/BrewSearchParser.swift
Sources/Engine/BrewInfoParser.swift
Sources/Engine/PackageStore.swift
Sources/Engine/PackageActions.swift         extension UpgradePipeline
Sources/Views/RootView.swift                NavigationSplitView + 사이드바 + 로그
Sources/Views/UpgradeScreen.swift           기존 ContentView 내용(로그 제외)
Sources/Views/InstalledScreen.swift
Sources/Views/SearchScreen.swift
Tests/BrewListParserTests.swift, BrewSearchParserTests.swift, BrewInfoParserTests.swift,
Tests/PackageStoreTests.swift, PackageActionsTests.swift
```

### Task 1: 모델 + 파서 3종 (TDD)
- [ ] 테스트 작성 → 실패 확인 → 구현 → 통과 → 커밋 `feat: 패키지 목록/검색/정보 파서`

### Task 2: PackageStore (TDD, FakeRunner + 임시 Caskroom)
- [ ] `refreshInstalled()`가 `list --formula --versions`, `list --cask` 두 번 호출하고 Caskroom에서 버전을 채움
- [ ] `search("rg")`가 `search --formula rg`, `search --cask rg` 호출, 설치 여부 표시
- [ ] `loadInfo`가 `info --json=v2 [--cask] name` 호출
- [ ] 커밋 `feat: PackageStore`

### Task 3: PackageActions (TDD)
- [ ] `install("ripgrep", .formula)` → `["install","ripgrep"]`, cask는 `["install","--cask",name]`
- [ ] `uninstall([f1, c1])` → `["uninstall","f1"]`, `["uninstall","--cask","c1"]` 순서, 실패 시 중단
- [ ] 완료 후 `onPackagesChanged` 호출, `refreshOutdated` 호출
- [ ] 커밋 `feat: 설치·삭제 액션`

### Task 4: 뷰 (RootView, UpgradeScreen, InstalledScreen, SearchScreen) + App 연결
- [ ] 빌드 → 앱 실행 → 세 화면 스크린샷 → 실제 검색·설치·삭제 1회씩 확인 → 커밋 `feat: 사이드바 화면(설치 목록, 검색, 삭제)`
