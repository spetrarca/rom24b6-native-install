#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="$ROOT/ops/systemd/rom24-quickmud-restart.service"
TIMER="$ROOT/ops/systemd/rom24-quickmud-restart.timer"

[[ -f "$SERVICE" ]] || { echo "missing $SERVICE" >&2; exit 1; }
[[ -f "$TIMER" ]] || { echo "missing $TIMER" >&2; exit 1; }

grep -qx 'ExecStart=/bin/systemctl restart rom24-quickmud.service' "$SERVICE"
grep -qx 'OnCalendar=\*-\*-\* 10:00:00' "$TIMER"
grep -qx 'Unit=rom24-quickmud-restart.service' "$TIMER"
grep -qx 'Persistent=false' "$TIMER"
