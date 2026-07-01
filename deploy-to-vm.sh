#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${ROM_DEPLOY_TARGET:-rom@4.227.179.210}"
TARGET_ROOT="${ROM_DEPLOY_TARGET_ROOT:-/opt/rom24-quickmud}"
SSH_KEY="${ROM_DEPLOY_SSH_KEY:-$HOME/.ssh/rom24_quickmud_azure_ed25519}"
SERVICE="${ROM_DEPLOY_SERVICE:-rom24-quickmud.service}"
LOCAL_TARGET="${ROM_DEPLOY_LOCAL_TARGET:-0}"
ALLOW_DIRTY="${ROM_DEPLOY_ALLOW_DIRTY:-0}"
BUILD="${ROM_DEPLOY_BUILD:-1}"
RESTART="${ROM_DEPLOY_RESTART:-1}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_committed_tree() {
  if [[ "$ALLOW_DIRTY" == "1" ]]; then
    return 0
  fi

  if ! git -C "$ROOT" diff --quiet || ! git -C "$ROOT" diff --cached --quiet; then
    echo "Refusing to deploy with uncommitted tracked changes." >&2
    echo "Commit first, or set ROM_DEPLOY_ALLOW_DIRTY=1 to deploy HEAD anyway." >&2
    exit 1
  fi
}

archive_head() {
  local stage="$1"
  git -C "$ROOT" archive --format=tar HEAD | tar -x -C "$stage"
}

rsync_tree() {
  local source="$1"

  if [[ "$LOCAL_TARGET" == "1" ]]; then
    mkdir -p "$TARGET_ROOT"
    rsync -a --delete \
      --exclude='player/' \
      --exclude='gods/' \
      --exclude='log/' \
      --exclude='area/rom' \
      --exclude='src/obj/' \
      "$source"/ "$TARGET_ROOT"/
  else
    rsync -az --delete \
      --exclude='player/' \
      --exclude='gods/' \
      --exclude='log/' \
      --exclude='area/rom' \
      --exclude='src/obj/' \
      -e "ssh -i $SSH_KEY -o BatchMode=yes" \
      "$source"/ "$TARGET:$TARGET_ROOT"/
  fi
}

run_remote_update() {
  if [[ "$LOCAL_TARGET" == "1" ]]; then
    mkdir -p "$TARGET_ROOT/log" "$TARGET_ROOT/player" "$TARGET_ROOT/gods"
    if [[ "$BUILD" != "0" ]]; then
      make -C "$TARGET_ROOT/src" clean
      make -C "$TARGET_ROOT/src"
    fi
    return 0
  fi

  local command="cd '$TARGET_ROOT' && mkdir -p log player gods"
  if [[ "$BUILD" != "0" ]]; then
    command="$command && make -C src clean && make -C src"
  fi
  if [[ "$RESTART" != "0" ]]; then
    command="$command && sudo -n systemctl restart '$SERVICE'"
  fi

  ssh -i "$SSH_KEY" -o BatchMode=yes "$TARGET" "$command"
}

require_command git
require_command rsync
require_command tar
if [[ "$LOCAL_TARGET" != "1" ]]; then
  require_command ssh
  [[ -f "$SSH_KEY" ]] || { echo "Missing SSH key: $SSH_KEY" >&2; exit 1; }
fi

ensure_committed_tree

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

archive_head "$STAGE"
rsync_tree "$STAGE"
run_remote_update

echo "QuickMUD deployed to $TARGET_ROOT."
echo "Runtime data preserved in player/, gods/, and log/."
