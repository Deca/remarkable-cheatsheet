// Page dimensions and visual styling read from assets/config.typ, which is
// materialised from cheatsheet.toml + a preset by scripts/materialize-config.sh.
// For the reMarkable Paper Pro: 180mm x 240mm (4:3). For reMarkable 2: 157 x 209.
#import "config.typ": config

#let rm-width = config.page_width_mm * 1mm
#let rm-height = config.page_height_mm * 1mm
#let body-pt = config.body_pt * 1pt
#let scratch-height = config.scratch_zone_mm * 1mm
#let margin-x = config.margin_x_mm * 1mm
#let margin-y = config.margin_y_mm * 1mm
#let leading = config.leading * 1em
#let border-color = if config.table_border_gray { gray } else { black }
#let border-stroke = config.table_border_pt * 1pt + border-color

// One tool sheet = one top-level heading = one PDF bookmark. Don't call
// pagebreak() anywhere else in a content file -- it desyncs bookmarks from pages.
#let tool-sheet(title, body) = {
  pagebreak(weak: true)
  set page(
    width: rm-width,
    height: rm-height,
    margin: (x: margin-x, y: margin-y),
    // Persistent "← Index" button at the top-right corner of every tool
    // sheet page, including overflow pages. The dy: 2mm offset clears the
    // reMarkable's status bar / close-document button (≈ 25px on a 12 px/mm
    // display). The button is a link target — `<cover>` is defined inside
    // the cover() function below. See 20-06-2026-back-to-index-button.md.
    header: [
      #place(top + right, dx: -2mm, dy: 2mm)[
        #box(
          stroke: 0.4pt + border-color,
          inset: 3pt,
          outset: 1.5pt,
          radius: 2.5pt,
          link(<cover>)[#text(size: 10pt)[← Index]],
        )
      ]
    ],
  )
  set text(size: body-pt)
  set par(leading: leading)
  // Typst markup-mode list syntax treats both `+` and `-` as the same
  // unordered list type, so this marker applies to both Workflows and
  // Gotchas. The gotcha_glyph knob is reserved for a future refactor.
  set list(marker: config.workflow_glyph)
  set heading(numbering: none)
  [= #title]
  body
  v(1fr)
  line(length: 100%, stroke: 0.5pt + border-color)
  v(4mm)
  // scratch label is conditional: empty string hides the caption.
  if config.scratch_label != "" [
    #text(size: 9pt, fill: border-color)[#config.scratch_label]
  ]
  v(scratch-height)
}

// rows: array of (command, description) pairs, e.g.
//   (([`git status`], [Show working tree status]), (([`git stash`], [Shelve changes])))
#let commands-table(rows) = {
  table(
    // Avoid auto-sizing the command column: long commands otherwise consume
    // the full width and squash the description column, especially on rm2.
    columns: (5fr, 4fr),
    stroke: border-stroke,
    inset: 5pt,
    [*Command*], [*What it does*],
    ..rows.flatten()
  )
}

// Cover / table-of-contents page. Call once from content/index.typ.
// The title is a level-1 heading so the reMarkable's bookmark panel
// shows it as a navigable entry -- users can jump back to the cover
// from any sheet via the TOC panel, without relying on the transient
// "Back to ..." affordance (which the reMarkable fades after a few seconds).
// Outline rows get a subtle gray fill so the clickable area is
// visually obvious on the touch target.
#let cover(title: "Dev Cheatsheet") = {
  set page(
    width: rm-width,
    height: rm-height,
    margin: (x: margin-x, y: margin-y),
    // Suppress the "← Index" page header on the cover — the user is
    // already at the index, so a self-link would be a no-op.
    header: none,
  )
  show heading.where(level: 1): it => text(size: 32pt, weight: "bold", it.body)
  // `<cover>` is the link target for the back-to-index button rendered in
  // tool-sheet()'s page header. Any `link(<cover>, ...)` elsewhere in the
  // document navigates here.
  [= #title <cover>]
  v(12mm)
  text(size: 16pt)[
    // Make tool titles visually distinct from intermediate section entries.
    // Level 1 = cover title + tool sheets. Level 2 = Core Commands / Workflows / Gotchas.
    #show outline.entry.where(level: 1): set text(size: 18pt, weight: "bold")
    #show outline.entry.where(level: 2): set text(size: 14pt)
    #outline(title: none, depth: config.index_depth)
  ]
}
