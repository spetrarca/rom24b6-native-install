#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

awk '
  /\(\(fp = fopen \(strsave, "w"\)\) == NULL\)/ {
    in_god_log_open = 1
    next
  }

  in_god_log_open && /^[[:space:]]*else[[:space:]]*$/ {
    found_else = 1
    next
  }

  in_god_log_open && /fprintf \(fp, "Lev/ {
    if (!found_else) {
      print "god log fprintf is not guarded after fopen failure" > "/dev/stderr"
      reported = 1
      exit 1
    }
    found_fprintf = 1
    exit 0
  }

  END {
    if (!found_fprintf && !found_else && !reported) {
      print "could not find guarded god log write" > "/dev/stderr"
      exit 1
    }
  }
' "$ROOT/src/save.c"
