#!/usr/bin/env bash
# Render a side-by-side comparison of the current cheatsheet config vs a
# candidate preset. Useful before switching presets — see the visual
# difference without rebuilding or pushing to the device.
#
# Usage:
#   bash scripts/diff-preview.sh <preset-name>
#   bash scripts/diff-preview.sh rm2-comfortable
#
# Output:
#   output/diff/current-vs-<preset>-page-1.png
#
# What it does:
#   1. Builds a "candidate" PDF in a temp project (does NOT touch your
#      project files: cheatsheet.toml, assets/config.typ, output/*).
#   2. Renders both the current PDF and the candidate PDF to PNGs.
#   3. Embeds them in a contact-sheet Typst doc, side-by-side, with labels.
#   4. Renders the contact sheet to a single PNG you can open and eyeball.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CANDIDATE="${1:-}"
if [ -z "$CANDIDATE" ]; then
    cat >&2 <<EOF
usage: bash scripts/diff-preview.sh <preset-name>

available presets:
EOF
    for f in "$ROOT/presets"/*.toml; do
        [ "$(basename "$f")" = "default.toml" ] && continue
        echo "  - $(basename "$f" .toml)" >&2
    done
    exit 1
fi

# --- guards ---
TYPST_BIN="${TYPST:-typst}"
PDFTOPPM_BIN="${PDFTOPPM:-pdftoppm}"
if ! "$TYPST_BIN" --version >/dev/null 2>&1; then
    echo "typst not found (set TYPST or add to PATH)" >&2
    exit 1
fi
if ! "$PDFTOPPM_BIN" -v >/dev/null 2>&1; then
    echo "pdftoppm not found (set PDFTOPPM or add to PATH; install poppler)" >&2
    exit 1
fi
if [ ! -f "$ROOT/presets/${CANDIDATE}.toml" ]; then
    echo "error: candidate preset '$CANDIDATE' not found in presets/" >&2
    exit 1
fi

CURRENT_PDF="$ROOT/output/cheatsheet.pdf"
if [ ! -f "$CURRENT_PDF" ]; then
    echo "error: $CURRENT_PDF not found. Run 'bash scripts/build.sh' first." >&2
    exit 1
fi

# Read current preset name from cheatsheet.toml
CURRENT=$(grep -E '^preset\s*=' "$ROOT/cheatsheet.toml" \
    | head -n1 \
    | sed -E 's/^[^=]*=\s*//; s/\s*#.*$//; s/^"(.*)"$/\1/; s/[[:space:]]+//g')
if [ -z "$CURRENT" ]; then
    echo "error: could not read 'preset' from cheatsheet.toml" >&2
    exit 1
fi

if [ "$CURRENT" = "$CANDIDATE" ]; then
    echo "current and candidate are the same preset ($CURRENT); nothing to diff." >&2
    exit 1
fi

echo "current:  $CURRENT"
echo "candidate: $CANDIDATE"

# --- build candidate in a temp project ------------------------------------
# Place temp inside the project's output/ to avoid git-bash's /tmp translation
# issues when invoking pdftoppm.exe with POSIX paths.
TMP="$ROOT/output/.diff-tmp-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/assets" "$TMP/content"

# Copy project structure (skip the generated config.typ)
find "$ROOT/assets" -maxdepth 1 -name '*.typ' ! -name 'config.typ' \
    -exec cp {} "$TMP/assets/" \;
cp "$ROOT/content/"*.typ "$TMP/content/"

# Generate candidate shim directly from the preset file (don't touch project's
# assets/config.typ — the diff should be side-effect-free).
PRESET_FILE="$ROOT/presets/${CANDIDATE}.toml"
{
    echo '// AUTO-GENERATED for diff-preview — do not edit'
    echo '#let config = ('
    grep -E '^[a-z_]+\s*=' "$PRESET_FILE" \
        | grep -v '^preset' \
        | sed -E 's/^[[:space:]]+//' \
        | sed -E 's/[[:space:]]*#.*$//' \
        | sed -E 's/^([a-z_]+)[[:space:]]*=[[:space:]]*/  \1: /' \
        | sed -E 's/$/,/'
    echo ')'
} > "$TMP/assets/config.typ"

echo "compiling candidate PDF (in temp)..."
"$TYPST_BIN" compile --root "$TMP" "$TMP/content/main.typ" "$TMP/candidate.pdf"

# --- render both PDFs to PNGs in temp -------------------------------------
# pdftoppm pads page numbers to 2 digits (page-02.png, not page-2.png)
# regardless of total page count, so we use printf to format the lookup.
# Paths stay inside the project to avoid git-bash /tmp translation issues.
SAMPLE_PAGE=2
SAMPLE_PAD=$(printf "%02d" "$SAMPLE_PAGE")
mkdir -p "$TMP/pngs/current" "$TMP/pngs/candidate"
"$PDFTOPPM_BIN" -png -r 100 -f "$SAMPLE_PAGE" -l "$SAMPLE_PAGE" \
    "$CURRENT_PDF" "$TMP/pngs/current/page"
"$PDFTOPPM_BIN" -png -r 100 -f "$SAMPLE_PAGE" -l "$SAMPLE_PAGE" \
    "$TMP/candidate.pdf" "$TMP/pngs/candidate/page"

# --- build the contact sheet ----------------------------------------------
# Sample page 2 (first tool sheet — the cover is page 1, has no commands).
# pdftoppm pads output names according to total PDF page count, so a 14-page
# PDF produces page-02.png while a 9-page PDF produces page-2.png.
current_sample="$TMP/pngs/current/page-${SAMPLE_PAD}.png"
candidate_sample="$TMP/pngs/candidate/page-${SAMPLE_PAD}.png"
[ -f "$current_sample" ] || current_sample="$TMP/pngs/current/page-${SAMPLE_PAGE}.png"
[ -f "$candidate_sample" ] || candidate_sample="$TMP/pngs/candidate/page-${SAMPLE_PAGE}.png"
if [ ! -f "$current_sample" ] || [ ! -f "$candidate_sample" ]; then
    echo "error: page $SAMPLE_PAGE missing from one of the PDFs" >&2
    exit 1
fi
cp "$current_sample" "$TMP/pngs/current/sample.png"
cp "$candidate_sample" "$TMP/pngs/candidate/sample.png"

cat > "$TMP/pngs/contact-sheet.typ" <<EOF
#set page(width: 380mm, height: 280mm, margin: 8mm)
#set text(size: 10pt)
#set heading(numbering: none)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 8mm,
  align: center + horizon,
  [
    #align(center)[== *Current: ${CURRENT}*]
    #v(3mm)
    #image("current/sample.png", width: 100%)
  ],
  [
    #align(center)[== *Candidate: ${CANDIDATE}*]
    #v(3mm)
    #image("candidate/sample.png", width: 100%)
  ],
)
EOF

"$TYPST_BIN" compile --root "$TMP/pngs" "$TMP/pngs/contact-sheet.typ" "$TMP/pngs/contact-sheet.pdf"

# --- render to output PNG -------------------------------------------------
mkdir -p "$ROOT/output/diff"
OUT_BASE="$ROOT/output/diff/current-vs-${CANDIDATE}-page"
"$PDFTOPPM_BIN" -png -r 150 "$TMP/pngs/contact-sheet.pdf" "$OUT_BASE"

echo ""
echo "diff PNG: ${OUT_BASE}-1.png"
echo "open it to compare ${CURRENT} vs ${CANDIDATE} side-by-side"
