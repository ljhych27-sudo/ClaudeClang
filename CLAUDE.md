# ClaudeClang

## 프로젝트 개요
Clang/LLVM 툴체인으로 C/C++ 코드를 작성·빌드하는 프로젝트.

- 컴파일러: `clang` / `clang++`
- 포맷·정적 분석: `clang-format`, `clang-tidy`
- 빌드 시스템: CMake (빌드 산출물은 `build/`, git 제외)

## Claude Code 구성
- `.claude/settings.json` — 팀 공유 설정 (권한, 훅 등)
- `.claude/settings.local.json` — 개인 설정 (git 제외)
- `.claude/skills/<skill-name>/SKILL.md` — 프로젝트 스킬
- `.claude/agents/<agent-name>.md` — 프로젝트 서브에이전트

## A-SPICE 개발 프로세스
모든 개발은 아래 스킬 순서를 따르고, 각 산출물은 `review` 스킬로 리뷰한다.

| 단계 | 스킬 | A-SPICE | 산출물 위치 |
|---|---|---|---|
| 요구사항 분석 | `requirements-analysis` | SWE.1 | `docs/requirements/` |
| 아키텍처 설계 | `architecture-design` | SWE.2 | `docs/architecture/` |
| 상세 설계 | `detailed-design` | SWE.3 | `docs/design/` |
| 구현 | `implementation` | SWE.3 | `src/`, `include/` |
| 단위 테스트 | `unit-test` | SWE.4 | `tests/unit/`, `docs/test/` |
| 통합 테스트 | `integration-test` | SWE.5 | `tests/integration/`, `docs/test/` |
| 리뷰 | `review` | SUP.4 | `docs/reviews/` |

### ID 체계 (추적성)
| 대상 | ID 형식 | 예 |
|---|---|---|
| 기능 요구사항 | `SWR-F-NNN` | SWR-F-001 |
| 품질 요구사항 (ISO 25010) | `SWR-Q-NNN` | SWR-Q-003 |
| 제한 요구사항 | `SWR-L-NNN` | SWR-L-002 |
| 제약 요구사항 | `SWR-C-NNN` | SWR-C-001 |
| 기능안전 요구사항 (별도 문서) | `SSR-NNN` | SSR-004 |
| 컴포넌트 / 컴포넌트 인터페이스 | `CMP-NNN` / `CIF-NNN` | CMP-002 / CIF-005 |
| 모듈 / 모듈 인터페이스 | `MOD-NNN` / `MIF-NNN` | MOD-010 / MIF-012 |
| 단위 / 통합 테스트 케이스 | `UT-NNN` / `IT-NNN` | UT-031 / IT-007 |
| 리뷰 기록 | `RV-YYYYMMDD-NN` | RV-20261127-01 |

- 추적성 매트릭스는 `docs/traceability.md` 한 곳에서 관리하며, 산출물을 추가·변경할 때마다 함께 갱신한다.
- 추적은 **양방향**이다: 요구사항 → 설계 → 코드 → 테스트로 내려가고, 각 하위 항목은 상위 ID를 `Traces:` 필드(문서) 또는 `@trace` 태그(코드·테스트 주석)로 거슬러 올라간다.
- 상위에 연결되지 않은 하위 항목, 하위로 구현·검증되지 않은 상위 항목은 결함으로 간주한다.

## 작업 규칙
- **프롬프트 기록**: 사용자의 모든 프롬프트와 Claude의 주요 응답(수행한 작업, 결과, 결정 사항)을 `prompt.md`에 날짜별·번호순으로 계속 추가한다. 프롬프트는 원문 그대로 인용하고, 응답은 핵심만 요약한다.
