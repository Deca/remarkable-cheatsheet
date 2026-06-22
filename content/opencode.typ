#import "../assets/template.typ": *

#tool-sheet("opencode")[
  == Core Commands
  #commands-table((
    ([`curl -fsSL https://opencode.ai/install | bash`], [Install with official script]),
    ([`npm install -g opencode-ai`], [Install with Node.js/npm]),
    ([`brew install anomalyco/tap/opencode`], [Install latest Homebrew tap]),
    ([`opencode`], [Start the terminal UI]),
    ([`opencode -c`], [Continue last TUI session]),
    ([`opencode -s <session-id>`], [Open a specific session]),
    ([`opencode run "prompt"`], [Run non-interactively]),
    ([`opencode run -f <file> "prompt"`], [Attach file to prompt]),
    ([`opencode run --format json "prompt"`], [Stream raw JSON events]),
    ([`opencode serve`], [Start headless API server]),
    ([`opencode web`], [Start server plus web UI]),
    ([`opencode attach <url>`], [Attach TUI to remote server]),
    ([`opencode auth login -p <provider>`], [Configure provider credentials]),
    ([`opencode auth list`], [Show authenticated providers]),
    ([`opencode models --refresh`], [Refresh and list models]),
    ([`opencode session list -n 10`], [List recent sessions]),
    ([`opencode stats --days 7 --models 5`], [Inspect recent usage costs]),
    ([`opencode export <sessionID>`], [Export a session as JSON]),
    ([`opencode agent create`], [Create custom agent]),
    ([`opencode mcp add`], [Add an MCP server]),
  ))

  == Workflows
  + *First project setup*: install opencode, run `opencode auth login -p <provider>` or use `/connect`, then start `opencode` in the project and run `/init` to generate `AGENTS.md`.
  + *Plan before building*: describe the feature, switch to Plan mode with `Tab`, iterate on the plan, then press `Tab` again to return to Build mode and ask it to implement.
  + *Script one-off tasks*: use `opencode run "..."` for automation; add `--file` for context, `--model provider/model` to pin a model, and `--format json` for tooling.
  + *Use a warm backend*: run `opencode serve` once, then call `opencode run --attach http://localhost:4096 "..."` to avoid repeated server/MCP startup.
  + *Add repeatable commands*: create `.opencode/commands/name.md` with frontmatter and a prompt body, then run it in the TUI as `/name`.
  + *Tune per project*: commit `opencode.json`, `.opencode/commands/`, and `.opencode/agents/`; keep personal TUI choices in `~/.config/opencode/tui.json`.

  == Gotchas
  - Running `opencode` with no arguments starts the TUI; `opencode run` is the non-interactive path.
  - Project `opencode.json` is merged with global config; it overrides conflicting global keys but preserves non-conflicting settings.
  - `OPENCODE_CONFIG_CONTENT` and managed config have higher precedence than normal project/global files.
  - TUI settings live in `tui.json`; legacy `theme`, `keybinds`, and `tui` keys in `opencode.json` are deprecated.
  - Default permissions allow operations unless configured otherwise; set `permission` to require approval for tools like `edit` or `bash`.
  - Snapshots enable `/undo`; disabling `snapshot` can improve large-repo performance but removes rollback safety.
  - Custom command names can override built-ins like `/init`, `/undo`, `/redo`, `/share`, and `/help`.
  - Command templates can inject `$ARGUMENTS`, positional `$1`, shell-output snippets, and file references with `@path`.
  - Built-in keybinds include `Tab` / `Shift+Tab` for agent cycling, `Esc` to interrupt, `Ctrl+P` for command list, `Ctrl+A` for provider/model selection, and `<leader>m` for model list.
  - Windows Bun install support is documented as in progress; use npm, Scoop/Chocolatey, Mise, Docker, or release binaries instead.
]
