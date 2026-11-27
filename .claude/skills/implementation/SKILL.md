---
name: implementation
description: A-SPICE SWE.3 소프트웨어 유닛 구현. 상세 설계(MOD/MIF)를 C/C++ 코드로 구현할 때 사용. 모든 함수가 상태값을 반환하고 return은 함수 끝에서 한 번만 하는 코딩 규칙, @trace 추적 태그, clang-format/clang-tidy 검사를 적용.
---

# 구현 (A-SPICE SWE.3 — Unit Construction)

## 입력
- `docs/design/`의 모듈(MOD)·인터페이스(MIF) 정의. **설계에 없는 모듈·공개 함수는 구현하지 않는다.** 필요하면 먼저 `detailed-design`으로 설계를 갱신한다.

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

### 예시
```c
/**
 * @brief  두 값의 합을 계산한다.
 * @trace  MOD-003, MIF-004, SWR-F-012
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

## 추가 규칙
- 모든 공개 함수에 doxygen 주석과 `@trace <MOD/MIF/SWR ID>` 태그를 단다.
- 파일 범위 헬퍼는 `static`으로 숨겨 캡슐화한다. 모듈 외부 공개는 헤더(MIF)에 선언된 것만.
- 전역 변수 금지 (모듈 내부 `static` 상태만 허용).
- 동적 메모리 할당은 제약 요구(SWR-C)가 허용할 때만 사용한다.
- 클린코드: 함수 40줄 이하, 순환 복잡도 10 이하, 파라미터 3개 이하, 매직 넘버 금지.

## 검사 (구현 후 반드시 수행)
```sh
clang-format --dry-run --Werror <변경 파일>
clang-tidy <변경 파일> -p build
cmake --build build      # 경고 0개 (-Wall -Wextra -Werror 권장)
```
도구가 설치되어 있지 않으면 사용자에게 알리고, 검사를 건너뛰었다고 명시한다.

## 완료 조건
- 설계의 모든 MOD/MIF가 구현되고 `@trace`로 연결됨
- `docs/traceability.md`의 코드 열 갱신
- 단일 return·상태값 반환 규칙 위반 0건
- `aspice-reviewer` 서브에이전트(`review` 스킬)의 코드 리뷰 `Pass` 후에만 `unit-test` 단계로 넘어감
