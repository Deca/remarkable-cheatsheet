#!/usr/bin/env bash
# Build the cheatsheet PDF from cheatsheet.toml + content/*.typ.
#
# Usage:
#   bash scripts/build.sh              compile PDF only
#   bash scripts/build.sh --preview    compile + render PNG previews
#   bash scripts/build.sh --push       compile + upload to reMarkable cloud
#   bash scripts/build.sh --preview --push   both
#
# Steps run in order:
#   1. Materialise config: cheatsheet.toml + preset → assets/config.typ
#   2. Compile: assets/template.typ + content/*.typ → output/cheatsheet.pdf
#   3. Preview (if --preview): render output/cheatsheet.pdf → output/preview/*.png
#   4. Push (if --push): upload output/cheatsheet.pdf via rmapi

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Source user-specific binary paths from .env if present. Copy .env.example
# to .env and uncomment the TYPST / PDFTOPPM lines as needed.
[ -f "$ROOT/.env" ] && source "$ROOT/.env"

# --- parse flags -----------------------------------------------------------
PREVIEW=0
PUSH=0
for arg in "$@"; do
    case "$arg" in
        --preview) PREVIEW=1 ;;
        --push)    PUSH=1 ;;
        -h|--help)
            sed -n '2,15p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "error: unknown flag '$arg' (use --help)" >&2
            exit 1
            ;;
    esac
done

# --- guards ----------------------------------------------------------------
# Honour explicit override for testability and Windows quirks where
# winget-installed binaries may not be on PATH in the current shell.
if [ -z "${TYPST:-}" ]; then
    if ! command -v typst >/dev/null 2>&1; then
        echo "typst not found on PATH. Install it: brew install typst | cargo install typst-cli | or https://typst.app" >&2
        exit 1
    fi
    TYPST=typst
fi

# --- step 1: materialise config --------------------------------------------
bash "$ROOT/scripts/materialize-config.sh"

# --- step 2: compile PDF ----------------------------------------------------
mkdir -p "$ROOT/output"
PDF_NAME=$(grep -E '^[[:space:]]*pdf_name:' "$ROOT/assets/config.typ" \
    | head -n1 \
    | sed -E 's/^[^:]*:[[:space:]]*//; s/,$//; s/^"(.*)"$/\1/')
[ -n "$PDF_NAME" ] || PDF_NAME=cheatsheet
PDF="$ROOT/output/${PDF_NAME}.pdf"
"$TYPST" compile --root "$ROOT" "$ROOT/content/main.typ" "$PDF"
echo "Built $PDF"

# --- step 3: preview (render PNGs) -----------------------------------------
if [ "$PREVIEW" -eq 1 ]; then
    PDFTOPPM_BIN="${PDFTOPPM:-pdftoppm}"
    if "$PDFTOPPM_BIN" -v >/dev/null 2>&1; then
        PREVIEW_DIR="$ROOT/output/preview"
        mkdir -p "$PREVIEW_DIR"
        rm -f "$PREVIEW_DIR"/page-*.png
        "$PDFTOPPM_BIN" -png -r 150 "$PDF" "$PREVIEW_DIR/page"
        PNG_COUNT=$(ls "$PREVIEW_DIR"/page-*.png 2>/dev/null | wc -l)
        echo "Preview: $PNG_COUNT PNGs in $PREVIEW_DIR"
    else
        echo "warning: pdftoppm not found; skipping --preview." >&2
        echo "  install poppler: brew install poppler | apt install poppler-utils | winget install oschwartz10612.Poppler" >&2
    fi
fi

# --- step 4: push to reMarkable cloud -------------------------------------
if [ "$PUSH" -eq 1 ]; then
    if ! command -v rmapi >/dev/null 2>&1; then
        echo "warning: rmapi not found; skipping --push." >&2
        echo "  see references/sync.md for setup." >&2
    else
        PDF="$PDF" bash "$ROOT/scripts/push.sh"
    fi
fi
