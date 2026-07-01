#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE="${ROM_DEPLOY_REMOTE:-origin}"
BRANCH="${ROM_DEPLOY_BRANCH:-main}"
REMOTE_URL="${ROM_DEPLOY_REMOTE_URL:-}"
SERVICE="${ROM_DEPLOY_SERVICE:-rom24-quickmud.service}"
RESTART="${ROM_DEPLOY_RESTART:-1}"
ALLOW_DIRTY="${ROM_DEPLOY_ALLOW_DIRTY:-0}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_runtime_dirs() {
  mkdir -p "$ROOT/log" "$ROOT/player" "$ROOT/gods"
}

tracked_changes() {
  git -C "$ROOT" status --porcelain --untracked-files=no
}

restart_service() {
  if [[ "$RESTART" == "0" ]]; then
    return 0
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    systemctl restart "$SERVICE"
  else
    sudo -n systemctl restart "$SERVICE"
  fi
}

require_command git
require_command make

if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$ROOT is not a git checkout." >&2
  exit 1
fi

if [[ -n "$REMOTE_URL" ]]; then
  if git -C "$ROOT" remote get-url "$REMOTE" >/dev/null 2>&1; then
    git -C "$ROOT" remote set-url "$REMOTE" "$REMOTE_URL"
  else
    git -C "$ROOT" remote add "$REMOTE" "$REMOTE_URL"
  fi
fi

if [[ "$ALLOW_DIRTY" != "1" ]]; then
  dirty="$(tracked_changes)"
  if [[ -n "$dirty" ]]; then
    echo "Tracked local changes would be overwritten or mixed with deploy:" >&2
    echo "$dirty" >&2
    echo "Commit/push builder changes first, or set ROM_DEPLOY_ALLOW_DIRTY=1 to override." >&2
    exit 1
  fi
fi

ensure_runtime_dirs

git -C "$ROOT" fetch "$REMOTE" "$BRANCH"

if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git -C "$ROOT" switch "$BRANCH"
else
  git -C "$ROOT" switch -c "$BRANCH" --track "$REMOTE/$BRANCH"
fi

git -C "$ROOT" merge --ff-only FETCH_HEAD

make -C "$ROOT/src" clean
make -C "$ROOT/src"

restart_service

echo "QuickMUD updated from $REMOTE/$BRANCH."
echo "Runtime data preserved in log/, player/, and gods/."
