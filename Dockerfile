# Flood-smoke harness only — hard-limited CPU/RAM so a 100% flood hits a
# killable cgroup, never the host. Do not use for GUI / gnome-terminal.
FROM debian:bookworm-slim

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bash \
		bsdutils \
		coreutils \
		netcat-openbsd \
		procps \
		util-linux \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /src
# Repo is bind-mounted at runtime; COPY keeps the image self-checkable.
COPY bin/port-broadcast-shell /src/bin/port-broadcast-shell
COPY scripts/flood-smoke-inner /src/scripts/flood-smoke-inner

RUN chmod +x /src/bin/port-broadcast-shell /src/scripts/flood-smoke-inner

ENTRYPOINT ["/src/scripts/flood-smoke-inner"]
CMD ["drop"]
