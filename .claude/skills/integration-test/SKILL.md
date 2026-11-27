---
name: integration-test
description: A-SPICE SWE.5 소프트웨어 통합 및 통합 테스트. 아키텍처의 컴포넌트 인터페이스(CIF)를 중심으로 컴포넌트 간 연동을 검증하는 통합 테스트를 작성하고, LLVM 커버리지 목표 100% 달성까지 경계값·동치 클래스·PICT 기반 케이스를 반복 추가할 때 사용.
---

# 통합 테스트 (A-SPICE SWE.5)

## 산출물
| 파일 | 내용 |
|---|---|
| `tests/integration/<scenario>_test.c(pp)` | 통합 테스트 |
| `docs/test/integration_strategy.md` | 통합 순서(빌드 단계), 대상 컴포넌트 조합 |
| `docs/test/integration_test_spec.md` | 테스트 케이스 목록 (IT-ID ↔ CIF/CMP/SWR) |
| `docs/test/integration_test_report.md` | 실행·커버리지 결과 |
| `docs/traceability.md` | 아키텍처(CMP/CIF) ↔ IT 열 갱신 |

## 핵심 원칙: 인터페이스 중심
- 통합 테스트의 대상은 **컴포넌트 내부 로직이 아니라 컴포넌트 간 연동**이다. 내부 로직은 `unit-test`에서 검증한다.
- **모든 CIF는 최소 하나의 IT로 검증**한다. 각 CIF에 대해 다음을 확인한다.
  - 정상 데이터 흐름: 제공자 → 소비자로 값·단위·범위가 올바르게 전달되는가
  - 오류 전파: 제공자의 오류 상태가 소비자에서 올바르게 처리되는가
  - 호출 순서·타이밍: 시퀀스 다이어그램(동적 뷰)의 순서대로 동작하는가
  - 경계 조건: 인터페이스 파라미터의 경계값에서 연동이 유지되는가
- 아키텍처의 동적 뷰(시퀀스 다이어그램) 시나리오마다 IT를 하나 이상 둔다.

## 통합 전략
1. `docs/architecture/`의 의존 관계로 통합 순서를 정한다 (하위 → 상위 bottom-up 권장).
2. 단계마다 실제 컴포넌트를 하나씩 추가하고, 아직 통합되지 않은 컴포넌트만 Stub으로 대체한다.
3. 최종 단계에서는 Stub 없이 전체 소프트웨어를 통합한다 (하드웨어 추상화 계층 아래만 예외).

## 커버리지 목표
- `docs/test/coverage_targets.md`의 통합 테스트 목표를 따르며, 없으면 사용자에게 묻는다.
- **정해진 커버리지를 100% 달성할 때까지** 케이스를 추가·재측정한다. 통합 커버리지의 기본 지표는 **인터페이스 커버리지(CIF 검증 비율)** 와 **함수 호출 커버리지**이며, 라인·브랜치는 보조 지표로 측정한다.
  ```sh
  bash .claude/skills/unit-test/scripts/llvm_coverage.sh \
      --build-dir build-cov --label integration --ctest-regex integration \
      --line 0 --branch 0
  ```
  인터페이스 커버리지는 `integration_test_spec.md`의 CIF ↔ IT 표에서 계산해 보고서에 기록한다.

## 테스트 설계 기법 (반드시 활용)
- **동치 클래스 / 경계값 분석**: CIF 파라미터의 범위·단위 정의를 기준으로 적용
- **PICT 조합**: 여러 인터페이스 입력·컴포넌트 상태가 결합될 때 `tests/integration/pict/<scenario>.txt`로 pairwise 조합 생성

## 테스트 함수 주석 (필수, doxygen)
```c
/**
 * @test     IT-004 센서 오류 상태가 제어 컴포넌트로 전파됨
 * @trace    CIF-002, CMP-001, CMP-003, SWR-F-020
 * @purpose  CMP-001이 STATUS_ERR_TIMEOUT을 반환하면 CMP-003이 안전 상태로 전환하는지 확인
 * @input    CMP-001 입력 소스: 응답 없음 (타임아웃 유도)
 * @procedure
 *   1. CMP-001, CMP-003을 초기화한다.
 *   2. 센서 응답을 차단한 상태로 Ctrl_Cycle()을 1회 실행한다.
 *   3. CMP-003의 상태를 조회한다.
 * @expected Ctrl_GetState() == CTRL_STATE_SAFE, 반환값 STATUS_OK
 */
```

## Stub / Mock 원칙
- 통합 대상 컴포넌트는 Stub으로 대체하지 않는다. 대체하면 통합 테스트가 아니다.
- 외부 경계(하드웨어, OS, 미통합 컴포넌트)에만 최소한으로 사용한다.

## 금지
- 커버리지 수치만 올리는 의미 없는 케이스
- 단위 테스트와 동일한 내부 로직 검증의 중복
- 인터페이스를 우회해 내부 상태를 직접 조작·검사하는 테스트

## 완료 후
결과를 보고서에 기록하고, 추적성 매트릭스를 갱신하고, `review` 스킬로 리뷰한다.
