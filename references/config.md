# Configuration reference

The build pipeline reads `cheatsheet.toml` at the project root. That file
selects a named preset, then overrides any keys you want to change.

## Minimal example

The shortest valid `cheatsheet.toml` — pick a preset, accept everything else:

```toml
preset = "paper-pro-default"
```

## Override a single value

Most users only want to change one or two things. Anything you don't list
falls through to the preset's value:

```toml
preset = "paper-pro-default"
scratch_zone_mm = 50     # give yourself more pen room
pdf_name = "dev cheatsheet"
```

## Full example with every key spelled out

See `presets/default.toml` — it documents every key with its type and
default value. Use it as a reference; you don't need to set keys you don't
care about.

## Keys

| Key | Type | Default | What it does |
|---|---|---|---|
| `preset` | string | required | Which preset file to load. Must match a filename in `presets/` without the `.toml` extension. Set to a value that doesn't match any preset file and the build will fail loudly. |
| `page_width_mm` | number | 180 | Page width in millimetres. Use 157 for reMarkable 2. |
| `page_height_mm` | number | 240 | Page height in millimetres. Use 209 for reMarkable 2. |
| `body_pt` | number | 11 | Body text size in typographic points. Floor 10pt — below that, e-ink Carta cannot resolve the anti-aliasing. |
| `scratch_zone_mm` | number | 40 | Vertical space reserved at the bottom of each tool sheet for pen annotations. Floor 30mm — below that, the pen zone becomes a worse reference experience than reading on a phone. |
| `table_border_pt` | number | 0.4 | Table border stroke width in points. 0.4 is the default; 0.6–0.8 is bolder. |
| `table_border_gray` | bool | true | If `true`, borders and the scratch divider render in gray so they recede. If `false`, borders render in pure black for high contrast. |
| `index_depth` | integer | 2 | How many heading levels to print on the cover index. `1` shows only the cover + sheet titles. `2` also shows intermediate section entries such as Core Commands / Workflows / Gotchas. |
| `pdf_name` | string | `cheatsheet` | Output filename stem. `pdf_name = "dev cheatsheet"` writes `output/dev cheatsheet.pdf`. If `.pdf` is included, it is stripped before writing. Allowed characters: letters, numbers, spaces, dots, underscores, hyphens. |
| `margin_x_mm` | number | `14` | Horizontal page margin in millimetres. Replaces the hardcoded `margin: (x: 14mm, …)` in `assets/template.typ`. Tighten on smaller devices (e.g. `12` for reMarkable 2). |
| `margin_y_mm` | number | `16` | Vertical page margin in millimetres. Replaces the hardcoded `margin: (…, y: 16mm)` in `assets/template.typ`. |
| `gotchas_pt` | number | *(falls through to `body_pt`)* | Body text size for the Gotchas section. Leave blank in the preset to inherit `body_pt` via cross-key fall-through. Set explicitly (e.g. `gotchas_pt = 9` against `body_pt = 10`) when Gotchas should be sized differently from Workflows. |
| `leading` | number | `0.65` | Line height in em units applied to body text. `0.65` is Typst's default — no behaviour change from before this key existed. Lower values (`0.6`) tighten the page; higher values (`0.75`) give more breathing room. |
| `scratch_label` | string | `"Scratch space — annotate exceptions and gotchas you hit live here."` | Caption rendered above the scratch zone. Set to `""` (empty string) to hide the label. Multi-byte characters and em-dashes are preserved. |
| `workflow_glyph` | string | `"+"` | Single-character list marker for the Workflows section. **Note:** Typst's markup-mode list syntax renders both `+` and `-` as the same unordered list type, so this marker also applies to Gotchas. See `IMPLEMENTATION_PLAN.md` for the workaround discussion. |
| `gotcha_glyph` | string | `"-"` | Single-character list marker reserved for the Gotchas section. Currently a no-op visually for the same reason as `workflow_glyph`. Stored in the shim for future per-section list styling. |

## Presets

Four named presets are shipped in `presets/`. Pick one as the starting
point for `cheatsheet.toml`; override only what you want to change.

| Preset | Page | Body | Scratch | Borders | When to use |
|---|---|---|---|---|---|
| `paper-pro-default` | 180×240mm | 11pt | 40mm | 0.4pt gray | Default. Balanced for Paper Pro. Pick this if unsure. |
| `paper-pro-dense` | 180×240mm | 10pt | 30mm | 0.4pt gray | Fit more commands per page. Accept tighter pen room. |
| `rm2-comfortable` | 157×209mm | 12pt | 50mm | 0.4pt gray | reMarkable 2 (smaller screen). Bigger text, more pen room. |
| `high-contrast` | 180×240mm | 11pt | 40mm | 0.8pt black | Frontlight / sunlight / low-vision. Bolder black borders. |

## How overrides work

`scripts/materialize-config.sh` (run automatically before each build):

1. Reads `cheatsheet.toml`.
2. Loads the preset named in `preset = "..."` from `presets/<name>.toml`.
3. Applies any keys from `cheatsheet.toml` on top of the preset.
4. Writes the merged result to `assets/config.typ` as Typst `#let` constants.
5. `scripts/build.sh` reads `pdf_name` from that generated shim and writes `output/<pdf_name>.pdf`.

The template (`assets/template.typ`) reads from `assets/config.typ`, so
every Typst build sees a fully-resolved config. No runtime merging.

## Validation

If `cheatsheet.toml` is missing the `preset` key, or references a preset
file that doesn't exist, the materialize script exits non-zero with a
clear error message and the build is aborted.

If a value is the wrong type (e.g. `body_pt = "eleven"` instead of a
number), TOML parsing fails before the materialize script runs.

## See also

- `presets/default.toml` — canonical reference for every key
- `references/design-system.md` — why these knobs exist and what they trade off
- `.agents/skills/cheatsheet/SKILL.md` — the skill spec: menu, guided checklist, source workflow
