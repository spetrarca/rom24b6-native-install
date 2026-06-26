#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

missing=()
for command in gcc make; do
  if ! command -v "$command" >/dev/null 2>&1; then
    missing+=("$command")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "Missing required build tools: ${missing[*]}" >&2
  echo "On Debian/Ubuntu, install them with:" >&2
  echo "  sudo apt update && sudo apt install -y build-essential libcrypt-dev" >&2
  exit 1
fi

mkdir -p "$ROOT/log" "$ROOT/player" "$ROOT/gods"
make -C "$ROOT/src" clean
make -C "$ROOT/src"

echo
echo "QuickMUD / ROM built successfully."
echo "Start it with:"
echo "  ./run-rom24b6.sh start"
