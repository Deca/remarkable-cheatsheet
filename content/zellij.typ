#import "../assets/template.typ": *

#tool-sheet("zellij")[
  == Core Commands
  #commands-table((
    ([`zellij`], [Start a new session with the default layout]),
    ([`zellij -s <name>`], [Start a new session with a specific name]),
    ([`zellij attach <name>`], [Reattach to a named session]),
    ([`zellij list-sessions`], [List running sessions]),
    ([`zellij kill-session <name>`], [Kill a session by name]),
    ([`zellij kill-all-sessions`], [Kill every running session]),
    ([`zellij --layout <file.kdl>`], [Start with a predefined layout]),
    ([`zellij --session <name> action ...`], [Send an action to a different session]),
    ([`zellij action new-pane`], [Open a new pane (CLI alternative to keybinding)]),
    ([`zellij action new-pane -- <cmd>`], [New pane running a specific command]),
    ([`zellij action new-tab --layout <file>`], [New tab with a specific layout]),
    ([`zellij action move-focus <dir>`], [Move focus to right/left/up/down]),
    ([`zellij action close-pane`], [Close the focused pane]),
    ([`zellij action close-tab`], [Close the current tab]),
    ([`zellij action rename-tab <name>`], [Rename the focused tab]),
    ([`zellij action dump-screen --path <file>`], [Dump pane viewport to a file]),
    ([`zellij action dump-screen --full`], [Dump full scrollback]),
    ([`zellij action list-panes`], [List all panes, optional JSON output]),
    ([`zellij action list-tabs`], [List all tabs with optional detail fields]),
    ([`zellij watch <name>`], [Read-only view of a session]),
    ([`zellij setup --generate-completion <shell>`], [Generate shell completions, also creates `zr`/`zrf`/`ze` aliases]),
    ([`zellij run -- <cmd>`], [Shortcut for `action new-pane -- <cmd>`]),
    ([`zellij edit <file>`], [Shortcut for `action edit <file>`]),
    ([`Ctrl+p n`], [Enter pane mode, then `n` for new pane]),
    ([`Ctrl+p x`], [Close focused pane]),
    ([`Ctrl+p <arrow>`], [Move focus direction]),
    ([`Ctrl+p +` / `-`], [Increase / decrease focused pane size]),
    ([`Ctrl+t n`], [New tab]),
    ([`Ctrl+t <num>`], [Go to tab by index (1-9)]),
    ([`Ctrl+o d`], [Detach from session]),
  ))

  == Workflows
  + *Persistent dev session across SSH disconnects*: `zellij -s work`, start your processes in separate panes, detach with `Ctrl+o d`, reattach later with `zellij attach work`. The session survives the SSH connection dropping.
  + *Predefined layout on startup*: `zellij --layout my-layout.kdl` — define panes/commands declaratively instead of arranging by hand each time. Layouts are KDL files.
  + *Run-and-wait for a command in a new pane*: `zellij run --block-until-exit -- make build` blocks until the command exits, useful for scripts that orchestrate zellij.
  + *Scripted automation via JSON output*: `zellij action list-panes --json` for machine-readable state. Pipe into `jq` to drive other tools.
  + *Tab-bar navigation*: `Ctrl+t n`/`Ctrl+t p` for next/prev tab, or `Ctrl+t <num>` to jump directly. Use `Ctrl+t r` to rename, `Ctrl+t x` to close.

  == Gotchas
  - Default keybinding is modal (like vim) — `Ctrl+p`/`Ctrl+t`/`Ctrl+o` enter a *mode*, then the next key acts within it. It's not a single chord; you can chain (e.g. `Ctrl+p n n` opens two new panes in succession).
  - Session names with the same name as a dead/detached session will reattach to it, not start fresh — `zellij list-sessions` first if unsure, or use `zellij kill-session <name>` first.
  - Copy mode behavior differs from tmux defaults; check `zellij --help` or the layout config if mouse copy-paste feels off out of the box.
  - `zellij action` is the canonical scripting surface — `zellij run` and `zellij edit` are shortcuts that wrap `action new-pane -- <cmd>` and `action edit <file>`.
  - `ZELLIJ_PANE_ID` env var is set inside every terminal pane — useful for self-aware commands like `tmux` or scripts that need to know their pane ID.
  - Pane IDs are prefixed: `terminal_N` for terminal panes, `plugin_N` for plugin panes. Passing `3` alone is shorthand for `terminal_3`; pass `plugin_3` to disambiguate.
  - Reattach race: if `list-sessions` shows a session but attach fails immediately, the previous process may not have released its socket. Wait a moment or `kill -9` the stale PID found in `~/.cache/zellij/`.
]
