# Combat Notes

Related backlog: [[requirements|QuickMUD Requirements Backlog]].
Design questions: [[design-questions]].

These notes summarize the current QuickMUD / ROM 2.4b6 combat flow from the
source. They describe current behavior only; they are not a redesign proposal.

## Core Loop

Combat is pulse-driven. `update_handler()` calls `violence_update()` every
`PULSE_VIOLENCE`, and `PULSE_VIOLENCE` is `3 * PULSE_PER_SECOND`. With
`PULSE_PER_SECOND` set to `4`, a combat round fires about every three seconds.

Key references:

- `src/merc.h:155` defines pulse timing.
- `src/update.c:1178` calls `violence_update()`.
- `src/fight.c:66` walks the active character list.

`violence_update()` checks every character with `ch->fighting` set. If the
fighter is awake and still in the same room as the target, it calls
`multi_hit()`. If either condition is false, it stops that fighter's combat.
After a round, it runs auto-assist checks and mob fight/hit-point triggers.

## Starting A Fight

Most combat entry points call either `multi_hit()` or `damage()`. `damage()` is
also responsible for creating reciprocal fight state when needed:

- If the victim is not fighting, `damage()` calls `set_fighting(victim, ch)`.
- If the attacker is not fighting, `damage()` calls `set_fighting(ch, victim)`.
- `set_fighting()` strips sleep, sets `ch->fighting`, and sets position to
  `POS_FIGHTING`.

Important entry points:

- `do_kill()` and `do_murder()` start with `multi_hit()`.
- `do_backstab()` starts a special `multi_hit()` using `gsn_backstab`.
- Offensive spells call spell functions, then may force a counterattack if the
  target was not already fighting.
- Aggressive mobs are handled by `aggr_update()` in `src/update.c:1077`.

## Combat Rounds

`multi_hit()` is the per-round attack bundle for player characters:

1. One normal `one_hit()`.
2. One extra `one_hit()` if hasted.
3. A possible second attack at `get_skill(second_attack) / 2`.
4. A possible third attack at `get_skill(third_attack) / 4`.

Slow reduces or prevents extra attacks. Backstab short-circuits after its
special hit and does not continue into second or third attacks.

NPCs use `mob_hit()`, which starts with the same basic attack pattern but adds
NPC-only behavior:

- Area attacks can hit other characters already fighting the mob.
- `AFF_HASTE` and `OFF_FAST` can grant extra attacks.
- NPCs can randomly attempt flagged combat skills such as bash, berserk,
  disarm, kick, dirt, trip, or backstab.

## Hit Resolution

`one_hit()` resolves a single melee swing.

The function:

1. Determines the weapon or natural attack message.
2. Maps the attack to a damage type such as slash, pierce, bash, fire, cold, or
   lightning.
3. Gets the attacker's weapon skill.
4. Computes THAC0 from class or NPC role.
5. Applies hitroll and weapon skill adjustments.
6. Chooses the victim AC bucket based on damage type.
7. Applies visibility and victim-position AC adjustments.
8. Rolls a 0-19 die. A 0 always misses, and a 19 bypasses the normal threshold
   check.
9. If the THAC0 roll succeeds, `damage()` may still stop the swing with parry,
   dodge, or shield block.

Relevant references:

- `src/fight.c:386` starts `one_hit()`.
- `src/const.c:394` defines class THAC0 values.
- `src/handler.c:450` maps wielded weapon types to weapon skills.
- `src/handler.c:492` computes weapon skill.
- `src/merc.h:2104` defines AC, hitroll, and damroll macros.
- `src/fight.c:793` runs parry, dodge, and shield block after a weapon-like hit
  passes the THAC0 roll.

Current class THAC0 values make warriors the strongest melee attackers, then
thieves, clerics, and mages.

For classless combat design, the main open question is whether a new
weapon-skill-centered formula replaces only the THAC0 gate or also absorbs
parry, dodge, and shield block. Today those active defenses happen after a
successful THAC0 roll, so final landed-hit chance can be much lower than the
main hit roll suggests.

## Damage Calculation

After a hit lands, `one_hit()` calculates base damage:

- Old-format NPCs use level-based random damage.
- New-format NPCs use their `damage` dice.
- Wielded weapons use object dice scaled by weapon skill.
- Empty hands use level and skill-based damage.

Damage is then modified by:

- No-shield bonus.
- Sharp weapon spike chance.
- Enhanced damage.
- Sleeping or resting victim position.
- Backstab multiplier.
- Damroll scaled by weapon skill.

`damage()` then applies the global damage pipeline:

- Weapon damage over 1200 is capped and treated as suspicious.
- Damage above 35 and above 80 is compressed, creating diminishing returns.
- Drunken PCs take 90 percent damage.
- Sanctuary halves incoming damage.
- Protection from good or evil reduces matching attacker damage by 25 percent.
- Melee attacks can be parried, dodged, or shield-blocked.
- Damage type immunity, resistance, or vulnerability applies last.
- Hit points are reduced and `update_pos()` sets the victim state.

Key references:

- `src/fight.c:522` calculates weapon or NPC damage.
- `src/fight.c:688` starts `damage()`.
- `src/fight.c:716` applies damage compression.
- `src/fight.c:804` applies immunity, resistance, and vulnerability.

## Defenses

Parry, dodge, and shield block only apply to melee-style attacks where
`dt >= TYPE_HIT`. Spell damage generally bypasses those checks and relies on
spell saves plus resistance flags instead.

Defense checks:

- `check_parry()` uses roughly half parry skill, requires the victim to be
  awake, and usually requires a wielded weapon.
- `check_dodge()` uses roughly half dodge skill and is weaker if the victim
  cannot see the attacker.
- `check_shield_block()` requires a shield and has a smaller base chance.

All three include the level difference between victim and attacker.

## Skills And Wait States

Combat commands add `WAIT_STATE()` or `DAZE_STATE()` rather than changing the
round scheduler directly. Player input processing decrements wait/daze once per
game loop and skips command execution while `wait > 0`.

Important combat commands:

- `berserk` trades mana/move for hitroll, damroll, AC penalty, and a small heal.
- `bash` can knock the target resting and dazed, with size/weight/strength/AC
  modifiers.
- `dirt` can blind the target based on dexterity, speed, level, and terrain.
- `trip` can knock the target resting and dazed unless they are flying.
- `kick` is a simple level-based damage skill.
- `disarm` compares weapon skills, dexterity, strength, and level.
- `rescue` retargets a fight onto the rescuer.
- `flee` tries random exits up to six times, with daze making escape harder.

## Death And Rewards

When `damage()` pushes a victim to `POS_DEAD`, it:

1. Calls `group_gain()`.
2. Logs the death.
3. Runs NPC death triggers.
4. Calls `raw_kill()`.
5. Runs autoloot, autogold, and autosac behavior for NPC corpses.

`raw_kill()` stops combat, sends a death cry, creates a corpse, and extracts the
victim. NPCs are removed. PCs are extracted without permanent removal, stripped
of affects, reset to resting, and left with at least 1 hit point, mana, and
movement.

XP is group-based. `xp_compute()` considers level difference, alignment, play
time per level, randomization, and total group levels.

## High-Impact Tuning Knobs

The most important current tuning points are:

- Round speed: `PULSE_VIOLENCE` in `src/merc.h`.
- Class melee accuracy: `class_table` THAC0 values in `src/const.c`.
- NPC and weapon skill scaling: `get_skill()` and `get_weapon_skill()` in
  `src/handler.c`.
- Damage compression thresholds in `damage()`.
- Extra-attack probabilities in `multi_hit()` and `mob_hit()`.
- Parry, dodge, and shield block odds in `src/fight.c`.
- Command-specific skill formulas in `do_bash()`, `do_dirt()`, `do_trip()`,
  `do_kick()`, and `do_disarm()`.
