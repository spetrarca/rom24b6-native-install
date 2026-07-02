# QuickMUD Requirements Backlog

This document captures early planning requirements for the QuickMUD / ROM 2.4b6 project. It is a synthesized backlog, not an implementation plan. Items marked as investigations need code reading, gameplay testing, or operator verification before implementation.

## Related Notes

- [[combat-notes|Combat notes]]
- [[class-combat-notes|Class and combat notes]]
- [[design-questions|Design questions]]
- [[summoning-notes|Summoning notes]]

## Planning Goals

- Keep the running MUD easy to access, update, test, and recover.
- Start with small, low-risk changes before deeper combat, class, magic, and world redesigns.
- Establish enough character progression, combat, magic, and item direction that NPCs, mobs, items, and zones can be built with confidence.
- Prefer classless player progression if code investigation supports it. Player identity should come from skills, equipment, background/culture choices, magic contamination, masks, tribe/faction, and play history instead of fixed fantasy classes.
- Prefer transparent combat formulas that are easier to tune and explain than class THAC0 curves, such as weapon skill plus attacker modifiers against a normalized defender armor/defense value.
- Preserve uncertainty where behavior is unknown until it has been tested in-game or traced in code.
- Prefer changes that unblock building and content work without committing too early to full system rewrites.

## Setting and Lore Pillars

- The game should not feel like a Tolkien clone.
- The inspiration is closer to Robert E. Howard / Conan: low fantasy, brutal, tribal, and practical.
- The world is post-apocalyptic and takes place inside a giant structure.
- Civilization is early iron-age and tribal.
- Ancient advanced technology exists but is understood as mythical, sacred, cursed, or magical.
- Precursor knowledge and possession of ancient trinkets should matter socially and mechanically.
- "Magic" is a disease or contamination rather than traditional fantasy spellcasting.
- Ancient technology still functions in some places. "The Dust" is an example of a surviving force or medium that enables what people call magic.
- Masks are important enough to support a face equipment slot, including official or ritual use such as acting on behalf of a tribe.

## Status Legend

- **Ready to define:** The desired direction is clear enough to turn into a small spec.
- **Investigate:** The current behavior or code path is unclear and must be verified first.
- **Design needed:** The goal is known, but the details affect balance, content, persistence, or several systems.
- **Deferred:** Keep the idea, but do not plan it until related decisions are made.

## Small Requirements

### Operations and Source Control

| Item | Status | Notes |
| --- | --- | --- |
| Add a second MUD instance for testing/building on another port | Design needed | Useful for builders and risky mechanic testing. Need decide port, data isolation, copy strategy, and whether it runs continuously. |
| Verify nightly or semi-nightly reboots | Investigate | First verify whether they already happen. If not, add scheduled reboots or copyovers to clear shops, litter, and stale world state. |
| Replace login screen | Ready to define | Should reflect the low-fantasy post-apocalyptic structure setting. Low code risk unless login flow behavior changes. |

### Immediate Gameplay Investigations

| Item | Status | Notes |
| --- | --- | --- |
| Figure out what the lore skill currently does | Investigate | ROM notes say lore is incomplete. Inspect current implementation, test in-game behavior, and propose final behavior. |
| Figure out what hunger and thirst currently do | Investigate | Food should be fairly rare. Need current effects before changing pacing and penalties. |
| Test summon spell reliability | Investigate | Determine whether failures are caused by `nosummon`, `imm_summon`, room flags, mob flags, or spell logic. Report findings before changing behavior. |
| Improve summon failure messages | Ready to define | Replace the generic `You failed.` response with specific player-facing reasons while preserving current summon rules. Useful reasons include target not found, caster or target room restrictions, target fighting, target too powerful, PC `nosummon`, aggressive NPC, summon-immune NPC, shopkeeper, and NPC saving throw/resistance. |
| Verify whether detect spells can target other PCs | Investigate | Need confirm current spell targeting rules and whether this is blocked by spell flags or target checks. |
| Audit guild restrictions | Investigate | Need identify whether restrictions apply to guild rooms, guild objects, practice, class access, commands, or other systems. |
| Audit strange THAC0 / THAC32 behavior | Investigate | Current notes live in [[class-combat-notes]]. Use them as the baseline for deciding what must be replaced by a classless, weapon-skill-centered hit formula. |

### Item Levels and Equipment Rules

| Item | Status | Notes |
| --- | --- | --- |
| Remove minimum levels on existing gear | Design needed | Could be done by bulk editing area data, changing code checks, or both. |
| Bulk edit existing items | Investigate | Identify item level fields across area files and whether automated edits are safe. |
| Remove or comment out level checks for use/equip | Investigate | Locate all checks for wearing, holding, using, and invoking item effects. |
| Build future gear for level 1 | Ready to define | Content convention once code/data policy is chosen. |
| Add face equipment slot for masks, armor, and clothing | Design needed | Known references: `src/merc.h` around lines 1134 and 1336. Need audit wear locations, body/slot tables, save/load, display, OLC, and area files. |
| Selective equipment durability with optional tag | Deferred | Keep until the original purpose is remembered and durability goals are clearer. |

### Existing Mechanic Removals and Condensations

| Item | Status | Notes |
| --- | --- | --- |
| Remove alignment | Design needed | Desired direction is to get rid of alignment altogether. Need audit class restrictions, spells, item flags, mobs, help text, score output, area content, and mob kill effects. |
| Remove movement points | Design needed | Need identify movement costs, regeneration, UI displays, commands, combat effects, and balance implications. |
| Fold spear into polearm | Design needed | Map existing weapon skills, item types, skill names, help text, and player data compatibility. |
| Fold flail into mace | Design needed | Same concerns as spear/polearm consolidation. |
| Widen group spread with no limit | Design needed | Need understand current group level checks and decide whether there should be XP or abuse side effects. |

### Hunger and Survival

| Item | Status | Notes |
| --- | --- | --- |
| Make food fairly rare | Design needed | Depends on understanding current hunger/thirst mechanics and world content. |
| Add starvation HP drain | Design needed | Desired behavior: starvation, defined as hunger below 0, drains current HP. Need decide rate, messaging, death rules, and whether thirst has separate effects. |

## Medium Requirements

### PVP, Death, and Loot

| Item | Status | Notes |
| --- | --- | --- |
| Add asymmetrical PVP level range | Design needed | Players can attack any target above their own level, but only targets up to 10 levels below. Need exact attacker/victim checks, group behavior, safe rooms, and immortals. |
| Allow smurfing | Ready to define | Low-level alternate characters are acceptable as a game policy. Mechanics should not try to prevent them unless a later abuse case requires it. |
| Full player loot | Design needed | A player who dies for any reason leaves a corpse that anyone can loot. Need define corpse ownership, decay, retrieval, room safety, and edge cases. |
| Death drops corpse with all gear | Design needed | Required for full loot. Need decide NPC vs PC behavior, inventory/equipment handling, gold/currency handling, and save interactions. |
| Less restrictive PVP generally | Design needed | Broader policy around safe rooms, clans/groups, guards, penalties, logging, and newbie protection. |

### Magic, Lore Skill, and Spell Costs

| Item | Status | Notes |
| --- | --- | --- |
| Let anyone learn magic | Design needed | Magic should not be mage-only. Need decide how trainers, skill tables, practice, class-removal work, and magic illness interact with spell access. |
| Replace mana-style spell economy | Design needed | Learning a new spell costs maximum HP, scaled by spell power. Casting spells costs current HP. Spellcasting should not rely on mana, MP, charges, or a separate magic resource. |
| Tie magic costs to illness lore | Design needed | Magic is a disease or contamination. Spell learning/casting should reinforce that fiction mechanically. |
| Fix or implement lore skill | Design needed | After investigation, define lore as a skill that helps identify ancient technology, precursor trinkets, magic disease effects, or related world knowledge. |

### Economy and Storage

| Item | Status | Notes |
| --- | --- | --- |
| Replace gold and silver currency | Design needed | Currency should be more lore-appropriate than stock ROM gold/silver. Need choose names, denominations, and display text. |
| Give money physical weight | Design needed | Currency should affect carrying capacity. Need decide unit weights, containers, banking implications, corpses, and shops. |
| Add bank/vault system near recall spot | Design needed | Need define currency storage, item vaults, limits, persistence, NPC interaction, access rules, and player file format. |

### Character Progression and Prestige

| Item | Status | Notes |
| --- | --- | --- |
| Add remort/prestige system | Design needed | A character loses everything to gain passive stat advantages and resistance to magic illness effects. Need define what resets, what persists, how rewards stack, and how this affects PVP. |
| Reduce maximum HP cost for spells as prestige reward | Design needed | Earlier prestige reward idea. May fit as one passive benefit among several. |
| Design classless progression enough for mobs/NPCs/items | Design needed | Needed before serious mob and item building. Desired direction is no fixed PC classes, but builders still need clear combat roles, skill access expectations, magic exposure rules, equipment assumptions, and NPC archetype guidance. Rooms can still be built while this is unresolved. |

### Builder and Environment Tools

| Item | Status | Notes |
| --- | --- | --- |
| Add temperature and environmental hazards in OLC | Design needed | Include hazards such as poison rooms. Need define room/area fields, effects, messaging, saving/loading, and builder UX. |
| Rewrite calendar | Design needed | Need define lore calendar, day/month/year display, seasonal behavior, and compatibility with existing time/weather code. |
| Decide whether any mobs should be unkillable | Design needed | Includes shopkeepers, healers, trainers, and quest or utility NPCs. Need policy before changing flags or code protections. |

## Large Requirements

### Character Identity and Class Removal

| Item | Status | Notes |
| --- | --- | --- |
| Human PCs only | Design needed | Need determine whether this removes races from character creation, keeps NPC races, and migrates existing players. |
| Add alternate means of distinguishing PCs | Design needed | Needed if race variety and fixed classes are removed. Could involve tribe, mask, background, culture, origin, faction, education, vocation, illness exposure, precursor knowledge, or starting skill package. |
| Remove fixed PC classes | Design needed | Desired direction is to go without player classes if feasible. Current classes affect creation, skill/group access, THAC0, HP gain, mana behavior, guild rooms, titles, pose text, and docs. Need decide whether NPC class-like act flags remain as builder archetypes. |
| Define classless progression model | Design needed | Need define starting choices, practices/trains, skill learning, weapon specialization, magic access, HP growth, prestige/remort hooks, titles, and how old class-indexed tables are replaced or collapsed. |

### Combat and Magic Overhauls

| Item | Status | Notes |
| --- | --- | --- |
| Understand combat before major redesign | Investigate | Required before class removal and combat overhaul. Document hit flow, damage, THAC0/THAC32, saves, skills, conditions, positions, and NPC behavior. |
| Replace class THAC0 with weapon-skill hit model | Design needed | Candidate direction: hit success should be driven mainly by weapon skill plus attacker modifiers against defender armor/defense. Stock ROM AC is lower-is-better, so decide whether to normalize AC into a positive defense score before using a formula like `weapon skill + modifiers - defender defense`. Classless design question: should this replace only the main THAC0 gate, leaving parry/dodge/shield block as separate active defenses, or should those defenses be folded into one transparent final hit formula? Need decide how level, hitroll, STR, DEX, visibility, victim position, active defenses, and NPCs fit. |
| Combat overhaul | Deferred | Do not scope until current combat is understood and classless progression goals are clearer. |
| Magic overhaul | Design needed | Touches class-removal work, skills, spells, saves, HP costs, remort rewards, detect spells, lore, item effects, and magic illness. |

### World Content

| Item | Status | Notes |
| --- | --- | --- |
| Build all new zones | Design needed | Large content effort. Room building can begin before combat/class decisions, but mobs and items are blocked by class/combat/magic/equipment direction. |

## Suggested First Planning Candidates

These are good small-task candidates because they reduce operational friction or start with investigation instead of risky edits.

1. Second test/build MUD instance.
2. Nightly reboot verification.
3. Summon spell investigation report.
4. Hunger/thirst behavior report.
5. Lore skill code review and expected behavior proposal.
6. Classless hit formula design from the THAC0/THAC32 investigation.
7. Item level policy: data edit, code edit, or combined approach.
8. Classless player progression sketch.
9. Login screen replacement.

## Cross-Cutting Questions

- Which repository and branch should be treated as canonical for production deployment?
    - Answer: https://github.com/spetr86/sturdy-spoon/
- Should builder/content changes be tested on a second live port before touching the production MUD?
    - Answer: Maybe - come back to this later.
- Are player files considered migration targets, or can early development assume fresh characters?
    - Answer: Assume all players will be deleted eventually - this will likely happen around the time we start replacing stock classes with classless progression.
- Should classless hit chance replace only the THAC0 gate, or absorb active defenses too?
    - Answer: Open. Current notes show swing count, THAC0 gate, and active defenses as separate layers. Decide during classless hit formula design whether parry, dodge, and shield block remain separate rolls or become part of one transparent hit-resolution formula.
- Should legacy ROM mechanics be removed cleanly from data/help/UI, or hidden while compatibility remains?
    - Answer: Remove them and update the documentation
- Which changes must preserve existing area compatibility?
    - Answer: Let's revisit this
- How much stock ROM terminology should remain visible to players during the transition?
    - Answer: We're going to play fast and loose with change management, so leave the world state intact
- Should the first playable target emphasize survival, PVP, exploration, tribal politics, precursor-tech discovery, or builder tooling?
    - Answer: let's explore Builder tooling
