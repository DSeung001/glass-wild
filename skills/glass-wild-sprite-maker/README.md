# Glass Wild Sprite Maker Skill

Glass Wild의 생물, 식물, 구조물, 장비, 먹이, 바닥재, 이끼, 벽면 이미지를 반복 가능한 프로젝트 규칙으로 생성하기 위한 ChatGPT/Codex 스킬입니다.

## 규칙 권한

| 환경 | 기준 |
|---|---|
| ChatGPT (스킬 ZIP만) | `SKILL.md` 내장 규칙만으로 완결. 저장소 `docs/` 불필요 |
| Cursor / 저장소 | `docs/`의 Decided·최신 값이 스킬 내장값보다 우선 |

## 해결하는 문제

매 요청마다 다음 조건을 다시 입력하지 않아도 됩니다.

- Glass Wild의 관찰형 사육 시뮬레이션 분위기 (MVP 기본 예시는 열대 팔루다리움)
- 측면 또는 측면에 가까운 3/4 시점
- 제한 팔레트 픽셀 아트
- 1픽셀 외곽선
- 좌측 상단 광원
- 투명 배경과 안티앨리어싱 금지
- 체급별 셀(32 / 48 / 64)과 논리 격자 배치
- 생물의 피벗, 바닥 접점, 몸 비율 고정
- Godot용 파일명, 노드와 텍스처 설정
- 생물·식물·타일별 품질 검수

## 설치

### ChatGPT Skills

1. 이 디렉터리(`glass-wild-sprite-maker`)를 ZIP으로 압축합니다. ZIP 루트에 `SKILL.md`가 있어야 합니다.
2. ChatGPT Skills에서 Upload from your computer로 설치합니다.
3. `docs/`는 포함하지 않아도 됩니다. 동작에 필요한 규칙은 모두 `SKILL.md`에 있습니다.

### Cursor / 저장소와 함께 사용

저장소 `docs/`를 읽을 수 있으면 스킬이 내장값보다 문서를 우선합니다.

1. `docs/decisions/` (D-002, D-003, D-004, D-007 등)
2. `docs/art/pixel-art-pipeline.md`, `animation-guide.md`
3. `docs/mvp/vertical-slice.md`, `scope.md`
4. `docs/entities/` (역할군·확장 후보; MVP 첫 축 예시는 D-007)

### 동기화

`docs/decisions` 또는 `docs/art`가 바뀌면 ChatGPT에 다시 올리기 전에 `SKILL.md`의 내장 표·목록을 갱신한다.

## 사용 예시

설치 후에는 짧게 요청합니다.

```text
Glass Wild용 네리트 달팽이 이동 애니메이션 만들어줘.
```

```text
습한 흙 바닥 타일 4종과 깃털이끼 투명 오버레이 만들어줘.
```

```text
고습 사육장에 놓을 포토스 스프라이트를 생성해줘.
```

```text
첨부한 등각류 스프라이트가 프로젝트 규칙에 맞는지 검수해줘.
```

```text
이미지는 만들지 말고 Godot 반입 규격과 프롬프트만 작성해줘.
```

## 반영된 결정 (내장 스냅샷)

스킬 기본값은 다음 Decided 결정을 반영합니다. 내장 규칙에 `walk`·`contact_mode`·체급 기본값이 포함되어 있으며, docs 애니 용어도 Walk/`walk`로 일치합니다.

| 결정 | 내용 |
|---|---|
| D-002 | 1920×1080 기준, 체급별 셀 32·48·64, 스파이크에서 기본 셀 비교 |
| D-003 | 논리 격자 + 셀 내부 시각 오프셋, 편집 격자 / 관찰 숨김 |
| D-004 | 현실 참고·가상·과장 가능, 실사 복제·사육 지침화 금지 |
| D-007 | 열대 팔루다리움 = MVP 첫 축·예시 (닫힌 로스터 아님, 동물군 확장 가능) |

## 권장 첫 테스트

세로형 프로토타입과 D-007에 맞춰 다음 순서로 테스트합니다.

1. `nerite_snail` 기준 스프라이트
2. `nerite_snail` Idle, Walk, Eat, Hide
3. `isopod` 기준 스프라이트
4. `isopod` Idle, Walk, Eat, Avoid
5. `substrate_moist` 중앙·가장자리 타일
6. `feather_moss` 투명 오버레이
7. `pothos` 정적 스프라이트와 2~4프레임 흔들림
8. `shelter_small`, `mister`, `food_plant`

세로형·스파이크 비교 요청에서는 32×32와 48×48 가독성을 함께 확인합니다. 그 외에는 요청 체급 셀 하나로 진행합니다.
