# Class And Combat Notes

Related backlog: [[requirements|QuickMUD Requirements Backlog]].
Design questions: [[design-questions]].

These notes describe how the current QuickMUD / ROM 2.4b6 class system affects
combat. They are a source-reading snapshot, not a redesign proposal.

## Class Table Shape

Player classes are hard-coded around `MAX_CLASS == 4` in `src/merc.h:143`.
The four current classes are defined in `class_table` in `src/const.c:394`:

| Class | Prime | First weapon | THAC0 0 | THAC0 32 | HP gain | Mana class | Base group | Default group |
| --- | --- | --- | ---: | ---: | ---: | --- | --- | --- |
| mage | INT | dagger | 20 | 6 | 6-8 | yes | mage basics | mage default |
| cleric | WIS | mace | 20 | 2 | 7-10 | yes | cleric basics | cleric default |
| thief | DEX | dagger | 20 | -4 | 8-13 | no | thief basics | thief default |
| warrior | STR | sword | 20 | -10 | 11-15 | no | warrior basics | warrior default |

The fields come from `struct class_type` in `src/merc.h:544`:

- `attr_prime`: the class's prime stat.
- `weapon`: intended first weapon vnum.
- `guild`: class-restricted guild room vnums.
- `skill_adept`: maximum practice percentage.
- `thac0_00` and `thac0_32`: the class melee accuracy curve.
- `hp_min` and `hp_max`: hit points gained on level-up before modifiers.
- `fMana`: whether the class is a full mana/spell class.
- `base_group` and `default_group`: skill packages granted at creation.

All four current classes have `skill_adept` set to 75, so the practice cap is
not presently a class differentiator.

## Character Creation

Race is chosen before class. Race sets base stats, max stats, size, innate
skills, and class experience multipliers in `pc_race_table`
(`src/const.c:356`, `src/nanny.c:475`).

Class is chosen in `nanny()` after sex selection (`src/nanny.c:521`). After
alignment, the character automatically receives:

- `rom basics`
- `class_table[ch->class].base_group`
- `recall` at 50 percent

If the player skips customization, the class default group is also added
(`src/nanny.c:609`). The player then chooses one known weapon skill, which is
raised to 40 percent (`src/nanny.c:632`). If the player customizes, class
ratings determine which groups and skills may be selected and how many creation
points they cost.

At first login, a level-0 character receives a direct +3 to the prime stat
(`src/nanny.c:769`), then starts at level 1 with 3 trains and 5 practices.

Starting equipment is class-adjacent but not purely `class_table.weapon`.
`do_outfit()` chooses the school weapon tied to the highest known weapon skill
(`src/act_wiz.c:278`). The static `class_table.weapon` field is still useful
documentation and legacy structure, but the actual outfit choice follows known
weapon skills.

## Skill And Group Access

The strongest class-combat coupling is in `skill_table` and `group_table`.
Each skill has:

- `skill_level[MAX_CLASS]`: the level each class needs.
- `rating[MAX_CLASS]`: the class-specific cost and learning difficulty.

Each group also has `rating[MAX_CLASS]`.

For mortals, current "not available" skill levels are usually represented by
`53`, which is above `LEVEL_HERO` and `LEVEL_IMMORTAL` in this codebase. This is
different from older Merc-era documentation that used a lower immortal-only
level for unavailable skills.

Class ratings matter in four places:

- Creation customization: unavailable when rating is less than 1, and otherwise
  adds that many creation points (`src/skills.c:698`).
- `gain`: post-creation learning requires enough trains and a positive class
  rating (`src/skills.c:176`).
- `practice`: practice increment is divided by the class rating
  (`src/act_info.c:2771`).
- `check_improve`: natural improvement chance is divided by rating
  (`src/skills.c:923`).

So a class can differ from another class even when both can eventually learn
the same skill. Lower rating means cheaper at creation, cheaper to gain later,
faster to practice up, and easier to improve through use.

## Current Combat Packages

The default groups make the four stock classes fight very differently.

Mages:

- Start with dagger basics and many spell groups.
- Get the weakest THAC0 curve and lowest HP gain.
- Are full mana classes.
- Can learn combat spells through the `combat` spell group.
- Have delayed defensive/melee skills: dodge at 20, parry at 22, hand-to-hand
  at 25, second attack at 30, enhanced damage at 45.

Clerics:

- Start with mace basics and divine/support spell groups.
- Have better THAC0 and HP than mages, but worse melee than thieves/warriors.
- Are full mana classes.
- Default into shield block and several offensive/healing spell groups.
- Get kick at 12, hand-to-hand at 10, parry at 20, dodge at 22, second attack
  at 24, enhanced damage at 30.

Thieves:

- Start with dagger and steal basics.
- Default into mace, sword, backstab, disarm, dodge, second attack, trip, hide,
  peek, pick lock, and sneak.
- Have the second-best PC THAC0 curve.
- Are not full mana classes.
- Get backstab, dodge, and trip at level 1; second attack at 12; third attack
  at 24; enhanced damage at 25.

Warriors:

- Start with sword and second attack basics.
- Default into `weaponsmaster`, shield block, bash, disarm, enhanced damage,
  parry, rescue, and third attack.
- Have the best THAC0 curve and best HP gain.
- Are not full mana classes.
- Get parry, rescue, bash, and enhanced damage very early, with third attack at
  12.

## Combat Loop

Combat is pulse-driven. `PULSE_VIOLENCE` is `3 * PULSE_PER_SECOND`, and
`PULSE_PER_SECOND` is 4, so normal combat rounds happen about every three
seconds (`src/merc.h:155`).

`violence_update()` walks characters with `ch->fighting` set and calls
`multi_hit()` if the attacker is awake and still in the same room as the target
(`src/fight.c:66`).

For player characters, `multi_hit()` does:

1. One normal `one_hit()`.
2. One extra hit if hasted.
3. A possible second attack at `get_skill(second attack) / 2`.
4. A possible third attack at `get_skill(third attack) / 4`.

Because the current practice cap is 75, a fully practiced second attack gives
about a 37 percent extra swing chance, and a fully practiced third attack gives
about an 18 percent extra swing chance.

NPCs use `mob_hit()` instead. Mobs do not use PC `class_table` for most combat
identity. They use act flags such as `ACT_WARRIOR`, `ACT_THIEF`, `ACT_CLERIC`,
and `ACT_MAGE`, plus offensive flags such as `OFF_BASH`, `OFF_FAST`,
`OFF_DODGE`, `OFF_TRIP`, and `OFF_DISARM`.

## Hit Chance

`one_hit()` resolves a single melee swing (`src/fight.c:386`).

The hit chance pipeline is:

1. Determine damage message and damage type.
2. Map wielded weapon type to a weapon skill with `get_weapon_sn()`.
3. Set local `skill = 20 + get_weapon_skill(ch, sn)`.
4. Get class or NPC-role THAC0 values.
5. Interpolate current-level THAC0 with `interpolate()`.
6. Compress very good THAC0 values.
7. Apply hitroll scaled by weapon skill.
8. Apply a penalty for weak weapon skill.
9. Compare a 0-19 roll to `thac0 - victim_ac`.

The interpolation formula is:

```c
value_00 + level * (value_32 - value_00) / 32
```

`thac0_00` and `thac0_32` are stored endpoints, not a full per-level table.
The code computes every level from them at runtime. Level 32 lands on the
second endpoint before compression; levels above 32 keep moving along the same
slope.

The formula uses C integer division, so small fractional changes are truncated
toward zero before they affect the final number. For example, all current
classes still have raw THAC0 20 at level 1.

After interpolation, `one_hit()` applies two clamps:

```c
if (thac0 < 0)
    thac0 = thac0 / 2;

if (thac0 < -5)
    thac0 = -5 + (thac0 + 5) / 2;
```

That means high-level THAC0 still improves beyond the level-32 table value, but
improvements are compressed.

Current post-compression class THAC0 values:

| Class | L0 | L1 | L5 | L10 | L15 | L20 | L25 | L30 | L32 | L33 | L40 | L51 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| mage | 20 | 20 | 18 | 16 | 14 | 12 | 10 | 7 | 6 | 6 | 3 | -1 |
| cleric | 20 | 20 | 18 | 15 | 12 | 9 | 6 | 4 | 2 | 2 | -1 | -4 |
| thief | 20 | 20 | 17 | 13 | 9 | 5 | 2 | -1 | -2 | -2 | -5 | -7 |
| warrior | 20 | 20 | 16 | 11 | 6 | 2 | -1 | -4 | -5 | -5 | -6 | -9 |

After class/NPC-role THAC0 is computed, other hit-success factors still apply:

- `GET_HITROLL(ch)` lowers THAC0, scaled by local weapon skill. `GET_HITROLL`
  includes the character's hitroll plus STR's to-hit modifier.
- Weak weapon skill raises THAC0 through `5 * (100 - skill) / 100`. The local
  combat skill is `20 + get_weapon_skill()`, so practiced or high-level weapon
  skill can reduce or erase this penalty.
- Backstab has a special THAC0 modifier in this tree:
  `thac0 -= 10 * (100 - get_skill(ch, gsn_backstab))`.
- Damage type chooses which victim AC bucket matters: pierce, bash, slash, or
  exotic.
- `GET_AC(victim, type)` includes armor plus DEX's defensive modifier when the
  victim is awake. Lower AC is better for the defender.
- Very good victim AC below `-15` is compressed with diminishing returns.
- If the attacker cannot see the victim, the victim's AC is lowered by 4, making
  the victim harder to hit.
- A victim below fighting position is easier to hit. The code adds 4 to AC below
  `POS_FIGHTING`, and another 6 below `POS_RESTING`.
- The final roll is a uniform 0-19. A 0 always misses. A 19 bypasses the normal
  threshold check. Other rolls miss when they are lower than `thac0 - victim_ac`.
- After the THAC0 roll succeeds, `damage()` can still stop weapon-like hits with
  parry, dodge, or shield block.

The current hit-resolution stack has three separate layers:

1. Swing count: one normal swing, plus haste, second attack, and third attack
   chances.
2. THAC0 gate: class/NPC-role THAC0, weapon skill, hitroll, defender AC,
   visibility, and victim position decide whether a swing passes the main
   hit/miss roll.
3. Active defenses: parry, dodge, and shield block can still stop weapon-like
   hits after the THAC0 roll succeeds.

This separation matters for a classless redesign. Replacing class THAC0 with a
weapon-skill-centered formula can mean either:

- Replace only the THAC0 gate, leaving parry, dodge, and shield block as
  separate active defense rolls.
- Fold active defenses into one transparent hit-resolution formula, so final
  landed-hit chance is computed in one place.

The first option is a smaller change and preserves more ROM behavior. The
second option would be easier to explain and tune, but it changes the meaning of
defense skills and needs a broader balance pass.

With max practiced weapon skill (`learned == 75`, local combat skill 95), no
hitroll, and no other modifiers, level-32 hit odds look roughly like this:

| Class | vs AC 0 | vs AC -10 | vs AC -15 |
| --- | ---: | ---: | ---: |
| mage | 70% | 20% | 5% |
| cleric | 90% | 40% | 15% |
| thief | 95% | 60% | 35% |
| warrior | 95% | 75% | 50% |

This is the main direct place where PC class changes melee accuracy.

## Damage

Class does not directly add melee damage in `one_hit()`. Damage mostly comes
from:

- Weapon dice.
- Weapon skill scaling.
- No-shield bonus.
- Sharp weapon spikes.
- Enhanced damage.
- Backstab multiplier.
- Damroll scaled by weapon skill.
- Strength's `str_app` hitroll/damroll bonuses.

Class affects this indirectly:

- Warrior prime STR makes higher hitroll/damroll easier.
- Thief prime DEX helps trip/disarm/dodge style play.
- Class skill tables determine who gets enhanced damage, backstab, bash, trip,
  kick, second attack, and third attack early or cheaply.
- Class HP gain affects how long a character survives trading blows.

After `one_hit()` computes raw damage, `damage()` applies global compression:

- Damage above 35 is reduced.
- Damage above 80 is reduced again.

Then sanctuary, protection, parry/dodge/shield block, resistance, vulnerability,
and immunity apply.

## Defenses

Melee defenses happen in `damage()` only for attacks where `dt >= TYPE_HIT`.
This means ordinary weapon swings can be parried, dodged, or shield-blocked,
while most spell damage bypasses those checks and uses saves/resistances.

Defense formulas:

- Parry: roughly half parry skill, requires awake, and PCs must wield a weapon.
- Dodge: roughly half dodge skill, reduced if the defender cannot see the
  attacker.
- Shield block: `skill / 5 + 3`, requires a shield.

All three add defender level minus attacker level to the chance.

Classes influence defenses mostly through skill access and prime stat:

- Warriors get parry and shield block early by default.
- Thieves get dodge at level 1 by default.
- Clerics default into shield block.
- Mages can eventually learn dodge/parry, but late and at high rating.
- DEX affects AC through `GET_AC()` and also affects several command formulas.

## Combat Commands

Several combat commands are explicitly class-gated through `skill_level[ch->class]`.

- `berserk`: warrior at 18, dwarf racial bonus can grant it separately.
- `bash`: warrior at 1.
- `dirt kicking`: thief and warrior at 3.
- `trip`: thief at 1, warrior at 15.
- `backstab`: thief at 1.
- `kick`: cleric at 12, thief at 14, warrior at 8.
- `disarm`: thief at 12, warrior at 11.
- `rescue`: warrior at 1.

The command formulas then mix skill percentage, stat checks, size, level
difference, equipment, and status flags. For example, bash uses carry weight,
relative size, STR versus target DEX, bash AC, haste/fast flags, and level
difference. Trip uses relative size, DEX, haste/fast flags, and level
difference. Disarm compares both characters' weapon skills, attacker's skill
with the victim's weapon type, attacker's DEX, victim's STR, and level
difference.

## Magic In Combat

Class affects magic in three important ways:

1. Spell access is per-class in `skill_table`.
2. Spell practice and improvement use class ratings.
3. `fMana` affects both spell power and mana growth.

`do_cast()` refuses spells the character does not know or is too low-level for
(`src/magic.c:327`). On successful cast, full mana classes cast at full level,
while non-mana classes cast at three-quarters level (`src/magic.c:558`).

Offensive spells can start or provoke combat. After an offensive spell resolves,
the victim may counterattack with `multi_hit()` if they were not already
fighting (`src/magic.c:566`).

Saving throws are mostly not class-specific. `saves_spell()` uses level
difference, `saving_throw`, resist/vulnerability/immunity, and then gives
full mana classes a small save advantage by multiplying the save target by 90
percent (`src/magic.c:215`).

## Training, Stats, And Survivability

Current class prime stats matter in three ways:

- New characters get +3 to their prime stat.
- `get_curr_stat()` allows a higher effective cap for prime stats.
- `get_max_train()` allows a higher trainable cap for prime stats.

Older Merc-era documentation says prime stats are cheaper to train, but current
`do_train()` initializes `cost = 1` and does not increase the cost for non-prime
stats. In this source tree, prime stat advantage is about starting value and
cap, not lower train cost.

Combat-relevant stat effects include:

- STR adds hitroll and damroll through `GET_HITROLL()` and `GET_DAMROLL()`.
- DEX improves AC through `GET_AC()` and appears in bash, trip, dirt, and disarm
  formulas.
- CON affects level-up HP and hit point regeneration.
- WIS affects practices gained on level-up.
- INT affects practice gains, skill improvement odds, and mana gain formulas.

Class HP gain also affects regeneration. `hit_gain()` adds
`class_table[ch->class].hp_max - 10` to the base gain for PCs, so warriors get a
better passive healing baseline than mages.

## NPC Class-Like Behavior

NPCs do not rely on `class_table` the way PCs do.

New-format mobs receive stat adjustments from act flags:

- `ACT_WARRIOR`: +3 STR, -1 INT, +2 CON.
- `ACT_THIEF`: +3 DEX, +1 INT, -1 WIS.
- `ACT_CLERIC`: +3 WIS, -1 DEX, +1 STR.
- `ACT_MAGE`: +3 INT, -1 STR, +1 DEX.

In `one_hit()`, NPC THAC0 also uses these act flags:

- warrior-like mobs use the warrior THAC0 endpoint.
- thief-like mobs use the thief endpoint.
- cleric-like mobs use the cleric endpoint.
- mage-like mobs use the mage endpoint.

NPC skills come from `get_skill()` rules based on level, act flags, and
offensive flags, not learned skill arrays. For builders, this means a future
PC class-removal pass will not automatically update mobs unless the mob flag
model and builder documentation are changed too.

## Redesign Implications

Important coupling points before removing fixed PC classes:

1. `class_table` is only the top layer. The real class footprint also includes
   `skill_table`, `group_table`, title tables, creation flow, save/load
   compatibility, help text, and mob flags.
2. THAC0 and skill access are separate balance levers. A warrior hits more
   often because of THAC0, but also because warriors receive more weapon and
   extra-attack support.
3. Current spellcasting is still class-shaped even if non-mana classes can know
   spells. `fMana` controls mana gain, spell save bonus, and full spell level.
4. If the design goal is "anyone can learn magic", the tables need policy for
   spell group availability, ratings, `fMana`, HP-cost magic, and practice
   behavior.
5. If the design moves to human-only PCs with tribe/background/vocation, avoid
   overloading one field with social identity, combat role, magic contamination,
   and builder-facing mob archetype.
6. Weapon consolidation touches more than text. `weapon_table`, weapon item
   classes, skill names, object values, player learned skills, OLC displays, and
   area data all need compatibility decisions.
7. Since early development can assume player files will eventually be wiped,
   deeper class data changes are less constrained by legacy pfiles than a live
   migration would normally be.

## Practical Model

The current class system is best understood as four overlapping layers:

1. Identity layer: class name, who abbreviation, title table, guild rooms.
2. Growth layer: prime stat, HP gain, mana gain, practice/training effects.
3. Access layer: skill/spell levels, ratings, base groups, default groups.
4. Combat math layer: THAC0 curve, weapon skill, extra attacks, defenses,
   command formulas, spell level, saves, and survivability.

Most class-combat behavior comes from layers 2-4, not from the class name
itself.
