# Glass Wild — Godot 처음 시작 (흑백 와이어)

Godot를 처음 쓰는 사람을 위한 **이 저장소 맞춤** 안내입니다.  
최종 도트 아트는 나중에 두고, 지금은 **색 면 플레이스홀더**로 관찰/편집만 익힙니다.

본격 MVP Godot 구현은 [D-008](../decisions/D-008-figma-exit-criteria.md) 이후입니다. 지금은 학습용입니다.

## 0. 시작 전

**Glass Wild**: 사육장을 꾸미고 생물을 관찰하는 Godot 2D 게임입니다. 용어는 [`../core/glossary.md`](../core/glossary.md)를 따릅니다.

| 지금 하는 것 | 지금 안 하는 것 |
|---|---|
| 관찰 / 편집 모드 전환 | 도트 스프라이트·타일맵 |
| 색 면 플레이스홀더 (도트는 이후) | 배경화면 투명 창 |
| **논리 셀** 1cm 스냅 · 표시 격자 5cm · 편집 팔레트 | 환경 시뮬·합사 판정 전체 |
| 사육장 규격 선택 · OS 창 리사이즈 | 채색 ColorRect UI |

따라 하기: 저장소 [`../../godot/`](../../godot/) 를 Godot에서 Import 후 F5.

## 1. Godot 설치

학습용 `godot/` 프로젝트 기준 에디터: **Godot 4.7 표준**(C# / .NET 아님).  
같은 메이저(4.x)라도 가능하면 이 버전으로 연다.

1. [Godot 4 다운로드 (Windows)](https://godotengine.org/download/windows/) — **4.7 표준 버전** (`.NET` / C# 아님)
2. ZIP을 풀고 `Godot_v4.7*_win64.exe` 실행

## 2. 프로젝트 열기

1. Godot 프로젝트 매니저 → **Import**
2. `glass-wild/godot/project.godot` 선택
3. **Play (F5)**

성공:

- 검은 화면 + 사육장 색 면 프레임
- 상단에서 규격 선택 · **편집** / **관찰로** · **격자** 토글
- 편집 시 우측 팔레트 · 표시 격자(5cm, ON/OFF)
- 지형·식물·동물은 **색 사각형** (도트 아트 전 단계)

## 3. 에디터 지도 (이 단계)

| 패널 | 쓰는 이유 |
|---|---|
| Scene | 노드 트리 (`main_wireframe.tscn`) |
| FileSystem | `scenes/ui/` 스크립트 |
| Inspector | 크기·앵커 |
| 중앙 뷰 | UI (`Control`) |

지금은 **UI용 `Control` + `_draw` 선**만 씁니다.

## 4. 와이어프레임 · 논리 셀 규칙

용어: [`../core/glossary.md`](../core/glossary.md), 결정: [D-010](../decisions/D-010-logic-cell-edit-palette.md)

| 역할 | 구현 |
|---|---|
| **논리 셀** | 한 변 **1cm**. 스냅·저장 단위 |
| **표시 격자** | 편집 시 **5cm마다** 선. **격자** 버튼으로 ON/OFF |
| 사육장·지형·생물 | **색 면** 플레이스홀더 (도트는 이후). `habitat_stage.gd` `_draw()` |
| 생물 자리 | `wire_actor.gd` (관찰 시 배회) |
| 편집 팔레트 | `edit_palette.gd` |

스프라이트 셀(px, D-002)과 논리 셀을 섞어 부르지 마세요.

## 5. 샌드박스에서 확인할 것

### 관찰 모드 (기본)

- 사육장 측면 프레임 + 수역 구분 수평선
- 배치한 동물이 있으면 자동 배회
- 하단 `상태: 안정`

### 편집 모드

1. **편집** → 우측 팔레트 + 표시 격자(기본 ON)
2. **격자** 버튼으로 표시 격자 ON/OFF
3. **지형** (벽지·땅·물): **점**(1셀 클릭) 또는 **사각형**(드래그로 영역 채우기)
4. **식물·이끼**: 클릭. 이끼(바닥)/이끼(벽지)는 `plant_surfaces` 면만
5. **동물**: 클릭. [D-007](../decisions/D-007-mvp-content-count.md) 팔루다리움 예시 7종(네리트 달팽이·체리새우·등각류·모어닝게코·스프링테일·다트프록·앤들러 구피). 라벨은 표시 이름, 도형은 색 사각형 더미
6. **관찰로** → 격자·팔레트 숨김, 동물 배회

### 사육장 규격 (가로×깊이×높이 cm)

측면은 **가로:높이** 비율. 하단 라벨에 **논리 셀 개수**(예: 60×45 → 60×45). 기본: `60×45×45cm`.

| 규격 | 측면 비율 | 논리 셀 (W×H) |
|---|---|---|
| 30×30×45 | 2:3 | 30×45 |
| 45×45×45 | 1:1 | 45×45 |
| 60×45×45 | 4:3 | 60×45 |
| 60×45×60 | 1:1 | 60×60 |
| 90×45×60 | 3:2 | 90×60 |
| 120×60×60 | 2:1 | 120×60 |

### 창 리사이즈

창 **resizable**. 스트레치 `canvas_items` + `expand`. ([D-002](../decisions/D-002-resolution-sprite-size.md))

### 주요 파일

| 파일 | 역할 |
|---|---|
| `scenes/ui/main_wireframe.gd` | 크롬·격자 토글·팔레트 |
| `scenes/ui/habitat_stage.gd` | 논리 격자·지형 점/사각형·배치 |
| `scenes/ui/edit_palette.gd` | 지형 / 식물·이끼 / 동물 |
| `scenes/ui/wire_actor.gd` | 관찰 시 배회 |
| `scenes/ui/wire_box.gd` | 재사용 외곽선 |

## 6. 다음에 할 일

1. Figma 와이어 — [`../design/figma-plan.md`](../design/figma-plan.md), [`../ui/flow.md`](../ui/flow.md)
2. 기술 스파이크 — [`../roadmap/development-order.md`](../roadmap/development-order.md) Phase 2
3. 와이어 → 도트 — [`../art/pixel-art-pipeline.md`](../art/pixel-art-pipeline.md), `skills/glass-wild-sprite-maker`

## 7. 공식 문서 (보조)

에디터 조작이 낯설면: [Godot Step by Step](https://docs.godotengine.org/en/stable/getting_started/step_by_step/index.html)
