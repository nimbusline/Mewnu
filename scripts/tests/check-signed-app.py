#!/usr/bin/env python3
"""Check nested signatures and the app's release sandbox installer permissions."""
import plistlib
import subprocess
import sys
from pathlib import Path

app = Path(sys.argv[1])
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(app)], capture_output=True, check=True)
entitlements = plistlib.loads(result.stdout)
bundle = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert entitlements['com.apple.security.app-sandbox'] is True
assert entitlements['com.apple.security.personal-information.calendars'] is True
assert entitlements['com.apple.security.temporary-exception.mach-lookup.global-name'] == [
    bundle['CFBundleIdentifier'] + '-spks', bundle['CFBundleIdentifier'] + '-spki']
assert 'com.apple.security.network.client' not in entitlements
print('PASS: nested signatures and expanded installer permissions; calendar sandbox retained')
