# QuickMUD Design Questions

Related backlog: [[requirements|QuickMUD Requirements Backlog]].
Source notes: [[combat-notes]], [[class-combat-notes]], [[summoning-notes]].

This is a living note for broad design work. It tracks the major design tracks,
current leanings, and questions to refine as they come up. It is not an
implementation plan.

## Current Broad Direction

- Keep the world low-fantasy, brutal, tribal, and post-apocalyptic.
- Prefer human PCs and classless player progression if the code can support it.
- Let player identity come from skills, equipment, culture/background, masks,
  tribe/faction, magic contamination, precursor knowledge, and play history.
- Prefer transparent combat math over class THAC0 curves.
- Preserve uncertainty until behavior is tested in-game or traced in code.
- Assume early player files can be wiped when classless progression work begins.

## Design Tracks

### Character Model

Current leaning:

- Remove fixed PC classes.
- Keep or replace stock races only after deciding what distinguishes PCs.
- Replace class identity with starting choices and later skill progression.

Questions to refine:

- Are PCs human-only from the start of the redesign, or should non-human stock
  options remain temporarily hidden/unsupported?
- What replaces class selection during character creation?
- Should starting identity be one choice, such as culture or background, or a
  package of choices such as culture plus starting skill package?
- Should player-facing titles exist without classes?
- Which stock class-indexed tables should collapse to one PC baseline, and
  which should become data-driven choices?
- Should NPC `ACT_WARRIOR`, `ACT_THIEF`, `ACT_CLERIC`, and `ACT_MAGE` flags stay
  as builder archetypes even after PC classes are removed?

### Progression And Skills

Current leaning:

- Make skills the main expression of character build.
- Keep practices/trains only if their purpose stays clear in a classless model.
- Use weapon specialization and learned skills to drive combat identity.

Questions to refine:

- How does a player gain access to new skills without classes?
- Are trainers, books, discoveries, tribes, guilds, or mentors the main unlock
  path?
- Should all skills be theoretically learnable by anyone?
- Should some skills require lore, culture, faction, equipment, illness, or
  environmental exposure?
- What caps skill mastery: practice count, trainer access, ability scores,
  diminishing returns, or nothing?
- How should HP growth work without class HP ranges?

### Combat Hit Resolution

Current leaning:

- Replace class THAC0 with a weapon-skill-centered hit model.
- Normalize defender armor/defense before using it in a transparent formula,
  because stock ROM AC is lower-is-better.

Questions to refine:

- Should the new formula replace only the current THAC0 gate?
- Or should parry, dodge, and shield block be folded into one final hit formula?
- Should level affect hit chance directly, indirectly through skills, or not at
  all?
- What should STR, DEX, hitroll, visibility, victim position, and equipment do?
- Should attacker weapon skill oppose defender armor, defender defense skill, or
  both?
- Should defense skills reduce hit chance, trigger active avoidance messages, or
  mitigate damage after a hit?
- Should NPCs use the same formula as PCs, or keep simple builder-facing
  archetype knobs?

### Combat Round Shape

Current leaning:

- Treat hit chance separately from swing count.
- Keep the current distinction visible while designing so attack count does not
  hide hit-rate changes.

Questions to refine:

- Should haste, slow, second attack, and third attack remain separate mechanics?
- Should extra attacks come from skills, weapons, conditions, or build choices?
- Should classless progression retain an equivalent of warrior/thief multi-hit
  identity, or should extra attacks be rarer?
- Should combat round length stay around three seconds?

### Magic And Illness

Current leaning:

- Magic should not be mage-only.
- Magic should feel like contamination, disease, or interaction with ancient
  forces rather than conventional spellcasting.
- Replace mana-style spell economy with HP and long-term cost mechanics if the
  design still supports it after code investigation.

Questions to refine:

- How does a non-class character learn magic?
- Does learning magic permanently cost maximum HP?
- Does casting magic cost current HP, maximum HP, illness progression, or some
  mix?
- How does magic illness show up mechanically and narratively?
- What does prestige/remort do for magic illness resistance?
- Which stock spells should survive, be renamed, or be removed?

### Death, PVP, And Loot

Current leaning:

- PVP should become less restrictive.
- Full player loot is desired.
- Low-level alternate characters are allowed as policy.

Questions to refine:

- What exact PVP range should apply, especially for attacking upward or downward?
- Which rooms or conditions should still prevent PVP?
- What happens to all worn gear, inventory, and currency on PC death?
- Should corpse ownership exist at all if full loot is desired?
- How do guards, shopkeepers, healers, trainers, and utility NPCs respond to
  PVP or theft?

### Equipment And Item Rules

Current leaning:

- Future gear should be buildable for level 1.
- Stock minimum-level equipment rules should likely be removed or bypassed.
- Weapon categories should be simplified where useful.
- Add a face slot for masks and similar equipment.

Questions to refine:

- Should item levels be removed from data, ignored in code, or both?
- Which equipment use/equip/invoke checks need to change?
- Should spear fold into polearm and flail fold into mace at the skill level,
  item type level, help-text level, or all three?
- What should masks do mechanically, socially, and in builder tooling?
- Should equipment durability exist, and if so should it be opt-in by item tag?

### Survival And Environment

Current leaning:

- Food should be fairly rare.
- Starvation should matter mechanically.
- Builder-facing environmental hazards are part of the target world.

Questions to refine:

- What do hunger and thirst currently do in code?
- Should starvation drain current HP, maximum HP, movement, or stats?
- Can starvation kill directly?
- Should thirst be separate from hunger?
- How should temperature, poison rooms, and other hazards be represented in OLC?

### Economy And Storage

Current leaning:

- Replace gold/silver terminology with something more setting-appropriate.
- Currency should probably have physical weight.
- A bank or vault near recall is desired.

Questions to refine:

- What are the new currency names and denominations?
- Should currency be an item, a character field, or both?
- How much should money weigh?
- Should banks store currency only, items only, or both?
- What limits, fees, risks, or access rules should vaults have?

### Builder And World Planning

Current leaning:

- Rooms can be built before final combat/classless decisions.
- Mobs and items need enough character/combat/magic direction first.
- A second test/build port is useful but not fully designed.

Questions to refine:

- What information do builders need before creating mobs?
- What information do builders need before creating items?
- Which NPCs should be unkillable, if any?
- Should a second MUD instance run continuously or only when needed?
- How should test/build data be isolated from production data?
- Should the lore calendar exist before or after major world building starts?

## Near-Term Design Sequence

Recommended broad order:

1. Character model and classless progression.
2. Weapon-skill-centered hit resolution.
3. Magic/illness access and costs.
4. Death, PVP, and loot.
5. Equipment rules and face slot.
6. Builder-facing NPC/item guidance.
7. Economy/storage.
8. Survival/environment systems.
9. Operations support such as a second test instance.

This order can change as investigations reveal blockers.
