#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACT_WIZ="$ROOT/src/act_wiz.c"
INTERP="$ROOT/src/interp.c"
INTERP_H="$ROOT/src/interp.h"

require_fixed() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "lorestat is missing: $label" >&2
    exit 1
  fi
}

require_fixed "$INTERP_H" "DECLARE_DO_FUN( do_lorestat" "command declaration"
if ! awk '/"lorestat"/ && /do_lorestat/ && /POS_DEAD/ && /IM/ { found = 1 }
  END { exit found ? 0 : 1 }' "$INTERP"; then
  echo "lorestat is missing: immortal-only command registration" >&2
  exit 1
fi

require_fixed "$ACT_WIZ" "void do_lorestat (CHAR_DATA * ch, char *argument)" "command implementation"
require_fixed "$ACT_WIZ" "lorestat vnum <vnum>" "prototype lookup syntax"
require_fixed "$ACT_WIZ" "get_obj_world (ch, original)" "multi-word loaded object lookup"
require_fixed "$ACT_WIZ" "Player preview:" "player-facing preview section"
require_fixed "$ACT_WIZ" "Admin facts:" "compact admin facts section"
require_fixed "$ACT_WIZ" "lorestat_print_obj_index" "vnum/prototype output path"
require_fixed "$ACT_WIZ" "lorestat_print_obj" "loaded object output path"
require_fixed "$ACT_WIZ" "passage-stone" "warpstone/component preview text"
require_fixed "$ACT_WIZ" "lore tags" "derived lore tag output"
require_fixed "$ACT_WIZ" "plainly named" "builder hint for obvious warpstone naming"
require_fixed "$ACT_WIZ" "magic flag" "builder hint for magical objects without flag"
