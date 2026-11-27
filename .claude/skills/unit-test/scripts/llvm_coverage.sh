#!/usr/bin/env bash
# LLVM source-based coverage (line / branch / MC/DC) for CMake + CTest projects.
#
# Builds the project with Clang coverage instrumentation, runs the selected
# CTest tests, merges raw profiles, writes text/HTML/JSON reports and checks the
# totals against the given thresholds. Exit code 0 = all targets met.
#
# Requirements: clang/clang++ (>= 18 for MC/DC), llvm-profdata, llvm-cov,
#               cmake, ctest, python3 (threshold check).
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: llvm_coverage.sh [options]

  --source-dir DIR     CMake source dir             (default: .)
  --build-dir DIR      Coverage build dir           (default: build-cov)
  --label NAME         Report name, e.g. unit / integration (default: unit)
  --ctest-regex RE     Run only tests matching RE (ctest -R)  (default: all)
  --ignore RE          Files to exclude from report
                       (default: '(tests|_deps|third_party)[/\\]')
  --line N             Required line coverage %     (default: 100)
  --branch N           Required branch coverage %   (default: 100)
  --mcdc N             Required MC/DC coverage %, 0 = not measured (default: 0)
  --no-build           Skip configure/build (reuse instrumented build)
  -h, --help           Show this help
EOF
}

SRC_DIR="."
BUILD_DIR="build-cov"
LABEL="unit"
CTEST_REGEX=""
IGNORE_RE='(tests|_deps|third_party)[/\\]'
REQ_LINE=100
REQ_BRANCH=100
REQ_MCDC=0
DO_BUILD=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source-dir)  SRC_DIR="$2"; shift 2 ;;
        --build-dir)   BUILD_DIR="$2"; shift 2 ;;
        --label)       LABEL="$2"; shift 2 ;;
        --ctest-regex) CTEST_REGEX="$2"; shift 2 ;;
        --ignore)      IGNORE_RE="$2"; shift 2 ;;
        --line)        REQ_LINE="$2"; shift 2 ;;
        --branch)      REQ_BRANCH="$2"; shift 2 ;;
        --mcdc)        REQ_MCDC="$2"; shift 2 ;;
        --no-build)    DO_BUILD=0; shift ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

for tool in clang clang++ llvm-profdata llvm-cov cmake ctest python; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        if [[ "$tool" == "python" ]] && command -v python3 >/dev/null 2>&1; then
            continue
        fi
        echo "ERROR: required tool not found: $tool" >&2
        exit 3
    fi
done
PYTHON="$(command -v python3 || command -v python)"

COV_FLAGS="-fprofile-instr-generate -fcoverage-mapping"
if [[ "$REQ_MCDC" != "0" ]]; then
    COV_FLAGS="$COV_FLAGS -fcoverage-mcdc"
fi

OUT_DIR="$BUILD_DIR/coverage/$LABEL"
RAW_DIR="$OUT_DIR/profraw"
PROFDATA="$OUT_DIR/coverage.profdata"

if [[ "$DO_BUILD" == "1" ]]; then
    GEN_ARGS=()
    command -v ninja >/dev/null 2>&1 && GEN_ARGS=(-G Ninja)
    cmake -S "$SRC_DIR" -B "$BUILD_DIR" "${GEN_ARGS[@]}" \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_C_FLAGS="$COV_FLAGS" -DCMAKE_CXX_FLAGS="$COV_FLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="-fprofile-instr-generate" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    cmake --build "$BUILD_DIR"
fi

rm -rf "$OUT_DIR"
mkdir -p "$RAW_DIR"
RAW_ABS="$(cd "$RAW_DIR" && pwd)"

CTEST_ARGS=(--test-dir "$BUILD_DIR" --output-on-failure)
[[ -n "$CTEST_REGEX" ]] && CTEST_ARGS+=(-R "$CTEST_REGEX")

# %p = pid, %m = binary signature: one raw profile per process.
set +e
LLVM_PROFILE_FILE="$RAW_ABS/%p-%m.profraw" ctest "${CTEST_ARGS[@]}"
TEST_RC=$?
set -e

shopt -s nullglob
RAW_FILES=("$RAW_DIR"/*.profraw)
if [[ ${#RAW_FILES[@]} -eq 0 ]]; then
    echo "ERROR: no .profraw produced - were tests built with coverage flags?" >&2
    exit 4
fi
llvm-profdata merge -sparse "${RAW_FILES[@]}" -o "$PROFDATA"

# Instrumented binaries = test executables listed by CTest.
mapfile -t BINARIES < <(
    ctest --test-dir "$BUILD_DIR" --show-only=json-v1 ${CTEST_REGEX:+-R "$CTEST_REGEX"} |
    "$PYTHON" -c '
import json, sys, os
seen = []
for t in json.load(sys.stdin).get("tests", []):
    cmd = t.get("command") or []
    if cmd and os.path.isfile(cmd[0]) and cmd[0] not in seen:
        seen.append(cmd[0])
print("\n".join(seen))'
)
if [[ ${#BINARIES[@]} -eq 0 ]]; then
    echo "ERROR: no test executables found via ctest" >&2
    exit 4
fi

OBJ_ARGS=("${BINARIES[0]}")
for b in "${BINARIES[@]:1}"; do OBJ_ARGS+=(-object "$b"); done

COMMON=(-instr-profile="$PROFDATA" -ignore-filename-regex="$IGNORE_RE")
MCDC_REPORT=(); MCDC_SHOW=()
if [[ "$REQ_MCDC" != "0" ]]; then
    MCDC_REPORT=(--show-mcdc-summary)
    MCDC_SHOW=(--show-mcdc)
fi

llvm-cov report "${OBJ_ARGS[@]}" "${COMMON[@]}" --show-branch-summary "${MCDC_REPORT[@]}" \
    | tee "$OUT_DIR/summary.txt"
llvm-cov show "${OBJ_ARGS[@]}" "${COMMON[@]}" -format=html -output-dir="$OUT_DIR/html" \
    --show-branches=count --show-line-counts-or-regions "${MCDC_SHOW[@]}"
llvm-cov export "${OBJ_ARGS[@]}" "${COMMON[@]}" -summary-only > "$OUT_DIR/summary.json"

set +e
"$PYTHON" - "$OUT_DIR/summary.json" "$REQ_LINE" "$REQ_BRANCH" "$REQ_MCDC" <<'PY'
import json, sys
path, req_line, req_branch, req_mcdc = sys.argv[1], *map(float, sys.argv[2:])
totals = json.load(open(path))["data"][0]["totals"]
checks = [("line", "lines", req_line), ("branch", "branches", req_branch)]
if req_mcdc > 0:
    checks.append(("mcdc", "mcdc", req_mcdc))
ok = True
print("\n== Coverage vs target ==")
for name, key, req in checks:
    entry = totals.get(key)
    if entry is None:
        print(f"{name:7s}: not available (needs clang >= 18 with -fcoverage-mcdc)")
        ok = False
        continue
    # No branches/conditions at all counts as fully covered.
    pct = 100.0 if entry.get("count", 0) == 0 else entry["percent"]
    status = "PASS" if pct + 1e-9 >= req else "FAIL"
    ok &= status == "PASS"
    print(f"{name:7s}: {pct:6.2f}% (target {req:g}%)  {status}  "
          f"[{entry.get('covered', 0)}/{entry.get('count', 0)}]")
sys.exit(0 if ok else 1)
PY
COV_RC=$?
set -e

echo "Reports: $OUT_DIR/summary.txt, $OUT_DIR/html/index.html"
if [[ $TEST_RC -ne 0 ]]; then
    echo "RESULT: FAIL (tests failed, ctest exit $TEST_RC)"
    exit 1
fi
if [[ $COV_RC -ne 0 ]]; then
    echo "RESULT: FAIL (coverage target not met)"
    exit 1
fi
echo "RESULT: PASS"
