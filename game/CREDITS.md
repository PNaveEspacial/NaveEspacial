# Credits

Third-party assets used by the Godot rebuild under `game/`. All assets
listed here are free to use under their stated license; crediting the
author is appreciated but not required by CC0.

## Kenney Pixel Shmup

- **Name**: Pixel Shmup (pack version 1.1)
- **Author**: Kenney (www.kenney.nl)
- **License**: CC0 1.0 Universal (Creative Commons Zero) —
  https://creativecommons.org/publicdomain/zero/1.0/
- **Source URL**: https://kenney.nl/assets/pixel-shmup
- **Direct download URL**: https://kenney.nl/media/pages/assets/pixel-shmup/640246b9cc-1677495782/kenney_pixel-shmup.zip
- **Downloaded**: 2026-09-24
- **Archive SHA-256**: `e33fd626b799de343f18c81ebaa6f3bc161772fdd717acf3f223589ce74cf952`
- **Files committed**: `game/assets/kenney_pixel_shmup/ships_packed.png`,
  `game/assets/kenney_pixel_shmup/tiles_packed.png`, and the pack's
  `License.txt`. Individual per-tile PNGs, the preview/sample images, and
  the `.url` shortcut files from the original archive were not committed
  (redundant with the two packed sheets, or non-functional extras).

### Verified sprite sheet metadata (from the downloaded pack, 2026-09-24)

| Sheet | Tile size | Grid | Tile count | Packed image size |
|---|---|---|---|---|
| `ships_packed.png` | 32x32 px | 4 x 6 | 24 | 128x192 px |
| `tiles_packed.png` | 16x16 px | 12 x 10 | 120 | 192x160 px |

**Correction to the design's OQ1 finding**: the design phase's OQ1
resolution stated the pack uses uniform 16x16 tiles across 128 files. That
is only true of the `tiles_packed.png` sheet (16x16, 120 tiles). The
`ships_packed.png` sheet — the sheet the player ship and enemy ships will
most likely draw from per design D13's `EnemyData.texture`/`frame` fields —
is actually **32x32 px per tile, 24 tiles**, not 16x16. This is a real
discrepancy from the design's stated assumption, verified directly against
the downloaded archive.

**S4 update**: design D2 states its own rule for this exact case ("if ships
are 32x32, switch to 640x360"). As the first commit of slice S4, the
internal resolution changed from 480x270 to **640x360** in
`game/project.godot` (window override raised to 1920x1080, keeping the
integer x3 default). `SpawnRing`'s `min_player_distance` (S5) scales
proportionally from 120 px to 160 px for the same reason. This keeps a
32x32 ship sprite at roughly the same relative screen height the design
originally assumed for a 16x16 sprite at 480x270 (~11.9% either way), so no
further re-evaluation is needed before S8/S9 pick actual ship frames.

## Press Start 2P (pixel UI font)

- **Name**: Press Start 2P
- **Author**: Cody "CodeMan38" Boisclair (The Press Start 2P Project
  Authors)
- **License**: SIL Open Font License, Version 1.1 (OFL-1.1) —
  https://openfontlicense.org/documents/OFL.txt (full text also committed
  at `game/assets/fonts/press_start_2p/OFL.txt`)
- **Source**: Google Fonts' canonical font repository (the upstream,
  actively-maintained mirror of this font family) —
  https://github.com/google/fonts/tree/main/ofl/pressstart2p
- **Direct download URL**: https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf
- **Downloaded**: 2026-09-24
- **File SHA-256**: `034c77f1f05ec89421e4a63f0e3a4ca1ecf852cc6d2bf611f126f275728e017`
- **Files committed**: `game/assets/fonts/press_start_2p/PressStart2P-Regular.ttf`
  and `game/assets/fonts/press_start_2p/OFL.txt`.

**Design D6 correction**: the design's primary choice was **monogram** by
datagoblin (CC0 1.0, `datagoblin.itch.io/monogram`), with Press Start 2P
named as the explicit fallback. At S15 apply time, itch.io's free-asset
download is a JS-driven claim flow (a "No thanks, just take me to the
downloads" button that POSTs to an endpoint derived from obfuscated
client-side script state, not a stable REST URL) that could not be
scripted headlessly within this slice's scope. Per design D6's own
documented fallback rule, this slice uses **Press Start 2P** instead.
Its glyph coverage for the full requirement set — every character in
`game/i18n/strings.csv` plus `áéíóúüñÁÉÍÓÚÜÑ¿¡` — was verified directly
against the downloaded file with `Font.has_char()` before committing (see
`game/tests/integration/test_font_glyphs.gd`), and via a one-off headless
probe run against the real Godot 4.7.2 binary during apply: zero missing
characters.

**Import settings** (`game/assets/fonts/press_start_2p/PressStart2P-Regular.ttf.import`,
per design D6): antialiasing None (`antialiasing=0`), hinting None
(`hinting=0`), subpixel positioning Disabled (`subpixel_positioning=0`),
no mipmaps (`generate_mipmaps=false`), no MSDF
(`multichannel_signed_distance_field=false`). `game/scenes/ui/theme/pixel_theme.tres`
uses it at `default_font_size = 8` — Press Start 2P's own native pixel
grid is 8x8, matching design D6's "native pixel size or integer
multiples" rule.
