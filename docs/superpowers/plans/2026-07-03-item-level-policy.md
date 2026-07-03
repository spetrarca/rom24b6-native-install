# Item Level Policy Implementation Plan

> **For Sal:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan.

**Goal:** Remove player-facing object-level gates while preserving object level as potency/cost metadata. Scrolls, wands, and staves should cost current HP on use, with a lethal cost allowed.

**Architecture:** Keep this scoped to existing C command handlers. Add a small helper in `src/act_obj.c` for magical item HP cost, remove item-level checks from use/equip/buy/steal/save/locate paths, and cover the policy with a source-level shell regression test.

**Tech Stack:** ROM C codebase, existing shell test style under `tests/`, existing make-based build.

## Task 1: Add regression coverage

Create `tests/item-level-policy.sh` that fails while the old level gates remain. It should:

- reject old gates in `src/act_obj.c`:
  - `ch->level < obj->level`
  - `ch->level < scroll->level`
  - `ch->level < staff->level`
  - `ch->level < wand->level`
  - `obj->level > ch->level`
- reject the save gate in `src/save.c`:
  - `ch->level < obj->level - 2`
- reject the locate-object gate in `src/magic.c`:
  - `ch->level < obj->level`
- require `magical_item_hp_cost`, `pay_magical_item_hp_cost`, the formula `1 + UMAX (0, obj->level - ch->level)`, and calls from `do_recite`, `do_brandish`, and `do_zap`.

Run:

```sh
tests/item-level-policy.sh
```

Expected result before implementation: failure on the existing gates.

## Task 2: Remove player-facing level gates

Edit `src/act_obj.c`:

- Remove the donation pit retrieval trust/level block.
- Remove the wear gate in `wear_obj`.
- Remove potion and scroll level rejection.
- Remove staff and wand level from misfire conditions, leaving skill failure intact.
- Remove steal and buy level gates.

Edit `src/magic.c`:

- Remove `ch->level < obj->level` from locate-object filtering.

Edit `src/save.c`:

- Keep key and blank-map exclusions, remove the level-based save exclusion.

## Task 3: Add magical item HP cost

In `src/act_obj.c`, add:

```c
static int magical_item_hp_cost args ((CHAR_DATA * ch, OBJ_DATA * obj));
static bool pay_magical_item_hp_cost args ((CHAR_DATA * ch, OBJ_DATA * obj));
```

Implement:

```c
static int magical_item_hp_cost (CHAR_DATA * ch, OBJ_DATA * obj)
{
    return 1 + UMAX (0, obj->level - ch->level);
}
```

`pay_magical_item_hp_cost` should subtract current HP directly, allow HP to fall below 1, and return `FALSE` when the payment is lethal. The item handlers should consume the scroll or staff/wand charge before calling `raw_kill(ch)` so lethal use is still a real activation.

Call `pay_magical_item_hp_cost` from:

- `do_recite`, after basic target validation and when the scroll will be consumed.
- `do_brandish`, after charge validation and when a staff charge will be consumed.
- `do_zap`, after charge/target validation and when a wand charge will be consumed.

Potions do not pay HP.

## Task 4: Verify

Run:

```sh
tests/item-level-policy.sh
make -C src
```

If an existing full test command is discoverable, run that too. Then inspect `git diff --check` and `git status --short`.
