# Glass Wild Sprite Maker Skill

Glass Wild의 생물, 식물, 구조물, 장비, 먹이, 바닥재, 이끼, 벽면 이미지를 반복 가능한 프로젝트 규칙으로 생성하기 위한 ChatGPT/Codex 스킬입니다.

## 해결하는 문제

매 요청마다 다음 조건을 다시 입력하지 않아도 됩니다.

- Glass Wild의 관찰형 테라리움 분위기
- 측면 또는 측면에 가까운 3/4 시점
- 제한 팔레트 픽셀 아트
- 1픽셀 외곽선
- 좌측 상단 광원
- 투명 배경과 안티앨리어싱 금지
- 생물의 피벗, 바닥 접점, 몸 비율 고정
- Godot용 파일명, 노드와 텍스처 설정
- 생물·식물·타일별 품질 검수

## 설치

### ChatGPT Skills

1. 이 디렉터리를 ZIP 파일로 압축합니다.
2. ChatGPT의 Skills 화면을 엽니다.
3. Create 또는 New skill에서 Upload from your computer를 선택합니다.
4. ZIP 파일을 업로드하고 내용을 검토한 뒤 설치합니다.

ZIP 루트에는 `SKILL.md`가 있어야 합니다. 따라서 `glass-wild-sprite-maker` 디렉터리 자체를 압축해야 합니다.

### 저장소와 함께 사용

저장소를 읽을 수 있는 환경에서는 스킬이 다음 문서의 최신 결정을 우선합니다.

- `docs/art/pixel-art-pipeline.md`
- `docs/art/animation-guide.md`
- `docs/decisions/D-002-resolution-sprite-size.md`
- `docs/decisions/D-003-placement-model.md`
- `docs/entities/animals.md`
- `docs/entities/plants.md`
- `docs/entities/items.md`

## 사용 예시

설치 후에는 짧게 요청합니다.

```text
Glass Wild용 달팽이 이동 애니메이션 만들어줘.
```

```text
습한 흙 바닥 타일 4종과 투명 이끼 오버레이 만들어줘.
```

```text
고습 사육장에 놓을 습도 유지 식물 스프라이트를 생성해줘.
```

```text
첨부한 등각류 스프라이트가 프로젝트 규칙에 맞는지 검수해줘.
```

```text
이미지는 만들지 말고 Godot 반입 규격과 프롬프트만 작성해줘.
```

## 현재 Pending 결정

스킬은 아래 항목을 최종 확정값으로 취급하지 않습니다.

- 생물 기본 셀: 32×32 또는 48×48
- 배치 방식과 논리 격자 크기
- 스프라이트 시트 또는 개별 프레임의 최종 저장 방식

관련 결정 문서가 확정되면 `SKILL.md`의 `셀 크기 임시 규칙`, `배치 모델 임시 규칙`, `Godot 전달 규격`을 갱신합니다.

## 권장 첫 테스트

세로형 프로토타입 범위에 맞춰 다음 순서로 테스트합니다.

1. `humid_snail` 기준 스프라이트
2. `humid_snail` Idle, Move, Eat, Hide
3. `cleanup_isopod` 기준 스프라이트
4. `cleanup_isopod` Idle, Move, Eat, Avoid
5. `substrate_moist` 중앙·가장자리 타일
6. 습윤 이끼 투명 오버레이
7. `moisture_plant` 정적 스프라이트와 2~4프레임 흔들림
8. `shelter_small`, `mister`, `food_plant`

각 결과는 32×32와 48×48 실제 표시 크기에서 가독성을 비교합니다.
