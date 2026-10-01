#!/usr/bin/env python3
"""Exercise development safeguards in an isolated Git repository, without altering the checkout."""
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def validate() -> None:
    with tempfile.TemporaryDirectory(prefix="MewnuToolValidation-") as temporary:
        repo = Path(temporary) / "repo"
        repo.mkdir()
        files = subprocess.check_output(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT
        ).decode().split("\0")
        for name in filter(None, files):
            source = ROOT / name
            if source.is_file():
                destination = repo / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
        shutil.copytree(ROOT / "build/tools", repo / "build/tools")

        def run(arguments: list[str], expected: int = 0) -> None:
            result = subprocess.run(arguments, cwd=repo, capture_output=True, text=True)
            assert result.returncode == expected, (arguments, result.returncode, result.stdout, result.stderr)

        def commit(message: str) -> None:
            run(["git", "add", "."])
            run(["git", "-c", "user.name=Validation", "-c", "user.email=validation@example.invalid",
                 "commit", "-qm", message])

        run(["git", "init", "-q"])
        commit("Validation baseline")
        run(["scripts/generate-project.sh", "--check"])
        run(["scripts/generate-project.sh", "--check"])

        project = repo / "Mewnu.xcodeproj/project.pbxproj"
        project.write_text(project.read_text() + "\n// Synthetic drift\n")
        run(["python3", "scripts/check-project-drift.py"], expected=1)
        run(["git", "restore", "Mewnu.xcodeproj/project.pbxproj"])

        extra = repo / "Mewnu.xcodeproj/unexpected.txt"
        extra.write_text("Synthetic untracked output")
        run(["python3", "scripts/check-project-drift.py"], expected=1)
        extra.unlink()

        ignored = repo / "Mewnu.xcodeproj/xcuserdata/synthetic.xcuserstate"
        ignored.parent.mkdir()
        ignored.write_text("Synthetic user state")
        run(["scripts/generate-project.sh", "--check"])

        spec = repo / "project.yml"
        spec.write_text(re.sub(r"(CURRENT_PROJECT_VERSION:\s*)(\d+)",
                              lambda match: match[1] + str(int(match[2]) + 1), spec.read_text()))
        run(["scripts/generate-project.sh", "--check"], expected=1)
        commit("Regenerated project")
        run(["scripts/generate-project.sh", "--check"])

        valid = (ROOT / "Mewnu/Mewnu.entitlements").read_bytes()
        malformed = Path(temporary) / "malformed.entitlements"
        malformed.write_bytes(valid.replace(
            b'"http://www.apple.com/DTDs/PropertyList-1.0.dtd"',
            b'"http://www.apple.com/DTDs/PropertyList 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"'
        ))
        result = subprocess.run(["xmllint", "--nonet", "--noout", str(malformed)], capture_output=True)
        assert result.returncode != 0, "Malformed DOCTYPE was accepted"
        assert plistlib.loads(valid) == {
            "com.apple.security.app-sandbox": True,
            "com.apple.security.personal-information.calendars": True,
            "com.apple.security.temporary-exception.mach-lookup.global-name": [
                "$(PRODUCT_BUNDLE_IDENTIFIER)-spks", "$(PRODUCT_BUNDLE_IDENTIFIER)-spki"],
        }
        run(["scripts/validate-entitlements.sh"])


if __name__ == "__main__":
    validate()
    print("PASS: clean/repeated generation, tracked/untracked drift rejection, ignored state, "
          "legitimate regeneration, strict XML rejection, and entitlement values.")
