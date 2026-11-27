#!/usr/bin/env bash
# Stop hook: when Claude finishes a turn, run Lizard on changed production
# sources (src/, include/). Violations (CCN > 10 or function length > 80)
# block the stop (exit 2) and are fed back to Claude to fix.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
cat > /dev/null   # hook input JSON is not needed

mapfile -t FILES < <(
    { git diff --name-only HEAD -- src include 2>/dev/null
      git ls-files --others --exclude-standard -- src include 2>/dev/null; } |
    grep -E '\.(c|h|cpp|hpp|cc|hh)$' | sort -u | while read -r f; do [[ -f $f ]] && echo "$f"; done
)
[[ ${#FILES[@]} -eq 0 ]] && exit 0

ARGS=(-C 10 -L 80 -w "${FILES[@]}")
if command -v lizard >/dev/null 2>&1; then
    OUT=$(lizard "${ARGS[@]}" 2>&1); RC=$?
elif docker image inspect claudeclangbuild >/dev/null 2>&1; then
    HOST_DIR=$PWD
    command -v cygpath >/dev/null 2>&1 && HOST_DIR=$(cygpath -w "$PWD")
    OUT=$(MSYS_NO_PATHCONV=1 docker run --rm -v "$HOST_DIR:/workspace" -w /workspace \
          claudeclangbuild lizard "${ARGS[@]}" 2>&1); RC=$?
else
    echo "lizard hook: neither lizard nor the claudeclangbuild image is available - build it with: docker build -t claudeclangbuild docker" >&2
    exit 2
fi

if [[ $RC -ne 0 ]]; then
    {
        echo "Lizard 품질 기준 위반 (순환복잡도 <= 10, 함수 길이 <= 80라인). 리팩터링 후 다시 완료하세요:"
        echo "$OUT"
    } >&2
    exit 2
fi
exit 0
