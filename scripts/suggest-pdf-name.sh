#!/usr/bin/env bash
# Suggest a filename stem from the included tool sheet titles.
# Does not modify cheatsheet.toml; intended for guided UX in the skill.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mapfile -t titles < <(
  grep -RhoE '#tool-sheet\("[^"]+"' "$ROOT/content"/*.typ \
    | sed -E 's/^#tool-sheet\("//'
)

if [ "${#titles[@]}" -eq 0 ]; then
  echo "dev-cheatsheet"
  exit 0
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

parts=()
for title in "${titles[@]}"; do
  part="$(slugify "$title")"
  [ -n "$part" ] && parts+=("$part")
done

if [ "${#parts[@]}" -eq 0 ]; then
  echo "dev-cheatsheet"
elif [ "${#parts[@]}" -le 6 ]; then
  joined="$(IFS=-; echo "${parts[*]}")"
  echo "dev-cheatsheet-${joined}"
else
  echo "dev-cheatsheet-${#parts[@]}-tools"
fi
