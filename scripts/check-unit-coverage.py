#!/usr/bin/env python3
"""Require meaningful unit coverage for Mewnu's calendar logic."""

import json
import subprocess
import sys


CORE_FILES = (
    "CalendarMath.swift",
    "CalendarText.swift",
    "CalendarViewModel.swift",
    "CalendarService.swift",
    "EventDisplayText.swift",
)
MINIMUM_COVERAGE = 0.95


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: check-unit-coverage.py RESULT_BUNDLE", file=sys.stderr)
        return 2

    result = subprocess.run(
        ["xcrun", "xccov", "view", "--report", "--json", sys.argv[1]],
        check=True,
        capture_output=True,
        text=True,
    )
    report = json.loads(result.stdout)
    target = next((item for item in report["targets"] if item["name"] == "Mewnu.app"), None)
    if target is None:
        print("Mewnu.app coverage target is missing", file=sys.stderr)
        return 1

    files = {item["name"]: item for item in target["files"]}
    failed = False
    for name in CORE_FILES:
        item = files.get(name)
        if item is None:
            print(f"{name}: no coverage data", file=sys.stderr)
            failed = True
            continue
        covered = item["coveredLines"]
        executable = item["executableLines"]
        ratio = covered / executable if executable else 0
        print(f"{name}: {covered}/{executable} lines ({ratio:.1%})")
        if ratio < MINIMUM_COVERAGE:
            failed = True

    if failed:
        print(f"Core unit coverage must be at least {MINIMUM_COVERAGE:.0%} per file", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
