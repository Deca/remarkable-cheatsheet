#import "../assets/template.typ": *

#tool-sheet("pi.dev")[
  == Core Commands
  #commands-table((
    ([`pi`], [Start an interactive session]),
    ([`pi -p "prompt"`], [Print mode, one-shot, exits after responding]),
    ([`pi -c`], [Continue the most recent session]),
    ([`pi -r`], [Browse and select a past session to resume]),
    ([`pi --session <path|id>`], [Resume a specific session by path or partial UUID]),
    ([`pi --fork <path|id>`], [Fork a session into a new session file]),
    ([`pi --no-session`], [Ephemeral mode, do not save anything]),
    ([`pi --name "task"`], [Set session display name at startup]),
    ([`pi @file "..."`], [Attach a file to the initial message]),
    ([`pi @file1 @file2 "..."`], [Attach multiple files]),
    ([`pi --provider <name>`], [Pick a provider: anthropic, openai, google, ...]),
    ([`pi --model <id>`], [Pick a model, supports `provider/id` and `:<thinking>`]),
    ([`pi --model sonnet:high`], [Model with thinking-level shorthand]),
    ([`pi --thinking <level>`], [Set thinking: off, minimal, low, medium, high, xhigh]),
    ([`pi --list-models`], [List available models, optionally filtered by search]),
    ([`pi --tools read,grep,find,ls`], [Allowlist specific built-in/extension tools]),
    ([`pi --exclude-tools <list>`], [Disable specific tools but keep the rest]),
    ([`pi --no-tools`], [Disable all tools, including extensions]),
    ([`pi -a` / `--approve`], [Trust project-local files for this one run]),
    ([`pi --no-context-files`], [Skip AGENTS.md/CLAUDE.md discovery]),
    ([`pi --no-extensions`], [Skip extension discovery]),
    ([`pi --skill <path>`], [Load a specific skill from CLI]),
    ([`pi install <source>`], [Install a pi package from npm or git]),
    ([`pi install <source> -l`], [Install package project-local]),
    ([`pi update --all`], [Update pi + all installed packages]),
    ([`pi update --extensions`], [Update packages only, reconcile pinned git refs]),
    ([`pi list`], [List installed packages]),
    ([`pi config`], [Enable or disable package resources]),
    ([`pi --mode json`], [Output all events as JSON lines]),
    ([`pi --mode rpc`], [RPC mode over stdin/stdout]),
    ([`pi --export <in> [out]`], [Export a session to HTML]),
    ([`!cmd`], [Run a shell command and send output to the model]),
    ([`!!cmd`], [Run a shell command without sending output to the model]),
  ))

  == Workflows
  + *Recover from a bad turn*: `/tree` → jump to the last good user message, or `/fork <session-id>` to branch into a new file and continue from there. Use `/clone` to duplicate the active branch instead.
  + *Read-only code review*: `pi --tools read,grep,find,ls -p "Audit this repo"` — disables bash/edit/write so the model can only inspect.
  + *Pipe a file into a one-shot*: `cat README.md | pi -p "Summarize"` — stdin merges into the initial prompt.
  + *Escalate thinking on a hard problem*: `Shift+Tab` cycles level interactively, or `--model sonnet:high "..."` from CLI. Use `/settings` to set the default.
  + *Custom keybinding*: edit `~/.pi/agent/keybindings.json`, then `/reload` inside pi — no restart needed.
  + *Share a session*: `/export file.html` for local HTML, or `/share` for a private GitHub gist link. Badlogic also publishes anonymized sessions via `pi-share-hf` for ML research.
  + *Project-local context with AGENTS.md*: drop an `AGENTS.md` (or `CLAUDE.md`) at the project root. Pi walks up from cwd to find it; pass `--no-context-files` to skip.
  + *Session tree navigation*: `/tree` opens an in-file tree navigator; use `Ctrl+left`/`Ctrl+right` to fold branches and `Ctrl+l` to label nodes.

  == Gotchas
  - Project folders with `.pi/` and no saved trust decision trigger a trust prompt on startup. In `-p` / `--mode json` / `--mode rpc` there is no prompt — `defaultProjectTrust` (default `"ask"`) silently ignores project-local files. Pass `-a`/`--approve` to load them, or `/trust` to persist.
  - `--exclude-tools` disables just listed tools; `--no-tools` disables *everything* including extension and custom tools. `--no-builtin-tools` is the middle ground (extensions stay enabled).
  - `Alt+Enter` queues a follow-up delivered *after the agent finishes all work*. `Enter` queues a *steering* message delivered after the current turn's tool calls. `Escape` aborts *and* restores queued messages to the editor — don't lose work thinking Escape only cancels.
  - Model shorthand `--model sonnet:high` sets thinking level inline; full form is `--model sonnet --thinking high`. Levels: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` (provider-dependent).
  - `pi update` never prompts for project trust and silently reconciles pinned git refs — `--all` updates pi + packages together, `--extensions` is packages only.
  - `PI_OFFLINE=1` disables startup network ops including update checks and install telemetry. `PI_SKIP_VERSION_CHECK=1` only skips the pi.dev version probe. `PI_CACHE_RETENTION=long` extends prompt cache where supported.
  - `Ctrl+P` is overloaded: in the editor it cycles models; in the session list it toggles path display. Same chord, different context.
  - On native Windows `app.suspend` has no default `Ctrl+Z` binding (no Unix job control). In WSL it works normally.
  - A pi skill is just a `SKILL.md` with YAML frontmatter — it's a behavior contract for the agent, not a binary. The agent reads the file and routes through shell scripts; there's no separate executable to install.
  - `--session <path|id>` accepts partial UUID prefixes from `/session` — you can paste the first 8 chars and it'll match.
]
