#!/usr/bin/env python3
"""Sign synthetic updates with an ephemeral key; reject archive/feed tampering."""
import importlib.util
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / 'build/tools/sparkle-2.10.0/bin'

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

metadata_check = load('feed_metadata', ROOT / 'scripts/validate-update-feed.py')
version_check = load('feed_version', ROOT / 'scripts/check-update-version.py')

def run(args, expected=0):
    result = subprocess.run(args, capture_output=True, text=True)
    assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout

with tempfile.TemporaryDirectory(prefix='MewnuUpdateTest-', dir=ROOT / 'build') as task_dir:
    stage = Path(task_dir)
    key = stage / 'private-key'
    public = stage / 'public-key'
    # CryptoKit writes the key directly to a private temporary file; no secret output.
    generator = stage / 'key.swift'
    generator.write_text('''import CryptoKit
import Foundation
let key = Curve25519.Signing.PrivateKey()
try key.rawRepresentation.base64EncodedString().write(toFile: CommandLine.arguments[1], atomically: true, encoding: .utf8)
try key.publicKey.rawRepresentation.base64EncodedString().write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)
''')
    run(['xcrun', 'swift', str(generator), str(key), str(public)])
    key.chmod(0o600)
    app = stage / 'Mewnu.app/Contents'
    (app / 'MacOS').mkdir(parents=True)
    info = app / 'Info.plist'
    info.write_bytes(plistlib.dumps({
        'CFBundleIdentifier': 'io.github.nimbusline.mewnu.synthetic-update',
        'CFBundleName': 'Mewnu', 'CFBundleExecutable': 'Mewnu', 'CFBundlePackageType': 'APPL',
        'CFBundleVersion': '4', 'CFBundleShortVersionString': '1.1.0',
        'LSMinimumSystemVersion': '26.0', 'SUPublicEDKey': public.read_text(),
        'SURequireSignedFeed': True, 'SUVerifyUpdateBeforeExtraction': True,
    }))
    source = stage / 'main.c'
    source.write_text('int main(void) { return 0; }\n')
    run(['xcrun', 'clang', '-arch', 'arm64', '-arch', 'x86_64', str(source), '-o', str(app / 'MacOS/Mewnu')])
    run(['codesign', '--force', '--sign', '-', str(app.parent)])
    archives = stage / 'archives'
    archives.mkdir()
    archive = archives / 'Mewnu.dmg'
    run(['hdiutil', 'create', '-volname', 'Mewnu', '-srcfolder', str(app.parent), '-format', 'UDZO', str(archive)])
    environment = dict(os.environ, SPARKLE_EDDSA_PRIVATE_KEY=key.read_text())
    result = subprocess.run([str(ROOT / 'scripts/generate-update-feed.sh'), '1.1.0', str(archive), str(app.parent)],
                            env=environment, capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stdout, result.stderr)
    feed = archives / 'appcast.xml'
    run([str(TOOLS / 'sign_update'), '--ed-key-file', str(key), '--verify', str(feed)])
    metadata_check.validate(feed, archive, '1.1.0', info)
    enclosure = ET.fromstring(feed.read_bytes()).find('./channel/item/enclosure')
    assert enclosure.get('url') == 'https://github.com/nimbusline/Mewnu/releases/download/v1.1.0/Mewnu.dmg'
    original_feed = feed.read_bytes()
    for old, new in [(b'1.1.0', b'1.1.9'), (b'https://github.com/', b'https://example.invalid/')]:
        feed.write_bytes(original_feed.replace(old, new))
        try:
            metadata_check.validate(feed, archive, '1.1.0', info)
        except ValueError:
            pass
        else:
            raise AssertionError('Accepted invalid update metadata')
    feed.write_bytes(original_feed)
    version_check.validate(feed.read_bytes(), '1.1.1', '5')
    for version, build in [('1.1.1', '4'), ('1.1.1', '3'), ('1.1.0', '5'), ('1.0.9', '5')]:
        try:
            version_check.validate(feed.read_bytes(), version, build)
        except ValueError:
            pass
        else:
            raise AssertionError('Accepted non-increasing version/build')
    item = ET.fromstring(feed.read_bytes()).find('./channel/item')
    signature = item.find('enclosure').get(f'{{{metadata_check.SPARKLE}}}edSignature')
    run([str(TOOLS / 'sign_update'), '--ed-key-file', str(key), '--verify', str(archive), signature])
    archive.write_bytes(archive.read_bytes() + b'Synthetic tampering')
    failed = subprocess.run([str(TOOLS / 'sign_update'), '--ed-key-file', str(key), '--verify', str(archive), signature], capture_output=True)
    assert failed.returncode != 0, 'Tampered archive accepted'
    feed.write_bytes(feed.read_bytes().replace(b'1.1.0', b'1.1.9'))
    failed = subprocess.run([str(TOOLS / 'sign_update'), '--ed-key-file', str(key), '--verify', str(feed)], capture_output=True)
    assert failed.returncode != 0, 'Tampered feed accepted'
print('PASS: signed synthetic feed/archive, metadata, increasing versions, archive/feed tampering rejected')
