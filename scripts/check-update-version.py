#!/usr/bin/env python3
"""Prevent publishing a stable update whose build/version would go backwards."""
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

SPARKLE = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
FEED = 'https://github.com/nimbusline/Mewnu/releases/latest/download/appcast.xml'


def validate(previous: bytes, version: str, build: str) -> None:
    item = ET.fromstring(previous).find('./channel/item')
    if item is None:
        raise ValueError('Published appcast has no update item')
    old_build = item.findtext(f'{{{SPARKLE}}}version', '')
    old_version = item.findtext(f'{{{SPARKLE}}}shortVersionString', '')
    if not old_build.isdecimal() or not build.isdecimal() or int(build) <= int(old_build):
        raise ValueError('CURRENT_PROJECT_VERSION must exceed the published build')
    if not re.fullmatch(r'\d+\.\d+\.\d+', old_version):
        raise ValueError('Published version is malformed')
    if tuple(map(int, version.split('.'))) <= tuple(map(int, old_version.split('.'))):
        raise ValueError('MARKETING_VERSION must exceed the published release')


if __name__ == '__main__':
    spec = Path('project.yml').read_text()
    version = re.search(r'MARKETING_VERSION:\s*(\d+\.\d+\.\d+)', spec)[1]
    build = re.search(r'CURRENT_PROJECT_VERSION:\s*(\d+)', spec)[1]
    if len(sys.argv) != 2 or sys.argv[1] != version:
        raise ValueError('Release argument must match MARKETING_VERSION in project.yml')
    try:
        with urllib.request.urlopen(FEED, timeout=30) as response:
            validate(response.read(), version, build)
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        print('No published appcast yet; first updater release.')
    else:
        print('PASS: version and build exceed the published stable update.')
