#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACT_WIZ="$ROOT/src/act_wiz.c"
CONST="$ROOT/src/const.c"
GROUP_HELP="$ROOT/area/group.are"
HANDLER="$ROOT/src/handler.c"
MAGIC="$ROOT/src/magic.c"
MERC="$ROOT/src/merc.h"
NANNY="$ROOT/src/nanny.c"
SAVE="$ROOT/src/save.c"

require_fixed() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "weapon consolidation is missing: $label" >&2
    exit 1
  fi
}

reject_fixed() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    echo "weapon consolidation still has legacy progression: $label" >&2
    grep -Fn "$pattern" "$file" >&2
    exit 1
  fi
}

require_fixed "$MERC" "int    weapon_skill_lookup" "weapon class to canonical skill declaration"
require_fixed "$MERC" "int    normalize_weapon_skill_sn" "legacy skill normalization declaration"
require_fixed "$MERC" "void   normalize_legacy_weapon_skills" "legacy learned-value migration declaration"

require_fixed "$HANDLER" "int weapon_skill_lookup (int weapon_class)" "weapon class to skill helper"
require_fixed "$HANDLER" "return normalize_weapon_table_index (type);" "weapon choice prefixes canonicalize legacy table hits"
require_fixed "$HANDLER" "case (WEAPON_SPEAR):" "legacy spear/staff weapon class branch"
require_fixed "$HANDLER" "return gsn_polearm;" "spear/staff weapons use polearm"
require_fixed "$HANDLER" "case (WEAPON_FLAIL):" "legacy flail weapon class branch"
require_fixed "$HANDLER" "return gsn_mace;" "flail weapons use mace"
require_fixed "$HANDLER" "normalize_weapon_skill_sn (sn)" "weapon skill lookups normalize legacy skill numbers"
require_fixed "$HANDLER" "normalize_legacy_weapon_skills (CHAR_DATA * ch)" "learned skill migration helper"
require_fixed "$HANDLER" "ch->pcdata->learned[gsn_polearm] = UMAX" "spear learned value merges into polearm"
require_fixed "$HANDLER" "ch->pcdata->learned[gsn_mace] = UMAX" "flail learned value merges into mace"

require_fixed "$MAGIC" "!str_cmp (name, \"spear\")" "exact spear skill alias"
require_fixed "$MAGIC" "!str_cmp (name, \"staff\")" "exact staff skill alias"
require_fixed "$MAGIC" "!str_cmp (name, \"flail\")" "exact flail skill alias"
require_fixed "$MAGIC" "return gsn_polearm;" "spear/staff aliases resolve to polearm"
require_fixed "$MAGIC" "return gsn_mace;" "flail alias resolves to mace"
require_fixed "$MAGIC" "return normalize_weapon_skill_sn (sn);" "skill lookup prefixes canonicalize legacy skill hits"

require_fixed "$SAVE" "normalize_legacy_weapon_skills (ch);" "pfile read/write normalizes legacy weapon skills"

require_fixed "$CONST" "\"flail\", {53, 53, 53, 53}, {0, 0, 0, 0}" "legacy flail skill unavailable for new progression"
require_fixed "$CONST" "\"spear\", {53, 53, 53, 53}, {0, 0, 0, 0}" "legacy spear skill unavailable for new progression"
require_fixed "$CONST" "{\"mace\", \"attack\", \"creation\", \"curative\", \"benedictions\"," "cleric default grants mace instead of flail"
require_fixed "$CONST" "{\"axe\", \"dagger\", \"mace\", \"polearm\", \"sword\", \"whip\"}" "weaponsmaster has canonical weapon list"
reject_fixed "$CONST" "{\"flail\", \"attack\", \"creation\", \"curative\", \"benedictions\"," "cleric default grants legacy flail"
reject_fixed "$CONST" "{\"axe\", \"dagger\", \"flail\", \"mace\", \"polearm\", \"spear\", \"sword\", \"whip\"}" "weaponsmaster grants legacy flail/spear"

require_fixed "$NANNY" "weapon_lookup (argument)" "creation still accepts weapon choices through lookup aliases"
require_fixed "$ACT_WIZ" "normalize_legacy_weapon_skills (ch);" "outfit selection ignores stale legacy learned values"
require_fixed "$ACT_WIZ" "case (WEAPON_SPEAR):" "stat supports legacy spear/staff weapon class"
require_fixed "$ACT_WIZ" "send_to_char (\"polearm\\n\\r\", ch);" "stat shows legacy spear/staff as polearm"
require_fixed "$ACT_WIZ" "case (WEAPON_FLAIL):" "stat supports legacy flail weapon class"
require_fixed "$ACT_WIZ" "send_to_char (\"mace/club\\n\\r\", ch);" "stat shows legacy flail as mace"

require_fixed "$MAGIC" "send_to_char (\"polearm.\\n\\r\", ch);" "identify shows legacy spear/staff as polearm"
require_fixed "$MAGIC" "send_to_char (\"mace/club.\\n\\r\", ch);" "identify shows legacy flail as mace"
reject_fixed "$MAGIC" "send_to_char (\"spear/staff.\\n\\r\", ch);" "identify exposes legacy spear/staff class"
reject_fixed "$MAGIC" "send_to_char (\"flail.\\n\\r\", ch);" "identify exposes legacy flail class"

require_fixed "$GROUP_HELP" "flails" "help text keeps flail as mace-compatible wording"
require_fixed "$GROUP_HELP" "spears and staves" "help text keeps spear/staff as polearm-compatible wording"
reject_fixed "$GROUP_HELP" "flails ignore shield blocking attempts" "obsolete flail shield-block claim"
