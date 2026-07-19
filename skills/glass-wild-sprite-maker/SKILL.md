---
name: glass-wild-sprite-maker
description: Glass Wild 프로젝트에 맞는 Godot용 도트 스프라이트, 애니메이션 프레임, 식물, 구조물, 바닥재, 이끼, 벽면 타일을 일관된 규격으로 설계·생성·검수한다. 사용자가 Glass Wild의 생물, 식물, 아이템, 타일, 배경, 애니메이션 이미지 제작을 요청할 때 사용한다.
---

# Glass Wild Sprite Maker

## 목적

짧은 요청만 받아도 Glass Wild의 기존 기획과 아트 규칙을 적용해 다음 결과를 일관되게 만든다.

1. 자산 유형과 게임 내 역할 해석
2. 프로젝트 기본값이 반영된 이미지 생성 명세
3. 이미지 생성용 프롬프트
4. 애니메이션 프레임 계획
5. Godot 반입 규격과 파일명
6. 수동 보정 및 품질 검수 목록

사용자가 이미지 생성을 직접 요청하면 이미지 생성 기능을 사용한다. 프롬프트, 명세 또는 가이드만 요청하면 이미지를 생성하지 않는다.

## 저장소 문서 우선순위

저장소에 접근할 수 있으면 다음 문서를 먼저 확인하고, 이 스킬의 내장 기본값보다 최신 문서의 확정 결정을 우선한다.

- `docs/art/pixel-art-pipeline.md`
- `docs/art/animation-guide.md`
- `docs/decisions/D-002-resolution-sprite-size.md`
- `docs/decisions/D-003-placement-model.md`
- `docs/entities/animals.md`
- `docs/entities/plants.md`
- `docs/entities/items.md`
- `docs/mvp/vertical-slice.md`

문서의 상태가 `Pending`이면 확정값처럼 말하지 않는다. 요청에 필요한 결정을 다음 규칙으로 임시 해석하고, 결과에 `작업 가정`으로 표시한다.

## 프로젝트 정체성

모든 결과는 다음 방향을 따른다.

- Godot 기반 2D 도트 스타일 관찰형 사육 시뮬레이션
- 플레이어가 직접 생물을 조작하기보다 환경을 설계하고 관찰하는 게임
- 분위기: 잔잔한 관찰, 작은 긴장, 복구 가능한 사고
- 생물의 상태와 행동이 UI 없이도 작은 화면에서 읽혀야 함
- 사실적인 고어, 과도한 위협 표현, 장난감 같은 과장된 광택은 사용하지 않음
- 실제 생물의 특징을 참고하되 사진을 그대로 추적하거나 복제하지 않음
- 여러 자산을 함께 배치했을 때 하나의 테라리움 생태계처럼 보여야 함

## 기본 시각 규칙

사용자가 별도 조건을 주지 않으면 아래 값을 적용한다.

| 항목 | 기본값 |
|---|---|
| 시점 | 측면 또는 측면에 가까운 3/4 시점 |
| 투영 | 원근 왜곡이 거의 없는 2D 게임 시점 |
| 스타일 | 읽기 쉬운 제한 팔레트 픽셀 아트 |
| 외곽선 | 1픽셀, 프레임 간 두께 고정 |
| 생물 팔레트 | 생물당 8~16색 |
| 광원 | 좌측 상단 |
| 안티앨리어싱 | 사용하지 않음 |
| 배경 | 개별 오브젝트와 생물은 완전 투명 |
| 확대 | 정수 배율, nearest-neighbor |
| 텍스트·격자선 | 이미지 안에 포함하지 않음 |
| 그림자 | 별도 요청이 없으면 제거하거나 최소화 |

### 셀 크기 임시 규칙

`D-002`가 확정되기 전까지 생물 기본 셀을 최종값으로 단정하지 않는다.

- 프로토타입 생물 요청에서 크기를 생략하면 `32×32 비교안`과 `48×48 비교안`을 제시한다.
- 실제 이미지 한 세트만 생성해야 하면 디테일 보존을 위해 48×48 구도를 우선하되, 32×32 축소 시 실루엣 가독성도 함께 검수한다.
- 식물과 구조물은 논리 셀의 1×1, 1×2, 2×2 점유 크기로 기술한다.
- 타일은 선택된 논리 셀 크기에 맞춰 동일한 격자를 유지한다.
- GPT 이미지 결과가 정확한 픽셀 크기나 픽셀 배치를 보장한다고 말하지 않는다. 생성 결과는 콘셉트 또는 키 포즈 원본이며 Aseprite, Pixelorama 또는 스크립트 후처리를 전제로 한다.

## 배치 모델 임시 규칙

`D-003`가 확정되기 전까지 다음 권장안을 사용한다.

- 내부 판정은 논리 격자 또는 슬롯 기준
- 식물과 구조물은 셀 내부에서 작은 시각 오프셋 허용
- 기능 아이템은 피벗과 점유 셀을 명확히 지정
- 관찰 화면에서는 격자가 보이지 않도록 자연스러운 가장자리와 실루엣 사용

## 자산 유형 분류

요청을 다음 중 하나로 분류한다.

1. `creature`: 달팽이, 등각류, 귀뚜라미, 사마귀, 개구리, 도마뱀 등
2. `plant`: 습도 식물, 바닥 덮개, 높은 은신처 식물, 등반 식물, 건조 식물, 식용 식물
3. `structure`: 은신처, 나뭇가지, 돌 구조물
4. `equipment`: 히터, 분무 장치, 환기 장치, 조명, 얕은 물 공간
5. `food`: 식물성 먹이, 과일·채소, 곤충 먹이, 사료
6. `substrate_tile`: 습윤 바닥재, 모래, 낙엽층, 혼합 바닥재
7. `moss_overlay`: 바닥이나 구조물 위에 겹치는 투명 이끼
8. `wall_tile`: 사육장 배경 벽면, 코르크, 암석면, 유리 가장자리
9. `background`: 사육장 후면의 넓은 반복 또는 단일 배경

자산 유형을 분류할 수 있으면 추가 질문 없이 기본값을 적용한다. 결과를 크게 바꾸는 정보가 완전히 누락된 경우에만 질문한다. 질문 대신 합리적인 작업 가정을 사용할 수 있으면 작업을 진행하고 가정을 명시한다.

## 요청 처리 모드

사용자의 문장에 따라 다음 모드를 선택한다.

- `생성`: “만들어줘”, “생성해줘”, “그려줘” — 실제 이미지 생성
- `프롬프트`: “프롬프트 만들어줘” — 복사 가능한 프롬프트만 제공
- `명세`: “규격 정해줘”, “기획해줘” — 자산 명세와 프레임 계획 제공
- `Godot`: “가져오는 법”, “Godot 설정” — 반입 구조와 노드 설정 제공
- `검수`: 이미지가 첨부됨 — 프로젝트 규칙에 따라 문제를 판정하고 수정 지시 작성

## 공통 출력 순서

이미지 생성 전 또는 프롬프트 제공 시 다음 순서로 정리한다.

### 1. 해석된 명세

```yaml
asset_type: creature | plant | structure | equipment | food | substrate_tile | moss_overlay | wall_tile | background
entity_id: snake_case_id
purpose: static | animation | tile | overlay | reference
view: side | near_side_3_4
cell_size: 32x32 | 48x48 | pending_comparison
footprint: 1x1 | 1x2 | 2x2 | custom
pivot: bottom_center | center | custom
background: transparent | opaque
lighting: upper_left
palette: limited
```

### 2. 생성 전략

- 한 장의 완성 스프라이트 시트를 바로 생성할지 여부
- 기준 스프라이트가 필요한지 여부
- 키 포즈와 중간 프레임 분리 여부
- 타일 변형과 오버레이 분리 여부
- 32×32와 48×48 비교가 필요한지 여부

### 3. 이미지 생성 프롬프트

프로젝트 기본값, 대상 특징, 자세, 캔버스 규칙, 투명 배경, 금지 조건을 하나의 완전한 프롬프트로 작성한다.

### 4. Godot 전달 규격

- 파일 경로와 파일명
- 노드 유형
- 프레임 수와 FPS
- 피벗과 바닥 접점
- 반복, 필터, 밉맵 여부
- TileSet 또는 SpriteFrames 구성

### 5. 검수 항목

실제 게임 크기, 프레임 간 일관성, 투명 픽셀, 팔레트, 루프, 타일 연결을 검사한다.

실제 이미지를 생성하는 요청에서는 설명을 과도하게 길게 하지 말고 명세를 짧게 확정한 뒤 생성한다.

## 생물 스프라이트 제작 규칙

### 기준 스프라이트 우선

애니메이션 요청에서 승인된 기준 이미지가 없으면 다음 순서로 진행한다.

1. 정지 기준 스프라이트 또는 모델 시트 생성
2. 사용자 또는 현재 요청의 조건으로 기준 디자인 확정
3. 시작·중간·끝 키 포즈 생성
4. 중간 프레임 생성
5. Aseprite 또는 Pixelorama에서 수동 정리
6. Godot용 개별 PNG 또는 시트로 내보내기

프레임 1을 편집해 프레임 2를 만들고, 프레임 2에서 프레임 3을 만드는 연쇄 편집은 피한다. 모든 프레임은 동일한 승인 기준 스프라이트를 참조해야 한다.

### 프레임 고정 조건

모든 프레임에서 다음 요소를 유지한다.

- 종과 개체의 동일성
- 몸 비율과 전체 크기
- 눈, 더듬이, 다리, 껍질 무늬 위치
- 외곽선 두께
- 팔레트와 광원
- 캔버스 크기
- 피벗과 바닥 접점
- 카메라 각도
- 투명 배경

동작에 필요한 부위만 변경한다.

### 애니메이션 기본값

| 애니메이션 | 기본 프레임 | 반복 | 기본 FPS |
|---|---:|---|---:|
| Idle | 4 | 반복 | 6 |
| Move/Walk | 6 | 반복 | 8 |
| Eat | 4 | 반복 또는 1회 | 6 |
| Hide | 4 | 1회 | 8 |
| Sleep/Rest | 3 | 반복 | 4 |
| Avoid/Flee | Move 재사용 또는 6 | 반복 | 10 |
| Chase | 6 | 반복 | 10 |
| Attack | 4 | 1회 | 10 |
| Hit | 2 | 1회 | 10 |
| Injured | 3 | 반복 | 5 |

프레임 속도와 실제 이동 속도는 별도로 다룬다. 도트 애니메이션은 기본적으로 6~12 FPS 범위에서 사용한다.

### 생물별 MVP 세트

- `humid_snail`: Idle, Move, Eat, Hide
- `cleanup_isopod`: Idle, Move, Eat, Avoid
- `feeder_cricket`: Idle, Move, Eat, Flee
- `ambush_mantis`: Idle, Move, Notice, Chase, Attack
- `humid_frog`: Idle, Hop, Eat, Hide
- `dry_lizard`: Idle, Move, Rest, Chase

세로형 프로토타입 요청에서는 `humid_snail`과 `cleanup_isopod`을 우선한다.

### 행동 가독성

작은 화면에서 미세한 실제 동작보다 실루엣 변화를 우선한다.

- 먹기: 머리 또는 몸의 반복적인 전후 운동
- 숨기: 몸이 구조물 아래로 명확히 들어감
- 경계: 정지, 시선 고정, 더듬이 또는 머리 방향 변화
- 추적: 목표 방향 고정과 평상시보다 큰 이동 리듬
- 스트레스: 짧고 불규칙한 이동 또는 장시간 은신
- 환경 부적합: 움직임 감소와 특정 구역 체류

## 식물 제작 규칙

식물은 장식이 아니라 환경과 공간에 영향을 주는 게임 오브젝트로 설계한다.

- `moisture_plant`: 풍성한 잎, 습도 유지 역할이 읽히는 실루엣
- `ground_cover`: 낮고 넓으며 작은 생물이 숨을 수 있는 형태
- `tall_shelter`: 높은 잎과 명확한 하부 은신 공간
- `climbing_plant`: 벽면으로 이어지는 줄기와 부착 방향
- `dry_plant`: 건조한 환경과 어울리는 두꺼운 잎 또는 낮은 실루엣
- `edible_plant`: 일부 잎이 섭식 가능하다는 구조적 여유

기본적으로 투명 배경의 개별 PNG를 만든다. 피벗은 `bottom_center`이며, 점유 셀과 시각 오프셋을 명시한다.

식물 상태 표현:

- 건강: 기본 팔레트와 미세한 흔들림
- 약화: 채도와 잎 움직임 감소
- 시듦: 실루엣이 아래로 처지고 효과가 약해 보임

식물 애니메이션은 기본 흔들림 2~4프레임으로 제한한다. 바람이 없는 밀폐 사육장이라는 점을 고려해 과도한 흔들림을 피한다.

## 구조물·장비·먹이 제작 규칙

### 구조물

- 투명 배경의 개별 PNG
- 생물이 들어가거나 올라갈 수 있는 공간을 실루엣으로 명확히 표시
- 점유 셀, 충돌 영역, 은신 영역을 구분할 수 있게 설계
- 돌과 나무의 질감은 제한 팔레트로 단순화

### 장비

- 사육장 분위기를 깨지 않는 작은 도트 장비
- 기능을 식별할 수 있는 핵심 형태를 유지
- 켜짐·꺼짐 상태가 필요하면 색상 한두 개와 짧은 애니메이션으로 구분
- 강한 네온, 큰 UI 문자, 실제 제품 로고는 사용하지 않음

### 먹이

- 생물보다 작지만 실제 게임 크기에서 선택 가능한 실루엣
- `fresh`, `old`, `spoiled`, `remove` 상태가 색과 형태로 구분됨
- 부패 상태는 과도하게 혐오스럽지 않게 표현

## 바닥재 타일 제작 규칙

바닥재는 탑다운 타일로 자동 해석하지 않는다. Glass Wild의 기본 시점에 맞춰 사육장 내부를 측면 또는 측면에 가까운 3/4 시점으로 보여주는 바닥 스트립 또는 논리 셀 타일로 설계한다.

자산별 특징:

- `substrate_moist`: 어두운 습윤 흙, 작은 수분 반사, 부드러운 입자
- `substrate_sand`: 밝고 건조한 입자, 습윤 표현 없음
- `substrate_leaf`: 낙엽층이 겹쳐지고 작은 생물이 숨을 수 있는 틈
- `substrate_mixed`: 흙, 작은 자갈, 유기물이 균형 있게 섞임

기본 타일 세트:

- 중앙 반복 타일 3~4종
- 왼쪽 가장자리
- 오른쪽 가장자리
- 위쪽 노출 경계
- 오목·볼록 코너가 필요하면 별도 변형
- 구조물과 식물이 자연스럽게 얹히도록 상단 접촉면을 일정하게 유지

타일은 이미지 안에 격자선과 여백을 넣지 않는다. 완성 후 정확한 셀 경계로 잘라 아틀라스를 구성한다.

## 이끼 오버레이 제작 규칙

이끼는 바닥재와 합쳐진 불투명 타일이 아니라 별도 투명 오버레이를 기본으로 한다.

- 투명 배경
- 아래 바닥재가 보이도록 불규칙한 빈 공간 유지
- 중앙, 가장자리, 코너, 작은 패치 변형 제공
- 이끼 녹색이 식물 팔레트와 충돌하지 않도록 명도 차이를 둠
- 타일 경계에서 덩어리가 갑자기 끊기지 않음
- 반투명 안티앨리어싱 대신 완전 불투명 픽셀과 완전 투명 픽셀을 우선

## 벽면·배경 제작 규칙

- 측면 또는 약한 3/4 시점의 사육장 후면
- 생물과 식물보다 대비를 낮춰 전경 가독성을 유지
- 코르크, 흙벽, 암석면, 유리 가장자리 등 재질을 제한 팔레트로 단순화
- 반복 배경은 좌우 연결이 자연스럽고 눈에 띄는 큰 랜드마크 반복을 피함
- 등반 식물이나 벽면 생물을 위한 부착 지점을 지나치게 규칙적으로 만들지 않음
- 배경 자체에 강한 그림자나 중심 조명을 넣지 않음

## 이미지 생성 프롬프트 구성

프롬프트는 다음 순서로 작성한다.

1. 게임과 용도
2. 대상의 생물학적·기능적 특징
3. 시점과 포즈
4. 픽셀 아트 규격
5. 캔버스, 피벗, 바닥 접점
6. 팔레트와 광원
7. 투명도 또는 반복 조건
8. 변경 금지 조건
9. 제외 요소

### 생물 기본 프롬프트 골격

```text
Glass Wild, a calm 2D pixel-art terrarium observation simulation.
Create one [entity] game sprite for [purpose].
[species and silhouette description].
Strict side or near-side 3/4 view, minimal perspective distortion.
Readable silhouette at [32x32 or 48x48] target size.
One-pixel outline, limited 8–16 color palette, light from upper left.
No anti-aliasing, no blur, no text, no scenery, no UI.
Transparent background, integer-pixel alignment.
Keep the body proportions, markings, palette, camera angle, pivot and ground contact consistent.
[pose or animation frame description].
```

### 타일 기본 프롬프트 골격

```text
Glass Wild 2D pixel-art terrarium environment asset.
Create a seamless [substrate, moss overlay or wall] tile for a side or near-side 3/4 terrarium view.
[material description and gameplay role].
Consistent upper-left lighting, limited palette, crisp pixel clusters.
No anti-aliasing, no text, no grid lines, no baked objects.
Edges must connect naturally with adjacent tiles.
[transparent background for overlay / opaque background for wall or substrate].
```

### 금지 조건

필요한 항목을 자동으로 추가한다.

- no text
- no labels
- no frame numbers
- no grid lines
- no UI
- no watermark
- no photorealism
- no smooth vector edges
- no anti-aliasing
- no blurry pixels
- no cast shadow unless requested
- no perspective camera distortion
- no extra animals or plants
- no cropped body parts
- no inconsistent markings

## Godot 전달 규격

### 폴더 구조

```text
assets/
  source/
    prompts/
    generated/
    aseprite/
  sprites/
    creatures/
    plants/
    structures/
    equipment/
    food/
  tiles/
    substrates/
    moss/
    walls/
  palettes/
  references/
```

### 파일명

생물 프레임:

```text
{entity_id}_{animation}_{direction}_{frame}.png
```

예:

```text
humid_snail_move_right_01.png
humid_snail_move_right_02.png
cleanup_isopod_eat_right_01.png
```

정적 오브젝트:

```text
{entity_id}_{variant}.png
```

타일:

```text
{material_id}_{tile_role}_{variant}.png
```

예:

```text
substrate_moist_center_01.png
moss_humid_edge_left_01.png
wall_cork_center_01.png
```

### Godot 노드 매핑

| 자산 | 노드 또는 리소스 |
|---|---|
| 생물 애니메이션 | `AnimatedSprite2D` + `SpriteFrames` |
| 식물·구조물·장비·먹이 | `Sprite2D`, 상호작용 시 `Area2D` 추가 |
| 바닥재·이끼·벽면 | `TileSet` + `TileMapLayer` |
| 움직이는 생물 | 상위 `CharacterBody2D` 또는 프로젝트 이동 노드 |

### 텍스처 설정

- nearest-neighbor 필터
- 밉맵 비활성화
- 정수 위치와 정수 배율
- 반복 텍스처는 실제 seamless 타일에만 활성화
- 개별 스프라이트의 불필요한 repeat 비활성화
- 피벗은 생물과 정적 오브젝트 모두 문서화

### 애니메이션 메타데이터

```json
{
  "entity_id": "humid_snail",
  "animation": "move",
  "direction": "right",
  "frame_width": 48,
  "frame_height": 48,
  "frame_count": 6,
  "fps": 8,
  "loop": true,
  "pivot": { "x": 24, "y": 42 },
  "ground_y": 42
}
```

셀 크기가 확정되지 않았으면 메타데이터를 최종 파일로 확정하지 않고 비교용으로 표시한다.

## 품질 검수

### 공통

- 실제 게임 크기 1배에서 대상이 식별되는가
- 2배와 4배 정수 확대에서 픽셀이 깨끗한가
- 반투명 경계 픽셀이 남아 있지 않은가
- 팔레트가 자산별 제한 범위를 벗어나지 않는가
- 광원이 좌측 상단으로 일관되는가
- 배경과 전경의 대비가 충돌하지 않는가

### 애니메이션

- 프레임마다 몸 크기가 변하지 않는가
- 피벗과 바닥 접점이 고정되어 있는가
- 외곽선이 깜빡이지 않는가
- 첫 프레임과 마지막 프레임이 자연스럽게 연결되는가
- 이동 속도와 도트 프레임 리듬이 어긋나지 않는가
- UI 없이도 Idle, Move, Eat, Hide 또는 위험 행동을 구분할 수 있는가
- 좌우 반전 시 비대칭 특징과 광원이 어색하지 않은가

### 타일

- 좌우 또는 상하 연결부가 끊기지 않는가
- 동일한 무늬가 짧은 주기로 눈에 띄게 반복되지 않는가
- 가장자리와 중앙 타일의 재질 밀도가 일치하는가
- 이끼 오버레이 아래 바닥재가 충분히 보이는가
- 타일 안에 식물, 생물, 장비가 구워져 있지 않은가

## 실패 시 수정 방식

이미지가 규칙을 위반하면 전체를 새로 설명하기보다 변경 범위를 좁혀 수정한다.

예:

```text
달팽이의 몸 위치, 껍질 크기, 팔레트, 외곽선, 카메라 각도와 투명 배경은 그대로 유지한다.
이번 수정에서는 더듬이 각도와 머리의 전진 동작만 변경한다.
다른 요소는 변경하지 않는다.
```

타일 수정 예:

```text
재질, 팔레트와 조명은 그대로 유지한다.
왼쪽과 오른쪽 경계만 자연스럽게 이어지도록 수정한다.
타일 중앙의 큰 자갈과 랜드마크는 제거한다.
```

## 최소 요청 예시

다음과 같은 짧은 요청을 완전한 명세로 확장한다.

- `달팽이 이동 애니메이션 만들어줘`
- `등각류 먹는 모션 4프레임`
- `습한 흙 바닥 타일 만들어줘`
- `바닥 위에 겹칠 이끼 만들어줘`
- `고습 사육장 벽지 필요해`
- `습도 유지 식물 하나 생성해줘`
- `이 이미지가 Glass Wild 스타일에 맞는지 검수해줘`

요청에 없는 프로젝트 공통 조건을 사용자에게 반복해서 입력하도록 요구하지 않는다.
