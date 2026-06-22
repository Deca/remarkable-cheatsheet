---
name: remarkable-cheatsheet
description: Maintain a personal library of quick-reference sheets for tools, programs, languages, frameworks, games, workflows, and other reference-heavy subjects, then compile them into one bookmarked PDF designed for e-ink reading and pen annotation on a reMarkable tablet. Configure appearance via TOML presets, render PNG previews, diff presets side-by-side, suggest content-based PDF names, and generate new sheets from user-provided docs or researched authoritative sources.
---

# reMarkable Cheatsheet Pipeline

A **sheet** is one subject's reference unit: a title, a commands/keybindings/API/concepts table, a workflows section, a gotchas section, and a blank scratch zone for pen annotation. The library is a folder of sheets compiled into one PDF with a bookmark per sheet.

The pipeline has three configuration surfaces:

- `cheatsheet.toml` — the user's per-project config (one line: `preset = "..."`, plus any overrides).
- `presets/*.toml` — four named starting points, one per supported persona.
- `assets/config.typ` — generated Typst shim. Do not edit by hand; regenerated on every build.

The build script (`scripts/build.sh`) runs `scripts/materialize-config.sh` automatically before compiling. This script reads `cheatsheet.toml`, loads the active preset, applies any overrides, and writes the merged result to `assets/config.typ` as Typst `#let` constants.

## Invocation behavior

There are two modes:

1. **Menu mode** — when the user types `/cheatsheet`, asks to configure, asks what options exist, or gives a vague request. Show the full menu below.
2. **Guided concrete-task mode** — when the user invokes the skill with a concrete request, e.g. `/skill:remarkable-cheatsheet make a cheatsheet for Codex <url>`, do not jump straight to edits. Instead, run the short guided checklist below, unless the user explicitly says "just do it", "no questions", or equivalent.

## Guided concrete-task checklist

Use this before editing files when the user already supplied a concrete subject/source request. Keep it short and default-heavy; the point is guidance, not interrogation.

1. **Restate detected request.** Example: "I found two requested sheets: Codex from <url>, OpenRouter from <url>."
2. **Ask scope/output choice.** Offer:
   - **Focused PDF** — include only the requested/new sheets.
   - **Library PDF** — keep all existing sheets and add the new ones. Default to library PDF if unsure.
3. **Ask main PDF settings.** Present current/default values and let the user accept all with one reply:
   - Device/preset: `paper-pro-dense`, `paper-pro-default`, `rm2-comfortable`, or `high-contrast`.
   - Index depth: `2` for tool titles + section entries; `1` for compact tool-title-only index.
   - PDF name: suggest one via `bash scripts/suggest-pdf-name.sh` or from requested subjects.
   - Preview: build with `--preview`? Default yes.
   - Push: upload with `--push`? Default no unless requested.
4. **Ask source mode only if unclear.** If URLs/files were provided, use them. If not, ask whether to research official/reputable docs.
5. **Confirm plan in one sentence.** Example: "Plan: add Codex and OpenRouter, keep existing library sheets, use `paper-pro-dense`, index depth 2, write `output/ai-dev-cheatsheet-codex-openrouter.pdf`, and build preview. Proceed?"
6. **Then act.** After confirmation, create/update sheets, config, includes, build, and report output path/page count.

If the user says "accept defaults", use: library PDF, current preset, `index_depth = 2`, content-based `pdf_name`, `--preview`, no push.

## Slash command: `/cheatsheet`

When the user types `/cheatsheet` (or asks in natural language: "make a cheatsheet", "add a cheatsheet for X", "configure the cheatsheet", "switch preset", "show diff", "rebuild", "what preset am I using?"), respond with this numbered menu:

```
1. Add/generate sheet  — create or update a sheet for any tool/program/language/framework/game/etc.
2. Switch preset       — choose one of the 4 named presets
3. Customize           — edit cheatsheet.toml by hand
4. Show diff           — pick a candidate, render side-by-side PNG
5. Build               — bash scripts/build.sh [--preview] [--push]
6. Show current        — print effective config (preset + overrides merged)
7. Set PDF name        — suggest/edit output filename based on included tools
8. Quit
```

Wait for the user's reply in natural language. Map short forms:

| User says | Maps to |
|---|---|
| "add", "generate", "new sheet", "make a cheatsheet", "sheet for", "1" | option 1 |
| "switch", "change preset", "2" | option 2 |
| "edit", "customize", "open config", "3" | option 3 |
| "diff", "compare", "preview switch", "4" | option 4 |
| "build", "compile", "render", "5" | option 5 |
| "show", "current", "what preset", "6" | option 6 |
| "name", "rename", "pdf name", "filename", "7" | option 7 |
| "quit", "cancel", "never mind", "8" | option 8 |

After the user picks, narrate what you're about to do before doing it (e.g. "Switching to `rm2-comfortable` will change page size to 157×209mm and bump body text to 12pt. Confirm?"). For add/generate tasks, also ask the main PDF settings from the guided concrete-task checklist unless already answered. Then act and report the result. The skill is the conversational router; the actual work is in real shell scripts — never duplicate logic from scripts in this skill body.

### Option details

**1. Add/generate sheet.** Run the guided source workflow below. The goal is to produce or update one `content/<slug>.typ` sheet from user-provided links/notes or researched authoritative sources, then include it in `content/main.typ` and offer to update `pdf_name`.

**2. Switch preset.** List the 4 named presets with a one-line description of each (copy from the table below). Ask which one. Confirm the persona-defining values will change. On confirmation, overwrite `cheatsheet.toml` with `preset = "<name>"`, run `bash scripts/materialize-config.sh`, and offer to run a build.

**3. Customize.** Open `cheatsheet.toml` in the user's editor. After they save and close, re-read the file, validate it (run `bash scripts/materialize-config.sh` — it exits non-zero on type errors with a clear message), and offer to build.

**4. Show diff.** Ask "compare against which preset?" then run `bash scripts/diff-preview.sh <name>`. Print the path to the rendered PNG so the user can open it. The PNG lands at `output/diff/current-vs-<name>-page-1.png`.

**5. Build.** Default: `bash scripts/build.sh`. If the user asks for previews too, add `--preview` (renders one PNG per page to `output/preview/`). If they want to push to the device, add `--push` (calls `scripts/push.sh` which uses `rmapi`). Report the output file path and page count.

**6. Show current.** Run `bash scripts/materialize-config.sh` (idempotent — just re-reads and writes the shim) then print the contents of `assets/config.typ`. That file shows the effective values after preset + user overrides.

**7. Set PDF name.** Run `bash scripts/suggest-pdf-name.sh` and show the suggested name. Ask whether to use it or enter a different filename stem. Preserve the current `preset` and other overrides in `cheatsheet.toml`; add or update only `pdf_name = "..."`. Then run `bash scripts/materialize-config.sh` to validate and offer to build.

**8. Quit.** Acknowledge and stop.

## Guided source workflow for adding a sheet

Use this whenever the user wants a cheatsheet for a new subject: a CLI tool, desktop program, programming language, framework, library, game, workflow, hardware device, or any other reference-worthy domain.

1. **Clarify the target.** Ask for:
   - Subject name.
   - Subject type: tool / program / language / framework / library / game / workflow / other.
   - Intended use: beginner quickstart, daily reference, advanced operator notes, troubleshooting, keybindings, commands/API, or mixed.
   - Preferred title and slug if they care; otherwise derive a filesystem-safe slug.
2. **Ask for sources.** Offer three source modes:
   - **User docs:** user provides one or more URLs, files, screenshots, or notes.
   - **Agent research:** user gives only the subject; agent finds official docs or reputable references.
   - **Hybrid:** user provides a starting URL and agent fills gaps from official/reputable docs.
3. **Research rules.** Prefer official documentation first. For code/API/framework/library questions, use `code_search` for concrete docs/examples. For current general documentation, use `web_search` or `fetch_content` on user-provided URLs. If sources conflict, preserve the official behavior and mention uncertainty rather than guessing.
4. **Scope before writing.** Summarize the proposed sheet sections in one short paragraph and ask for confirmation if the subject is broad. For example, a language/framework may need a narrow scope (`Python packaging`, `React hooks`, `Docker Compose`) instead of a giant generic sheet.
5. **Create or update the sheet.** Use `assets/skeleton.typ` and `references/tool-sheet-template.md`. Keep the canonical structure:
   - `== Core Commands` or domain-appropriate equivalent (commands, keybindings, API calls, concepts, controls).
   - `== Workflows` for real tasks the user will perform.
   - `== Gotchas` for failure modes, edge cases, version traps, or game mechanics that are easy to forget.
6. **Include it.** Add `#include "<slug>.typ"` to `content/main.typ`, alphabetically unless the user asks for a custom order.
7. **Name the PDF.** Run `bash scripts/suggest-pdf-name.sh`. If the generated library is clearly content-specific, offer to set `pdf_name` to that suggestion (or a user-edited version). Do not silently rename without confirmation.
8. **Validate.** Run `bash scripts/build.sh --preview` when feasible. Report the output PDF path, page count, and preview directory.

Important: the agent must not invent detailed commands/API/keybindings/game mechanics without a source unless the user explicitly asks for a rough draft. If no authoritative source can be found, state that and ask for a URL or notes.

## First-run wizard

At the start of any session, check whether `cheatsheet.toml` exists at the project root. If not, this is a fresh project — run the first-run wizard:

1. Acknowledge: "No cheatsheet.toml yet. Let's pick a starting preset."
2. Ask which device they're targeting: reMarkable Paper Pro (11.8", 180×240mm) or reMarkable 2 (10.3", 157×209mm). If unsure, default to Paper Pro.
3. Map device + reading preference to one of the 4 presets (see table below). Default to `paper-pro-default` if no preference expressed.
4. Optionally offer a diff preview against another preset before committing (uses option 3 above).
5. Write `cheatsheet.toml` containing `preset = "<name>"`.
6. Run `bash scripts/materialize-config.sh` to validate.
7. Offer to run `bash scripts/build.sh` (and optionally `--preview`).

Do not run the wizard again in the same session once the user has chosen — they can switch presets later via the slash command.

## Presets

| Preset | Page | Body | Scratch | Borders | When to use |
|---|---|---|---|---|---|
| `paper-pro-default` | 180×240mm | 11pt | 40mm | 0.4pt gray | Default. Balanced for Paper Pro. |
| `paper-pro-dense` | 180×240mm | 10pt | 30mm | 0.4pt gray | Fit more commands per page. |
| `rm2-comfortable` | 157×209mm | 12pt | 50mm | 0.4pt gray | reMarkable 2. Bigger text, more pen room. |
| `high-contrast` | 180×240mm | 11pt | 40mm | 0.8pt black | Frontlight / sunlight / low-vision. |

Full schema in `references/config.md`. Per-preset rationale in `presets/<name>.toml` (each file's comments explain its trade-offs).

## Adding or updating a tool sheet

1. Check `content/` for an existing `<tool-slug>.typ`. If updating, edit it in place — skip to step 5.
2. If new, copy `assets/skeleton.typ` to `content/<tool-slug>.typ`. Fill in every section using `references/tool-sheet-template.md` as the checklist. Don't invent new sections, and don't skip Gotchas even for a one-liner — that section is what makes this better than a generic cheatsheet pulled off the internet.
3. Add `#include "<tool-slug>.typ"` to `content/main.typ`, positioned alphabetically unless told otherwise.
4. The cover page (`content/index.typ`) auto-collects headings via configured `index_depth` — no manual entry needed. Default `index_depth = 2` prints sheet titles plus intermediate entries such as Core Commands / Workflows / Gotchas. Set `index_depth = 1` in `cheatsheet.toml` for a compact sheet-title-only cover index. The new sheet's title appears in the PDF outline automatically.

**Completion criterion**: the new include compiles (step 5 of build) and the tool's title appears in the PDF outline.

## Building the PDF

5. Run `bash scripts/build.sh`. Optionally add `--preview` (render PNG previews via `pdftoppm` after compile) or `--push` (upload to reMarkable cloud via `rmapi`). To customize the output filename, set `pdf_name = "dev cheatsheet"` in `cheatsheet.toml`; the build writes `output/dev cheatsheet.pdf`. For a content-based suggestion, run `bash scripts/suggest-pdf-name.sh`.
6. Verify: page count should equal `(number of tool sheets) + 1` (the cover) plus any spillover pages from overflow sheets, and the PDF's outline should list every tool sheet by title. If a sheet is missing from the outline, its heading was nested under the wrong level — `tool-sheet()` expects a single top-level heading, see the skeleton.

The build script handles missing tools gracefully: if `pdftoppm` (poppler) isn't installed, `--preview` prints a warning and skips but the build still succeeds. If `rmapi` isn't installed, `--push` warns and skips. The build only fails if `typst` itself is missing or there's a Typst compile error.

If `typst` isn't on PATH, tell the user to install it (`brew install typst`, `cargo install typst-cli`, or the static binary from typst.app) rather than substituting Pandoc or LaTeX — the template uses Typst-specific layout functions and won't translate.

## Syncing to the device (optional)

7. Either run `bash scripts/build.sh --push` (compile + push in one step) or run `bash scripts/push.sh` after a successful build. If `rmapi` isn't configured, point the user at `references/sync.md` rather than walking through rmapi setup inline — it's a one-time setup, not part of this loop.

## Design rules

Full rationale is in `references/design-system.md`; the load-bearing ones to never violate:

- One `tool-sheet()` call per file, exactly one `pagebreak` (the template inserts it) — never hand-roll a page break elsewhere, it desyncs the bookmarks from the pages.
- 10–11pt body text minimum; e-ink doesn't forgive smaller.
- No color-only distinctions — the reMarkable 2 is grayscale. Use weight or borders to separate table rows or callouts, not hue.
- Never shrink the scratch zone to fit more content. If a sheet overflows, split it across two pages instead.
- Don't hardcode visual values in `assets/template.typ`. Every persona-defining value lives in `cheatsheet.toml` + `presets/*.toml`. New knobs belong in the config schema, not as magic numbers in the template.

## Device profile

`assets/template.typ` reads page dimensions from `assets/config.typ`, which is materialised from `cheatsheet.toml` + the active preset. The shipped presets cover the reMarkable Paper Pro (180×240mm) and reMarkable 2 (157×209mm). To add a new device, create a new preset in `presets/<device>.toml` with the correct dimensions — do not edit the template.
