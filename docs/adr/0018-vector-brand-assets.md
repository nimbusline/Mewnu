# ADR-0018: Use one vector cat mark with the Ice and Rust palette

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The logo should be friendly, simple, and recognizable at menu bar size. The app and menu bar should share one identity.

## Decision

Use a canonical SVG cat head on a 24 × 24 artboard with transparent eyes. Use an 18-point monochrome template in the menu bar and app header. The app icon uses rust red #A63925 on ice blue #CEE8F0. Generate derived SVGs and required app-icon PNG sizes with a script.

## Alternatives

- Maintain a raster original with exports for each size: supports detailed artwork, but requires more size-specific editing. A vector original supports the simple shared silhouette.
- Draw separate marks for the app and menu: can optimize each format independently, but requires maintaining two visual identities. One silhouette with different treatments keeps them recognizable as one product.

## Consequences

One vector original keeps proportions consistent across menu, header, and app icon exports. A change to that original requires regenerating and reviewing the derived assets. The template mark prioritizes small-size legibility and system tinting, so the two-color palette appears in the app icon rather than the menu bar mark.

## Implementation and validation

The menu mark is a scalable template without embedded raster data. The generator creates derived SVGs and all required app-icon sizes.

Implementation references:

- [Brand/README.md](../../Brand/README.md)
- [Brand/mewnu-logo.svg](../../Brand/mewnu-logo.svg)
- [scripts/generate-brand-assets.py](../../scripts/generate-brand-assets.py)
- [Mewnu/Assets.xcassets/MenuIcon.imageset/Contents.json](../../Mewnu/Assets.xcassets/MenuIcon.imageset/Contents.json)
