#!/usr/bin/env python3
"""Reject tracked differences and non-ignored untracked generated project output."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
# Include staged differences, deletions, and new files; ignore xcuserdata via .gitignore.
changes = subprocess.check_output(
    ['git', 'status', '--porcelain', '--untracked-files=all', '--', 'Mewnu.xcodeproj'],
    cwd=root, text=True,
)
if changes:
    print('Generated project differs from the committed project. Regenerate and commit it:', file=sys.stderr)
    print(changes, end='', file=sys.stderr)
    sys.exit(1)
print('Generated project matches the committed project.')
