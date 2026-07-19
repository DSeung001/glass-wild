# Glass Wild Sprite Maker Skill

Glass Wild의 생물, 식물, 구조물, 장비, 먹이, 바닥, 벽지, 수역, 이끼 이미지를 반복 가능한 프로젝트 규칙으로 생성하기 위한 ChatGPT/Codex 스킬입니다.

## 규칙 권한

| 환경 | 기준 |
|---|---|
| ChatGPT (스킬 ZIP만) | `SKILL.md` 내장 규칙만으로 완결. 저장소 `docs/` 불필요 |
| Cursor / 저장소 | `docs/`의 Decided·최신 값이 스킬 내장값보다 우선 |

## 해결하는 문제

매 요청마다 다음 조건을 다시 입력하지 않아도 됩니다.

- Glass Wild의 관찰형 사육 시뮬레이션 분위기 (MVP 기본 예시는 열대 팔루다리움)
- 바닥·벽지(`wall_face`)·수역 레이어와 zone(`air`/`water`)
- 측면 또는 측면에 가까운 3/4 시점
- 제한 팔레트 픽셀 아트, 1픽셀 외곽선, 좌측 상단 광원
- 투명 배경과 안티앨리어싱 금지
- 체급별 셀(32 / 48 / 64), `walk`/`Swim`, `contact_mode`
- Godot용 파일명·노드·텍스처 설정

## 설치

### ChatGPT Skills

1. 이 디렉터리(`glass-wild-sprite-maker`)를 ZIP으로 압축합니다. ZIP 루트에 `SKILL.md`가 있어야 합니다.
2. ChatGPT Skills에서 Upload from your computer로 설치합니다.
3. `docs/`는 포함하지 않아도 됩니다. 동작에 필요한 규칙은 모두 `SKILL.md`에 있습니다.

### Cursor / 저장소와 함께 사용

1. `docs/decisions/` (D-002, D-003, D-004, D-007, D-009 등)
2. `docs/core/habitat-surfaces.md`
3. `docs/art/pixel-art-pipeline.md`, `animation-guide.md`
4. `docs/mvp/vertical-slice.md`, `scope.md`
5. `docs/entities/` (역할군·확장 후보)

### 동기화

`docs/decisions`, `docs/core/habitat-surfaces.md` 또는 `docs/art`가 바뀌면 ChatGPT에 다시 올리기 전에 `SKILL.md` 내장 표를 갱신한다.

## 사용 예시

```text
Glass Wild용 네리트 달팽이 이동 애니메이션 만들어줘.
```

```text
육상 코르크 벽지와 수중 암석 벽지 타일 만들어줘.
```

```text
수역 타일이랑 수면 흐름 이펙트 만들어줘. 유체 물리 없이 도트 애니로.
```

```text
첨부한 등각류 스프라이트가 프로젝트 규칙에 맞는지 검수해줘.
```

## 반영된 결정 (내장 스냅샷)

내장 규칙에 `walk`·`contact_mode`·체급 기본값·바닥/벽지/수역·zone이 포함되어 있으며 docs와 용어를 맞춥니다.

| 결정 | 내용 |
|---|---|
| D-002 | 1920×1080 기준, 체급별 셀 32·48·64 |
| D-003 | 논리 격자 + 셀 내부 시각 오프셋 |
| D-004 | 현실 참고·가상·과장, 실사·사육 지침화 금지 |
| D-007 | 열대 팔루다리움 = MVP 첫 축·예시 |
| D-009 | 바닥·벽지·수역 레이어, 수중 식재, 유체 물리 MVP 제외 |

## 권장 첫 테스트

1. `nerite_snail` 기준 + Idle/Walk/Eat/Hide
2. `isopod` 기준 + Idle/Walk/Eat/Avoid
3. `substrate_moist` (zone air) 타일
4. `wall_cork` (zone air) 벽지
5. `feather_moss` 오버레이
6. `pothos`, `shelter_small`, `mister`, `food_plant`

이후 팔루다리움 확장: `water_body`, `wall_aquatic_rock`, `endler_guppy` Swim.
