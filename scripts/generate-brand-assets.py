#!/usr/bin/env python3
"""Export the canonical SVG mark to Xcode assets. Requires librsvg's rsvg-convert."""

import copy
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "Brand"
ASSETS = ROOT / "Mewnu" / "Assets.xcassets"
SVG_NAMESPACE = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NAMESPACE)


def main():
    converter = shutil.which("rsvg-convert")
    if converter is None:
        raise SystemExit("Install librsvg to regenerate artwork: brew install librsvg")

    source = ET.parse(BRAND / "mewnu-logo.svg").getroot()
    mark = source.find(f"{{{SVG_NAMESPACE}}}path[@id='mewnu-mark']")
    if mark is None or source.get("viewBox") != "0 0 24 24":
        raise SystemExit("Expected the mewnu-mark path on the canonical 24 × 24 artboard")

    menu_mark = copy.deepcopy(mark)
    menu_mark.set("fill", "#000000")
    menu_path = ET.tostring(menu_mark, encoding="unicode").strip()
    menu_svg = f'''<svg xmlns="{SVG_NAMESPACE}" width="18" height="18" viewBox="0 0 24 24" role="img" aria-label="Mewnu">
  <!-- Generated from mewnu-logo.svg by scripts/generate-brand-assets.py. -->
  {menu_path}
</svg>
'''
    (BRAND / "mewnu-menu.svg").write_text(menu_svg)
    menu_assets = ASSETS / "MenuIcon.imageset"
    (menu_assets / "MenuIcon.svg").write_text(menu_svg)
    contents = {
        "images": [{"filename": "MenuIcon.svg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "preserves-vector-representation": True,
            "template-rendering-intent": "template",
        },
    }
    (menu_assets / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")

    app_path = ET.tostring(mark, encoding="unicode").strip()
    app_svg = f'''<svg xmlns="{SVG_NAMESPACE}" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-labelledby="title desc">
  <title id="title">Mewnu app icon</title>
  <desc id="desc">A rust-red cat on an ice-blue tile.</desc>
  <!-- Generated from mewnu-logo.svg by scripts/generate-brand-assets.py. -->
  <rect x="100" y="100" width="824" height="824" rx="184" fill="#CEE8F0"/>
  <g transform="translate(200 184) scale(26)">
    {app_path}
  </g>
</svg>
'''
    app_source = BRAND / "mewnu-app.svg"
    app_source.write_text(app_svg)

    for size in (16, 32, 64, 128, 256, 512, 1024):
        destination = ASSETS / "AppIcon.appiconset" / f"AppIcon-{size}.png"
        subprocess.run(
            [converter, "--width", str(size), "--height", str(size),
             "--output", str(destination), str(app_source)],
            check=True,
        )
    # Remove obsolete raster menu assets only after successful generation.
    for filename in ("MenuIcon.png", "MenuIcon@2x.png"):
        (menu_assets / filename).unlink(missing_ok=True)
    print("Generated vector menu artwork and all seven macOS app icon sizes.")


if __name__ == "__main__":
    main()
