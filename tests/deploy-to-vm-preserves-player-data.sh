#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/deploy-to-vm.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

[[ -x "$SCRIPT" ]] || { echo "missing executable $SCRIPT" >&2; exit 1; }

TARGET="$TMPDIR/target"
mkdir -p "$TARGET/player" "$TARGET/gods" "$TARGET/log" "$TARGET/.git"
printf 'player data\n' > "$TARGET/player/Norm"
printf 'god data\n' > "$TARGET/gods/Norm"
printf 'log data\n' > "$TARGET/log/rom-systemd.log"
printf 'git data\n' > "$TARGET/.git/HEAD"
printf 'stale\n' > "$TARGET/stale.txt"

ROM_DEPLOY_LOCAL_TARGET=1 \
ROM_DEPLOY_TARGET_ROOT="$TARGET" \
ROM_DEPLOY_ALLOW_DIRTY=1 \
ROM_DEPLOY_BUILD=0 \
ROM_DEPLOY_RESTART=0 \
  "$SCRIPT" >/dev/null

grep -qx 'player data' "$TARGET/player/Norm"
grep -qx 'god data' "$TARGET/gods/Norm"
grep -qx 'log data' "$TARGET/log/rom-systemd.log"
grep -qx 'git data' "$TARGET/.git/HEAD"
[[ -f "$TARGET/README.md" ]] || { echo "README.md was not deployed" >&2; exit 1; }
[[ ! -e "$TARGET/stale.txt" ]] || { echo "stale tracked-tree file was not removed" >&2; exit 1; }
