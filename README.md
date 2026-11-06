# port-broadcast-bash

Interactive PTY → TCP stream hop for Cursor on Raider.

Clones a live shell session two ways:

1. **This terminal** — real PTY via `script(1)` (interactive; curses/TTY apps work)
2. **TCP listen port** — same bytes for an agent/client (`nc` / `socat`)

**Stack:** bash + `script` + `nc` only. No Python, no disk session log.
**UI:** Cursor integrated terminal tabs (not GNOME Terminal).

## Layout

```
bin/port-broadcast-shell      # PTY → TCP hop (canonical)
bin/port-broadcast-launcher   # port map + Tasks: Run Task labels
scripts/                      # thin wrappers → bin/
.vscode/tasks.json            # port-broadcast: smoke | 6 tabs | tab 4591–4596
```

## Requirements

- `bash`
- `script(1)` (`bsdutils` / `util-linux`)
- `nc` (OpenBSD netcat: `netcat-openbsd`)

## Quick start

```bash
cd ~/Development/port-broadcast-bash

# Interactive hop (default 127.0.0.1:4591)
./bin/port-broadcast-shell

# One-shot command under the PTY
./bin/port-broadcast-shell -- sh -c 'tty; echo hello; seq 3'

# Agent / other terminal attaches as TCP client
nc 127.0.0.1 4591
```

Override bind/port with `-b` / `-p` or `PORT_BROADCAST_BIND` / `PORT_BROADCAST_PORT`.

## Multi-tab (Cursor integrated terminal)

```bash
./bin/port-broadcast-launcher --smoke
./bin/port-broadcast-launcher --tabs 6 --confirm
```

Then in Cursor (with this folder open as the workspace, or via a multi-root workspace):

- Command Palette → **Tasks: Run Task** → `port-broadcast: smoke`
- Command Palette → **Tasks: Run Task** → `port-broadcast: 6 tabs`

Agent attach: `nc 127.0.0.1 4591` … `nc 127.0.0.1 4596`

Default ports: `4591`–`4596`. Shipped tasks bind that range; `--base-port` only remaps the printed cheat-sheet.

## Caveats

- No authentication — prefer localhost bind
- One listener at a time (v1)
- Late joiners see live output only
- Stream includes terminal control sequences
- If nobody is attached and the pipe buffer fills, the session can stall — attach `nc` first for noisy sessions

## Portfolio checkout

`austenstrine/austenstrine_portfolio` keeps thin wrappers under `scripts/` that `exec` this repo (`PORT_BROADCAST_HOME` or `~/Development/port-broadcast-bash`). Canonical copy lives here.
