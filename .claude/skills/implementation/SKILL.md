---
name: implementation
description: A-SPICE SWE.3 소프트웨어 유닛 구현. 상세 설계(MOD/MIF)를 C/C++ 코드로 TDD(test-driven-development 스킬)로 구현할 때 사용. TDD 테스트는 tests/tdd/에 단위 테스트와 분리하고, 상태값 반환·단일 return 코딩 규칙, doxygen HITL 주석, 주석률 20%, Cppcheck·Lizard 기준을 적용.
---

# 구현 (A-SPICE SWE.3 — Unit Construction, TDD)

## 입력
- `docs/design/`의 모듈(MOD)·인터페이스(MIF) 정의. **설계에 없는 모듈·공개 함수는 구현하지 않는다.** 필요하면 먼저 `detailed-design`으로 설계를 갱신하고 리뷰를 받는다.

## TDD 절차 (필수)
`test-driven-development` 스킬을 로드해 그 규칙(실패하는 테스트 없이 프로덕션 코드 금지)을 따른다. 이 프로젝트에서의 적용:
1. **Red**: `tests/tdd/<module>_tdd_test.cpp`에 GoogleTest로 실패하는 테스트를 하나 쓰고, 실행해 **실패를 확인**한다.
2. **Green**: 테스트를 통과시키는 최소 코드를 `src/`, `include/`에 쓴다.
3. **Refactor**: 코딩 규칙·품질 기준에 맞게 정리하고 모든 TDD 테스트가 통과하는지 확인한다.
4. MIF의 모든 동작이 구현될 때까지 반복한다.

TDD 테스트 규칙:
- 위치 `tests/tdd/`, CTest 접두사 `tdd.` (`gtest_discover_tests(<target> TEST_PREFIX "tdd.")`), ID `TDD-NNN`
- **단위 테스트(`tests/unit/`)와 섞지 않는다.** 결과·커버리지는 별도 리포트로 뽑는다:
  ```sh
  bash tools/quality_gate.sh build tdd     # -> build/cov/coverage/tdd/ (junit.xml, summary, html)
  ```
- TDD 테스트 함수에도 doxygen `@test`, `@trace`를 단다.

## 필수 코딩 규칙
1. **모든 함수는 반환값을 갖는다.** 의미 있는 반환값이 없는 함수도 `void` 대신 **정상 실행 여부를 판단할 수 있는 상태값**을 반환한다.
2. **return은 함수 마지막에 한 번만** 둔다. 조기 return, 루프·분기 중간 return을 금지한다.
3. 결과 값이 필요한 함수는 결과를 출력 파라미터로 내보내고, 반환값은 상태값으로 쓴다.
4. 호출한 함수의 상태값은 반드시 확인한다 (무시 금지).
5. 공개 함수의 입력 파라미터(NULL 포인터, 범위)를 검증하고 위반 시 오류 상태를 반환한다.

### 상태 타입 (프로젝트 공통)
`include/common/std_status.h`에 한 번만 정의하고 모든 모듈이 재사용한다.
```c
typedef enum
{
    STATUS_OK = 0,
    STATUS_ERR_NULL_PTR,
    STATUS_ERR_OUT_OF_RANGE,
    STATUS_ERR_INVALID_STATE,
    STATUS_ERR_TIMEOUT,
    STATUS_ERR_UNKNOWN
} Std_Status_t;
```

### 예시 (doxygen HITL 주석 포함)
```c
/**
 * @brief         두 값의 합을 계산한다.
 * @trace         MOD-003, MIF-004, SWR-F-012
 * @ai_model      claude-opus-5-5
 * @ai_date       2026-11-27
 * @requested_by  ljhych27-sudo
 * @human_review  Pending
 * @param[in]  a, b    입력 값 (0..1000)
 * @param[out] result  합 결과
 * @return STATUS_OK, STATUS_ERR_NULL_PTR, STATUS_ERR_OUT_OF_RANGE
 */
Std_Status_t Calc_Add(uint16_t a, uint16_t b, uint16_t *result)
{
    Std_Status_t status = STATUS_OK;

    if (result == NULL)
    {
        status = STATUS_ERR_NULL_PTR;
    }
    else if ((a > CALC_MAX_INPUT) || (b > CALC_MAX_INPUT))
    {
        status = STATUS_ERR_OUT_OF_RANGE;
    }
    else
    {
        *result = (uint16_t)(a + b);
    }

    return status;   /* 유일한 return */
}
```

## 주석 규칙 (HITL)
- 모든 파일의 `@file` 블록과 모든 함수의 doxygen 블록에 `@brief`, `@ai_model`, `@ai_date`, `@requested_by`, `@human_review`를 넣는다 (`CLAUDE.md` 2.1).
  - `@ai_model`: 지금 작성하는 AI의 모델 ID, `@ai_date`: 오늘 날짜, `@requested_by`: `git config user.name`
- 코드를 수정하면 `@ai_date`를 갱신하고 `@human_review Pending`으로 되돌린다.
- **`@human_review Done`은 사용자가 리뷰 완료를 명시적으로 알려준 경우에만** 그 리뷰어·일자로 기록한다.
- **주석률 20% 이상**을 파일마다 지킨다 (주석 ÷ (주석 + 코드), CLOC 기준). 의미 없는 주석으로 채우지 말고 의도·계약·제약을 설명한다.

## 품질 기준 (CLAUDE.md 2장)
- 순환 복잡도 ≤ 10, 함수 길이 ≤ 80라인 (Lizard). 작업 종료 시 Stop 훅이 변경 파일을 검사해 위반하면 종료를 막는다.
- Cppcheck 지적 0건 (억제 금지), Clang 경고 0건.
- 그 밖에: 파라미터 3개 이하, 매직 넘버 금지, 전역 변수 금지(모듈 내부 `static` 상태만), 내부 헬퍼는 `static`, 모듈 외부 공개는 헤더(MIF)에 선언된 것만, 동적 메모리는 제약 요구(SWR-C)가 허용할 때만.

## 검사 (구현 후 반드시, 이미지 안에서)
```sh
bash tools/quality_gate.sh build static metrics comments hitl tdd
clang-format --dry-run --Werror <변경 파일>
```
하나라도 FAIL이면 구현 완료가 아니다.

## 완료 조건
- 설계의 모든 MOD/MIF가 구현되고 `@trace`로 연결됨, `docs/traceability.md`의 코드·TDD 열 갱신
- 위 검사 전부 PASS, TDD 테스트 성공률 100%
- `aspice-reviewer` 서브에이전트(`review` 스킬)의 코드 리뷰 `Pass` 후에만 `unit-test` 단계로 넘어감
