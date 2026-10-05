# Uldum: quests after Do the Honors

Checked 2026-09-24 against mop_world_test, local client DBC files and server source.
This is a static audit, not an in-game playthrough. Scope: the next five quests.

| Quest | Finding |
| --- | --- |
| 27899 That Gleam in his Eye | Delivery quest; starter/ender relationships and questgiver spawns exist. No obvious missing objective wiring. |
| 27900 I've Got This Guy | Kill objective 46979, ten required; 21 spawns exist. Starter/ender Harrison 46978 exists. No obvious missing objective wiring. |
| 27901 They Don't Know What They've Got Here | Objective item 62607 is in coffer 206531's loot at -100 quest chance. Ten coffers exist. Lock 1937 accepts key 62608, which drops at -100 quest chance from officer 46993 (11 spawns). No obvious missing loot wiring. |
| 27903 Ignition | Activation item 62611 casts 87623, a dummy aura targeting a nearby entry. No corresponding spell script, linked spell or guardian SmartAI was found. Guardian 47032 has aura 87656 (decrease movement speed) and a dummy aura, with no AI/script. Lens 62705 loot and ender 50401 exist. Activation event needs repair or in-game confirmation; killing the existing guardian may bypass the missing activation. |
| 27905 Tailgunner! | Escape objective 47054 exists, but Harrison 46978/48082 and bomber 47054 have no AI/script bindings. No matching SmartAI credit, flight startup, vehicle accessories or spell script/link was found for bomber summon 87682 or tailgun summon 87781. Summoned vehicles need not have static spawns, but their summon spells alone do not implement the escape event. Flight/completion implementation is missing from the inspected chain. |

Empty lootmode values are valid here: LootMgr only filters a row by mode when
its lootmode is nonzero. No loot changes were made for this audit.

## Do the Honors repair

Quest 27669: item 62054 casts 89314. Added spell_uldum_orbs_of_the_stars,
granting objective credit 46283 only to a player with the active incomplete
quest, on map 1, within 20 yards in 3D of Ancient Mechanism 301083.
This restores objective credit; it does not implement the original cinematic.

Database binding: sql/updates/world/2026_09_24_16_world_do_the_honors.sql.
Rollback: sql/backup/world_do_the_honors_before_20260924.sql.
Binding applied and verified; worldserver build passed. The new binary must
be installed and the service restarted before the handler is available.
The five following quests were inspected only; no repairs to them were applied.
