# Syncing the compiled PDF to your reMarkable

This is one-time setup, not part of the regular add/rebuild loop.

## Option A — rmapi (recommended)
1. Install: https://github.com/ddvk/rmapi (Go binary, single download, no Python deps).
2. Run `rmapi` once interactively — it'll prompt for a one-time code from your reMarkable account (my.remarkable.com → register a new device) and store a token locally.
3. After that, `scripts/push.sh` just runs `rmapi put output/cheatsheet.pdf /` — uploads to the cloud root folder, which then syncs to the device over wifi.
4. To *update* rather than duplicate: `rmapi put output/cheatsheet.pdf /YourFolder` will create a new version if a file with the same name already exists at that path in most rmapi builds; check `rmapi --help` for your installed version's exact overwrite behavior before relying on it.

## Option B — SSH (no cloud account needed)
The device has SSH enabled by default (Settings → Help → Copyrights and licenses → General information, for the password). You can `scp output/cheatsheet.pdf root@<device-ip>:/home/root/` but the tablet's own file index (xochitl) won't pick up files dropped directly into the filesystem without a restart of the `xochitl` service or a re-trigger of its file scan — this is fiddlier and more fragile across firmware updates than Option A. Only use this if you specifically don't want the file touching reMarkable's cloud.

## Option C — manual
Drag-and-drop via the reMarkable desktop/web app. No script needed; fine if you rebuild infrequently and don't mind the manual step.
