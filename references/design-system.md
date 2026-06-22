# Design System — why the rules in the skill spec exist

## Why 4:3, device-matched dimensions
PDFs aren't pixel-locked to a device, but matching the reMarkable's actual aspect ratio means no letterboxing or awkward re-scaling when it auto-fits to screen width. Paper Pro: 2160×1620px, 11.8", 4:3. reMarkable 2: 1872×1404px, 10.3", same 4:3 ratio, smaller physical size.

## Why one tool sheet = one Typst heading = one pagebreak
Typst derives the PDF outline (bookmarks) from headings. If a sheet's content isn't wrapped in exactly one top-level heading inside `tool-sheet()`, you either get no bookmark or a bookmark mid-sheet. The mapping (1 file = 1 heading = 1 bookmark) is what makes the outline panel double as your nav menu on the device — that's the entire point of compiling everything into one PDF instead of separate files.

## Why no color-only distinctions
The reMarkable 2 (still the most common device) is grayscale. The Paper Pro and Paper Pro Move support color, but designing for grayscale-first means your sheets work on either, and you're not relying on a distinction that vanishes on half the install base.

## Why a fixed scratch zone, never compressed
The reMarkable's actual advantage over a phone or laptop reference is the pen. A sheet with no annotation room becomes just a worse PDF viewer experience than reading it on a screen. The zone is generous (40mm) deliberately — better to spill to a second page than to make annotation cramped.

## Why landscape is not the default
Despite git/zellij being command-table-heavy, the template defaults every sheet to portrait for one reason: consistency in the bound PDF. A mix of portrait and landscape pages means rotating the device mid-flip-through. If a specific sheet's table genuinely needs landscape width, override `page(width:, height:)` locally inside that one `tool-sheet()` call rather than changing the global default — keep the exception visible at the point it happens.

## Why Typst over Pandoc/LaTeX or HTML+wkhtmltopdf
- LaTeX: powerful but slow to iterate on, and table layout fights you exactly where this project lives (dense, mixed-width command tables).
- Pandoc-as-converter: fine for prose, but converting Markdown tables through Pandoc into a custom page template adds a lossy translation step for no benefit when you're hand-authoring content anyway.
- HTML+wkhtmltopdf/Playwright: viable, but pulls in a browser engine dependency and CSS print-quirks (page-break handling, repeating headers) that Typst's `page()`/`pagebreak()` model handles natively.
- Typst: single static binary, fast incremental compiles, first-class page/heading/outline model — the bookmark-per-sheet mechanic this whole pipeline depends on is a built-in, not a workaround.
