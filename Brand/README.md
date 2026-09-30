# Mewnu artwork

A rounded cat silhouette with two open eyes. No outlines, small facial details,
or lettering are needed to recognize it at menu bar size.

- `mewnu-logo.svg` is the canonical, editable vector mark on a 24 × 24 artboard.
- `mewnu-menu.svg` is its 18-point monochrome template for the macOS menu bar.
  Its eyes are transparent cutouts, so they also work on dark backgrounds.
- `mewnu-app.svg` places the same mark on an ice-blue app icon tile, with space
  around the tile for the macOS icon grid.

The “Eis & Rost” palette is rust red `#A63925` and ice blue `#CEE8F0`. For monochrome use,
change the path's fill to the foreground color; keep the eyes transparent.
Keep the mark's proportions and clear space. Use at 18 points or larger on its
own; the system app icon also has an exported 16-pixel version.

The menu bar and app header share the SVG `MenuIcon` asset. Xcode preserves its
vector representation, and SwiftUI uses template rendering to follow the system
appearance. The header image is decorative beside the accessible app name.
App icon PNGs are exports required by the macOS app icon catalog; the editable
source remains vector artwork.

After editing the canonical mark, regenerate all derived artwork:

```sh
brew install librsvg # Only needed to regenerate artwork, not to build the app.
python3 scripts/generate-brand-assets.py
xcodegen generate
```

All SVGs contain vector paths, with no embedded raster images, fonts, or external
resources. The artwork is covered by the repository's MIT license.
