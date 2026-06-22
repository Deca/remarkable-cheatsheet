#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDF="${PDF:-}"
if [ -z "$PDF" ]; then
  if [ -f "$ROOT/assets/config.typ" ]; then
    PDF_NAME=$(grep -E '^[[:space:]]*pdf_name:' "$ROOT/assets/config.typ" \
      | head -n1 \
      | sed -E 's/^[^:]*:[[:space:]]*//; s/,$//; s/^"(.*)"$/\1/')
  fi
  PDF_NAME="${PDF_NAME:-cheatsheet}"
  PDF="$ROOT/output/${PDF_NAME}.pdf"
fi

if ! command -v rmapi >/dev/null 2>&1; then
  echo "rmapi not found. See references/sync.md for setup." >&2
  exit 1
fi

if [ ! -f "$PDF" ]; then
  echo "$PDF doesn't exist yet — run scripts/build.sh first." >&2
  exit 1
fi

rmapi put "$PDF" /
echo "Pushed $PDF to reMarkable cloud root."
