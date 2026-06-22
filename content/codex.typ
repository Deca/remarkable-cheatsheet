#import "../assets/template.typ": *

#tool-sheet("Codex")[
  == Core Commands
  #commands-table((
    ([`curl -fsSL https://chatgpt.com/codex/install.sh | sh`], [Install or upgrade Codex CLI on macOS/Linux]),
    ([`CODEX_NON_INTERACTIVE=1 sh`], [Use with the installer for unattended installs]),
    ([`codex`], [Start the interactive terminal UI in the current repo]),
    ([`codex --sandbox workspace-write --ask-for-approval on-request`], [Low-friction local session with writable workspace and approval prompts]),
    ([`codex --model <model>`], [Override the model for this invocation]),
    ([`codex --search`], [Use live web browsing instead of cached search mode]),
    ([`codex exec "<task>"`], [Run Codex non-interactively for scripts, CI, or pipelines]),
    ([`codex exec --json "<task>"`], [Emit JSONL events for automation]),
    ([`codex exec -o result.md "<task>"`], [Write the final agent message to a file]),
    ([`codex exec --output-schema schema.json -o out.json "<task>"`], [Request structured JSON matching a schema]),
    ([`codex exec resume --last "<task>"`], [Continue the most recent non-interactive session]),
    ([`codex login`], [Authenticate with ChatGPT account, API key, or access token]),
    ([`codex login status`], [Return success when credentials are present]),
    ([`codex logout`], [Remove saved credentials]),
    ([`codex apply`], [Apply the most recent diff from a Codex cloud task locally]),
    ([`codex cloud list --json`], [List recent cloud tasks for automation]),
    ([`codex doctor`], [Generate local diagnostics for installation/config/auth/runtime issues]),
    ([`codex mcp`], [Manage MCP server entries in `~/.codex/config.toml`]),
    ([`codex completion zsh > .../_codex`], [Generate shell completions]),
  ))

  == Workflows
  + *Start an interactive coding session*: open a repo, run `codex`, describe the task, review Codex's plan/diffs, approve commands or edits as needed, then run tests before accepting changes.
  + *Safe local automation*: use `codex exec --sandbox workspace-write "<task>"`; prefer explicit sandbox settings instead of deprecated `--full-auto`.
  + *Pipe logs into Codex*: `npm test 2>&1 | codex exec "summarize failures and propose the smallest likely fix"`.
  + *Prompt from stdin*: use `codex exec -` when stdin should be the full prompt, for example `cat prompt.txt | codex exec -`.
  + *CI autofix pattern*: run setup/tests without exposing secrets, run Codex in a restricted job, save its diff as a patch artifact, then open the PR from a separate write-permission job.
  + *GitHub PR review*: enable Codex code review for a repo/org, add repository guidance in `AGENTS.md`, then request review with `@codex review`; follow up with `@codex fix it` when appropriate.

  == Gotchas
  - `codex exec` streams progress to `stderr` and prints only the final agent message to `stdout`; redirect accordingly.
  - Default `codex exec` sandbox is read-only. Add `--sandbox workspace-write` only when edits are needed.
  - `danger-full-access` should only be used in controlled environments such as isolated containers or CI runners.
  - Codex requires commands to run inside a Git repo; override with `--skip-git-repo-check` only when the environment is safe.
  - `CODEX_API_KEY` is only supported for `codex exec`; avoid job-level API key env vars in workflows that run repository-controlled code.
  - Treat `~/.codex/auth.json` like a password; do not commit, paste, or share it.
  - Use `--add-dir` to grant extra directory access instead of broadening to full-danger sandbox.
  - `--full-auto` is deprecated compatibility behavior; prefer explicit sandbox/approval flags.
]  
