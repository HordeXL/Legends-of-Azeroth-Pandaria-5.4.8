# Normal dungeon level audit — 2026-09-24

Checked 1,643 unique database templates from static spawns and NPC/BOSS constants or numeric summons in 41 dungeon script directories: 16 TBC, 16 Wrath, and 9 Pandaria-era dungeons (including the three revamped classic dungeons). Unused maps and raids are excluded. Spell-defined summons and runtime behavior have not been exhaustively tested.

The fix corrects verified level errors only. It does not claim to audit or rebalance all melee or spell damage. Existing combat multipliers remain unchanged. Normal-only rows mirror the existing `Creature::SelectLevel` damage/AP fallback to avoid altering heroic or challenge fallback data.

Reference comparison: [Firelands](https://github.com/FirelandsProject/firelands-cata/blob/b250899d4fdf68603e4d8a4d05b4b522d8319eb0/data/sql/base/db_world/creature_template.sql), [AzerothCore](https://github.com/azerothcore/azerothcore-wotlk/blob/9c1bbfafecc1b6d12dacb69a05bb4754cce40cc5/data/sql/base/db_world/creature_template.sql), and per-entry normal-difficulty blocks in the MoP [TauriShoot](https://mop-shoot.tauri.hu/) database. Older expansion references disagree on numerous TBC level ranges; those are preserved unless the MoP reference corroborates the correction.

## Corrected entries

| Entry | NPC | Before | Normal after | Method | Source |
|---|---|---|---|---|---|
| 16807 | Grand Warlock Nethekurse | 71–72 | 71–71 | template | [normal data](https://mop-shoot.tauri.hu/?npc=16807) |
| 18176 | Tainted Earthgrab Totem | 71–72 | 64–64 | template | [normal data](https://mop-shoot.tauri.hu/?npc=18176) |
| 18177 | Tainted Stoneskin Totem | 71–72 | 64–64 | template | [normal data](https://mop-shoot.tauri.hu/?npc=18177) |
| 18206 | Wastewalker Captive | 70–70 | 62–63 | template | [normal data](https://mop-shoot.tauri.hu/?npc=18206) |
| 20978 | Wrath-Scryer's Felfire | 70–70 | 69–69 | template | [normal data](https://mop-shoot.tauri.hu/?npc=20978) |
| 19226 | Void Traveler | 69–70 | 69–69 | template | [normal data](https://mop-shoot.tauri.hu/?npc=19226) |
| 27973 | Crystalline Shardling | 80–80 | 77–77 | template | [normal data](https://mop-shoot.tauri.hu/?npc=27973) |
| 28583 | Blistering Steamrager | 81–81 | 79–80 | template | [normal data](https://mop-shoot.tauri.hu/?npc=28583) |
| 59051 | Strife | 90–90 | 87–87 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59051) |
| 59726 | Peril | 90–90 | 87–87 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59726) |
| 59479 | Yan-Zhu the Uncasked | 90–90 | 87–87 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59479) |
| 59494 | Yeasty Brew Alemental | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59494) |
| 59518 | Bloated Brew Alemental | 90–90 | 86–86 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59518) |
| 59522 | Sudsy Brew Alemental | 90–90 | 86–86 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59522) |
| 58998 | Scarlet Defender | 90–90 | 31–31 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=58998) |
| 59893 | Empowering Spirit | 90–90 | 32–32 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59893) |
| 61634 | Commander Vo'jak | 92–92 | 91–91 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=61634) |
| 56631 | Hopling | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=56631) |
| 59458 | Hopling | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59458) |
| 59459 | Hopling | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59459) |
| 59461 | Hopling | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59461) |
| 60276 | Hozen Clinger | 90–90 | 85–85 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=60276) |
| 65522 | Bubble Shield | 90–90 | 87–87 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=65522) |
| 59706 | Fuel Tank | 90–90 | 32–32 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59706) |
| 59980 | Meat Graft | 90–90 | 41–41 | normal_override | [normal data](https://mop-shoot.tauri.hu/?npc=59980) |

## Deliberately preserved

Seasonal Ahune/Headless Horseman levels, heroic-only Nexus commanders, quest/NPC presentation levels, invisible spell helpers, and ambiguous source differences are excluded. Examples: Raigonn is also level 92 in the MoP normal reference; Habanero Brew and Serpent Trainer are level 90. Magical book/visual helpers are non-attackable in their scripts and are not included in this combat-creature correction.

## Validation

Run `verify.py` against before/after TSV exports of `creature_template` and `creature_difficulty` (MariaDB batch format with headers). It checks effective normal levels, all untouched template columns, every pre-existing difficulty row, inserted normal stats against the original template values when `damage_exp4` is zero, and exact change counts. Apply the migration twice and compare resulting snapshots to check idempotence. No game-client test has been performed.

Validation result: all 25 effective normal-level checks passed. Exactly 8 base level pairs changed and 17 normal-only records were added; all other template fields and every pre-existing difficulty row were identical. A second migration run produced byte-identical table exports.
