#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AREA_DIR="$ROOT/area"
PORT="${ROM_PORT:-4000}"
PID_FILE="$ROOT/rom.pid"
LOG_FILE="$ROOT/log/rom.log"

is_running() {
  [[ -s "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

ensure_runtime_dirs() {
  mkdir -p "$ROOT/log" "$ROOT/player" "$ROOT/gods"
}

start() {
  if is_running; then
    echo "QuickMUD / ROM is already running on port $PORT (pid $(cat "$PID_FILE"))."
    return 0
  fi

  ensure_runtime_dirs

  if [[ ! -x "$AREA_DIR/rom" ]]; then
    echo "Missing $AREA_DIR/rom. Build first with ./install-rom24b6.sh." >&2
    return 1
  fi

  cd "$AREA_DIR"
  rm -f shutdown.txt
  setsid ./rom "$PORT" > "$LOG_FILE" 2>&1 < /dev/null &
  echo "$!" > "$PID_FILE"
  sleep 1

  if is_running; then
    echo "QuickMUD / ROM started on port $PORT (pid $(cat "$PID_FILE"))."
  else
    echo "QuickMUD / ROM failed to start. Last log lines:"
    tail -40 "$LOG_FILE" || true
    return 1
  fi
}

stop() {
  if ! is_running; then
    echo "QuickMUD / ROM is not running."
    rm -f "$PID_FILE"
    return 0
  fi

  pid="$(cat "$PID_FILE")"
  kill "$pid"
  for _ in {1..10}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PID_FILE"
      echo "QuickMUD / ROM stopped."
      return 0
    fi
    sleep 1
  done

  echo "QuickMUD / ROM did not stop gracefully; pid $pid is still alive."
  return 1
}

status() {
  if is_running; then
    echo "QuickMUD / ROM is running on port $PORT (pid $(cat "$PID_FILE"))."
  else
    echo "QuickMUD / ROM is not running."
    return 1
  fi
}

case "${1:-status}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  status) status ;;
  log) tail -f "$LOG_FILE" ;;
  *) echo "Usage: $0 {start|stop|restart|status|log}" >&2; exit 2 ;;
esac
