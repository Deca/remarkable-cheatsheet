#import "../assets/template.typ": *

#tool-sheet("git")[
  == Core Commands
  #commands-table((
    ([`git init`], [Initialize a new repo in the current directory]),
    ([`git clone <url>`], [Clone a remote repository]),
    ([`git clone <url> <dir>`], [Clone into a specific directory]),
    ([`git status`], [Show working tree status]),
    ([`git status -s`], [Short-format status (porcelain)]),
    ([`git add <file>`], [Stage a file]),
    ([`git add -p`], [Stage selected hunks interactively]),
    ([`git add -A`], [Stage all changes including deletions]),
    ([`git commit -m "msg"`], [Commit staged changes with a message]),
    ([`git commit --amend`], [Amend the last commit]),
    ([`git commit --amend --no-edit`], [Amend without changing the message]),
    ([`git log --oneline --graph --all`], [Compact graph of all branches]),
    ([`git log -p <file>`], [Log with patches for a file]),
    ([`git log --follow <file>`], [Log including renames]),
    ([`git diff`], [Show unstaged working tree changes]),
    ([`git diff --staged`], [Show staged changes]),
    ([`git diff <a>..<b>`], [Diff between two refs]),
    ([`git switch -c <branch>`], [Create and switch to a new branch]),
    ([`git switch <branch>`], [Switch to an existing branch]),
    ([`git restore <file>`], [Discard working tree changes]),
    ([`git restore --staged <file>`], [Unstage a file]),
    ([`git reset --hard <ref>`], [Hard reset to a ref, destructive]),
    ([`git reset --soft HEAD~1`], [Undo last commit, keep changes staged]),
    ([`git stash`], [Stash working tree and uncommitted changes]),
    ([`git stash pop`], [Restore the top stash and drop it]),
    ([`git stash list`], [List all stashes]),
    ([`git rebase -i HEAD~n`], [Interactively rewrite last n commits]),
    ([`git rebase --continue`], [Continue rebase after resolving conflicts]),
    ([`git cherry-pick <sha>`], [Apply a commit from another branch]),
    ([`git fetch origin`], [Fetch from remote without merging]),
    ([`git pull --rebase`], [Pull with rebase instead of merge]),
    ([`git push`], [Push current branch to its upstream]),
    ([`git push --force-with-lease`], [Force push safely — refuses if remote moved]),
    ([`git remote -v`], [List remotes with URLs]),
    ([`git branch -d <branch>`], [Delete a merged branch]),
    ([`git branch -D <branch>`], [Force-delete a branch]),
    ([`git tag <name>`], [Create a lightweight tag at HEAD]),
    ([`git worktree add <path> <branch>`], [Add a linked working tree on a branch]),
    ([`git reflog`], [Show HEAD history, recovery lifeline]),
    ([`git bisect start`], [Binary search for the commit that introduced a bug]),
    ([`git blame <file>`], [Show who last modified each line]),
    ([`git config --global user.name "..."`], [Set a global config value]),
  ))

  == Workflows
  + *Rebase a feature branch onto updated main*: `git fetch origin`, then `git rebase origin/main`, resolve conflicts per commit, `git rebase --continue`. Then `git push --force-with-lease`.
  + *Undo a bad merge before pushing*: `git reset --hard ORIG_HEAD`. ORIG_HEAD only exists right after the merge.
  + *Recover a "lost" commit via reflog*: `git reflog`, find the SHA, `git switch -c recovery <sha>` to branch off it.
  + *Squash fixup commits with autosquash*: `git commit --fixup=<sha>`, then `git rebase -i --autosquash <sha>~1`.
  + *Find the commit that introduced a bug with bisect*: `git bisect start`, `git bisect bad`, `git bisect good <known-good-sha>`, then mark each commit `good`/`bad` until git identifies the culprit.
  + *Clean up before opening a PR*: rebase onto upstream main, force-push with `--force-with-lease`, verify `git log --oneline origin/main..HEAD`.

  == Gotchas
  - `git rebase --continue` after resolving conflicts does *not* auto-stage; you still need `git add` first.
  - `ORIG_HEAD` only exists right after the operation that set it (merge, reset, rebase) — it gets overwritten by the next one.
  - `git stash` drops untracked files by default; use `-u` to include them.
  - `git push --force` overwrites the remote unconditionally — `git push --force-with-lease` refuses if the remote moved since your last fetch, which is what you almost always want.
  - `git reset --hard` is destructive: it discards uncommitted changes in the working tree and the index. No undo. Use `git reset --soft` or `git reset --mixed` to keep your changes.
  - `git checkout` historically did both branch-switching and file-restoring. Modern split: `git switch` for branches, `git restore` for files. Use the new commands to avoid surprises.
  - `git rebase` rewrites commit hashes — never rebase commits that others have already pulled (unless you coordinate and they reset).
  - `git pull` defaults to merge; `--rebase` keeps your local commits on top of the upstream history. Configure `pull.rebase true` globally if you want this always.
  - `git diff` and `git diff --staged` show different things: working tree vs index. For "what did I just change before committing", use `git diff`. For "what am I about to commit", use `git diff --staged`.
  - `git log --all` includes every ref (branches, remotes, stash, reflog). Without `--all`, you only see the current branch's history.
]
