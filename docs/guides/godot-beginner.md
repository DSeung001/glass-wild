# Glass Wild — Godot 처음 시작 (그림판 와이어)

Godot를 처음 쓰는 사람을 위한 **이 저장소 맞춤** 안내입니다.  
최종 도트 아트는 나중에 두고, 지금은 **그림판처럼 색 면**으로 화면만 만듭니다.

본격 MVP Godot 구현은 [D-008](../decisions/D-008-figma-exit-criteria.md) 이후입니다. 지금은 학습용입니다.

## 0. 시작 전

**Glass Wild**: 사육장을 꾸미고 생물을 관찰하는 Godot 2D 게임입니다. 용어는 [`../core/glossary.md`](../core/glossary.md)를 따릅니다.

| 지금 하는 것 | 지금 안 하는 것 |
|---|---|
| 화면 전환 (대시보드 ↔ 관찰 ↔ 편집) | 도트 스프라이트·타일맵 |
| `ColorRect` / `Label` / `Button` | 배경화면 투명 창 |
| 사육장·생물 **자리**만 잡기 | 환경 시뮬·합사 판정 전체 |

따라 하는 방법 두 가지:

1. **이미 있는 샌드박스 열기** — 저장소의 [`../../godot/`](../../godot/) 를 Godot에서 Import 후 F5  
2. **직접 만들기** — 아래 Step을 빈 프로젝트에서 따라 하기  

둘 다 결과는 비슷합니다.

## 1. Godot 설치

1. [Godot 4 다운로드 (Windows)](https://godotengine.org/download/windows/) — **표준 버전** (`.NET` / C# 아님)
2. ZIP을 풀고 `Godot_v4*_win64.exe` 실행
3. 권장: **4.3 이상** 안정판

## 2. 프로젝트 열기

1. Godot 프로젝트 매니저 → **Import**
2. `glass-wild/godot/project.godot` 선택
3. 열리면 상단 **Play (F5)**

성공: 회색·색 박스 UI가 뜨고 버튼으로 화면이 바뀝니다.

## 3. 에디터 지도 (이 단계)

| 패널 | 쓰는 이유 |
|---|---|
| Scene | 노드 트리 (화면 구조) |
| FileSystem | `scenes/`, 스크립트 |
| Inspector | 색·텍스트·크기 |
| 중앙 뷰 | UI 배치 (Control) |

지금은 **UI용 `Control` 계열만** 씁니다. 생물용 `Node2D` / `CharacterBody2D`는 나중입니다.

## 4. 그림판 규칙

이미지 대신 단색으로 “그린다”고 생각하면 됩니다.

| 역할 | 노드 |
|---|---|
| 회색 UI 박스 | `Panel` 또는 `ColorRect` |
| 글자 | `Label` (용어는 glossary: 사육장, 안정, 주의 …) |
| 클릭 | `Button` |
| 생물 자리 | 색 `ColorRect` + `Label` (`nerite_snail` 등) |
| 격자 | 작은 `ColorRect`를 여러 개 |

이 단계에서는 도트 PNG·스프라이트 시트를 넣지 마세요.

## 5. Step-by-step (직접 만들기)

샌드박스를 고치지 않고 연습하려면 **새 씬**을 만들어도 됩니다. 목표는 샌드박스와 같습니다.

### Step 1 — 빈 메인

1. Scene → New Scene → **User Interface** (`Control`)
2. 루트 이름을 `MainWireframe`으로
3. Inspector에서 전체 화면에 맞게 Anchor를 full rect
4. Project Settings → Display → Window: Width **1920**, Height **1080** ([D-002](../decisions/D-002-resolution-sprite-size.md))
5. Project → Project Settings → Application → Run → Main Scene에 이 씬 지정

성공: F5에 빈(또는 단색) 창이 1920×1080으로 뜸.

### Step 2 — 대시보드 (사육장 카드 3칸)

[`../ui/layout.md`](../ui/layout.md) **UI-02** 요약입니다.

1. `MainWireframe` 아래 `Dashboard` (`Control`, full rect)
2. 제목 `Label`: `사육장 대시보드`
3. 가로로 `ColorRect` 카드 3개 — 각각 Label: `사육장 1` / `2` / `3`, 상태 `안정` 등
4. 버튼 `관찰하기`

성공: 카드 세 개가 보이고 상태가 읽힘.

### Step 3 — 관찰 화면

1. `Habitat` (`Control`, full rect) — 처음엔 `visible = false`
2. 큰 `ColorRect` (사육장 관찰 영역)
3. 그 안에 작은 색 박스 + Label `nerite_snail` (생물 자리)
4. 하단 Label: `상태: 안정`
5. 버튼 `대시보드로` / `편집`

성공: 큰 영역 + 생물 자리 + 상태가 보임.

### Step 4 — 화면 전환

루트에 스크립트를 붙입니다.

```gdscript
extends Control

@onready var dashboard: Control = $Dashboard
@onready var habitat: Control = $Habitat
@onready var edit_screen: Control = $Edit

func _ready() -> void:
	_show_only(dashboard)

func _show_only(screen: Control) -> void:
	dashboard.visible = screen == dashboard
	habitat.visible = screen == habitat
	edit_screen.visible = screen == edit_screen

func _on_to_habitat_pressed() -> void:
	_show_only(habitat)

func _on_to_dashboard_pressed() -> void:
	_show_only(dashboard)

func _on_to_edit_pressed() -> void:
	_show_only(edit_screen)
```

버튼 Signal → 위 함수에 연결 (노드 선택 → Node 탭 → pressed).

성공: 버튼으로 대시보드 ↔ 관찰이 바뀜.

### Step 5 — 편집 화면 (격자)

[`../ui/layout.md`](../ui/layout.md) **UI-04** 요약.

1. `Edit` (`Control`, 처음 `visible = false`)
2. 작은 `ColorRect`를 격자로 여러 개 (논리 격자 느낌, [D-003](../decisions/D-003-placement-model.md))
3. Label `편집 — 격자 표시`
4. 버튼 `관찰로 돌아가기`

성공: 격자 칸이 보이고 관찰 화면으로 돌아올 수 있음.

### Step 6 (선택) — 색 생물 살짝 움직이기

관찰 화면의 생물 `ColorRect`에 스크립트:

```gdscript
extends ColorRect

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	position += dir * 120.0 * delta
```

성공: 관찰 화면에서 화살표 키로 색 박스가 움직임. (나중에 `Walk` 애니로 교체)

## 6. 다음에 할 일

1. Figma 와이어 — [`../design/figma-plan.md`](../design/figma-plan.md), [`../ui/flow.md`](../ui/flow.md)
2. 기술 스파이크 — [`../roadmap/development-order.md`](../roadmap/development-order.md) Phase 2
3. 그림판 → 도트 — [`../art/pixel-art-pipeline.md`](../art/pixel-art-pipeline.md), `skills/glass-wild-sprite-maker`

## 7. 공식 문서 (보조)

에디터 조작이 낯설면: [Godot Step by Step](https://docs.godotengine.org/en/stable/getting_started/step_by_step/index.html)  
장르는 달라도 **씬·시그널·F5** 감각을 익히는 용도입니다.
