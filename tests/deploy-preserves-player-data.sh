#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/deploy-rom24b6.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

[[ -x "$SCRIPT" ]] || { echo "missing executable $SCRIPT" >&2; exit 1; }

REMOTE="$TMPDIR/remote.git"
SEED="$TMPDIR/seed"
WORK="$TMPDIR/work"

git init --bare "$REMOTE" >/dev/null
git clone "$REMOTE" "$SEED" >/dev/null 2>&1
git -C "$SEED" config core.hooksPath /dev/null

mkdir -p "$SEED/src" "$SEED/area" "$SEED/player" "$SEED/log" "$SEED/gods"
cp "$SCRIPT" "$SEED/deploy-rom24b6.sh"
cat > "$SEED/.gitignore" <<'EOF'
area/rom
player/*
log/*
gods/*
EOF
cat > "$SEED/src/Makefile" <<'EOF'
rom:
	mkdir -p ../area
	printf 'built\n' > ../area/rom
	chmod +x ../area/rom

clean:
	rm -f ../area/rom
EOF
cat > "$SEED/README.md" <<'EOF'
initial
EOF

git -C "$SEED" add .
git -C "$SEED" commit -m "initial" >/dev/null
git -C "$SEED" branch -M main
git -C "$SEED" push origin main >/dev/null 2>&1

git clone "$REMOTE" "$WORK" >/dev/null 2>&1
git -C "$WORK" config core.hooksPath /dev/null
git -C "$WORK" switch main >/dev/null 2>&1
mkdir -p "$WORK/player"
printf 'player data\n' > "$WORK/player/Norm"

printf 'updated\n' > "$SEED/README.md"
git -C "$SEED" add README.md
git -C "$SEED" commit -m "update" >/dev/null
git -C "$SEED" push origin main >/dev/null 2>&1

ROM_DEPLOY_RESTART=0 "$WORK/deploy-rom24b6.sh" >/dev/null

grep -qx 'player data' "$WORK/player/Norm"
grep -qx 'updated' "$WORK/README.md"
[[ -x "$WORK/area/rom" ]] || { echo "missing rebuilt area/rom" >&2; exit 1; }
