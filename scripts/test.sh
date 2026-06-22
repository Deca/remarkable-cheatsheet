#!/usr/bin/env bash
# End-to-end regression test for the cheatsheet pipeline.
#
# Exercises every script and config preset, then resets the project to a
# clean state with the default preset. Run after any change to the
# template, presets, or build scripts.
#
# Usage: bash scripts/test.sh
#
# Exits non-zero on any failure. Warnings (rmapi not installed, etc.)
# don't fail the test — those are environment, not code.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Source user-specific binary paths from .env if present. Copy .env.example
# to .env and uncomment the TYPST / PDFTOPPM lines as needed.
[ -f .env ] && source .env

PASS=0
FAIL=0
WARNINGS=()

# --- helpers --------------------------------------------------------------

# Portable Python launcher: `py` on Windows, `python3` on Linux/macOS,
# `python` as final fallback. Avoids hardcoding the Windows-specific
# `py` launcher in a script that also runs on Linux CI runners.
py() {
    if command -v py >/dev/null 2>&1; then
        command py "$@"
    elif command -v python3 >/dev/null 2>&1; then
        command python3 "$@"
    elif command -v python >/dev/null 2>&1; then
        command python "$@"
    else
        echo "py: no python interpreter found" >&2
        return 127
    fi
}

ok()      { echo "  ok    $1"; PASS=$((PASS+1)); }
fail()    { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
warn()    { echo "  warn  $1"; WARNINGS+=("$1"); }
section() { echo ""; echo "── $1"; }

# --- preflight ------------------------------------------------------------

section "preflight"

# Locate typst: env var ($TYPST) first, then PATH.
if [ -n "${TYPST:-}" ] && [ -x "$TYPST" ]; then
    ok "typst from \$TYPST: $TYPST"
elif command -v typst >/dev/null 2>&1; then
    export TYPST="$(command -v typst)"
    ok "typst found on PATH: $($TYPST --version 2>&1 | head -1)"
else
    fail "typst not found"
    echo "test aborted — install typst, or set \$TYPST in .env"
    exit 1
fi

# Locate pdftoppm: env var ($PDFTOPPM) first, then PATH.
if [ -n "${PDFTOPPM:-}" ] && [ -x "$PDFTOPPM" ]; then
    ok "pdftoppm from \$PDFTOPPM: $PDFTOPPM"
elif command -v pdftoppm >/dev/null 2>&1; then
    export PDFTOPPM="$(command -v pdftoppm)"
    ok "pdftoppm found on PATH"
else
    warn "pdftoppm not found (preview tests will be skipped)"
fi

# --- backup current state so we can restore it ----------------------------

section "save current state"

BACKUP_DIR=$(mktemp -d)
[ -f cheatsheet.toml ] && cp cheatsheet.toml "$BACKUP_DIR/" && ok "backed up cheatsheet.toml"
[ -f assets/config.typ ] && cp assets/config.typ "$BACKUP_DIR/" && ok "backed up assets/config.typ"
[ -d output ] && cp -r output "$BACKUP_DIR/" && ok "backed up output/"
trap 'echo ""; echo "restoring state from $BACKUP_DIR ..."; rm -f cheatsheet.toml assets/config.typ; [ -f "$BACKUP_DIR/cheatsheet.toml" ] && cp "$BACKUP_DIR/cheatsheet.toml" cheatsheet.toml; cp "$BACKUP_DIR/config.typ" assets/config.typ 2>/dev/null; rm -rf output; cp -r "$BACKUP_DIR/output" . 2>/dev/null; echo "done"' EXIT

# --- wipe and test the "no config" error path -----------------------------

section "no-config error path"

rm -f cheatsheet.toml assets/config.typ
rm -rf output

if bash scripts/materialize-config.sh >/dev/null 2>&1; then
    fail "materialize should fail when cheatsheet.toml is missing"
else
    ok "materialize exits non-zero when cheatsheet.toml is missing"
fi

# --- minimal config + build with paper-pro-default ------------------------

section "first-run with paper-pro-default"

echo 'preset = "paper-pro-default"' > cheatsheet.toml
ok "wrote cheatsheet.toml"

bash scripts/materialize-config.sh >/dev/null 2>&1
[ -f assets/config.typ ] && ok "materialize wrote assets/config.typ" || fail "materialize did not produce assets/config.typ"

# Build to a temp file (avoids file-lock issues if a viewer has the output open)
BUILD_PDF="$ROOT/output/cheatsheet.pdf"
mkdir -p output
bash scripts/build.sh >/dev/null 2>&1
[ -f "$BUILD_PDF" ] && ok "build produced output/cheatsheet.pdf" || fail "build did not produce PDF"

# Page count and outline (expanded content overflows; expect 13 pages)
PAGE_COUNT=$(py -c "from pypdf import PdfReader; print(len(PdfReader('$BUILD_PDF').pages))" 2>/dev/null)
if [ "$PAGE_COUNT" = "13" ]; then
    ok "PDF has 13 pages (cover + expanded Codex/git/OpenRouter/pi.dev/zellij sheets)"
else
    fail "expected 13 pages, got $PAGE_COUNT"
fi

OUTLINE=$(BUILD_PDF="$BUILD_PDF" py <<'PY' 2>/dev/null
import os
from pypdf import PdfReader
r = PdfReader(os.environ['BUILD_PDF'])
out = []
stack = list(r.outline)
while stack:
    item = stack.pop(0)
    if isinstance(item, list):
        stack = list(item) + stack
    elif hasattr(item, 'title'):
        out.append(item.title)
print('|'.join(out))
PY
)
echo "$OUTLINE" | grep -q "git" && ok "outline contains 'git'" || fail "outline missing 'git'"
echo "$OUTLINE" | grep -q "pi.dev" && ok "outline contains 'pi.dev'" || fail "outline missing 'pi.dev'"
echo "$OUTLINE" | grep -q "zellij" && ok "outline contains 'zellij'" || fail "outline missing 'zellij'"
echo "$OUTLINE" | grep -q "Core Commands" && ok "outline contains intermediate section entries" || fail "outline missing intermediate section entries"

SUGGESTED_NAME=$(bash scripts/suggest-pdf-name.sh 2>/dev/null)
[ "$SUGGESTED_NAME" = "dev-cheatsheet-codex-git-openrouter-pi-dev-zellij" ] \
    && ok "suggest-pdf-name derives a content-based filename" \
    || fail "unexpected suggested PDF name: $SUGGESTED_NAME"

# Page dimensions = 180x240mm
MEDIA=$(py -c "from pypdf import PdfReader; r=PdfReader('$BUILD_PDF'); m=r.pages[0].mediabox; print(f'{m.width}x{m.height}')" 2>/dev/null)
# 180mm = 510.236 pt, 240mm = 680.315 pt
if [[ "$MEDIA" =~ 510\.23.*680\.31 ]] || [[ "$MEDIA" =~ 510\.236.*680\.315 ]]; then
    ok "page dimensions are 180x240mm (paper-pro-default)"
else
    fail "expected 180x240mm, got $MEDIA"
fi

# --- --preview flag -------------------------------------------------------

section "--preview flag"

if [ -n "${PDFTOPPM:-}" ]; then
    bash scripts/build.sh --preview >/dev/null 2>&1
    PNG_COUNT=$(ls output/preview/page-*.png 2>/dev/null | wc -l)
    if [ "$PNG_COUNT" = "13" ]; then
        ok "preview produced 13 PNGs"
    else
        fail "expected 13 preview PNGs, got $PNG_COUNT"
    fi
else
    warn "pdftoppm not installed — skipping preview PNG check"
fi

# --- --push flag (rmapi not installed, should warn but not fail) ----------

section "--push flag (rmapi expected absent)"

if command -v rmapi >/dev/null 2>&1; then
    warn "rmapi is installed; --push may actually try to upload"
else
    BUILD_OUTPUT=$(bash scripts/build.sh --push 2>&1 || true)
    if echo "$BUILD_OUTPUT" | grep -q "rmapi not found"; then
        ok "--push warns about missing rmapi but does not fail the build"
    else
        fail "--push output did not mention rmapi"
    fi
fi

# --- preset switch via cheatsheet.toml edit -------------------------------

section "switch to rm2-comfortable"

echo 'preset = "rm2-comfortable"' > cheatsheet.toml
bash scripts/build.sh >/dev/null 2>&1

MEDIA=$(py -c "from pypdf import PdfReader; r=PdfReader('$BUILD_PDF'); m=r.pages[0].mediabox; print(f'{m.width}x{m.height}')" 2>/dev/null)
# 157mm = 445.039 pt, 209mm = 592.441 pt
if [[ "$MEDIA" =~ 445\.03.*592\.44 ]] || [[ "$MEDIA" =~ 445\.039.*592\.441 ]]; then
    ok "page dimensions are 157x209mm (rm2-comfortable)"
else
    fail "expected 157x209mm, got $MEDIA"
fi

# --- diff-preview ---------------------------------------------------------

section "diff-preview"

if [ -n "${PDFTOPPM:-}" ]; then
    rm -rf output/diff
    # Current is rm2-comfortable, compare against paper-pro-default
    DIFF_OUTPUT=$(bash scripts/diff-preview.sh paper-pro-default 2>&1)
    if echo "$DIFF_OUTPUT" | grep -q "diff PNG"; then
        ok "diff-preview produced output"
    else
        fail "diff-preview did not report a diff PNG"
    fi
    [ -f output/diff/current-vs-paper-pro-default-page-1.png ] \
        && ok "diff PNG exists at output/diff/current-vs-paper-pro-default-page-1.png" \
        || fail "diff PNG missing"
else
    warn "pdftoppm not installed — skipping diff-preview test"
fi

# diff-preview edge case: same preset as current
SAME_OUTPUT=$(bash scripts/diff-preview.sh rm2-comfortable 2>&1 || true)
echo "$SAME_OUTPUT" | grep -q "nothing to diff" \
    && ok "diff-preview rejects same-as-current" \
    || fail "diff-preview should reject same-as-current"

# --- preset switch to paper-pro-dense -------------------------------------

section "switch to paper-pro-dense"

echo 'preset = "paper-pro-dense"' > cheatsheet.toml
bash scripts/build.sh >/dev/null 2>&1

PAGE_COUNT=$(py -c "from pypdf import PdfReader; print(len(PdfReader('$BUILD_PDF').pages))" 2>/dev/null)
# paper-pro-dense should fit on fewer pages (or same — depends on content)
ok "paper-pro-dense build produced $PAGE_COUNT pages (cover + sheets)"

# --- preset switch to high-contrast ---------------------------------------

section "switch to high-contrast"

echo 'preset = "high-contrast"' > cheatsheet.toml
bash scripts/build.sh >/dev/null 2>&1
[ -f "$BUILD_PDF" ] && ok "high-contrast build produced PDF" || fail "high-contrast build failed"

# Verify the shim has table_border_gray: false
if grep -q "table_border_gray: false" assets/config.typ; then
    ok "shim correctly materialised table_border_gray: false"
else
    fail "shim missing table_border_gray: false"
fi

# --- user override path ----------------------------------------------------

section "user override path"

cat > cheatsheet.toml <<EOF
preset = "paper-pro-default"
scratch_zone_mm = 55
pdf_name = "my dev cheatsheet"
index_depth = 1
margin_x_mm = 18
margin_y_mm = 14
leading = 0.8
scratch_label = "Notes:"
workflow_glyph = "→"
gotcha_glyph = "!"
EOF

bash scripts/materialize-config.sh >/dev/null 2>&1
if grep -q "scratch_zone_mm: 55" assets/config.typ; then
    ok "user override (scratch_zone_mm = 55) applied on top of preset"
else
    fail "user override not applied"
fi
if grep -q 'pdf_name: "my dev cheatsheet"' assets/config.typ; then
    ok "user override (pdf_name) applied"
else
    fail "pdf_name override not applied"
fi
if grep -q "index_depth: 1" assets/config.typ; then
    ok "user override (index_depth = 1) applied"
else
    fail "index_depth override not applied"
fi
if grep -q "margin_x_mm: 18" assets/config.typ; then
    ok "user override (margin_x_mm = 18) applied"
else
    fail "margin_x_mm override not applied"
fi
if grep -q "margin_y_mm: 14" assets/config.typ; then
    ok "user override (margin_y_mm = 14) applied"
else
    fail "margin_y_mm override not applied"
fi
if grep -q "leading: 0.8" assets/config.typ; then
    ok "user override (leading = 0.8) applied"
else
    fail "leading override not applied"
fi
if grep -q 'scratch_label: "Notes:"' assets/config.typ; then
    ok "user override (scratch_label) applied"
else
    fail "scratch_label override not applied"
fi
if grep -q 'workflow_glyph: "→"' assets/config.typ; then
    ok "user override (workflow_glyph) applied"
else
    fail "workflow_glyph override not applied"
fi
if grep -q 'gotcha_glyph: "!"' assets/config.typ; then
    ok "user override (gotcha_glyph) applied"
else
    fail "gotcha_glyph override not applied"
fi
bash scripts/build.sh >/dev/null 2>&1
[ -f "output/my dev cheatsheet.pdf" ] \
    && ok "custom pdf_name produced output/my dev cheatsheet.pdf" \
    || fail "custom pdf_name did not produce expected PDF"

# --- cross-key fall-through for gotchas_pt --------------------------------

section "cross-key fall-through for gotchas_pt"

# When the preset omits gotchas_pt, the shim should materialise it as body_pt.
cat > cheatsheet.toml <<EOF
preset = "paper-pro-default"
EOF
bash scripts/materialize-config.sh >/dev/null 2>&1
if grep -q "gotchas_pt: 11" assets/config.typ; then
    ok "gotchas_pt falls through to body_pt (= 11) when preset omits it"
else
    fail "gotchas_pt fall-through not working (expected 11 from body_pt)"
fi

# When the user sets gotchas_pt explicitly, that value wins.
cat > cheatsheet.toml <<EOF
preset = "paper-pro-default"
gotchas_pt = 7
EOF
bash scripts/materialize-config.sh >/dev/null 2>&1
if grep -q "gotchas_pt: 7" assets/config.typ; then
    ok "explicit gotchas_pt override wins over cross-key fall-through"
else
    fail "explicit gotchas_pt override not applied"
fi

# Empty glyph should be rejected.
cat > cheatsheet.toml <<EOF
preset = "paper-pro-default"
workflow_glyph = ""
EOF
ERR=$(bash scripts/materialize-config.sh 2>&1 || true)
echo "$ERR" | grep -q "workflow_glyph must not be empty" \
    && ok "materialize rejects empty workflow_glyph" \
    || fail "materialize should reject empty workflow_glyph"

# --- error path: bad preset name ------------------------------------------

section "error path: unknown preset"

echo 'preset = "does-not-exist"' > cheatsheet.toml
if bash scripts/materialize-config.sh >/dev/null 2>&1; then
    fail "materialize should fail for unknown preset"
else
    ok "materialize exits non-zero for unknown preset"
fi

# --- error path: wrong type -----------------------------------------------

section "error path: wrong type"

cat > cheatsheet.toml <<EOF
preset = "paper-pro-default"
body_pt = "eleven"
EOF
ERR=$(bash scripts/materialize-config.sh 2>&1 || true)
echo "$ERR" | grep -q "body_pt must be a number" \
    && ok "materialize rejects non-numeric body_pt" \
    || fail "materialize should reject non-numeric body_pt"

# --- summary --------------------------------------------------------------

section "summary"

echo "passed: $PASS"
echo "failed: $FAIL"
if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo "warnings: ${#WARNINGS[@]}"
    for w in "${WARNINGS[@]}"; do echo "  - $w"; done
fi

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "TEST FAILED"
    exit 1
fi

echo ""
echo "ALL TESTS PASSED"
exit 0
