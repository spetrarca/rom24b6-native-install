# Item Level Policy Design

## Context

QuickMUD currently uses object level for two different purposes:

- Player-facing access gates, such as whether a character can wear, use, buy, steal, locate, retrieve, or save an item.
- Object potency metadata, such as old-format conversion, spell effect metadata, dispel resistance, heat metal behavior, enchantment, identify/stat output, OLC, and builder-facing object information.

The design goal is to remove object level as an access gate without flattening item power. Existing object levels should not be bulk-set to level 1 as part of this pass.

## Decision

Remove player-facing object-level gates. Keep object level as potency metadata.

Future mundane gear may use level 1 as a builder convention, but existing object level values remain meaningful for object conversion, magic-item behavior, and builder/operator visibility.

## In Scope

Remove item-level restrictions from:

- Wearing, wielding, holding, and using equipment.
- Quaffing potions.
- Reciting scrolls.
- Brandishing staves.
- Zapping wands.
- Buying shop items.
- Stealing carried items.
- Retrieving items from the donation pit.
- `locate object` visibility.
- Player save filtering that skips non-container objects more than two levels above the character.

Add current HP costs for scrolls, staves, and wands:

- Potions have no HP item-use cost.
- Scrolls, staves, and wands cost current HP on use.
- Starting formula: `1 + max(0, item_level - player_level)` current HP per use.
- The HP cost replaces the current item-level failure gate.

## Out Of Scope

Do not bulk edit area files or prototype object levels.

Do not remove object level from OLC, identify, stat, save/load, object conversion, enchantment, dispel resistance, heat metal, or builder documentation in this pass.

Do not redesign spell learning, maximum HP spell costs, or the full mana replacement economy in this pass. This policy only handles magical item use enough to remove object-level access gates cleanly.

## Behavior Details

Equipment:

- A character can wear, wield, hold, or otherwise equip an item regardless of object level.
- Existing strength, size, two-handed weapon, slot occupancy, item flag, alignment, curse, and no-remove rules continue to apply unless separately redesigned.

Potions:

- A character can quaff any potion they can obtain.
- Potions do not cost current HP.
- Potion spell power remains controlled by the potion's stored spell level values.

Scrolls, Staves, And Wands:

- A character can use any scroll, staff, or wand they can obtain.
- Each activation attempt that would consume the scroll or a staff/wand charge costs current HP using `1 + max(0, item_level - player_level)`.
- Existing scroll, staff, and wand skill checks still determine misfire/failure unless separately changed.
- Spell power remains controlled by the object's stored spell level values, not by the character level.
- Staff and wand charges continue to work normally.

Shops And Theft:

- Shopkeepers no longer refuse sales because the item level is above the buyer's level.
- Steal no longer refuses an object because the item level is above the thief's level.
- Cost, carry number, carry weight, inventory flags, drop flags, and shopkeeper availability continue to apply.

Locate Object:

- `locate object` should no longer hide matching objects solely because their object level is above the caster's level.
- Existing visibility, no-locate, randomness, and spell mechanics continue to apply.

Saving:

- Player object saves should no longer discard non-container items because object level is more than two levels above the character.
- Existing key/map exclusions and other save/load rules remain unchanged unless separately redesigned.

## HP Cost Edge Cases

If the HP cost would reduce the user below 1 HP, the item use should proceed and the user should die from the cost. Magical item use is allowed to be lethal.

The death or damage message should make the cost legible in-world without exposing formula jargon. Example direction: the item draws too deeply from the user's blood/strength.

The HP cost should be applied only when the item use proceeds past basic validation and would consume the scroll or a staff/wand charge. It should not punish typos, missing targets, wrong item type, or attempts to use an item with no charges.

## Testing

Manual or automated coverage should verify:

- A low-level character can wear, wield, hold, buy, steal, locate, save, and reload an above-level mundane item.
- A low-level character can quaff an above-level potion without HP cost.
- A low-level character can recite an above-level scroll and pays `1 + max(0, item_level - player_level)` current HP when the scroll is consumed.
- A low-level character can brandish an above-level staff and pays the same formula when a charge is consumed.
- A low-level character can zap an above-level wand and pays the same formula when a charge is consumed.
- Scroll/staff/wand use can kill the user if the current HP cost drops them below 1 HP.
- Object level still appears in identify/stat/OLC output and still affects existing potency mechanics such as dispel resistance, heat metal, enchantment, and old-format conversion.

## Follow-Up Questions

After implementation and playtesting, revisit whether scrolls, staves, and wands should cost additional HP based on stored spell level, item type, or magic illness state. The initial implementation intentionally uses only item level versus player level so the first pass stays small and testable.
