---
name: unit-test
description: A-SPICE SWE.4 소프트웨어 유닛 검증. 모듈(MOD) 단위 테스트를 작성하고, LLVM 소스 기반 커버리지(라인·브랜치·MC/DC)를 측정해 목표 커버리지 100% 달성까지 경계값·동치 클래스·PICT 기반 테스트 케이스를 반복 추가할 때 사용.
---

# 단위 테스트 (A-SPICE SWE.4)

## 산출물
| 파일 | 내용 |
|---|---|
| `tests/unit/<module>_test.c(pp)` | 모듈별 단위 테스트 |
| `tests/unit/stubs/`, `tests/unit/mocks/` | 필요한 최소한의 Stub/Mock |
| `docs/test/unit_test_spec.md` | 테스트 케이스 목록 (UT-ID ↔ MOD/SWR) |
| `docs/test/unit_test_report.md` | 실행 결과·커버리지 결과 |
| `docs/traceability.md` | 모듈/요구사항 ↔ UT 열 갱신 |

## 커버리지 목표
- 목표는 `docs/test/coverage_targets.md`에 정한 값을 따른다. 없으면 사용자에게 묻고 그 파일에 기록한다.
  ```markdown
  | 대상 | Line | Branch | MC/DC |
  |---|---|---|---|
  | 전체 | 100 | 100 | 100 |   ← 예: ASIL-D 모듈
  ```
- **정해진 커버리지 목표를 100% 달성할 때까지** 테스트 케이스를 추가하고 재측정한다.
- 도달 불가능한 코드(방어 코드 등)가 있으면 테스트를 억지로 만들지 말고, 사유와 함께 보고서에 "정당화(justification)" 항목으로 기록한 뒤 사용자 확인을 받는다.

## 테스트 설계 기법 (반드시 활용)
1. **동치 클래스 분할**: 각 입력을 유효/무효 클래스로 나누고 클래스당 대표값을 고른다.
2. **경계값 분석**: 각 범위의 min-1, min, min+1, max-1, max, max+1.
3. **PICT 조합**: 입력 파라미터가 3개 이상이면 PICT 모델 파일(`tests/unit/pict/<module>.txt`)을 작성해 pairwise 조합을 생성한다. PICT가 없으면 수동으로 pairwise 표를 만들고 그 사실을 명시한다.
   ```
   # tests/unit/pict/calc.txt
   a: 0, 1, 500, 999, 1000, 1001
   b: 0, 1000, 1001
   ptr: VALID, NULL
   ```
4. **MC/DC**: 목표가 수립된 경우, 각 조건이 결정 결과에 독립적으로 영향을 주는 케이스 쌍을 만든다. LLVM 리포트(`--show-mcdc`)에서 미충족 조건을 확인해 케이스를 추가한다.

## 테스트 함수 주석 (필수, doxygen)
```c
/**
 * @test     UT-012 Calc_Add 상한 경계 초과 입력 거부
 * @trace    MOD-003, MIF-004, SWR-F-012
 * @purpose  입력이 최대값(1000)을 1 초과하면 범위 오류를 반환하는지 확인
 * @input    a = 1001, b = 0, result = 유효 포인터
 * @procedure
 *   1. 결과 변수를 0으로 초기화한다.
 *   2. Calc_Add(1001, 0, &result)를 호출한다.
 *   3. 반환값과 결과 변수를 확인한다.
 * @expected 반환값 STATUS_ERR_OUT_OF_RANGE, result는 0으로 변경되지 않음
 */
```

## 절차
1. 대상 모듈의 MIF와 요구사항에서 테스트 케이스를 설계하고 `unit_test_spec.md`에 기록한다.
2. 테스트 코드를 작성한다. 프레임워크는 프로젝트에 정해진 것을 쓰고, 없으면 C는 Unity, C++는 GoogleTest를 제안해 사용자 확인 후 도입한다.
3. 커버리지를 측정한다:
   ```sh
   bash .claude/skills/unit-test/scripts/llvm_coverage.sh \
       --build-dir build-cov --label unit --ctest-regex unit \
       --line 100 --branch 100 --mcdc 100
   ```
4. 목표 미달이면 리포트(`build-cov/coverage/unit/html/index.html`, 콘솔 요약)에서 미커버 라인·브랜치·MC/DC 조건을 찾아 **의미 있는** 케이스를 추가하고 3번을 반복한다.
5. 결과를 `unit_test_report.md`에 기록하고, 추적성 매트릭스를 갱신하고, `aspice-reviewer` 서브에이전트(`review` 스킬)로 테스트 리뷰를 수행한다.

## Stub / Mock 원칙
- 하드웨어 접근, 다른 컴포넌트 의존, 비결정적 요소(시간·난수)처럼 **격리가 꼭 필요한 경우에만** 사용한다.
- 테스트 대상 모듈 자신의 로직을 Mock으로 대체하지 않는다.
- Mock의 기대 호출 검증보다 대상 모듈의 출력·상태 검증을 우선한다.

## 금지
- 커버리지 수치만 올리고 아무것도 검증하지 않는 테스트 (assert 없음, 결과 무시)
- 같은 동치 클래스를 반복하는 중복 케이스
- 구현 내부 세부사항에 결합된 테스트 (리팩터링하면 깨지는 테스트)

## LLVM 커버리지 도구
`scripts/llvm_coverage.sh`가 Clang 소스 기반 커버리지(`-fprofile-instr-generate -fcoverage-mapping -fcoverage-mcdc`)로 빌드하고, ctest 실행 → `llvm-profdata merge` → `llvm-cov report/show/export` → 목표 대비 합격 여부를 판정한다. MC/DC는 Clang 18 이상이 필요하다. `--help`로 옵션을 확인한다.
