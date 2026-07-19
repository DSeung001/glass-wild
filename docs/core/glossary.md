# Glass Wild 용어집

고유 용어의 **단일 기준**입니다. 문서·스킬·코드를 작성할 때 이 파일과 아래 치환표를 따릅니다.

## 치환표

| 쓰지 말 것 | 쓸 것 |
|---|---|
| `Move` (애니 이름) | `Walk` / 파일·키 `walk` |
| `IdleToMove` / `MoveToIdle` | `IdleToWalk` / `WalkToIdle` |
| 물 공간 | 수역 |
| 사육장 배경 벽 / 배경 벽면 (사육장 면) | 벽지 (`wall_face`) |
| 사육장 뒷벽을 “배경화면”으로 부름 | 벽지 (`wall_face`) |
| OS·제품 desktop wallpaper를 “벽지”로 부름 | 배경화면 / 배경화면 모드 (D-006) |
| `substrate_tile` (asset_type) | `floor_tile` |
| `wall_tile` (asset_type) | `wall_face` |
| 바닥 접점 (육상·수중 혼용) | `contact_mode` 기준점 (`ground_y` / `waterline_y`) |
| 도트 셀 / 스프라이트 셀 (배치·판정 단위로) | **논리 셀** |
| 셀 (모호한 단독 표기, 맥락 없을 때) | **논리 셀** 또는 **스프라이트 셀**로 구분 |
| 편집 화면 / 편집 모드 / 편집 팔레트 | 가꾸기 화면 / 가꾸기 모드 / 가꾸기 팔레트 |
| `edit view` / `edit mode` / `edit_palette` | `tend view` / `tend mode` / `tend_palette` |

### 치환하지 않는 것

- D-001·D-006의 **배경화면** (데스크톱 관찰 모드 — 의도된 용어)
- 「벽면 활동 구역」의 **벽면** (활동 구역 태그; 벽지와 다름)
- 레거시 entity 예시 ID (`humid_snail` 등) — ID 마이그레이션은 별도
- 아트 파이프라인의 **편집 원본**, 스프라이트 **연쇄 편집** 등 이미지·파일 편집 의미의 「편집」

## 플레이 공간·모드

| 한국어 | ID / 영문 | 정의 | 쓰지 말 것 |
|---|---|---|---|
| 사육장 | tank / enclosure | 독립 환경·배치물·생물을 가진 플레이 공간 | 테라리움만으로 혼용(맥락에 따라 허용하되 기본은 사육장) |
| 프리셋 | preset | 고습·온대·건조 등 사육장 환경 설정 묶음 | |
| 배경화면 모드 | wallpaper mode | UI 최소화, 도트 관찰 중심 실행 모드 (D-006) | 벽지 |
| 가꾸기 화면 | tend view | 표시 격자·블록형 배치 (D-003, D-010) | 편집 화면, edit view |
| 관찰 화면 | observe view | 격자 숨김, 생태 관찰 | |
| 세로형 프로토타입 | vertical slice | 적은 콘텐츠로 전체 흐름을 검증하는 빌드 | |
| 기술 스파이크 | tech spike | 본개발 전 최소 범위 위험 검증 | |

## 면·수역 (D-009)

| 한국어 | ID / 영문 | 정의 | 쓰지 말 것 |
|---|---|---|---|
| 벽지 | `wall_face` | 사육장 뒷벽·배경면 베이스 | 배경화면, wallpaper(OS) |
| 바닥 | `floor` / substrate | 육상·수중 기질 레이어 | |
| 수역 | `water_body` | 논리 격자 물 셀 집합, 물고기 유영 공간 | 물 공간 |
| 식재 오버레이 | plant overlay | 바닥·벽지에 겹치는 이끼·흙 포켓·부착 식물 | 베이스에 구워 넣기 |
| zone | `air` / `water` | 기상부 / 수중부 | |
| 기상부 | air zone | 수면 위 공간 | |
| 수중부 | water zone | 수역·수중 면 | |
| 벽면 | wall zone (activity) | 생물 **활동 구역** 태그 | 벽지와 혼동 |

## 격자·셀 (D-003 · D-010 · D-002)

| 한국어 | ID / 영문 | 정의 | 쓰지 말 것 |
|---|---|---|---|
| 논리 셀 | logic cell | 배치·판정·길찾기·저장의 최소 단위. **한 변 1cm** (D-010). 측면 뷰는 가로×높이 평면 | 도트 셀, 스프라이트 셀과 동일시 |
| 논리 격자 | logic grid | 논리 셀의 집합 (D-003, D-010) | |
| 표시 격자 | display grid | 가꾸기 화면에 그리는 선. **5cm마다**(기본), ON/OFF 가능. **스냅 단위는 논리 셀** | 표시 간격 = 논리 셀이라고 단정 |
| 스프라이트 셀 | sprite cell | 이미지 캔버스 32/48/64px (D-002) | 논리 셀 cm·판정 단위와 동일시 |

## 판정·상태

| 한국어 | ID / 영문 | 정의 | 쓰지 말 것 |
|---|---|---|---|
| 환경 적합도 | fitness score | 생물별 0~100 | |
| 전체 안정도 | tank stability | 사육장 대표 안정도 | |
| 합사 판정 | compatibility check | 같은 사육장 다수 생물 위험 평가 | |
| 활동 구역 | activity zone | 바닥·식물·벽면·수중 등 (플레이 태그) | |
| locomotion | locomotion / access | 종이 접근 가능한 면·수역 **태그 조합** (`floor_air`, `swim` 등). 선택 `access_limits`로 cm 한도. 활동 구역보다 배치·이동 판정에 가깝다 | 활동 구역과 동일시; bool 플래그 객체로만 기술 |
| 표시 이름 | display name | UI에 보이는 이름. 내부 `id`와 분리 | ID를 그대로 UI에 노출 |
| 부상·격리·병원 | injury / quarantine | MVP 실패·복구 (D-005), 사망 없음 | |

## 아트·애니

| 한국어 | ID / 영문 | 정의 | 쓰지 말 것 |
|---|---|---|---|
| Walk | `walk` | 육상·기질 보행 애니 | `Move` |
| Swim | `swim` | 수역 유영 애니 | Walk로 대체 |
| contact_mode | `ground` / `water` / `surface` | 피벗·기준점 모드 | 무조건 “바닥 접점” |
| content_axis | `paludarium_mvp` / `extension` | MVP 첫 축 vs 확장 | |

## 혼동 쌍 요약

| A | B | 구분 |
|---|---|---|
| 벽지 (`wall_face`) | 배경화면 모드 | 사육장 면 vs OS 관찰 모드 |
| Walk / `walk` | Move (폐기) | 애니·파일명 |
| 수역 | 물 공간 (구) | 동일 개념 → 수역만 사용 |
| 벽면 (활동 구역) | 벽지 | 행동 공간 vs 뒷벽 자산 |
| 논리 셀 (1cm) | 스프라이트 셀 (px) | 배치·판정 vs 아트 캔버스 |
| 논리 셀 | 표시 격자 | 스냅 단위 vs 화면용 선 |
| 가꾸기 / `tend` | 편집 / `edit` (폐기) | 사육장 배치·환경 변경 모드 |
