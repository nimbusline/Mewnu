#!/usr/bin/env python3
"""Validate release metadata after Sparkle has verified the feed signature."""
import base64
from pathlib import Path
import plistlib
import sys
import xml.etree.ElementTree as ET

SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"

def validate(feed: Path, artifact: Path, version: str, info: Path) -> None:
    metadata = plistlib.loads(info.read_bytes())
    root = ET.fromstring(feed.read_bytes())
    items = root.findall("./channel/item")
    if len(items) != 1:
        raise ValueError("Expected exactly one stable update")
    item = items[0]
    enclosure = item.find("enclosure")
    expected = f"https://github.com/nimbusline/Mewnu/releases/download/v{version}/{artifact.name}"
    if enclosure is None or enclosure.get("url") != expected:
        raise ValueError("Update URL does not match tagged release")
    if int(enclosure.get("length", "0")) != artifact.stat().st_size:
        raise ValueError("Update length mismatch")
    signature = base64.b64decode(enclosure.get(f"{{{SPARKLE}}}edSignature", ""), validate=True)
    if len(signature) != 64:
        raise ValueError("Missing EdDSA archive signature")
    for name, expected_value in {
        "version": metadata["CFBundleVersion"],
        "shortVersionString": version,
        "minimumSystemVersion": metadata["LSMinimumSystemVersion"],
    }.items():
        if item.findtext(f"{{{SPARKLE}}}{name}") != str(expected_value):
            raise ValueError(f"Update {name} mismatch")
    if metadata["CFBundleShortVersionString"] != version:
        raise ValueError("App version does not match release")
    if not metadata.get("SURequireSignedFeed") or not metadata.get("SUVerifyUpdateBeforeExtraction"):
        raise ValueError("Release must require signed feeds and archives")

if __name__ == "__main__":
    validate(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], Path(sys.argv[4]))
    print("PASS: tagged HTTPS URL, archive signature metadata, size, build, version, minimum OS")
