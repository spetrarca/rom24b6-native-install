# Summoning Notes

Related backlog: [[requirements|QuickMUD Requirements Backlog]].
Design questions: [[design-questions]].

These notes summarize current summon and nearby transport-spell behavior from
the QuickMUD / ROM 2.4b6 source. They describe current behavior only; they are
not a redesign proposal.

## Main Spell

The direct summon spell is `spell_summon()` in `src/magic.c:4472`. It looks up
the requested target globally with `get_char_world(ch, target_name)`. On
success, it moves the victim from their current room to the caster's room:

1. Message the old room that the target disappears.
2. `char_from_room(victim)`.
3. `char_to_room(victim, ch->in_room)`.
4. Message the caster's room that the target arrives.
5. Tell the victim who summoned them.
6. Force `look auto` for the victim.

The current help entry says summon brings a character from anywhere in the
world into the caster's room, and that fighting characters may not be summoned
(`area/help.are:1645`).

## Failure Conditions

`spell_summon()` collapses all of these conditions into the same player-facing
message: `You failed.`

Current failure cases:

- The named target is not found.
- The target is the caster.
- The target has no room.
- The caster is in a safe room.
- The target is in a safe room.
- The target is in a private room.
- The target is in a solitary room.
- The target is in a no-recall room.
- The target is an aggressive NPC.
- The target is at least three levels above the spell level.
- The target is a PC at immortal level or above.
- The target is already fighting.
- The target is an NPC with `IMM_SUMMON`.
- The target is an NPC shopkeeper.
- The target is a PC with `PLR_NOSUMMON`.
- The target is an NPC that passes `saves_spell(level, victim, DAM_OTHER)`.

This explains why summon can appear unreliable in play: many different rule
failures are intentionally indistinguishable right now.

## Player And NPC Immunity

The `nosummon` command toggles summon immunity differently for PCs and NPCs:

- PCs toggle `PLR_NOSUMMON` in `ch->act`.
- NPCs toggle `IMM_SUMMON` in `ch->imm_flags`.

Reference: `src/act_info.c:1007`.

The flag tables expose these as:

- `nosummon` player flag in `src/tables.c:118`.
- `summon` immunity/resistance/vulnerability flag names in `src/tables.c:637`
  and `src/tables.c:665`.

`spell_summon()` checks NPC `IMM_SUMMON`, but it does not inspect `RES_SUMMON`
or `VULN_SUMMON`. Its NPC saving throw uses `DAM_OTHER`; `check_immune()` falls
back to general magic immunity/resistance/vulnerability for that damage type
rather than mapping it to the summon-specific resistance bit.

## Related Transport Spells

Several nearby transport spells share parts of the summon rule set but move
different things:

- `gate` moves the caster to the target's room and can bring the caster's pet.
- `portal` creates a one-way portal object to the target's room and requires a
  warp stone for non-immortal casters.
- `nexus` creates paired portal objects between the caster's room and target's
  room and also requires a warp stone for non-immortal casters.
- `teleport` moves a target to a random room.

References:

- `src/magic.c:2966` for `spell_gate()`.
- `src/magic2.c:56` for `spell_portal()`.
- `src/magic2.c:105` for `spell_nexus()`.
- `src/magic.c:4508` for `spell_teleport()`.

## Important Differences From Gate And Portal

`gate`, `portal`, and `nexus` check whether the caster can see the destination
room. Direct summon does not check `can_see_room()`.

`gate`, `portal`, and `nexus` also block clan targets from other clans. Direct
summon does not have the clan restriction.

Direct summon blocks caster safe rooms, target safe/private/solitary/no-recall
rooms, aggressive NPCs, fighting targets, immortal PCs, shopkeepers, target
`nosummon`/`IMM_SUMMON`, high-level targets, and NPC saving throws.

Direct summon does not block caster no-recall rooms. By contrast, gate, portal,
and nexus do block no-recall on the caster/from room.

## Documentation And UX Gap

The current help text documents only one failure rule: fighting characters may
not be summoned. The source has many more restrictions, all hidden behind the
same generic failure message.

The existing [[requirements|backlog item]] to improve summon failure messages is
well aligned with the current source. A low-risk implementation would preserve
the current rules but split the long guard clause into named checks that return
specific messages for cases such as target not found, target fighting, room
restriction, target too powerful, `nosummon`, summon-immune NPC, aggressive NPC,
shopkeeper, and saving throw.
