#!/usr/bin/env python3
"""System test requirements coverage (target: 100%).

Requirements: `### SWR-x-NNN` / `### SSR-NNN` headings in docs/requirements/*.md.
Covered = referenced by `@trace` in at least one system test under tests/system/
(and that system test passed, when --junit is given).

Exit code: 0 = 100% covered, 1 = uncovered requirements, 0 with notice if no
requirements exist yet.
"""
import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REQ_RE = re.compile(r"^#{2,4}\s+((?:SWR-[FQLC]|SSR)-\d{3})\b", re.M)
TRACE_RE = re.compile(r"@trace\b([^\n]*)")
TEST_RE = re.compile(r"@test\s+(STC-\d{3})")
ID_RE = re.compile(r"(?:SWR-[FQLC]|SSR)-\d{3}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--req-dir", default="docs/requirements")
    ap.add_argument("--test-dir", default="tests/system")
    ap.add_argument("--junit", help="JUnit XML of the system test run")
    args = ap.parse_args()

    reqs = set()
    for f in Path(args.req_dir).glob("*.md") if Path(args.req_dir).is_dir() else []:
        reqs |= set(REQ_RE.findall(f.read_text(encoding="utf-8")))
    if not reqs:
        print("Requirements coverage: no requirements defined - skipped")
        return 0

    failed = set()
    if args.junit and Path(args.junit).is_file():
        for case in ET.parse(args.junit).iter("testcase"):
            if case.find("failure") is not None or case.find("error") is not None:
                failed.add(case.get("name", ""))

    covered = set()
    tdir = Path(args.test_dir)
    for f in tdir.rglob("*") if tdir.is_dir() else []:
        if f.suffix not in {".c", ".cpp", ".cc", ".h", ".hpp"}:
            continue
        for block in re.findall(r"/\*\*.*?\*/", f.read_text(encoding="utf-8"), re.S):
            traces = set()
            for line in TRACE_RE.findall(block):
                traces |= set(ID_RE.findall(line))
            stc = TEST_RE.search(block)
            if stc and any(stc.group(1) in n for n in failed):
                continue  # a failing test does not cover anything
            covered |= traces

    missing = sorted(reqs - covered)
    pct = 100.0 * (len(reqs) - len(missing)) / len(reqs)
    for r in missing:
        print(f"NOT COVERED by a passing system test: {r}")
    print(f"Requirements coverage: {len(reqs) - len(missing)}/{len(reqs)} = {pct:.2f}% (target 100%)")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
