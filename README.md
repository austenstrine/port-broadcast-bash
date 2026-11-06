# port-broadcast-bash

Interactive PTY → TCP stream hop for Cursor agents on Raider.

Clones a live shell session two ways:

1. **This terminal** — real PTY via `script(1)` (interactive; curses/TTY apps work)
2. **TCP listen port** — same bytes for an agent/client (`nc` / `socat`)

**Stack:** bash + `script` + `tee` + `nc` only. No Python. No on-disk session typescript.
**UI:** one regular Linux Terminal window with N tabs (Ubuntu default: **Ptyxis**, desktop name “Terminal”) — **not** Cursor’s integrated terminal, and not a hard-wired `gnome-terminal` path.

## Layout

```
bin/port-broadcast-shell         # PTY → TCP hop (canonical)
bin/port-broadcast-launcher      # ONE Terminal window, N tabs + flags
bin/flood-smoke-container        # limited Docker flood smoke (only safe flood path)
scripts/                         # thin wrappers → bin/
scripts/flood-smoke-inner        # flood modes run *inside* the container
Dockerfile                       # flood-smoke image (bash + script + nc)
docker-compose.flood-smoke.yml   # 1 CPU / 256MiB / 64 pids
.vscode/tasks.json               # optional Cursor tasks (not the primary UI)
```

## Requirements

- `bash`
- `script(1)` (`bsdutils` / `util-linux`)
- `nc` (OpenBSD netcat: `netcat-openbsd`)
- Terminal emulator for the launcher (prefer `ptyxis`, then `kgx`, then `gnome-terminal`; override with `PORT_BROADCAST_TERMINAL`). Hop works without a GUI terminal.

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

## Multi-tab (Linux Terminal window)

One regular Terminal window with N tabs (never N windows). On current Ubuntu the
default app is **Ptyxis** (`.desktop` name “Terminal”, also `x-terminal-emulator`).
Ptyxis cannot combine `--new-window` and `--tab` in one argv, so the launcher
opens the window once, then adds tabs into that MRU window. Override the binary
with `PORT_BROADCAST_TERMINAL` if needed.

After a tab’s hop command exits, the hop itself drops to an interactive bash
(`cmd; exec bash`) so the tab, scrollback, and TCP listen stay up (restart /
one-shot commands no longer close the tab).

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

## Noisy sessions / flood smoke (container only)

**Never run a bare-metal flood on the host.** A hung flood previously pegged ~100% host CPU and survived `timeout`. All flood smokes go through a hard-limited Docker cgroup that `docker kill` can stop.

Limits (compose + wrapper): **1.0 CPU**, **256MiB RAM** (no extra swap), **64 pids**. Container name: `port-broadcast-flood-smoke`.

```bash
cd ~/Development/port-broadcast-bash

# Bounded flood, no nc — PTY must not stall (default)
./bin/flood-smoke-container drop

# Bounded flood with nc attached (full-fidelity clone path)
./bin/flood-smoke-container attach

# Unbounded flood for kill drills (pegs the *container* CPU only)
./bin/flood-smoke-container stress
# emergency stop:
docker kill port-broadcast-flood-smoke

# One-shot: start stress → wait 3s → kill
./bin/flood-smoke-container kill-demo
```

Compose equivalent:

```bash
docker compose -f docker-compose.flood-smoke.yml build
docker compose -f docker-compose.flood-smoke.yml run --rm --name port-broadcast-flood-smoke flood-smoke drop
docker kill port-broadcast-flood-smoke   # if a stress run is still up
```

Hop behavior (inside or out):

- No on-disk typescript: `script` writes to a process sink (pipes/sockets; small tmpfs bounce only).
- The clone sink **never stalls the PTY**. If nobody is attached (or the client is slow), surplus clone bytes are **dropped**.
- Light interactive attach (not a flood) may still use host `nc` against a manually started hop — floods stay in the container.

## Optional Cursor tasks

`.vscode/tasks.json` can still open hop tabs inside Cursor if you want, but the **supported multi-tab UI is the Linux terminal launcher**, not Tasks: Run Task.

## Caveats

- No authentication — prefer localhost bind
- One TCP listener at a time per port (v1)
- Late joiners see live output only
- Stream includes terminal control sequences
- Do not automate multi-window terminal spawns; use this launcher’s one-window path + `--confirm`
- GUI still requires `--confirm` (1-tab `--smoke` included). Prefer `--dry-run` and container flood over host GUI when unsure.
- Flood tests: **container only** (`./bin/flood-smoke-container`); never bare-metal urandom/base64 floods on the host
- Launcher prefers Ptyxis (Ubuntu “Terminal”); set `PORT_BROADCAST_TERMINAL` only if you intentionally want another emulator

## Portfolio checkout

`austenstrine/austenstrine_portfolio` keeps thin wrappers under `scripts/` that `exec` this repo (`PORT_BROADCAST_HOME` or `~/Development/port-broadcast-bash`). Canonical copy lives here.
