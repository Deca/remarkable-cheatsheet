#!/usr/bin/env bash
# materialise cheatsheet.toml + presets/<name>.toml into assets/config.typ
# (a Typst file with the merged values as #let constants).
#
# This runs automatically at the top of scripts/build.sh. You only need
# to invoke it by hand if you want to inspect the resolved config without
# triggering a full compile.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CONFIG="$ROOT/cheatsheet.toml"
PRESETS_DIR="$ROOT/presets"
SHIM="$ROOT/assets/config.typ"

# --- helpers --------------------------------------------------------------

# Read one key from a simple TOML file. Returns empty if the key is absent.
# Handles: key = value / key = "value" / key = true / key = 0.4
# Strips inline comments after the value. Whitespace tolerant.
toml_get() {
    local file="$1" key="$2"
    [ -f "$file" ] || return 1
    grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" \
        | head -n1 \
        | sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]*#.*$//' \
        | sed -E 's/^"(.*)"$/\1/; s/^['"'"'](.*)['"'"']$/\1/' \
        | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
    [ ${PIPESTATUS[0]} -eq 0 ]
}

# --- guard: cheatsheet.toml must exist ------------------------------------

if [ ! -f "$CONFIG" ]; then
    cat >&2 <<EOF
error: $CONFIG not found.

This is a fresh project. Either:
  - Run the skill's first-run wizard (/cheatsheet)
  - Or copy a preset manually:
      cp presets/paper-pro-default.toml cheatsheet.toml
      bash scripts/build.sh
EOF
    exit 1
fi

# --- resolve preset name ---------------------------------------------------

USER_PRESET=$(toml_get "$CONFIG" preset)
if [ -z "$USER_PRESET" ]; then
    echo "error: cheatsheet.toml has no 'preset' key." >&2
    exit 1
fi

PRESET_FILE="$PRESETS_DIR/${USER_PRESET}.toml"
if [ ! -f "$PRESET_FILE" ]; then
    echo "error: preset '$USER_PRESET' not found at $PRESET_FILE" >&2
    echo "available presets:" >&2
    for f in "$PRESETS_DIR"/*.toml; do
        [ "$(basename "$f")" = "default.toml" ] && continue
        echo "  - $(basename "$f" .toml)" >&2
    done
    exit 1
fi

# --- merge: preset is base, user overrides if non-empty --------------------

merged() {
    local key="$1"
    local user_val preset_val
    user_val=$(toml_get "$CONFIG" "$key")
    preset_val=$(toml_get "$PRESET_FILE" "$key")
    if [ -n "$user_val" ]; then
        echo "$user_val"
    else
        echo "$preset_val"
    fi
}

PAGE_W=$(merged page_width_mm)
PAGE_H=$(merged page_height_mm)
BODY_PT=$(merged body_pt)
SCRATCH_MM=$(merged scratch_zone_mm)
BORDER_PT=$(merged table_border_pt)
BORDER_GRAY=$(merged table_border_gray)
INDEX_DEPTH=$(merged index_depth)
PDF_NAME=$(merged pdf_name)
MARGIN_X=$(merged margin_x_mm)
MARGIN_Y=$(merged margin_y_mm)
GOTCHAS_PT=$(merged gotchas_pt)
LEADING=$(merged leading)
SCRATCH_LABEL=$(merged scratch_label)
WORKFLOW_GLYPH=$(merged workflow_glyph)
GOTCHA_GLYPH=$(merged gotcha_glyph)
[ -n "$INDEX_DEPTH" ] || INDEX_DEPTH=2
[ -n "$PDF_NAME" ] || PDF_NAME=cheatsheet
PDF_NAME="${PDF_NAME%.pdf}"

# Cross-key fall-through: if a preset omits `gotchas_pt`, default to `body_pt`.
# Presets that want Gotchas sized differently from Workflows set the value
# explicitly in their .toml file.
[ -n "$GOTCHAS_PT" ] || GOTCHAS_PT="$BODY_PT"

# --- validate --------------------------------------------------------------

for entry in "page_width_mm:$PAGE_W" \
             "page_height_mm:$PAGE_H" \
             "body_pt:$BODY_PT" \
             "scratch_zone_mm:$SCRATCH_MM" \
             "table_border_pt:$BORDER_PT" \
             "index_depth:$INDEX_DEPTH" \
             "margin_x_mm:$MARGIN_X" \
             "margin_y_mm:$MARGIN_Y" \
             "gotchas_pt:$GOTCHAS_PT" \
             "leading:$LEADING"; do
    name="${entry%%:*}"
    val="${entry#*:}"
    if ! [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "error: $name must be a number, got '$val'" >&2
        exit 1
    fi
done

BORDER_GRAY=$(echo "$BORDER_GRAY" | tr '[:upper:]' '[:lower:]')
if [ "$BORDER_GRAY" != "true" ] && [ "$BORDER_GRAY" != "false" ]; then
    echo "error: table_border_gray must be true or false, got '$BORDER_GRAY'" >&2
    exit 1
fi

if ! [[ "$INDEX_DEPTH" =~ ^[0-9]+$ ]] || [ "$INDEX_DEPTH" -lt 1 ] || [ "$INDEX_DEPTH" -gt 4 ]; then
    echo "error: index_depth must be an integer from 1 to 4, got '$INDEX_DEPTH'" >&2
    exit 1
fi

if ! [[ "$PDF_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._[:space:]-]*$ ]]; then
    echo "error: pdf_name must start with a letter or number and contain only letters, numbers, spaces, dots, underscores, or hyphens; got '$PDF_NAME'" >&2
    exit 1
fi

# Glyphs must be non-empty (Typst would render an empty marker as a
# missing bullet, which is silently broken).
if [ -z "$WORKFLOW_GLYPH" ]; then
    echo "error: workflow_glyph must not be empty" >&2
    exit 1
fi
if [ -z "$GOTCHA_GLYPH" ]; then
    echo "error: gotcha_glyph must not be empty" >&2
    exit 1
fi

# --- write the shim --------------------------------------------------------

mkdir -p "$(dirname "$SHIM")"

cat > "$SHIM" <<EOF
// AUTO-GENERATED by scripts/materialize-config.sh — do not edit by hand.
// Edit cheatsheet.toml or the preset file in presets/ instead.
// Active preset: ${USER_PRESET}

#let config = (
  page_width_mm: ${PAGE_W},
  page_height_mm: ${PAGE_H},
  body_pt: ${BODY_PT},
  scratch_zone_mm: ${SCRATCH_MM},
  table_border_pt: ${BORDER_PT},
  table_border_gray: ${BORDER_GRAY},
  index_depth: ${INDEX_DEPTH},
  pdf_name: "${PDF_NAME}",
  margin_x_mm: ${MARGIN_X},
  margin_y_mm: ${MARGIN_Y},
  gotchas_pt: ${GOTCHAS_PT},
  leading: ${LEADING},
  scratch_label: "${SCRATCH_LABEL}",
  workflow_glyph: "${WORKFLOW_GLYPH}",
  gotcha_glyph: "${GOTCHA_GLYPH}",
)
EOF

echo "materialised $SHIM (preset: ${USER_PRESET})"
