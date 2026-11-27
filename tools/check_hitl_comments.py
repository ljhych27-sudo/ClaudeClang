#!/usr/bin/env python3
"""Check doxygen Human-in-the-Loop (HITL) tags in production source files.

Every file under src/ and include/ must have a `@file` doxygen block, and every
function (found with lizard) must be preceded by a doxygen block (/** ... */).
Each of those blocks must contain:

    @brief
    @ai_model       <model id>                (which AI model wrote it)
    @ai_date        <YYYY-MM-DD>              (when)
    @requested_by   <person>                  (who asked for it)
    @human_review   Pending | Done
    @reviewed_by    <person>     (required when @human_review Done)
    @reviewed_date  <YYYY-MM-DD> (required when @human_review Done)

With --require-review, every block must be `@human_review Done`
(used by CI for release/hotfix branches and PRs into main).

Exit code: 0 = OK, 1 = violations found.
"""
import argparse
import csv
import io
import re
import subprocess
import sys
from pathlib import Path

EXTS = {".c", ".h", ".cpp", ".hpp", ".cc", ".hh", ".cxx", ".hxx"}
REQUIRED = ["@brief", "@ai_model", "@ai_date", "@requested_by", "@human_review"]
DATE_RE = re.compile(r"\d{4}-\d{2}-\d{2}$")


def tag_value(block, tag):
    m = re.search(rf"{re.escape(tag)}[ \t]+([^\n*]+)", block)
    return m.group(1).strip() if m else None


def check_block(block, where, require_review):
    errors = []
    for tag in REQUIRED:
        if tag_value(block, tag) is None:
            errors.append(f"{where}: missing or empty {tag}")
    date = tag_value(block, "@ai_date")
    if date and not DATE_RE.match(date):
        errors.append(f"{where}: @ai_date must be YYYY-MM-DD (got '{date}')")
    review = tag_value(block, "@human_review")
    if review and review not in ("Pending", "Done"):
        errors.append(f"{where}: @human_review must be Pending or Done (got '{review}')")
    if review == "Done":
        for tag in ("@reviewed_by", "@reviewed_date"):
            if tag_value(block, tag) is None:
                errors.append(f"{where}: @human_review Done requires {tag}")
        rdate = tag_value(block, "@reviewed_date")
        if rdate and not DATE_RE.match(rdate):
            errors.append(f"{where}: @reviewed_date must be YYYY-MM-DD (got '{rdate}')")
    if require_review and review != "Done":
        errors.append(f"{where}: human review not completed (@human_review {review})")
    return errors


def preceding_doxygen(lines, start_idx):
    """Return the /** ... */ block that ends right above line start_idx (0-based)."""
    i = start_idx - 1
    while i >= 0 and lines[i].strip() == "":
        i -= 1
    if i < 0 or not lines[i].rstrip().endswith("*/"):
        return None
    end = i
    while i >= 0 and "/**" not in lines[i]:
        if i < end and "*/" in lines[i]:
            return None  # ran into a different comment
        i -= 1
    return "\n".join(lines[i:end + 1]) if i >= 0 else None


def functions(paths):
    out = subprocess.run(["lizard", "--csv", *map(str, paths)],
                         capture_output=True, text=True, check=False).stdout
    # columns: nloc,ccn,token,param,length,location,file,function,long_name,start,end
    for row in csv.reader(io.StringIO(out)):
        if len(row) >= 11 and row[9].isdigit():
            yield Path(row[6]), row[7], int(row[9])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("roots", nargs="*", default=["src", "include"])
    ap.add_argument("--require-review", action="store_true")
    args = ap.parse_args()

    files = sorted(p for r in args.roots if Path(r).is_dir()
                   for p in Path(r).rglob("*") if p.suffix in EXTS)
    if not files:
        print("HITL check: no production sources - skipped")
        return 0

    errors = []
    texts = {f: f.read_text(encoding="utf-8", errors="replace") for f in files}
    for f, text in texts.items():
        m = re.search(r"/\*\*(?:(?!\*/).)*@file(?:(?!\*/).)*\*/", text, re.S)
        if not m:
            errors.append(f"{f}: missing @file doxygen block")
        else:
            errors += check_block(m.group(0), f"{f} (@file)", args.require_review)

    for path, name, start in functions(files):
        lines = texts.get(path, path.read_text(encoding="utf-8", errors="replace")).splitlines()
        block = preceding_doxygen(lines, start - 1)
        where = f"{path}:{start} {name}()"
        if block is None:
            errors.append(f"{where}: missing doxygen block")
        else:
            errors += check_block(block, where, args.require_review)

    for e in errors:
        print(e)
    print(f"HITL check: {len(files)} files, {len(errors)} violation(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
