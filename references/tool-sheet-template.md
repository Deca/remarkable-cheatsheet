# Tool Sheet Template

Every tool sheet has exactly four sections, in this order. Don't add a fifth.

## 1. Core Commands
A table: command (literal, in backticks) → one-line description of what it does. Keep descriptions under ~8 words. Only include commands you'd actually forget — skip ones obvious enough to never need lookup.

## 2. Workflows
Numbered steps for the 2–4 multi-step tasks you actually do with this tool (e.g., for git: "rebase a feature branch onto updated main", "undo a bad merge"). Not a tutorial — assume the reader knows the tool exists, just not the exact sequence under pressure.

## 3. Gotchas
Bullet list of non-obvious behavior, footguns, or things that broke your mental model the first time. This is the highest-value section and the reason a self-made sheet beats devhints/Cheatography for tools like zellij or pi.dev that don't have public sheets yet. Be specific — "the `usage_percent` field in MiniMax's quota response is the *remaining* quota, not used" is a good gotcha; "be careful with the API" is not.

## 4. Scratch space
Generated automatically by `tool-sheet()` in the template — don't author this section, just don't compress it.

## Slug convention
File name = lowercase tool name, hyphenated: `pi-dev.typ`, `zellij.typ`, `git.typ`, `agentic-loops.typ`. The slug is also what shows in `content/main.typ`'s include list — keep them in sync.
