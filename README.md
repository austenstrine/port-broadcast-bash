# port-broadcast-bash

Interactive PTY → TCP stream hop for Cursor agents on Raider.

Clones a live shell session two ways:

1. **This terminal** — real PTY via `script(1)` (interactive; curses/TTY apps work)
2. **TCP listen port** — same bytes for an agent/client (`nc` / `socat`)

**Stack:** bash + `script` + `tee` + `nc` only. No Python. No on-disk session typescript.
**UI:** one regular Linux terminal window with N tabs (gnome-terminal) — **not** Cursor’s integrated terminal.

## Layout

```
bin/port-broadcast-shell      # PTY → TCP hop (canonical)
bin/port-broadcast-launcher   # ONE gnome-terminal window, N tabs + flags
scripts/                      # thin wrappers → bin/
.vscode/tasks.json            # optional Cursor tasks (not the primary UI)
```

## Requirements

- `bash`
- `script(1)` (`bsdutils` / `util-linux`)
- `nc` (OpenBSD netcat: `netcat-openbsd`)
- `gnome-terminal` (launcher only; hop works without it)

## Quick start (hop)

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

## Multi-tab (Linux terminal window)

One `gnome-terminal` process: `--window` + N `--tab` (never N windows).

```bash
# Agent-safe: print argv + port map only (no GUI)
./bin/port-broadcast-launcher --dry-run --smoke
./bin/port-broadcast-launcher --dry-run --tabs 6 --confirm

# GUI launch requires --confirm (machine has hard-crashed on reckless GUI spawns)
./bin/port-broadcast-launcher --smoke --confirm
./bin/port-broadcast-launcher --tabs 6 --confirm

# Ports / per-tab commands (any or none)
./bin/port-broadcast-launcher --ports 4591,4600,4700 --confirm
./bin/port-broadcast-launcher --tabs 3 --confirm --tab-cmd 2='npm run dev' --tab-cmd 3=
./bin/port-broadcast-launcher --tabs 2 --confirm --cmd 'dssh logs backend'
./bin/port-broadcast-launcher --config ./tabs.conf --confirm
```

Config file (`KEY=VALUE`, `#` comments):

```
tabs=3
base-port=4591
bind=127.0.0.1
# or: ports=4591,4600,4700
cmd=echo default
tab.1=
tab.2=npm run dev
```

Agent attach: `nc 127.0.0.1 4591` … (printed port map).

Defaults: bind `127.0.0.1`, base port `4591`, tabs `6` (cap `16`, override with `PORT_BROADCAST_MAX_TABS`).

## Noisy sessions / nc flood

- No on-disk typescript: `script` writes to a process sink (pipes/sockets; small tmpfs bounce only).
- The clone sink **never stalls the PTY**. If nobody is attached (or the client is slow), surplus clone bytes are **dropped**.
- For a full-fidelity flood, attach `nc` first, then generate load:

```bash
# terminal A
./bin/port-broadcast-shell -p 4591 -- bash -c 'while true; do date; done'

# terminal B (attach promptly)
nc 127.0.0.1 4591
```

## Optional Cursor tasks

`.vscode/tasks.json` can still open hop tabs inside Cursor if you want, but the **supported multi-tab UI is the Linux terminal launcher**, not Tasks: Run Task.

## Caveats

- No authentication — prefer localhost bind
- One TCP listener at a time per port (v1)
- Late joiners see live output only
- Stream includes terminal control sequences
- Do not automate multi-window GNOME spawns; use this launcher’s one-window path + `--confirm`

## Portfolio checkout

`austenstrine/austenstrine_portfolio` keeps thin wrappers under `scripts/` that `exec` this repo (`PORT_BROADCAST_HOME` or `~/Development/port-broadcast-bash`). Canonical copy lives here.
