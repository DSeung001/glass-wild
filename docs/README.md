# Glass Wild 기획 문서

이 디렉터리는 구현 전에 게임의 규칙, 디자인 기준, 기술 위험과 MVP 범위를 확정하기 위한 단일 기준 문서입니다.

## 문서 원칙

- 파일 하나에는 하나의 주제만 포함합니다.
- 게임 규칙은 가능한 한 표와 명시적인 판정 기준으로 작성합니다.
- `안정`, `정보`, `주의`, `위험`, `긴급` 같은 상태 용어를 문서 전체에서 동일하게 사용합니다.
- 아직 확정되지 않은 내용은 `검토 필요` 또는 `Pending`으로 표시합니다.
- 사용자가 직접 결정해야 하는 항목은 `decisions/`에만 기록합니다.
- 현실 생물 정보를 게임에 적용하기 전 별도의 검증이 필요합니다.
- 코드 구조나 Godot 노드 구조는 핵심 게임 규칙과 기술 스파이크 이후 작성합니다.

## 먼저 읽을 문서

1. [`core/concept.md`](core/concept.md): 게임의 정체성과 설계 원칙
2. [`roadmap/development-order.md`](roadmap/development-order.md): 디자인부터 MVP까지 개발 순서
3. [`decisions/README.md`](decisions/README.md): 사용자가 확정해야 하는 결정 목록
4. [`design/figma-plan.md`](design/figma-plan.md): Figma 파일과 산출물 기준
5. [`mvp/vertical-slice.md`](mvp/vertical-slice.md): 첫 번째 세로형 프로토타입

## 문서 구조

### 핵심 정의

- [`core/concept.md`](core/concept.md): 게임 정체성, 설계 원칙, 범위
- [`core/loop.md`](core/loop.md): 일반 플레이와 배경화면 모드의 핵심 루프
- [`core/systems.md`](core/systems.md): 환경, 공간, 관계, 시간, 경고, 복구 시스템

### 엔티티

- [`entities/animals.md`](entities/animals.md): MVP 생물 역할과 데이터 필드
- [`entities/plants.md`](entities/plants.md): 식물 역할과 환경 효과
- [`entities/items.md`](entities/items.md): 바닥재, 구조물, 환경 장비와 먹이

### 관계 규칙

- [`relations/compatibility.md`](relations/compatibility.md): 합사, 포식, 경쟁과 과밀 판정
- [`relations/environment.md`](relations/environment.md): 환경 적합도와 구성 요소의 영향

### UI/UX와 디자인

- [`ui/layout.md`](ui/layout.md): 대시보드, 사육장, 편집, 긴급, 배경화면 화면 구성
- [`ui/flow.md`](ui/flow.md): 배치, 진단, 이동, 경고와 복구 사용자 흐름
- [`design/figma-plan.md`](design/figma-plan.md): Figma 페이지, 컴포넌트와 완료 기준

### 아트와 애니메이션

- [`art/pixel-art-pipeline.md`](art/pixel-art-pipeline.md): AI 생성부터 수동 보정까지 도트 에셋 제작 절차
- [`art/animation-guide.md`](art/animation-guide.md): 애니메이션 상태, 프레임과 전환 규칙

### 기술 검증

- [`technical/wallpaper-spike.md`](technical/wallpaper-spike.md): 투명 창, 입력 통과, 다중 모니터와 성능 스파이크

### MVP 관리

- [`mvp/scope.md`](mvp/scope.md): 포함 범위, 제외 범위와 콘텐츠 수량
- [`mvp/vertical-slice.md`](mvp/vertical-slice.md): 첫 번째 완결형 프로토타입
- [`mvp/checklist.md`](mvp/checklist.md): 개발, 품질과 플레이테스트 완료 기준

### 개발 순서

- [`roadmap/development-order.md`](roadmap/development-order.md): 의사결정, Figma, 기술 스파이크, 세로형 프로토타입과 확장 순서

### 사용자 의사결정

- [`decisions/README.md`](decisions/README.md): 결정 등록부와 우선순위
- [`decisions/D-001-platform-wallpaper.md`](decisions/D-001-platform-wallpaper.md): 플랫폼과 배경화면 MVP 기준
- [`decisions/D-002-resolution-sprite-size.md`](decisions/D-002-resolution-sprite-size.md): 기준 해상도와 도트 셀 크기
- [`decisions/D-003-placement-model.md`](decisions/D-003-placement-model.md): 자유 배치와 격자 배치
- [`decisions/D-004-creature-naming-realism.md`](decisions/D-004-creature-naming-realism.md): 실제 종명과 현실성 수준
- [`decisions/D-005-failure-death.md`](decisions/D-005-failure-death.md): 사망, 부상과 실패 처리
- [`decisions/D-006-wallpaper-interaction.md`](decisions/D-006-wallpaper-interaction.md): 배경화면 입력과 알림
- [`decisions/D-007-mvp-content-count.md`](decisions/D-007-mvp-content-count.md): MVP 콘텐츠 수량
- [`decisions/D-008-figma-exit-criteria.md`](decisions/D-008-figma-exit-criteria.md): Figma 완료와 Godot 진입 기준

## 주요 용어

| 용어 | 정의 |
|---|---|
| 사육장 | 독립적인 환경 상태, 배치물과 생물을 가진 플레이 공간 |
| 프리셋 | 고습·온대·건조 등 사육장 환경 설정 묶음 |
| 환경 적합도 | 특정 생물이 현재 사육장 환경에 얼마나 적합한지 나타내는 0~100 점수 |
| 전체 안정도 | 사육장 내부 생물 상태와 위험 요소를 종합한 대표 점수 |
| 합사 판정 | 둘 이상의 생물을 같은 사육장에 둘 때 발생할 위험을 평가하는 절차 |
| 활동 구역 | 바닥, 식물, 벽면, 수중 등 생물이 주로 사용하는 공간 |
| 배경화면 모드 | UI를 최소화하고 도트 애니메이션 중심으로 생태계를 관찰하는 실행 모드 |
| 긴급 상태 | 즉시 조치하지 않으면 부상 또는 심각한 환경 문제가 발생하는 상태 |
| 세로형 프로토타입 | 적은 콘텐츠로 전체 플레이 흐름을 끝까지 구현한 검증 빌드 |
| 기술 스파이크 | 구현 위험이 큰 기능을 본 개발 전에 최소 범위로 검증하는 작업 |

## 현재 확정된 원칙

| 항목 | 상태 |
|---|---|
| Godot 기반 2D 도트 스타일 | 확정 |
| 사육장 3개 | MVP 원칙 |
| 모든 콘텐츠 최초 공개 | MVP 확정 |
| 배경화면 관찰 기능 | 제품 핵심, 구현 기준은 결정 필요 |
| 환경·공간·관계 3계층 관리 | 확정 |
| 위험 배치 허용과 사전 경고 | 확정 |
| 사고 전 대응 시간 제공 | 확정 |
| 오프라인 진행 | MVP 제외 |
| 번식과 유전 | MVP 제외 |

## 현재 작업 순서

1. `decisions/`의 P0 항목 확정
2. Figma Foundations와 핵심 와이어프레임 작성
3. 배경화면·도트 애니메이션 기술 스파이크
4. 기술 결과를 Figma에 반영
5. 달팽이형·등각류형 세로형 프로토타입
6. 관계 시스템과 사육장 3개 확장
7. 콘텐츠, 저장, 설정과 성능 안정화
