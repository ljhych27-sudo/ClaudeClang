#!/usr/bin/env bash
# ClaudeClang source code quality gate. Runs inside the claudeclangbuild image
# (same for local development and Jenkins CI).
#
#   bash tools/quality_gate.sh [stage ...]
#   stages: build static metrics comments hitl unit tdd integration system  (default: all)
#
# Env: REQUIRE_HUMAN_REVIEW=1  -> every HITL block must be `@human_review Done`
#
# Reports: build/reports/  (cppcheck.xml, lizard.txt, cloc.json, coverage/<suite>/...)
# Exit code: 0 = all selected stages PASS, 1 = at least one FAIL.
set -uo pipefail
cd "$(dirname "$0")/.."

STAGES=("$@")
[[ ${#STAGES[@]} -eq 0 ]] && STAGES=(build static metrics comments hitl unit tdd integration system)

REPORTS=build/reports
mkdir -p "$REPORTS"
SRC_DIRS=()
for d in src include; do [[ -d $d ]] && SRC_DIRS+=("$d"); done
has_sources() {
    [[ ${#SRC_DIRS[@]} -gt 0 ]] && find "${SRC_DIRS[@]}" -type f \( -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name '*.hpp' \) | grep -q .
}

declare -A RESULT
FAILED=0
pass() { RESULT[$1]="PASS${2:+ ($2)}"; }
fail() { RESULT[$1]="FAIL${2:+ ($2)}"; FAILED=1; }
skip() { RESULT[$1]="SKIP ($2)"; }
banner() { echo; echo "==================== $1 ===================="; }

stage_build() {
    banner build
    if cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug \
         -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ && cmake --build build; then
        pass build
    else
        fail build
    fi
}

# Cppcheck: 100% clean, no code-level suppressions. Only tool notices that are
# not findings are turned off: missingIncludeSystem (system headers are not
# analysed) and checkersReport. Tests are analysed together with production
# code so that public APIs used only by tests are not "unusedFunction".
stage_static() {
    banner "static (cppcheck)"
    if ! has_sources; then skip static "no sources"; return; fi
    local inc=() dirs=("${SRC_DIRS[@]}")
    [[ -d include ]] && inc=(-I include)
    [[ -d tests ]] && dirs+=(tests)
    local opts=(--enable=all --inconclusive --error-exitcode=1
                --suppress=missingIncludeSystem --suppress=checkersReport "${inc[@]}")
    if cppcheck "${opts[@]}" --xml --output-file="$REPORTS/cppcheck.xml" "${dirs[@]}"        && cppcheck "${opts[@]}" -q "${dirs[@]}"; then
        pass static "0 findings"
    else
        fail static "see $REPORTS/cppcheck.xml"
    fi
}

# Lizard: cyclomatic complexity <= 10, function length <= 80 lines.
stage_metrics() {
    banner "metrics (lizard)"
    if ! has_sources; then skip metrics "no sources"; return; fi
    lizard -C 10 -L 80 "${SRC_DIRS[@]}" > "$REPORTS/lizard.txt"
    if lizard -C 10 -L 80 -w "${SRC_DIRS[@]}"; then
        pass metrics "CCN<=10, length<=80"
    else
        fail metrics "see $REPORTS/lizard.txt"
    fi
}

# CLOC: comment ratio = comment / (comment + code) >= 20%, for the total AND
# for every individual file (a well-commented file cannot hide an uncommented one).
stage_comments() {
    banner "comments (cloc)"
    if ! has_sources; then skip comments "no sources"; return; fi
    cloc --json --quiet --by-file --include-lang=C,C++,"C/C++ Header" "${SRC_DIRS[@]}" > "$REPORTS/cloc.json"
    local out
    if out=$(python3 - "$REPORTS/cloc.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
ratio = lambda e: 100.0 * e["comment"] / (e["comment"] + e["code"]) if e["comment"] + e["code"] else 100.0
bad = [(f, ratio(e)) for f, e in data.items() if f not in ("header", "SUM") and ratio(e) < 20]
for f, r in bad:
    print(f"  {f}: {r:.2f}% < 20%", file=sys.stderr)
print(f"{ratio(data['SUM']):.2f}")
sys.exit(1 if bad or ratio(data["SUM"]) < 20 else 0)
PY
    ); then
        pass comments "total ${out}%, every file >= 20%"
    else
        fail comments "total ${out}%, file(s) below 20% listed above"
    fi
}

stage_hitl() {
    banner "hitl (doxygen AI/review tags)"
    local opt=()
    [[ "${REQUIRE_HUMAN_REVIEW:-0}" == "1" ]] && opt=(--require-review)
    if python3 tools/check_hitl_comments.py "${opt[@]}"; then pass hitl; else fail hitl; fi
}

# run_suite <suite> <coverage args...>
run_suite() {
    local suite=$1; shift
    banner "$suite tests"
    if ! has_sources; then skip "$suite" "no sources"; return; fi
    if [[ ! -f tests/$suite/CMakeLists.txt ]]; then fail "$suite" "tests/$suite missing"; return; fi
    if bash tools/llvm_coverage.sh --build-dir build/cov --label "$suite" \
         --ctest-regex "^${suite}\\." "$@" ${COV_NO_BUILD:+--no-build}; then
        pass "$suite"
    else
        fail "$suite" "see build/cov/coverage/$suite/"
    fi
    COV_NO_BUILD=1
}

stage_unit()        { run_suite unit        --function 0 --line 0 --branch 0 --mcdc 100; }
stage_tdd()         { run_suite tdd         --function 0 --line 0 --branch 0 --mcdc 100 --report-only; }
stage_integration() { run_suite integration --function 100 --line 0 --branch 0; }
stage_system() {
    banner "system tests (requirements coverage)"
    if ! grep -qsE '^#{2,4}[[:space:]]+(SWR-[FQLC]|SSR)-[0-9]{3}' docs/requirements/*.md; then
        skip system "no requirements"; return
    fi
    local junit=""
    if [[ -f tests/system/CMakeLists.txt ]] && has_sources; then
        run_suite system --function 0 --line 0 --branch 0
        junit=build/cov/coverage/system/junit.xml
        [[ ${RESULT[system]} == FAIL* ]] && return
    fi
    if python3 tools/check_requirements_coverage.py ${junit:+--junit "$junit"}; then
        pass system "requirements coverage 100%"
    else
        fail system "requirements coverage < 100%"
    fi
}

COV_NO_BUILD=
for s in "${STAGES[@]}"; do
    if declare -F "stage_$s" >/dev/null; then "stage_$s"; else echo "unknown stage: $s"; exit 2; fi
done

banner SUMMARY
for s in "${STAGES[@]}"; do printf '%-12s %s\n' "$s" "${RESULT[$s]}"; done
[[ $FAILED -eq 0 ]] && echo "QUALITY GATE: PASS" || echo "QUALITY GATE: FAIL"
exit $FAILED
