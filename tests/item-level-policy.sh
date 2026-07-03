#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACT_OBJ="$ROOT/src/act_obj.c"
FIGHT="$ROOT/src/fight.c"
MERC="$ROOT/src/merc.h"
MAGIC="$ROOT/src/magic.c"
SAVE="$ROOT/src/save.c"

reject_fixed() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    echo "item level policy still has gate: $label" >&2
    grep -Fn "$pattern" "$file" >&2
    exit 1
  fi
}

require_fixed() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "item level policy is missing: $label" >&2
    exit 1
  fi
}

reject_fixed "$ACT_OBJ" "get_trust (ch) < obj->level" "donation pit retrieval level check"
reject_fixed "$ACT_OBJ" "ch->level < obj->level" "object use/wear level check"
reject_fixed "$ACT_OBJ" "ch->level < scroll->level" "scroll level check"
reject_fixed "$ACT_OBJ" "ch->level < staff->level" "staff level check"
reject_fixed "$ACT_OBJ" "ch->level < wand->level" "wand level check"
reject_fixed "$ACT_OBJ" "obj->level > ch->level" "buy/steal level check"
reject_fixed "$ACT_OBJ" "raw_kill (ch);" "item-use direct raw_kill shortcut"
reject_fixed "$SAVE" "ch->level < obj->level - 2" "save filtering level check"
reject_fixed "$MAGIC" "ch->level < obj->level" "locate object level check"

require_fixed "$FIGHT" "bool finish_death" "shared standard death finalizer"
require_fixed "$FIGHT" "if (ch == NULL)" "standard death finalizer null killer guard"
if ! awk '
  /if \(ch != victim/ { saw_self_guard = 1; next }
  saw_self_guard && /&& !IS_NPC \(ch\)/ { found = 1 }
  END { exit found ? 0 : 1 }
' "$FIGHT"; then
  echo "item level policy is missing: self-death skips killer auto commands" >&2
  exit 1
fi
require_fixed "$MERC" "bool    finish_death" "standard death finalizer declaration"
require_fixed "$ACT_OBJ" "static int magical_item_hp_cost" "magical item HP cost helper"
require_fixed "$ACT_OBJ" "static bool pay_magical_item_hp_cost" "magical item HP payment helper"
require_fixed "$ACT_OBJ" "return 1 + UMAX (0, obj->level - ch->level);" "HP cost delta formula"
require_fixed "$ACT_OBJ" "pay_magical_item_hp_cost (ch, scroll)" "scroll HP cost payment"
require_fixed "$ACT_OBJ" "pay_magical_item_hp_cost (ch, staff)" "staff HP cost payment"
require_fixed "$ACT_OBJ" "pay_magical_item_hp_cost (ch, wand)" "wand HP cost payment"
