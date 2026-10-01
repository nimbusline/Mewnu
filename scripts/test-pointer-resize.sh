#!/bin/bash
# Opt-in local gesture check. Requires a reliable interactive macOS test session.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
mkdir -p build
validation_dir="$(mktemp -d "$root/build/PointerValidation.XXXXXX")"
xcodebuild -project Mewnu.xcodeproj -scheme Mewnu -destination 'platform=macOS' \
  -derivedDataPath "$validation_dir/DerivedData" CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build-for-testing
run_file="$(python3 - "$validation_dir/DerivedData/Build/Products" <<'PY'
from pathlib import Path
import plistlib
import sys

path = next(Path(sys.argv[1]).glob('*.xctestrun'))
data = plistlib.loads(path.read_bytes())
targets = [data['MewnuUITests']] if 'MewnuUITests' in data else [
    target for configuration in data.get('TestConfigurations', [])
    for target in configuration.get('TestTargets', [])
    if target.get('BlueprintName') == 'MewnuUITests'
]
assert targets, 'No UI test target in generated test run'
for target in targets:
    target.setdefault('EnvironmentVariables', {})['MEWNU_TEST_POINTER_DRAG'] = '1'
path.write_bytes(plistlib.dumps(data))
print(path)
PY
)"
xcodebuild -xctestrun "$run_file" -destination 'platform=macOS' \
  -resultBundlePath "$validation_dir/PointerDrag.xcresult" \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 90 \
  '-only-testing:MewnuUITests/MewnuUITests/testPointerDragSavesHeightAcrossRelaunch' test-without-building
