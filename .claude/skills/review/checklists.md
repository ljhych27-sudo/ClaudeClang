# 산출물별 리뷰 체크리스트 (A-SPICE 기반)

각 항목은 `OK / NOK / N/A`로 판정한다. 괄호는 관련 A-SPICE 프로세스와 프로젝트 스킬이다.

## CMN — 공통 (모든 산출물)
| ID | 확인 항목 |
|---|---|
| CMN-01 | 산출물이 정해진 위치·파일명·템플릿을 따른다 |
| CMN-02 | 모든 항목에 `CLAUDE.md` ID 체계에 맞는 고유 ID가 있고 중복이 없다 |
| CMN-03 | 상위 산출물로의 추적(`Traces:` / `@trace`)이 모든 항목에 있다 |
| CMN-04 | `docs/traceability.md`가 이번 변경을 반영해 갱신되었다 |
| CMN-05 | 상위 산출물과 내용이 일관된다 (모순·누락 없음) |
| CMN-06 | 변경 이력·상태(Draft/Reviewed/Approved)가 최신이다 |

## REQ — 요구사항 (SWE.1, `requirements-analysis`)
| ID | 확인 항목 |
|---|---|
| REQ-01 | 모든 요구가 기능(F) / 품질(Q) / 제한(L) / 제약(C) 중 하나로 분류되었다 |
| REQ-02 | 기능안전 요구사항이 `safety_requirements.md`(SSR)에 별도로 관리되고, SWR에는 참조만 있다 |
| REQ-03 | 모든 품질 요구(SWR-Q)가 ISO 25010 특성/하위 특성에 매핑되었다 |
| REQ-04 | 각 요구가 하나의 요구만 담는다 (atomic) |
| REQ-05 | 모호어 없이 측정 가능한 합격 기준(Acceptance)이 있다 |
| REQ-06 | 검증 방법(Test/Analysis/Inspection/Demonstration)이 지정되었다 |
| REQ-07 | 출처(Source)가 명시되고 상위 요구와 양방향 추적된다 |
| REQ-08 | 요구 간 충돌·중복이 없다 |
| REQ-09 | 설계 해법을 요구로 기술하지 않았다 (SWR-C 제외) |
| REQ-10 | 운영 환경·인터페이스·자원 제한이 요구로 식별되었다 |

## ARC — 아키텍처 (SWE.2, `architecture-design`)
| ID | 확인 항목 |
|---|---|
| ARC-01 | 모든 SWR/SSR이 하나 이상의 컴포넌트에 할당되었다 |
| ARC-02 | 모든 컴포넌트에 단일 책임(Responsibility)이 기술되었다 |
| ARC-03 | **모든 컴포넌트가 인터페이스(CIF)를 하나 이상 정의**한다 |
| ARC-04 | 컴포넌트 간 연결이 **오직 CIF를 통해서만** 이루어진다 (전역 공유·내부 헤더 접근 없음) |
| ARC-05 | CIF에 타입·범위·단위·반환 상태·사전/사후 조건·타이밍이 정의되었다 |
| ARC-06 | 순환 의존이 없고 의존 방향이 단방향이다 |
| ARC-07 | 고응집·저결합: 책임 불명확 컴포넌트(Utils/Common/Manager)가 없다 |
| ARC-08 | SOLID(SRP·OCP·LSP·ISP·DIP) 위반이 없다 |
| ARC-09 | 정적 뷰(컴포넌트 다이어그램)와 동적 뷰(시퀀스/상태)가 있다 |
| ARC-10 | 제한 요구가 컴포넌트별 자원 예산으로 배분되었다 |
| ARC-11 | 주요 설계 결정의 대안과 선택 근거가 기록되었다 |

## DD — 상세 설계 (SWE.3, `detailed-design`)
| ID | 확인 항목 |
|---|---|
| DD-01 | 모든 컴포넌트가 모듈(MOD)로 분해되고 각 모듈이 상위 CMP/SWR로 추적된다 |
| DD-02 | 인터페이스 정의 의무 기준에 해당하는 **모든 모듈에 MIF가 정의**되었다 |
| DD-03 | MIF를 생략한 모듈에 생략 사유가 있다 |
| DD-04 | 인터페이스가 정의된 모듈 간 통신이 **오직 MIF를 통해서만** 이루어진다 |
| DD-05 | 각 모듈이 단일 책임 원칙(SRP)을 만족한다 |
| DD-06 | 동적 동작(흐름·상태 머신·에러 경로)이 기술되었다 |
| DD-07 | 데이터의 타입·범위·단위·초기값·소유 모듈이 정의되었다 |
| DD-08 | 설계가 클린코드 기준(함수 크기·복잡도·파라미터 수·명명)을 지키도록 계획되었다 |
| DD-09 | 모든 함수가 상태값 반환 규칙을 만족하도록 설계되었다 |

## CODE — 구현 (SWE.3, `implementation`)
| ID | 확인 항목 |
|---|---|
| CODE-01 | 설계에 없는 모듈·공개 함수가 없고, 설계의 모든 MOD/MIF가 구현되었다 |
| CODE-02 | **모든 함수가 반환값을 가지며 `void` 함수 대신 상태값을 반환**한다 |
| CODE-03 | **return이 함수 마지막에 한 번만** 존재한다 |
| CODE-04 | 호출한 함수의 상태값을 모두 확인한다 |
| CODE-05 | 공개 함수가 입력(NULL·범위)을 검증한다 |
| CODE-06 | 모든 공개 함수에 doxygen 주석과 `@trace` 태그가 있다 |
| CODE-07 | 전역 변수가 없고 내부 헬퍼는 `static`으로 캡슐화되었다 |
| CODE-08 | 다른 모듈과 인터페이스(헤더의 MIF)로만 통신한다 |
| CODE-09 | 순환 복잡도 10 이하·함수 길이 80라인 이하(Lizard), 파라미터 3개 이하, 매직 넘버 없음 |
| CODE-10 | Clang 경고 0개, clang-format 통과 |
| CODE-11 | Cppcheck 지적 0건 (억제·예외 없음, `build/reports/cppcheck.xml`로 확인) |
| CODE-12 | 주석률 20% 이상 — 전체 및 **파일별** (CLOC, `build/reports/cloc.json`으로 확인) |
| CODE-13 | 모든 `@file` 블록과 함수 doxygen 블록에 HITL 태그(`@ai_model`, `@ai_date`, `@requested_by`, `@human_review`)가 있고, `Done`은 사용자 리뷰 근거가 있을 때만 쓰였다 |
| CODE-14 | `tools/quality_gate.sh build static metrics comments hitl` 전부 PASS (실행 로그로 확인) |

## TDD — TDD 테스트 (SWE.3, `implementation` + `test-driven-development`)
| ID | 확인 항목 |
|---|---|
| TDD-01 | TDD 테스트가 `tests/tdd/`에 있고 CTest 접두사 `tdd.`를 쓰며 단위 테스트와 섞이지 않았다 |
| TDD-02 | TDD 결과(JUnit)와 커버리지가 `build/cov/coverage/tdd/`에 별도로 추출되었다 |
| TDD-03 | TDD 테스트 성공률 100% |
| TDD-04 | 모든 MIF 동작에 대응하는 TDD 테스트가 있고 `@test`/`@trace`가 달려 있다 |

## UT — 단위 테스트 (SWE.4, `unit-test`)
| ID | 확인 항목 |
|---|---|
| UT-01 | 모든 모듈·MIF가 하나 이상의 UT로 검증되고 UT가 MOD/SWR로 추적된다 |
| UT-02 | 동치 클래스·경계값 분석이 적용되었다 |
| UT-03 | 입력 3개 이상인 함수에 PICT(또는 pairwise 표) 조합이 적용되었다 |
| UT-04 | **MC/DC 커버리지 100%** (LLVM 리포트 `build/cov/coverage/unit/`로 직접 확인, 정당화로 면제 불가) |
| UT-05 | **테스트 성공률 100%** (`junit.xml`로 확인) |
| UT-06 | 모든 테스트 함수에 doxygen 형식의 목적·입력·절차·예상 출력이 있다 |
| UT-07 | 모든 테스트가 의미 있는 검증(assert)을 하며 커버리지용 무의미 케이스가 없다 |
| UT-08 | Stub/Mock이 격리가 꼭 필요한 곳에만 쓰였고 대상 로직을 대체하지 않는다 |
| UT-09 | 테스트 결과·커버리지가 `unit_test_report.md`에 기록되었다 |
| UT-10 | 단위 테스트가 TDD 테스트의 복사본이 아니며, TDD 테스트 없이 단독으로 MC/DC 100%를 달성한다 |

## IT — 통합 테스트 (SWE.5, `integration-test`)
| ID | 확인 항목 |
|---|---|
| IT-01 | 통합 전략(순서·단계)이 아키텍처 의존 관계에 맞게 정의되었다 |
| IT-02 | **모든 CIF가 하나 이상의 IT로 검증**된다 (인터페이스 커버리지 100%) |
| IT-03 | 각 CIF의 정상 흐름·오류 전파·순서/타이밍·경계 조건이 검증되었다 |
| IT-04 | 동적 뷰의 각 시나리오에 대응하는 IT가 있다 |
| IT-05 | 동치 클래스·경계값·PICT 조합이 적용되었다 |
| IT-06 | **함수 커버리지 100%**, **테스트 성공률 100%** (`build/cov/coverage/integration/`로 확인, 면제 불가) |
| IT-07 | 모든 테스트 함수에 doxygen 형식의 목적·입력·절차·예상 출력이 있다 |
| IT-08 | 통합 대상 컴포넌트를 Stub으로 대체하지 않았고, 단위 테스트와 중복되지 않는다 |
| IT-09 | 테스트 결과가 `integration_test_report.md`에 기록되었다 |

## ST — 시스템 테스트 (SWE.6, `sw-system-test-case`)
| ID | 확인 항목 |
|---|---|
| ST-01 | `sw-system-test-case` 스킬의 생성 조건 1~10을 모두 만족한다 (명세서의 점검 결과표를 재확인) |
| ST-02 | **요구사항 커버리지 100%** — 모든 SWR/SSR이 통과한 시스템 테스트에 `@trace`된다 (`tools/check_requirements_coverage.py` 결과로 확인) |
| ST-03 | 시스템 테스트가 외부 인터페이스만 사용하는 블랙박스 테스트다 (내부 함수·구조 의존 없음) |
| ST-04 | 명세서의 모든 STC가 `tests/system/`에 `@test STC-NNN`으로 구현되었다 |
| ST-05 | 테스트 성공률 100% (`build/cov/coverage/system/junit.xml`) |
| ST-06 | 모든 테스트 함수에 doxygen 형식의 목적·입력·절차·예상 출력이 있다 |

## CI — 이터레이션 종료 / PR
| ID | 확인 항목 |
|---|---|
| CI-01 | 전체 품질 게이트 `tools/quality_gate.sh`가 이미지 `claudeclangbuild`에서 PASS |
| CI-02 | PR이 Gitflow 규칙(feature/* → develop, release/*·hotfix/* → main·develop)을 따른다 |
| CI-03 | Jenkins 빌드가 SUCCESS다 |
