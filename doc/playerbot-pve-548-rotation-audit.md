# Group PvE profile and rotation audit — 2026-09-08

## Scope

Source-level review of all 11 classes / 34 specializations, including managed equipment preparation, talent and glyph selection, single-target and gathered-pack actions. This is not a DPS benchmark or proof of complete encounter support. The server was left stopped; no live LFG/LFR gameplay was performed for this audit.

The preceding rogue fix was committed and pushed as `537611d4`. The changes described here follow that commit.

## Preparation and shared fixes

- Managed preparation retains bag initialization, specialization equipment repair, talents/glyphs, pet initialization, enhancements, weapon/armor validation and rejection of inappropriate managed PvE items. This audit did not rewrite existing characters directly in SQL; profiles apply through managed preparation.
- PvE talent columns are explicit and authoritative for all six unlocked rows. They favor abilities supported by these bots and suitable passives, not a claim of mathematically optimal player builds. Existing PvP profile columns remain unchanged.
- Each specialization has an explicit three-major-glyph effect whitelist, still filtered through class glyph data, unlocked slots and duplicate checks. Minor glyph handling remains class/level/type checked; the previously fixed rogue minor profile is retained.
- Blood DK is recognized as a tank. Feral no longer falls into the old pre-MoP Thick Hide / bear-role heuristic; Guardian remains separate.
- Spell-name aliases resolve learned 5.4.8 spells, including Judgment, Shield of the Righteous, Reckoning, Mangle, Swipe, Faerie Fire and Hand of Gul'dan. An alias does not teach an absent spell.
- Restored audited missing conditions through `PveRotationTriggerContext`; missing registrations are not all enabled indiscriminately. Old inactive helper/PvP references still exist in source.
- Group healing counts injured, living, visible, same-map members in range without relying on the unregistered legacy `aoe heal` value.
- Friendly dispels use MoP class/spec masks. For example, restoration shaman dispels magic/curse, not obsolete poison/disease cleansing; offensive priest Dispel Magic is not substituted for friendly Purify.
- Shaman weapon imbues explicitly target the equipped weapon and compare its temporary enchant with the selected specialization's enchant. The shared spell-casting path now preserves an explicitly supplied item target.

## Class coverage

All specs in each row had their managed talent/glyph profile and ST/AoE strategy wiring reviewed. Entries describe the principal changed or retained logic, not an exhaustive rotation guide.

| Class | Specializations | Principal review / fixes |
| --- | --- | --- |
| Warrior | Arms, Fury, Protection | Existing ST/pack priorities, stance and main-tank taunt guard retained; explicit PvE talent/glyph profiles align with supported abilities. |
| Paladin | Holy, Protection, Retribution | Modern spell names; Righteous Fury, Beacon and Sacred Shield conditions; Execution Sentence and friendly Holy Prism wiring; Holy Power ST/pack spenders retained. |
| Hunter | Beast Mastery, Marksmanship, Survival | Spec-specific default priorities; Cobra Shot for BM/Survival, Steady Shot for MM; stings, Black Arrow, Rapid Fire, Crows/Glaive Toss; Hawk resolves to learned Iron Hawk. Multi-Shot retains final AoE safety. |
| Rogue | Assassination, Combat, Subtlety | Previous poison, combo/finisher and Subtlety burst fix retained; Combat Blade Flurry enabled for a nearby pack and removed for single-target conditions. |
| Priest | Discipline, Holy, Shadow | Friendly Purify and group-heal conditions; Cascade wiring; Inner Fire; existing Shadow orb/DoT/Mind Sear logic retained. |
| Death knight | Blood, Frost, Unholy | Blood role/Bone Shield; disease conditions and Rime; Unholy PvE bypasses obsolete ghoul-frenzy/Corpse Explosion paths; Pestilence requires own diseases and another nearby target missing them. |
| Shaman | Elemental, Enhancement, Restoration | Shield/Flame Shock conditions; Fulmination uses Lightning Shield charges; five-stack Maelstrom; correct weapon imbues; Searing does not replace Fire Elemental; PvE Fire Nova uses own Flame Shock rather than the old fire-totem requirement. Larger healer cooldowns use the lower health threshold. |
| Mage | Arcane, Fire, Frost | Arcane charge/missile thresholds; Fire Combustion requires own Ignite/Pyroblast; Frost Living Bomb matches the talent profile; existing proc/AoE priorities retained. |
| Warlock | Affliction, Demonology, Destruction | Haunt no longer starved by the filler; Demonology removes AoE-only defaults from ST; Destruction Chaos Bolt priority/resource guard; Fire and Brimstone follows pack conditions; Seed can coexist with Corruption; Rain of Fire avoids duplicate overlapping casts. |
| Monk | Brewmaster, Mistweaver, Windwalker | Purifying Brew at moderate/heavy Stagger, Tiger Power maintenance, Chi Wave/Xuen wiring; Uplift/Revival use friendly/self targeting; group heals and Detox masks. |
| Druid | Balance, Feral, Guardian, Restoration | Eclipse-direction fillers, Feral combo/bleed/roar conditions, actual Bear Form, combat-only Savage Defense, Thrash for gathered packs; group heals/Nature's Cure; Balance Guided Stars glyph. |

## Single target, packs and PvP boundary

ST resource/proc/DoT conditions are distinct from existing nearby-pack conditions. The final group-PvE AoE guard still checks nearby unpulled enemies, crowd control, allowed engagement and tank collection. Script-selected Glaive Toss, Chi Wave, Holy Prism and Cascade receive conservative additional reach checks because their complete target selection is not expressed through DBC chain fields alone. Friendly Cascade remains healing-only.

These bounds can intentionally delay a bouncing spell near an idle pack. They are not a guarantee against a new enemy moving into an already active area effect, nor a replacement for encounter testing.

New PvE triggers and rotation branches are gated to controlled group PvE activities, including dungeon/raid/caller use. PvP talent columns are unchanged; PvP combat branches are not replaced with PvE rotations. Shared correctness fixes (spell aliases, role identification, explicit item targets and Uplift/Revival targeting) also apply where those common paths are used in PvP. Open-world solo behavior was not redesigned.

## Verification

- `worldserver.vcxproj`, `RelWithDebInfo|x64`: successful build, including the final Searing Totem correction.
- Isolated C++ regression: **1028 checks passed** for 34 specialization profiles, unchanged PvP columns, talent/glyph DBC validity, representative ST/pack state conditions and dispel masks.
- Read-only DBC audit: **50 major-glyph effect IDs, 41 registered rotation spell IDs and 13 spell aliases passed** against the local 5.4.8 data.
- `git diff --check`: passed. The build still prints the existing CMake revision-information warning; this is separate from a compiler error.
- No worldserver startup, database mutation, client graphics change or live DPS test was performed.

From an x64 Visual Studio Developer PowerShell, with DBC files installed under `Build/bin/RelWithDebInfo/dbc`:

```powershell
./contrib/playerbot_auto_queue_548/test_pve_rotation.ps1
./contrib/playerbot_auto_queue_548/audit_pve_rotation.ps1 -CheckDbc
```

The isolated harness uses production function bodies with lightweight mocks, not the server scheduler, full spell engine or real combat. Its runner rejects stale copied bodies. The inventory script also reports legacy/PvP missing references; these require manual review and are not automatically active PvE failures.

## Remaining live acceptance checks

1. After starting the new binary, prepare fresh managed groups and inspect learned talents, glyphs and weapon imbues after specialization changes.
2. Record comparable single-target and tank-gathered-pack combat segments. Confirm finishers/procs/resource generation, AoE switching and no advance into an idle pack.
3. Check healer targeting, group cooldowns and dispels under damage, and then test PvP separately for shared-path regressions.
4. Compare DPS only for like roles, item level, target uptime and encounter mechanics. Passing these source tests does not establish optimal DPS for every specialization.

The separately reported client-exit crash remains an investigation; these rotation changes do not establish or fix its root cause.
