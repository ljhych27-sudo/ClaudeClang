# ClaudeClang

## 프로젝트 개요
Clang/LLVM 툴체인으로 C/C++ 코드를 A-SPICE 기준으로 개발하는 프로젝트.

## Claude Code 구성
- `.claude/settings.json` — 팀 공유 설정 (권한, 훅)
- `.claude/settings.local.json` — 개인 설정 (git 제외)
- `.claude/skills/<skill-name>/SKILL.md` — 프로젝트 스킬
- `.claude/agents/<agent-name>.md` — 프로젝트 서브에이전트 (`aspice-reviewer`)
- `.claude/hooks/lizard_check.sh` — Stop 훅: 작업 종료 시 변경된 소스에 Lizard 검사

## 1. 개발 절차

### 1.1 원칙
- 개발은 **A-SPICE** 기준으로 한다.
- 생명주기는 **애자일**이다. 아래 단계 전체(분석 → 시스템 테스트)를 **하나의 이터레이션**으로 하고, 이터레이션을 반복해 기능을 늘린다.
- 개발은 **메인 에이전트**가 수행하며, 각 단계에 맞는 스킬을 반드시 사용한다.
- 리뷰는 **`aspice-reviewer` 서브에이전트**만 수행한다.

### 1.2 이터레이션 단계
| # | 단계 | 스킬 | A-SPICE | 산출물 |
|---|---|---|---|---|
| 1 | 요구사항 분석 | `requirements-analysis` | SWE.1 | `docs/requirements/` |
| 2 | 아키텍처 설계 | `architecture-design` | SWE.2 | `docs/architecture/` |
| 3 | 상세 설계 | `detailed-design` | SWE.3 | `docs/design/` |
| 4 | 구현 (TDD) | `implementation` + `test-driven-development` | SWE.3 | `src/`, `include/`, `tests/tdd/` |
| 5 | 단위 테스트 | `unit-test` | SWE.4 | `tests/unit/`, `docs/test/` |
| 6 | 통합 테스트 | `integration-test` | SWE.5 | `tests/integration/`, `docs/test/` |
| 7 | 시스템 테스트 | `sw-system-test-case` | SWE.6 | `tests/system/`, `docs/test/` |
| - | 리뷰 (각 단계 종료 시) | `review` (`aspice-reviewer`) | SUP.4 | `docs/reviews/` |

### 1.3 단계 게이트 (필수)
1. 각 단계가 끝나면 **반드시 `aspice-reviewer`** 를 호출해 그 단계 산출물을 리뷰한다. 메인 에이전트가 스스로 판정하지 않는다.
2. `Fail`이면 **모든 부적합(NOK)을 조치하고 재리뷰**한다. `Pass`가 나올 때까지 반복한다.
3. **`Pass` 전에는 다음 단계를 시작하지 않는다.** 조건부 진행 없음. 리뷰 지적에 이견이 있으면 사용자에게 보고해 결정을 받는다.
4. 리뷰 결과(판정, NOK 건수, 기록 파일)를 사용자에게 그대로 보고한다.

### 1.4 이터레이션 종료와 PR
1. 7단계까지 모두 `Pass`이고 로컬 품질 게이트(`tools/quality_gate.sh`)가 PASS이면, **사용자에게 이터레이션 결과를 보고하고 확인을 받는다.**
2. 사용자 확인 후에만 PR 절차를 진행한다 (3장 Gitflow).

### 1.5 TDD
- 구현은 `test-driven-development` 스킬로 **TDD(Red → Green → Refactor)** 로 한다.
- TDD로 생성한 테스트는 **단위 테스트와 분리**한다: `tests/tdd/`, CTest 이름 접두사 `tdd.`
- TDD 테스트의 결과(JUnit)와 커버리지는 **별도 리포트**로 추출한다: `build/cov/coverage/tdd/`
- 단위 테스트(`tests/unit/`)는 5단계에서 설계 기법(동치·경계·PICT·MC/DC) 기반으로 새로 작성하며, TDD 테스트로 대체하지 않는다.

## 2. 소스코드 품질 기준
모든 기준은 `tools/quality_gate.sh`로 검사하며, CI에서 하나라도 FAIL이면 PR을 완료할 수 없다. 예외(suppression, 정당화로 면제)는 없다.

| 구분 | 기준 | 도구 | 게이트 스테이지 |
|---|---|---|---|
| 시스템 테스트 | 요구사항 커버리지 100% (모든 SWR/SSR이 통과한 시스템 테스트에 `@trace`됨) | `tools/check_requirements_coverage.py` | `system` |
| 통합 테스트 | 함수 커버리지 100%, 테스트 성공률 100% | LLVM, CTest | `integration` |
| 단위 테스트 | MC/DC 커버리지 100%, 테스트 성공률 100% | LLVM, CTest | `unit` |
| TDD 테스트 | 성공률 100%, 커버리지는 별도 리포트(강제 없음) | LLVM, CTest | `tdd` |
| 정적 분석 | Cppcheck 지적 0건 (`--enable=all --inconclusive`), 억제 없음 | Cppcheck | `static` |
| 순환 복잡도 | 함수당 10 이하 | Lizard | `metrics` + Stop 훅 |
| 함수 길이 | 함수당 80라인 이하 | Lizard | `metrics` + Stop 훅 |
| 주석률 | 주석 ÷ (주석 + 코드) ≥ 20%, **전체 및 파일별** | CLOC | `comments` |
| 주석 형식 | doxygen, HITL 태그 필수 (아래) | `tools/check_hitl_comments.py` | `hitl` |
| 빌드 | Clang 경고 0 (`-Wall -Wextra -Wpedantic -Werror`) | Clang, CMake | `build` |

### 2.1 주석 (doxygen + Human in the Loop)
`src/`, `include/`의 모든 파일(`@file` 블록)과 모든 함수의 doxygen 블록에 아래 태그를 넣는다. 테스트 파일은 `@file` 블록에 넣는다.

```c
/**
 * @brief         <설명>
 * @ai_model      claude-opus-5-5          (작성한 AI 모델 ID)
 * @ai_date       2026-11-27               (작성/수정 일자, YYYY-MM-DD)
 * @requested_by  ljhych27-sudo            (작성을 요청한 사람 = git user.name)
 * @human_review  Pending                  (Pending | Done)
 * @reviewed_by   <사람>                   (Done일 때 필수)
 * @reviewed_date <YYYY-MM-DD>             (Done일 때 필수)
 */
```
- AI가 코드를 새로 쓰거나 수정하면 `@ai_model`, `@ai_date`를 갱신하고 `@human_review`를 **`Pending`으로 되돌린다.**
- **`@human_review Done`은 AI가 임의로 쓰지 않는다.** 사용자가 리뷰 완료를 명시적으로 알려준 코드에만, 사용자가 알려준 리뷰어·일자로 기록한다.
- `main`으로 가는 코드(`release/*`, `hotfix/*`, `main` 대상 PR)는 CI가 모든 블록의 `Done`을 강제한다.
- 커스텀 태그는 `Doxyfile`의 `ALIASES`에 정의되어 문서에 표시된다.

## 3. Git 브랜치 및 PR 전략 (Gitflow)
| 브랜치 | 분기 원천 | 병합 대상 | 용도 |
|---|---|---|---|
| `main` | - | - | 릴리스된 코드만. 직접 커밋 금지 |
| `develop` | `main` | - | 통합 브랜치. 직접 커밋 금지 |
| `feature/<이름>` | `develop` | `develop` (PR) | 이터레이션·기능 개발 |
| `release/<버전>` | `develop` | `main` + `develop` (PR) | 릴리스 준비 |
| `hotfix/<버전>` | `main` | `main` + `develop` (PR) | 긴급 수정 |

- 모든 병합은 **PR**로 하고, **Jenkins CI가 통과해야만** 병합한다. Jenkinsfile이 Gitflow에 맞지 않는 PR(예: `feature/* → main`)을 실패 처리한다.
- CI 통과 조건 = 빌드 성공 + 2장 품질 기준 전부.
- PR 병합은 사용자가 한다. Claude는 PR을 만들고 CI 결과를 보고한다.

## 4. 개발 환경
개발 빌드와 CI 빌드는 **같은 Docker 이미지 `claudeclangbuild`** 를 쓴다 (`docker/Dockerfile`).
요청된 이름은 `ClaudeCLangBuild`이나 Docker 이미지 이름은 소문자만 허용되어 `claudeclangbuild`로 한다.

| 항목 | 도구 (이미지에 포함) |
|---|---|
| 컴파일러 | Clang/LLVM 21 (18 이상 최신 안정판, `LLVM_VERSION` 빌드 인자) |
| 빌드 | CMake + Ninja, CTest |
| 정적 분석 | Cppcheck |
| 테스트 프레임워크 | GoogleTest, GMock |
| 커버리지 | LLVM source-based coverage (`llvm-profdata`, `llvm-cov`, MC/DC 포함) — `tools/llvm_coverage.sh` |
| 복잡도·함수 길이 | Lizard |
| 주석률 | CLOC |
| 추가 (추천) | clang-format(코드 스타일), Doxygen + Graphviz(문서), PICT(조합 테스트), Python 3(게이트 스크립트) |

```sh
docker build -t claudeclangbuild docker                       # 이미지 빌드
docker run --rm -v "<repo>:/workspace" claudeclangbuild \
    bash tools/quality_gate.sh                                 # 전체 품질 게이트
docker run --rm -v "<repo>:/workspace" claudeclangbuild \
    bash tools/quality_gate.sh unit                            # 특정 스테이지만
```
Windows Git Bash에서는 `MSYS_NO_PATHCONV=1`과 `$(cygpath -w "$PWD")`를 쓴다.

### 테스트 구성 규칙
- `tests/<suite>/CMakeLists.txt`에서 `gtest_discover_tests(<target> TEST_PREFIX "<suite>.")` — suite = `unit`, `tdd`, `integration`, `system`
- 리포트: `build/reports/`(cppcheck, lizard, cloc), `build/cov/coverage/<suite>/`(summary, html, junit)

## 5. CI 환경 (Jenkins)
- Jenkins LTS를 이 PC의 Docker에서 실행, 포트 **8080**: `docker compose -f ci/jenkins/docker-compose.yml --env-file ci/jenkins/.env up -d --build`
- 관리자: `admin` / 비밀번호는 `ci/jenkins/.env` (git 제외)
- 설정은 코드로 관리: `ci/jenkins/plugins.txt`(플러그인), `ci/jenkins/casc.yaml`(JCasC: 보안, 멀티브랜치 잡)
- 잡 `ClaudeClang`: GitHub 저장소의 Gitflow 브랜치와 PR을 15분마다 스캔해 `Jenkinsfile` 실행

## 6. ID 체계 (추적성)
| 대상 | ID 형식 | 예 |
|---|---|---|
| 기능 요구사항 | `SWR-F-NNN` | SWR-F-001 |
| 품질 요구사항 (ISO 25010) | `SWR-Q-NNN` | SWR-Q-003 |
| 제한 요구사항 | `SWR-L-NNN` | SWR-L-002 |
| 제약 요구사항 | `SWR-C-NNN` | SWR-C-001 |
| 기능안전 요구사항 (별도 문서) | `SSR-NNN` | SSR-004 |
| 컴포넌트 / 컴포넌트 인터페이스 | `CMP-NNN` / `CIF-NNN` | CMP-002 / CIF-005 |
| 모듈 / 모듈 인터페이스 | `MOD-NNN` / `MIF-NNN` | MOD-010 / MIF-012 |
| TDD / 단위 / 통합 / 시스템 테스트 | `TDD-NNN` / `UT-NNN` / `IT-NNN` / `STC-NNN` | UT-031 |
| 리뷰 기록 | `RV-YYYYMMDD-NN` | RV-20261127-01 |

- 추적성 매트릭스는 `docs/traceability.md` 한 곳에서 관리하며, 산출물을 추가·변경할 때마다 함께 갱신한다.
- 추적은 **양방향**이다: 요구사항 → 설계 → 코드 → 테스트로 내려가고, 각 하위 항목은 상위 ID를 `Traces:` 필드(문서) 또는 `@trace` 태그(코드·테스트 주석)로 거슬러 올라간다.
- 상위에 연결되지 않은 하위 항목, 하위로 구현·검증되지 않은 상위 항목은 결함으로 간주한다.

## 작업 규칙
- **프롬프트 기록**: 사용자의 모든 프롬프트와 Claude의 주요 응답(수행한 작업, 결과, 결정 사항)을 `prompt.md`에 날짜별·번호순으로 계속 추가한다. 프롬프트는 원문 그대로 인용하고, 응답은 핵심만 요약한다.
