#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SYSTEMD_DIR="${ROM_SYSTEMD_DIR:-/etc/systemd/system}"
UNITS=(
  rom24-quickmud.service
  rom24-quickmud-restart.service
  rom24-quickmud-restart.timer
)

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run this script with sudo so it can install systemd units." >&2
  exit 1
fi

for unit in "${UNITS[@]}"; do
  install -m 0644 "$ROOT/ops/systemd/$unit" "$SYSTEMD_DIR/$unit"
done

systemctl daemon-reload
systemctl enable rom24-quickmud.service
systemctl enable --now rom24-quickmud-restart.timer

echo "Installed QuickMUD systemd units."
echo "Nightly restart timer:"
systemctl list-timers rom24-quickmud-restart.timer --no-pager
