# Startup Log Fix Plan - 2026-07-09

Scope: worldserver startup cleanup for the active 5.4.8 Build 18414 project.
Rule: do not delete content to hide errors. Prefer filling missing data, linking existing scripts, or moving bad data to correct coordinates.

Database environment rule: this project uses Wampserver 3.4.2 with MySQL 5.7.44. Do not use MariaDB 11.4.9 or any newer installed MySQL/MariaDB version to select, inspect, import, migrate, or draw schema conclusions for this project's databases. Other installed versions may contain unrelated schemas. Before applying SQL, confirm that the client/server is MySQL 5.7.44 and that the configured target is this project's `world` database.

## Already Fixed

- Added empty optional `AiPlayerbot.PremadeSpecName.*` config keys in `Build/bin/RelWithDebInfo/worldserver.conf`.
  - Result after restart: missing playerbot config warnings are gone.
- Added SQL update `sql/updates/world/2026_07_09_00_world_startup_log_fixes.sql`.
  - Sets `AIName='SmartAI'` for creature templates that already had SmartAI rows and no C++ `ScriptName`.
  - Result after restart: the specific `Creature entry has SmartAI scripts, but its AIName is not SmartAI` errors are gone for the fixed entries.
- Added SQL update `sql/updates/world/2026_07_09_04_world_smartai_minmax_startup_fixes.sql`.
  - Fixes incomplete or reversed SmartAI min/max-style parameters for entries `17214`, `17215`, `25073`, `32423`, and `3304100`.
  - Applied to the active world DB.
  - Result after restart: `uses min/max params wrong` count is `0`.
- Added SQL update `sql/updates/world/2026_07_09_05_world_smartai_missing_spell_fixes.sql`.
  - Fixes selected SmartAI spell references where the old spell id does not exist in local 5.4.8 `Spell.dbc` and a clear local replacement exists.
  - Applied to the active world DB.
  - Needs one worldserver restart to verify the missing-spell startup count drops.
- Added SQL update `sql/updates/world/2026_07_09_06_world_smartai_missing_spell_fixes_part2.sql`.
  - Fixes `27842` by changing the bad spell cast into the intended `SUMMON_CREATURE 9521` action for `Enraged Felbat`.
  - Fixes `1707700` by replacing creature id `30011` with valid `Self Snare` spell `58606`.
  - Applied to the active world DB.
  - Result after restart: `uses non-existent Spell entry` count dropped to `3`.

## Current Highest-Volume Categories

Counts are from the appended `DBErrors.log`, so duplicated startup runs can inflate totals. Clear or rotate the log before the next restart for exact per-run counts.

1. Pool data across multiple maps
   - Examples: `pool_gameobject`, `pool_pool`, empty pools.
   - Risk: medium. These affect spawn pools and can cause missing or duplicated world spawns.
   - Fix method: inspect each pool id, split pools by map, correct child pool membership, or move bad spawn membership to the correct pool. Do not delete pool rows as the first step.

2. `npc_vendor` wrong `ExtendedCost`
   - Affected costs seen earlier: `5962`, `5963`, `5964`, `5966`.
   - Affected vendors include MoP PvP quartermasters around entries `69971` to `69978`.
   - Risk: high. Adding dummy `itemextendedcost` rows would hide errors but make wrong prices.
   - Fix method: map those old cost ids to valid 5.4.8 extended-cost ids, then update vendor rows.

3. `script_waypoint` without creature `ScriptName`
   - Current affected templates:
     - `349` Corporal Keeshan, 115 waypoints per run
     - `17238` Anchorite Truuen, 26
     - `7780` Rin'ji, 24
     - `5391` Galen Goodward, 22
     - `8856` Tyrion's Spybot, 18
     - `1754` Lord Gregor Lescovar, 17
     - `3850` Sorcerer Ashcrombe, 14
     - `3849` Deathstalker Adamant, 14
     - `6575` Scarlet Trainee, 12
     - `4962` Tapoke "Slim" Jahn, 7
   - Risk: medium-high. Waypoints exist but no matching core script is present in this codebase.
   - Fix method: implement or port the matching escort/quest C++ scripts, then set `creature_template.ScriptName`. Do not set made-up script names.

4. SmartAI action warnings
   - Common warnings:
     - kill credit action duplicates an existing spell kill-credit effect
     - summon action duplicates an existing summon spell effect
     - invalid talk text ids
     - non-existent SmartAI text ids or spells
   - `has SmartAI scripts, but AIName is not SmartAI` follow-up finding:
     - Entries `18166`, `25967`, `31848`, `64267`, and `64656` all have C++ `ScriptName` values.
     - Do not set these to `AIName='SmartAI'`; that would override the C++ scripts.
     - Their `smart_scripts` rows are likely stale or duplicate data. Leave them untouched unless we explicitly decide on a reversible cleanup policy.
   - `uses min/max params wrong` follow-up:
     - Applied `sql/updates/world/2026_07_09_04_world_smartai_minmax_startup_fixes.sql`.
     - `17214` and `17215`: filled missing reward-quest cooldown max values.
     - `25073`: corrected Darkspine Siren health range from `15-0%` to `0-15%`.
     - `32423`: filled missing reward-quest cooldown max value.
     - `3304100`: kept 5-yard distance and added a 500 ms repeat value.
   - `uses non-existent Spell entry` follow-up:
     - Applied `sql/updates/world/2026_07_09_05_world_smartai_missing_spell_fixes.sql`.
     - Corrected clear local replacements:
       - `90981` -> `90980` (`Cleave`) for `47403`, `47404`.
       - `90982` -> `90099` (`Watch`) for `47403`, `47404`.
       - `91039` -> `91038` (`Throw`) for `48278`.
       - `90947` -> `90946` (`Bloodwash`) for `48417`.
       - `91006`/`91010` -> `91009` (`Renegade Strength`) for `48418`, `48419`.
       - `100101` -> `99705` (`Kneel to the Flame!`) for duplicate hit event `53619`.
     - Left unresolved for separate research:
       - `14822`/`23770` Sayge's Carnie Buff: no clear 5.4.8 replacement found.
       - `70021`/`223971` and `70034`/`215377`: spell ids are outside local 5.4.8 DBC range and likely imported from a later expansion or wrong source.
     - Applied `sql/updates/world/2026_07_09_06_world_smartai_missing_spell_fixes_part2.sql`.
       - `27842`/`14252`: row comment says summon `Enraged Felbat`; old local SAI source confirms creature `9521`, `TempSummonType=4`, duration `30000`.
       - `1707700`/`30011`: row comment says Self Snare; local 5.4.8 `Spell.dbc` confirms `58606` is `Self Snare`.
     - Remaining unresolved after part 2:
       - `14822`/`23770` Sayge's Carnie Buff: no clear 5.4.8 replacement found.
       - `70021`/`223971` and `70034`/`215377`: spell ids are outside local 5.4.8 DBC range and likely imported from a later expansion or wrong source.
     - Result after restart: only the three unresolved lines remain.
   - `using non-existent Text id` follow-up:
     - Applied `sql/updates/world/2026_07_09_07_world_smartai_text_validation_fixes.sql`.
     - Added validation mirror rows from already-existing authentic `creature_text`:
       - `39712` High Tinker Mekkatorque groups `2-4` mirrored to `1268` Ozzie Togglevolt.
       - `39712` High Tinker Mekkatorque groups `5-7` mirrored to `6119` Tog Rustsprocket.
       - `8421` Dorius groups `0-6` mirrored to `8400` Obsidion.
       - `25751` High Overlord Saurfang groups `0-7` mirrored to `25730` En'kilah Necrolord.
     - Reason: these SmartAI rows make another creature speak through a target selector, but startup validation checks the SmartAI source entry. The mirror rows satisfy validation without deleting script rows or inventing text.
     - Result after restart: `using non-existent Text id` count dropped from `76` to `53`.
     - Applied `sql/updates/world/2026_07_09_08_world_smartai_text_validation_mirrors_part2.sql`.
       - `39712` High Tinker Mekkatorque group `1` mirrored to `7955` Milli Featherwhistle.
       - `3389` Regthar Deathgate group `1` mirrored to `9457` Horde Defender.
       - `20227` Apprentice Tedon groups `1-2` mirrored to `16514` Botanist Taerix.
       - `17233` Ghost of Uther Lightbringer groups `4-7` mirrored to `17253` Defile Uther's Tomb Trigger.
       - `24797` Reef Cow group `0` mirrored to `24786` Reef Bull.
       - `25317` Civilian Recruit group `0` mirrored to `25307` Recruitment Officer Blythe.
       - `35230` Lord Darius Crowley groups `1-2` mirrored to `35231` Crowley's Horse.
     - Needs one worldserver restart to verify the warning count drops again.
     - Result after restart: `using non-existent Text id` count dropped from `53` to `41`.
     - Applied `sql/updates/world/2026_07_09_09_world_smartai_text_known_broadcasts.sql`.
       - Added `30474` The North Wind group `2` from broadcast `31183` (`The horn! Use the horn on it while it's weak!`).
       - Added `46425` Ramkahen Prisoner group `2` from broadcast `46522` (warning about Caimas).
       - Added `54924` Zhi-Zhi group `1` from broadcast `53204` (sparring complete).
     - Result after restart: `using non-existent Text id` count dropped from `41` to `38`.
     - Remaining text warnings need a stronger source before changing:
       - Suspicious GUID scripts: `-121192`, `-84714`, `-84709`, `-84635`. At least `-84709` resolves to Driz Tumblequick but its comments say Gordok Brew Barker, so do not patch with filler text.
       - Self-talk entries without a trusted text row found locally: `2719`, `8719`, `13601`, `14860`, `15324`, `15526`, `18938`, `19354`, `23669`, `24198`, `30284`, `45152`, `46134`, `46276`, `46402`, `46425` group `3`, `48012`, `54615`, `54944`, `55488`, `57760`, `59296`, `59392`, `60572`, `66693`, `69267`, `69305`.
       - For these, use a trusted sniff/source or inspect the quest in-game before adding text. Do not fill with generic greetings.
   - Risk: medium. Some are redundant script actions, some can break quests.
   - Fix method: handle one quest/NPC group at a time. Prefer correcting the SmartAI action or text reference instead of deleting the whole script.

5. Quest objective references
   - Problem rows include quests `10794`, `11997`, `29046`, `29048`, `29056`, `29466`, `29554`, `32470`, `32475`.
   - Important finding: SkyFire full 2024 world dump does not contain the missing `item_template` rows for the affected item ids.
   - Important finding: quest `11997` is titled `REUSE` but has objectives pointing to existing MoP PvP gear item ids as creature objectives. Do not create fake creature templates for those ids.
   - Fix method: validate against a trusted 5.4.8 quest/objective source or DBC export before changing IDs or adding item templates.

6. Missing loot templates
   - Examples seen earlier:
     - creature loot: `60491` Sha of Anger, `62346` Galleon
     - gameobject loot: `218197`, `218577`, `220196`, `221776`
   - Risk: high for boss/world-boss rewards.
   - Fix method: import real loot rows from a trusted source. Do not create empty loot templates.

7. Runtime Dalaran `creature_text` gaps
   - Seen while server was running:
     - `28703` Linzy Blackbolt
     - `28704` Dorothy Egan
     - `29511` Lalla Brightweave
     - `32172` Harold Winston
     - `32450` Badluck
     - `32606` [DND] Cosmetic Book
     - `35496` Rueben Lauren
     - `47581` Archmage Aranhir Starsinger
   - All listed spawns are in Northrend Dalaran (`map 571`, `zoneId 4395`).
   - Current DB originally had no `creature_text` rows for those entries.
   - SkyFire full 2024 world dump also has no `creature_text` rows for those entries.
   - Applied `sql/updates/world/2026_07_09_01_world_dalaran_creature_text.sql` with `INSERT IGNORE` `GroupID=0` fallback rows.
   - Role-specific existing `broadcast_text` was used where reasonable: herbalism, tailoring, jewelry/cloth vendor.
   - Neutral `Greetings!` fallback was used for entries without a reliable role-specific text: `28703`, `32450`, `32606`, `47581`.
   - Risk: low-medium. This usually means missing NPC flavor/event text; the event continues, but the intended chat line is skipped.
   - Follow-up method: after restart, if logs change to `Could not find TextGroup X`, add the exact missing group instead of changing unrelated rows. If a trusted WotLK/MoP Dalaran sniff/source is found later, replace fallback lines with authentic text.

8. Additional runtime `creature_text` gaps from in-game walk-through
   - Seen after testing the first Dalaran creature text batch:
     - `29506` Orland Schaeffer
     - `32709` Hunaka Greenhoof
     - `32711` Warp-Huntress Kula
     - `32714` Moon Priestess Nici
     - `32718` Disidra Stormglory
     - `32720` Violetta
     - `35497` Rafael Langrom
     - `64077` Kergan Swiftbeard
     - `64160` Frostflower
     - `65574` Brad Rhodes
   - Applied `sql/updates/world/2026_07_09_02_world_runtime_creature_text_fallback.sql` with `INSERT IGNORE` `GroupID=0` fallback rows.
   - Role-specific existing `broadcast_text` was used where reasonable: blacksmithing trainer, leather armor merchant, trade goods.
   - Neutral `Greetings!` fallback was used for visitor/flavor NPCs without a reliable role-specific text.
   - Follow-up method: clear the current log, retest the same route, and only add more rows if a new entry or specific missing `TextGroup` appears.

9. Additional Dalaran `creature_text` gap after second route
   - Seen after further in-game testing:
     - `32702` Drog Skullbreaker
   - Applied `sql/updates/world/2026_07_09_03_world_dalaran_drog_creature_text.sql` with an `INSERT IGNORE` `GroupID=0` fallback row.
   - Important operational note: `creature_text` is cached by worldserver. After applying SQL while the server is running, use `.reload creature_text` or restart worldserver before retesting, otherwise old missing-text errors can continue until reload.

10. Runtime item update warning
   - Seen in `Server.log`:
     - `Item::RemoveFromUpdate - owner not found, guid 30495, entry 25537, owner 170`
   - DB check:
     - Item `30495` exists in `item_instance`.
     - Item entry `25537` is `Hewing Axe of the Marsh`.
     - Owner `170` exists as character `Gloria`, currently `online=0`.
     - Item is in `character_inventory` for owner `170`, `bag=0`, `slot=24`.
   - Current assessment: not a world DB missing-data issue and not an orphan item. This is likely a runtime update-queue ordering issue during logout/shutdown where the player object is already gone but one item still tries to leave the update list.
   - Fix method: do not delete the item. If it repeats during normal gameplay, inspect the logout/item update path in core code. If it only appears next to shutdown/restart, treat as low priority unless it causes a crash or item loss.

11. SmartAI duplicate spell-effect warnings
   - Current categories:
     - `Kill Credit ... has already spell kill credit`
     - `creature summon: There is a summon spell for creature entry`
   - Code check: these validation messages log an error but do not reject the SmartAI row. The action can still run at runtime.
   - Important risk: most rows are not safe for automatic DB cleanup. The warning means a spell exists that can grant the same credit or summon the same creature, but it does not prove the SmartAI event always uses that spell in the same flow.
   - Applied `sql/updates/world/2026_07_09_10_world_smartai_duplicate_spell_effect_batch1.sql` for only 3 proven duplicate rows:
     - `48119`, `48121`: spell `89568` already grants kill credit `48195`; redundant linked `Action 33` was changed to `Action 0`.
     - `56686`: spell `109335` already summons creature `57874`; redundant linked `Action 12` was changed to `Action 0`.
   - No rows were deleted. Links and original parameters were kept in place so the SmartAI chain remains intact and the old data is still visible.
   - DB-side count against the current log candidates after this batch:
     - duplicate kill credit rows still matching active `Action 33`: `232`
     - duplicate summon rows still matching active `Action 12`: `199`
   - Fix method for the remaining rows: handle only by quest or spawn group after confirming the spell and explicit SmartAI action happen in the same gameplay path. Do not bulk-disable all warnings.

12. SmartAI missing creature text, verified batch 4
   - Applied `sql/updates/world/2026_07_09_11_world_smartai_missing_text_batch4.sql`.
   - Fixes included:
     - `8719` Auctioneer Fitch / Hired Courier: restored the 3-line `Fencing the Goods` dialogue sequence using local `broadcast_text` ids `52638`, `52639`, `52640`.
     - `14860` Flik: SmartAI now uses existing random `creature_text` `GroupID=0` instead of missing `GroupID=1`.
     - `19354` Arzeth the Merciless: added missing spell-hit response from local `broadcast_text` id `18349`.
     - `-84635` Gordok Brew Barker: SmartAI now uses existing random `creature_text` `GroupID=0` instead of missing `GroupID=1`.
     - `46276` Caimas the Pit Master: added missing line from local `broadcast_text` id `46639`.
     - `46425` Ramkahen Prisoner: did not invent a missing fourth line. Trusted quest flow has three speech lines, so waypoint start was moved to text-over group `2`; the old group `3` waypoint trigger was changed to no-op.
   - No rows were deleted.
   - DB-side active missing-text candidates from the current log set after this batch: `31` unique SmartAI rows remain.
   - Remaining rows should be handled only after finding authentic text or confirming that a SmartAI action should be changed instead of adding filler `creature_text`.

13. SmartAI missing creature text, verified batch 5
   - Applied `sql/updates/world/2026_07_09_12_world_smartai_missing_text_batch5.sql`.
   - Fixes included:
     - `13601` Tinkerer Gizlock: added aggro line from local `broadcast_text` id `8852`.
     - `60572` Nakk'rakas: added five encounter lines from local `broadcast_text` ids `61229`, `61232`, `61230`, `61269`, `60775`.
     - `2719` Dustbelcher Lord: added two random aggro lines from local `broadcast_text` ids `1925`, `1926`.
     - `23669` Winterskorn Oracle: added six random combat lines from local `broadcast_text` ids `22702`, `22697`, `22822`, `22700`, `22820`, `30508`.
   - No rows were deleted.
   - DB-side active missing-text candidates from the current log set after this batch: `23` unique SmartAI rows remain.

14. SmartAI missing creature text, verified batch 6
   - Applied `sql/updates/world/2026_07_09_13_world_smartai_missing_text_batch6.sql`.
   - Fixes included:
     - `15324` Qiraji Gladiator: added Vengeance/enrage emote from local `broadcast_text` id `10677`.
     - `30284` Bonegrinder: added Enrage emote from local `broadcast_text` id `10677`.
     - `24198` Plagued Dragonflayer Rune-Caster: added Plague Spray control-loss emote from local `broadcast_text` id `23081`.
   - No rows were deleted.
   - DB-side active creature missing-text groups after this batch: `21` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 3 lines.

15. SmartAI missing creature text, verified batch 7
   - Applied `sql/updates/world/2026_07_09_14_world_smartai_missing_text_batch7.sql`.
   - Fixes included:
     - `18938` Krexcil: added Flight Master aggro yell `Guards!` from local `broadcast_text` id `4583`, matching other gryphon/wyvern master SmartAI patterns.
     - `45152` Magus Bisp: added quest aggro yell from local `broadcast_text` id `45301`.
   - No rows were deleted.
   - DB-side active creature missing-text groups after this batch: `19` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 2 more lines.

16. SmartAI missing creature text, verified batch 8
   - Applied `sql/updates/world/2026_07_09_15_world_smartai_missing_text_batch8.sql`.
   - Fixes included:
     - `46134` High Commander Kamses
     - `46402` Ramkahen Citizen
     - `48012` Sergeant Mehat
   - All three use the existing 15% HP flee + say SmartAI pattern. The added emote uses local `broadcast_text` id `1150`: `%s attempts to run away in fear!`.
   - No rows were deleted.
   - DB-side active creature missing-text groups after this batch: `16` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 3 more lines.

17. SmartAI missing creature text, verified batch 9
   - Applied `sql/updates/world/2026_07_09_16_world_smartai_missing_text_batch9.sql`.
   - Fixes included:
     - `59296` Lazy Hozen: added five random motivation response lines from local `broadcast_text` ids `58274`, `58273`, `58275`, `58272`, `58271`.
     - `59392` Kitemaster Shoku: added quest gossip response from local `broadcast_text` id `58451`.
   - No rows were deleted.
   - Corastrasza was not changed here because the locally found `I am ready, Lady Corastrasza.` text is a player gossip option, not an NPC say line.
   - DB-side active creature missing-text groups after this batch: `14` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 2 more lines.

18. SmartAI missing creature text, verified batch 10
   - Applied `sql/updates/world/2026_07_09_17_world_smartai_missing_text_batch10.sql`.
   - Fixes included:
     - `54615` Nodd Codejack: added group `2` gyrocopter-ready line from local `broadcast_text` id `68502`.
     - `54944` Tian Pupil: added three duel-complete lines from local `broadcast_text` ids `53244`, `53240`, `53246`.
     - `66693` Zandalari Overlord: added five aggro/yell lines from local `broadcast_text` ids `67810` through `67814`.
   - No rows were deleted.
   - DB-side active creature missing-text groups after this batch: `11` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 3 more lines.

19. SmartAI missing creature text, verified batch 11
   - Applied `sql/updates/world/2026_07_09_18_world_smartai_missing_text_batch11.sql`.
   - Fixes included:
     - `55488` Corastrasza: added local `npc_text` gossip line for `A Hidden Message`.
     - `69267` Silver Covenant Scout: added Isle of Thunder rescue response lines from local `broadcast_text` ids `71514`, `71515`, `71522` through `71532`.
     - `69305` Sunreaver Scout: added Isle of Thunder rescue response lines from local `broadcast_text` ids `71507` through `71513`, `71516` through `71521`.
   - No rows were deleted.
   - DB-side active creature missing-text groups after this batch: `8` remain.
   - Expected effect after next worldserver restart: current SmartAI missing-text log count should drop by 3 more lines.

20. Current state after batch 11 restart
   - Fresh restart result:
     - `SmartAI missing text`: `7`
     - `CreatureTextMgr`: `0`
     - `Missing spell`: `3`
   - Remaining missing text entries:
     - `15526` Meridith the Mermaiden: gossip flow exists, but local `npc_text`/`broadcast_text` rows for the relevant Meridith text are blank in this DB. Do not invent text without a better source.
     - `57760` Wugou: local `broadcast_text` has event-description rows for the Shu/Wugou scene, not a clean NPC say line. Do not add the parenthesized event-description text as creature speech.
     - `-121192`, `-84709`, `-84714`: these are negative GUID SmartAI rows whose comments do not match the current creature spawned at those GUIDs. Treat as spawn/script ownership mismatches, not simple missing `creature_text`.
   - Remaining missing spell entries:
     - `14822` uses missing spell `23770`.
     - `70021` uses missing spell `223971`.
     - `70034` uses missing spell `215377`.

21. Negative GUID SmartAI ownership, verified batch 1
   - Added `sql/updates/world/2026_07_10_00_world_smartai_negative_guid_ownership.sql`.
   - `-84709` was not a Gordok Brew Barker: current GUID `84709` is Driz Tumblequick (`24510`).
   - The real nearby Horde Gordok Brew Barker is GUID `84711` (`23685`).
   - Moved the seven spawn-specific Gordok Brew Barker SmartAI rows from `-84709` to `-84711`.
   - Updated the matching Dark Iron event generator timed-action target from GUID `84709` to `84711`.
   - No SmartAI rows were deleted. The SQL includes creature-entry and collision guards.
   - Left `-84714` unresolved: GUID `84714` is Gordok Brew Chief, and there is no Horde Drunken Brewfest Reveler (`23698`) spawn in the current DB to receive that faction-specific script safely.
   - Left `-121192` unresolved: GUID `121192` is Shoveltusk, while the script says ELM General Purpose Bunny (`23837`); no incoming SmartAI GUID reference or uniquely matching bunny spawn was found.
   - Verification after application: restart worldserver and confirm the missing-text warning for `-84709` is gone, then test the Horde Brewfest Barker wave/sample and Dark Iron event phase flow.
   - Restart verification confirmed `-84709` no longer appears. The script now loads for the correct `-84711` spawn.
   - Added and applied `sql/updates/world/2026_07_10_01_world_gordok_brew_barker_text_group.sql` for the remaining `-84711` validation warning.
   - Changed only SmartAI row `id=4` from missing text `GroupID=1` to the existing authentic random Barker lines in `GroupID=0`, matching the verified Alliance Barker correction.
   - Restart verified: SmartAI missing-text count dropped from `5` to `4`; neither `-84711` nor stale `-84709` appears in `DBErrors.log`.
   - Remaining missing-text entries are `-121192`, `-84714`, `15526`, and `57760`.
   - Missing-spell count remains `3`: entries `14822`, `70021`, and `70034`.
   - Follow-up provenance check for `-84714` and `-121192`:
     - Both rows first entered this repository in commit `4829d22f`, a large SAI-only import. That commit added no matching creature spawn data.
     - `-84714` expects Horde Drunken Brewfest Reveler (`23698`), but GUID `84714` is Gordok Brew Chief (`23696`). The active DB has no Horde/map 1 `23698` spawn, and no Brewfest event action targets GUID `84714`.
     - `-121192` expects ELM General Purpose Bunny (`23837`), but GUID `121192` is one member of a consecutive Shoveltusk (`23690`) spawn group. No SmartAI row targets GUID `121192` or sends it the required `Set Data 0 1` event.
     - The `-121192` action target type `21` means closest player within 20 yards; it provides no creature or coordinate clue from which the missing bunny spawn could be reconstructed.
     - Conclusion: both are orphaned spawn-specific SAI imports, not safely repairable ownership mappings. Do not create speculative spawns, attach them to the current creatures, or add filler text merely to suppress validation warnings.

22. SmartAI foreign spell actions, verified batch
   - Added `sql/updates/world/2026_07_10_02_world_smartai_foreign_spell_actions.sql`.
   - Entry `70021` spell `223971` is not present in local 5.4.8 spell data and also collides with a local gameobject entry. The source import assigned it as `Hunter's Rush` to many unrelated Isle of Giants templates.
   - The valid `70021` `Skycall` action (`138817`) remains active. Only its invalid `Hunter's Rush` action was changed to no-op; original parameters remain stored in the row.
   - Entry `70034` spell `215377` is outside local 5.4.8 spell data. The import labelled the same spell `The Maw Must Feed` on unrelated Arnold Raygun, Gormali Incinerator, and level-29 Scarlet Sentry templates, proving mechanical foreign-data contamination.
   - Changed only the invalid `70034` action to no-op, preserving the row and old parameters. No replacement spell was invented.
   - Restart confirmed missing-spell count dropped from `3` to `1`; only Sayge entry `14822` / spell `23770` remains.
   - Follow-up: this core's DB validator rejects `SMART_ACTION_NONE` (`Action 0`) despite defining it in the enum, producing two replacement `invalid action type (0)` warnings.
   - Added and applied `sql/updates/world/2026_07_10_03_world_smartai_valid_disabled_foreign_actions.sql`.
   - Converted the two disabled rows to unreachable `LINK` events with valid `SET_EVENT_PHASE 0` actions after verifying no row links to those event ids. Stored the old foreign spell ids in `action_param6` and comments for provenance.
   - Also corrected the original `2026_07_10_02` update so a clean database application uses the valid disabled representation directly.
   - Restart verified: missing-spell remains `1`, and both `70021`/`70034` invalid-action warnings are gone.
   - The fresh log still has seven unrelated/older invalid-action warnings: `31238` rows `0-1`, `31848` row `0`, and earlier Action-0 changes for `46425`, `48119`, `48121`, and `56686`.
   - Follow-up: convert the four earlier Action-0 changes to a valid disabled representation after checking their link chains. Handle original `31238` and `31848` data separately.
   - Added and applied `sql/updates/world/2026_07_10_04_world_smartai_valid_disabled_prior_actions.sql` for those four earlier Action-0 rows.
   - `48119`, `48121`, and `56686` are linked chain steps. Replaced Action 0 with valid harmless `SET_EVENT_PHASE 0` while retaining their outgoing links; none of the three scripts uses phase masks.
   - `46425 id=12` has no incoming link and refers to the removed text-group-3 waypoint trigger. Converted it to an unreachable `LINK` event with valid `SET_EVENT_PHASE 0`.
   - Preserved the old credit/summon/entry ids in `action_param6` and comments. Also corrected original update files `2026_07_09_10` and `2026_07_09_11` for clean installations.
   - Restart verified: total invalid-action count dropped from `7` to `3`; `46425`, `48119`, `48121`, and `56686` no longer appear.
   - Remaining invalid actions are only original data: `31238` rows `0-1` with Action `0`, and `31848` row `0` with unsupported Action `134`.
   - Current related counts remain stable: missing text `4`, missing spell `1`.

23. Invalid SmartAI actions `31238` and `31848` investigation
   - `31238` Hira Snowdawn rows have shifted action fields: Action `0`, then values `80` and `3123800/3123801` in the following parameter columns. Comments identify intended `CALL_TIMED_ACTIONLIST` behavior.
   - Timed action lists `3123800` and `3123801` do not exist in the active DB or local SQL sources. Do not merely shift the columns to Action `80`; that would suppress validation while leaving Hira's flight/dialogue behavior missing.
   - Added and applied `sql/updates/world/2026_07_10_05_world_zidormi_invoker_cast_action.sql` for `31848` Zidormi.
   - The older valid local SAI source has Action `85`, spell `46343`, flags `2`; this core defines Action `85` as `SMART_ACTION_INVOKER_CAST`. The base dump had regressed only the action id to unsupported `134`.
   - Changed only `31848` Action `134` to `85`. Kept the existing C++ `ScriptName=npc_zidormi_dalaran` and did not set `AIName=SmartAI`.
   - Restart verified: invalid-action count dropped from `3` to `2`; Zidormi `31848` no longer has an invalid-action warning.
   - The separate `31848 has SmartAI scripts, but its AIName is not SmartAI` warning remains expected because the template uses C++ `npc_zidormi_dalaran`. Do not set `AIName=SmartAI`, as that would override the C++ behavior.
   - Only the two incomplete Hira `31238` rows remain in the invalid-action category. Missing text remains `4`; missing spell remains `1`.
   - Hira source follow-up:
     - A historical TrueWoW update log independently confirms the intended behavior: `Hira Snowdawn - missing fly around every 10 min`.
     - The documented behavior and quotes match the six authentic local `creature_text` rows: three bored emotes in group `1`, then one of three Cloudwing flight lines in group `0`.
     - The active DB has no `creature_addon` path for Hira GUID `98180`, and no matching rows under candidate waypoint ids `98180`, `981800`, `31238`, `312380`, `3123800`, or `3123801`.
     - Therefore both timed action lists and the actual flight coordinates are missing. The text alone is insufficient to reconstruct the event safely.
     - Follow-up on 2026-07-10 recovered two independent complete sources:
       - modern TDB `TDB_full_world_1200.26021_2026_02_06.sql` contains timed action lists `3123800`/`3123801` and waypoint path `249905`;
       - TrinityCore's historical `sql/old/4.3.4/TDB8_to_TDB9_updates/world/065_2014_10_08_00_world.sql` contains the same behavior in the old SmartAI schema used by this core.
     - The historical 11-point path already exists intact in the active DB as `waypoints.entry=31238`; its coordinates match the modern path and return to Hira's spawn position.
     - Added `sql/updates/world/2026_07_10_06_world_hira_snowdawn_flight.sql` to correct the two shifted caller rows and restore the six missing timed-action steps without deleting content.
     - Compatibility translation is source-backed: modern Action `146` (toggle unit flag) maps to this core's Actions `18`/`19` with `UNIT_FLAG_NOT_SELECTABLE=33554432`, exactly as specified by the historical old-schema update.
     - Applied the SQL to the active `world` DB and verified both corrected callers, all six timed-action steps, and all 11 waypoint rows.
     - Restart verified: both `31238` invalid-action errors are gone; the fresh log has no invalid SmartAI actions.
     - In-game test completed with a temporary 5-second timer: Hira spoke, became non-selectable, flew the recovered 11-point loop, and returned correctly.
     - Restored the active DB timer to the authentic 600000 ms (10 minutes) after the successful test so trainer availability is interrupted only briefly and infrequently.

24. Automatic random bot login disabled
   - Changed active `Build/bin/RelWithDebInfo/playerbots.conf`: `AiPlayerbot.RandomBotAutologin = 0`.
   - Kept `AiPlayerbot.Enabled = 1`, `AiPlayerbot.AddClassCommand = 1`, and the manual bot limit unchanged, so manually added bots remain available.
   - Restart verified: no `BotLevelBrackets` activity, no repeated item-owner warning, and the character DB reports `0` online `RNDBOT%` characters.
   - The startup message about 200 random-bot accounts/2200 characters only loads the available account pool; it does not mean they were logged into the world.

25. Orphan creature addon GUID 10011
   - Investigated startup error `Couldn't get creature data for GUIDLow 10011`.
   - Initial DB inspection confirmed there is no creature, creature addon, or waypoint path owned by GUID `10011`; the first guarded cleanup therefore had no addon row to remove.
   - Restart showed the warning remained. Code tracing identified the actual source as `linked_respawn (10011,136105,0)`.
   - Master GUID `136105` is Lady Deathwhisper (`36855`) in Icecrown Citadel; nine other valid creature links to this master remain intact. The repository base dump contains the orphan link but no slave creature spawn `10011`.
   - Updated `sql/updates/world/2026_07_10_07_world_orphan_creature_addon_10011.sql` with a guarded deletion of only that relation, requiring the slave to be absent and the master to match Lady Deathwhisper on map `631`.
   - Applied to the active DB: orphan link count is now zero and all nine valid Lady Deathwhisper links remain.
   - Restart verified: `Couldn't get creature data for GUIDLow 10011` is gone.

26. Three unresolved linked server-side spells
   - Current warnings are missing linked spell ids `203754`, `200002`, and `200003`.
   - `203754` is linked from MoP Prayer of Mending `123262`, but the local custom definition using that numeric id is an unrelated Murozond credit marker, indicating cross-version/id collision.
   - `200002` and `200003` are referenced by battleground cleanup code and link to existing effects `200004`/`200005`, but their own custom Spell/SpellEffect definitions are absent. Existing `spell_dbc` rows `11202`/`12507` only point at SpellMisc ids with those numbers and do not create SpellInfo entries `200002`/`200003`.
   - Leave all three linked rows visible for now. Do not delete them or invent trigger effects until a complete matching 5.4.8 custom spell source is recovered.

27. Quest 1242/1244 invalid emote sequences
   - Investigated invalid emote `9` warnings in `quest_details` and `quest_offer_reward`.
   - The modern TDB source contains corrected complete sequences, showing that the old dump had shifted/repeated emotes rather than one missing animation.
   - Added `sql/updates/world/2026_07_10_08_world_quest_1242_1244_emotes.sql` with exact old-row guards:
     - quest details `1242`: `1,1,9,0` -> `1,1,0,0`;
     - quest reward `1242`: `6,9,6,11` -> `6,11,0,0`;
     - quest reward `1244`: `1,9,1,0` -> `1,1,0,0`.
   - No quest text, objectives, rewards, or delays are changed. Applied and restart verified; all quest `1242`/`1244` invalid-emote warnings are gone.

28. Galen Goodward script_waypoint migration
   - The 269 `script_waypoint` warnings represent only ten NPC entries. Galen Goodward (`5391`) was selected first because active quest `1393 Galen's Escape` still directly uses him.
   - Recovered TrinityCore's complete source-backed SmartAI implementation from the official `3.3.5` branch update `2020_06_26_03_world_335.sql`.
   - Added and applied `sql/updates/world/2026_07_10_09_world_galen_goodward_smartai.sql`.
   - Restored 13 creature SmartAI events, eight timed-action steps, SmartTrigger area trigger `2387`, cage opening, escort start, quest credit/failure, final dialogue, and despawn.
   - Migrated the exact existing 22 coordinates from obsolete `script_waypoint` numbering `0-21` to SmartAI `waypoints` numbering `1-22`.
   - Preserved all nine existing authentic `creature_text` rows and remapped their groups by BroadcastText ID for the SmartAI sequence.
   - Removed only Galen's obsolete `script_waypoint` copy after guarded checks confirmed all 22 new path points and all 21 required SmartAI rows exist.
   - DB and restart verification passed: `script_waypoint` warnings dropped exactly from `269` to `247`, with no Galen/SmartTrigger validation errors. In-game quest `1393` testing remains recommended.

29. Tapoke "Slim" Jahn script_waypoint investigation
   - Tapoke (`4962`) is the smallest remaining obsolete path with seven points and belongs to quest `1249 The Missing Diplomat (Part 11)`.
   - Recovered both the removed historical C++ escort and TrinityCore's complete official SmartAI conversion (`2018_08_11_12_world_335.sql`).
   - The conversion includes Mikhail (`4963`), Tapoke, Slim's Friend (`4971`), three authentic Tapoke lines, friend/Mikhail dialogue, stealth, seven waypoints, ambush combat, surrender at 20% health, quest credit/failure, and despawns.
   - Active DB has the exact seven old path coordinates, but only two incomplete combat rows for Slim's Friend and none of the quest-control SmartAI chain.
   - Modern TDB independently retains the same behavior and still uses SmartAI Action `27` (`COMBAT_STOP`) for Tapoke's surrender.
   - This project has standard Action `27` commented out because the identical `SMART_ACTION_COMBAT_STOP` implementation is already registered as project Action `203`. Its handler calls `CombatStop()` on creature targets and the validator accepts it.
   - Compatibility mapping is therefore exact and requires no core rebuild: translate only source Action `27` to local Action `203`. Do not use `EVADE`, which would change health/movement/reset behavior.
   - Added and applied `sql/updates/world/2026_07_10_10_world_tapoke_slim_jahn_smartai.sql` with exact compatibility adaptations:
     - source Action `27` -> local identical Action `203`;
     - old Tapoke GUID `10873` -> active GUID `217269`;
     - old Mikhail GUID `9432` -> active GUID `216482`.
   - Restored 11 Tapoke events, eight Tapoke timed actions, six Mikhail events, two Mikhail timed actions, four Slim's Friend events, four friend timed actions, and all five authentic dialogue rows.
   - Migrated all seven exact coordinates to `waypoints` ids `1-7`; removed the obsolete `script_waypoint` copy only after guarded row-count checks passed.
   - DB verification passed, including Action `203`. Pending restart validation and in-game quest `1249` test.
   - First restart reduced `script_waypoint` warnings exactly from `247` to `240` and validated Action `203`, but exposed three old ranked spell ids skipped by 5.4.8: Stealth `1785` twice and Backstab `2589` once.
   - Added `2026_07_10_11_world_tapoke_548_spell_ids.sql` and corrected the original migration: source Stealth `1785` -> local Stealth `1784`; source Backstab `2589` -> local Backstab `53`. Both replacements are explicitly defined by this 5.4.8 core.
   - Second restart verified: no errors for Tapoke `4962/496200`, Mikhail, Slim's Friend `4971/497100`, or their spells; invalid actions and missing text remain zero. `script_waypoint` count remains the expected `240`.

30. Scarlet Trainee and Shadowfang path triage
   - Scarlet Trainee (`6575`, 12 points) is not a standalone DB escort. Herod's C++ `JustDied` summons 20 trainees; each trainee waits 1-6 seconds and starts the running escort path.
   - This 5.4.8 repository has Herod (`3975`) and Scarlet Trainee data on map `189`, but no `boss_herod`/`npc_scarlet_trainee` C++ implementation or script registration at all.
   - The official modern implementation uses a dedicated path and still requires C++ summon/escort logic. Do not delete the 12 old points or attach a ScriptName that is not registered. Correct repair requires porting the complete Herod+trainee script and rebuilding worldserver.
   - Deathstalker Adamant (`3849`) and Sorcerer Ashcrombe (`3850`) are likewise Shadowfang Keep instance-event NPCs referenced by the official instance header, not independent SmartAI escorts. Their required instance scripts are absent from this repository too.
   - Continue DB-only migration only for entries with a complete source-backed SmartAI conversion. Group these dungeon-dependent paths into a later C++ restoration batch rather than suppressing their warnings.

31. Anchorite Truuen script_waypoint migration
   - Quest `9446 Tomb of the Lightbringer` used Anchorite Truuen (`17238`) with 26 obsolete `script_waypoint` rows but no active C++ ScriptName or SmartAI.
   - Recovered TrinityCore's complete official SmartAI conversion from `2015_11_23_00_world_335.sql`, including Ghost of Uther (`17233`), summoned attackers, dialogue timing, kneeling, quest escort state, completion, and despawn.
   - Added and applied `sql/updates/world/2026_07_10_12_world_anchorite_truuen_smartai.sql`.
   - Preserved and remapped the three existing authentic Anchorite text rows by BroadcastText ID, then added the five missing official rows. Ghost of Uther's compatible existing text groups were left unchanged.
   - Installed 21 Anchorite events, one + three Anchorite timed actions, one Ghost of Uther event, four Uther timed actions, and the official corrected 17-point path.
   - Removed the old 26-point `script_waypoint` path only after guarded checks confirmed every required SmartAI group and all 17 replacement waypoints.
   - Database verification passed exactly: SmartAI row counts `21/1/3/1/4`, eight Anchorite text groups `0-7`, 17 new waypoints, and zero old Anchorite script waypoints.
   - Restart verification passed: no Anchorite/Ghost of Uther validation errors, and `script_waypoint` warnings dropped exactly from `240` to `214`. In-game quest `9446` test remains recommended.

32. Lord Gregor Lescovar path triage
   - Entry `1754` is Lord Gregor Lescovar from quest `434 The Attack!`; he has no permanent spawn and is driven by the larger Tyrion/Spybot event.
   - Recovered TrinityCore's complete official implementation in `zone_stormwind_city.cpp`. It couples Lescovar's 17-point escort to Tyrion's Spybot (`8856`, another 18 obsolete points), Tyrion (`7766`), Priestess Tyriona (`7779`), Marzon (`1755`), Stormwind guards (`1756`), dialogue phases, summons, faction changes, quest credit, and synchronized combat.
   - This repository registers `zone_stormwind_city.cpp`, but its local file contains only an empty `AddSC_stormwind_city()`; all four required script classes are absent. Active templates likewise have blank ScriptNames, and neither replacement path `70850` nor the Spybot replacement path is installed.
   - Restored the official 5.4.8-era implementation in `zone_stormwind_city.cpp`, with only local API-name adaptations (`SetFaction`/`GetFaction` and `JustEngagedWith`). The scripts library and final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Added and applied `sql/updates/world/2026_07_10_13_world_stormwind_the_attack_scripts.sql`, binding only the four quest participants: Lescovar, Marzon, Tyrion, and Tyrion's Spybot.
   - Retained both authentic `script_waypoint` paths. This core's `npc_escortAI` loads that table directly, so deletion or conversion would break the restored C++ event.
   - Restart verification passed. `DBErrors.log` is append-only during these runs: its cumulative count rose from `214` to `393`, meaning the fresh run contains `179` warnings (`214 - 35`). The file contains exactly the 17+18 old pre-fix Lescovar/Spybot messages and no second set from the new run. Active DB bindings remain correct and there are no missing-script errors. In-game quest `434` test remains recommended.

33. Rin'ji escort restoration
   - Entry `7780` belongs to quest `2742 Rin'ji is Trapped!` and has an authentic 24-point `script_waypoint` path plus complete creature text groups `0-4`.
   - Restored the official `npc_rinji` C++ escort in `zone_hinterlands.cpp`: cage opening, player-bound escort, two ranger/outrunner ambushes, combat dialogue, quest completion, running finish, and post-event dialogue.
   - Adapted only the local API differences: `JustEngagedWith` replaces the old combat callback, and respawn state is reset through this core's `Reset()` hook.
   - Added and applied `sql/updates/world/2026_07_10_14_world_rinji_script.sql`, binding entry `7780` to the registered script while retaining all 24 path rows used directly by this core's `npc_escortAI`.
   - Both the scripts library and final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed on a fresh log: exactly `155` `script_waypoint` warnings remain (`179 - 24`), with zero Rin'ji or missing-script errors. Active entry `7780` remains correctly bound to `npc_rinji`. In-game quest `2742` test remains recommended.

34. Corporal Keeshan SmartAI migration
   - Entry `349` is the 115-point escort for quest `219 Missing In Action`, the largest remaining obsolete path.
   - Recovered TrinityCore's complete official SmartAI conversion from `2020_01_15_01_world_335.sql`; no C++ port or rebuild was required.
   - Added and applied `sql/updates/world/2026_07_10_15_world_corporal_keeshan_smartai.sql`, restoring quest accept/start, stored player target, faction and npcflag handling, Shield Bash `11972`, Mocking Blow `21008`, the rest/pause scene, run transition, all dialogue, quest completion/failure, and despawn.
   - Both spell ids are independently present throughout this project's native 5.4.8 SmartAI source, so no rank adaptation was necessary.
   - Preserved the five existing authentic text groups and upserted the missing BroadcastText `28` as group `5` without deleting dialogue.
   - Installed all 115 official waypoints and removed the obsolete `script_waypoint` copy only after guarded checks confirmed SmartAI counts `7/5/5/2/4` and all path points.
   - Database verification passed exactly: SmartAI template active, all required event groups present, six text groups `0-5`, 115 replacement waypoints, and zero old Keeshan rows.
   - Restart verification passed. The append-only log contains `195 = 155` previous-run warnings plus exactly `40` from the fresh run; Keeshan's 115 old messages occur only once and did not recur. No Keeshan SmartAI, dialogue, action, or spell validation errors appeared. In-game quest `219` test remains recommended.

35. Classic Herod and Scarlet Trainee restoration
   - Entry `6575` is not a standalone escort: Herod (`3975`) summons 20 trainees on death, each waits 1-6 seconds and runs the authentic 12-point path.
   - Restored `boss_herod.cpp` from the official 5.4.8-era behavior: charge, cleave, whirlwind dialogue/timing, 30% frenzy, kill dialogue, and the 20 trainee summons.
   - The active Herod spawn is on classic map `189`, while this project's existing `instance_scarlet_monastery` belongs to MoP map `1004`. To avoid binding classic Herod to the wrong instance, preserved the official encounter logic in an independent `ScriptedAI` rather than the source `BossAI`; no map-1004 code was changed.
   - Restored the official `npc_scarlet_trainee` delayed running escort, added the source to CMake and ScriptLoader, and applied `sql/updates/world/2026_07_10_16_world_herod_scarlet_trainee_scripts.sql` for both template bindings.
   - Retained all 12 `script_waypoint` rows because this core's `npc_escortAI` loads them directly. Scripts library and final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed. The append-only log total is `223 = 195` previous runs plus exactly `28` fresh warnings; the old `6575` messages occur only in the two earlier runs and did not recur. No Herod, Trainee, or missing-script errors appeared. An in-game Herod kill remains recommended to verify the 20 delayed runners.

36. Shadowfang Keep prisoner restoration
   - The final 28 obsolete-path warnings belong to Deathstalker Adamant (`3849`) and Sorcerer Ashcrombe (`3850`), each with an authentic 14-point path and distinct dialogue.
   - Restored the official shared `npc_shadowfang_prisoner` escort in the existing Shadowfang Keep source: post-Rethilgore gossip, escort start, entry-specific dialogue, Ashcrombe's Unlock `6421`, courtyard-door opening, and Adamant's final departure line.
   - The original script depended on removed classic instance fields `TYPE_RETHILGORE` and `TYPE_FREE_NPC`. Adapted this without guessing enum numbers: gossip requires no living Rethilgore (`3914`) nearby, and waypoint 12 opens the actual courtyard door (`18895`) directly. The modern instance and its boss-state data were not altered.
   - Added and applied `sql/updates/world/2026_07_10_17_world_shadowfang_prisoner_scripts.sql`, binding both templates while retaining both 14-row paths used directly by `npc_escortAI`.
   - Scripts library and final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed on a fresh log: `script_waypoint` warnings are exactly zero, with no Adamant, Ashcrombe, prisoner-script, or missing-script errors. The only log match for number `6421` is unrelated quest `6421` with a missing AreaTrigger objective, not Ashcrombe's Unlock spell. In-game prisoner/door testing remains recommended.

37. SmartAI Action 124 restoration
   - The sole unsupported Action `124` belongs to timed action list `170600`, event `9`, for Defias Prisoner (`1706`). The sequence summons four helpers, assigns their data, activates the prisoner, changes equipment, and then starts waypoint path `1706`.
   - Confirmed from TrinityCore's authoritative SmartAI definitions that Action `124` is `SMART_ACTION_LOAD_EQUIPMENT` with parameters `equipment id` and boolean `force`. The active row requests id `0`, force `1`.
   - This core's `Creature::LoadEquipment(int8 id, bool force)` already implements the required behavior; only the SmartAI plumbing was missing.
   - Restored enum `124`, its two action parameters, force/range validation, target resolution, and execution in `SmartScriptMgr.h/.cpp` and `SmartScript.cpp`. No DB row was deleted or altered.
   - Final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed: Action `124`, `LOAD_EQUIPMENT`, and all general `Not handled action_type` warnings are zero.
   - With Action `124` now accepted, validation reaches the next row and exposes a separate missing dependency: timed list `170600` event `10` starts waypoint path `1706`, but neither `waypoints` nor `script_waypoint` contains that path. The two active Prisoner spawns are at different Stormwind positions, so coordinates must not be inferred from one spawn. TrinityCore 3.3.5 has only the Prisoner's combat SAI and no matching escape sequence; continue searching a matching Cataclysm/5.4.8 world source rather than disabling Action `53` or inventing a route.

38. Pool-data scope and root cause
   - Fresh startup contains roughly `1908` pool validation messages (the inspected log had three accumulated starts and `5724` pool lines). There are `2335` distinct affected pool ids, so this is not a small set of isolated bad rows.
   - Active pool data is a very large imported hierarchy: `14062` templates, `58506` gameobject members, `1435` creature members, and `8066` child-pool links.
   - The dominant error is `pool_pool` parents containing child pools from multiple maps. Example master `9757` (`max_limit=2`) intentionally groups child `8665` on map `0` with children `8666-8668` on map `1`; each child is internally single-map, but the parent is invalid for this core's per-map PoolMgr model.
   - Many direct `pool_gameobject` and a few `pool_creature` memberships also resolve to multiple maps, indicating that pool hierarchy and active spawn GUID data were imported/remapped from different dataset generations.
   - Do not mass-delete the reported memberships: that would silently remove mining/herb/fishing/rare spawn rotation. Repair requires rebuilding or splitting pools by map from a matching 5.4.8 spawn+pool dataset, preserving each master pool's `max_limit` semantics. Treat this as a dedicated data migration rather than a startup-log suppression batch.

39. SmartAI rows shadowed by C++ scripts
   - Loader warnings named five templates with SmartAI rows but blank `AIName`: Khadgar `18166`, Zephyr `25967`, Zidormi `31848`, Tornado `64267`, and Spirit of Violence `64656`.
   - Do not set `AIName=SmartAI`: every template is intentionally bound to a registered C++ implementation (`npc_khadgar`, `npc_zephyr`, `npc_zidormi_dalaran`, `npc_kraxik_tornado`, or `celestial_experience_sha`). Enabling SmartAI would replace or conflict with live behavior.
   - Added and applied `sql/updates/world/2026_07_10_18_world_remove_shadowed_smartai.sql`. It removes only source-type `0` rows through an exact `(entry, ScriptName)` guarded join; these 15 rows were unreachable and ignored by the loader, so no active behavior was deleted.
   - Verified all five C++ bindings remain unchanged and zero shadowed rows remain.
   - Restart verification passed on a fresh log: SmartAI/AIName mismatch warnings are zero, none of the five entries appears in errors, and Action `124` plus `script_waypoint` remain clean.

40. Numeric ScriptName import artifacts
   - Missing-core-script names `'0'` and `'1'` were not actual scripts. `'0'` appeared on six ordinary condition rows whose condition fields are otherwise valid; `'1'` appeared on gameobject spawn GUID `20936` (`id 200004`) while its actual state is already stored in the separate `state` column.
   - Added and applied `sql/updates/world/2026_07_10_19_world_normalize_numeric_script_names.sql`, changing only those exact guarded ScriptName values to empty strings.
   - No condition, spawn, state, or behavior row was removed. Verification shows zero condition ScriptNames `'0'` and an empty ScriptName for GUID `20936`.
   - Restart verification passed exactly: missing-core-script warnings dropped from `31` to `29`; names `'0'` and `'1'` are both absent. Action `124` and `script_waypoint` remain clean.
   - The remaining named warnings are a mixture of implemented-but-commented registrations (achievement, area trigger, and spell scripts) and absent battle-pay/item scripts; handle each family separately rather than deleting their bindings together.

41. Safe commented-script registrations
   - Audited four DB-bound but commented registrations instead of enabling them as a batch.
   - Enabled `achievement_im_on_a_boat`: its criteria implementation is complete, its four DB criteria rows are present, and current TrinityCore independently registers the same script.
   - Enabled `sat_icy_shadows`: its Throne of Thunder area-trigger implementation is complete, including LOS gating and aura apply/remove behavior, and DB template `742` is bound to it.
   - Deliberately left `at_well_of_eternity_skip_illidan_intro` disabled because the source documents a progression/pass closure bug. Left `spell_howling_gale_howling_gale` disabled because all three behavior casts inside its periodic handler are commented out; registering it would only hide the warning.
   - Final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed exactly: missing-core-script warnings dropped `29 -> 27`; neither enabled name appears in errors, and there are no replacement achievement/area-trigger errors. Action `124` and `script_waypoint` remain clean.

42. WoW token item-script registration
   - Missing names `wow_token_1`, `wow_token_2`, `wow_token_5`, and `wow_token_10` map to existing items `110001-110004` and a complete compiled implementation in `Custom/wow_token.cpp`.
   - Verified all required support exists: `Player::AddDonateTokenCount`, login DB token persistence, Trinity strings `30007-30010`, and active `Wow.Token = 1` configuration.
   - Restored the existing `AddSC_wow_token()` call in `AddCustomScripts()`; no item, coin amount, account data, or configuration value was changed.
   - Final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed exactly: missing-core-script warnings dropped `27 -> 23`; all four `wow_token_*` names and item IDs are absent from errors. Action `124` and `script_waypoint` remain clean.

43. Battle-pay item-script triage
   - Audited all 17 DB-bound `battle_pay_*` items before enabling the commented custom loaders.
   - The two profession classes register as `Boost_Profession` / `Boost_Profession_Small`, while DB expects `battle_pay_boost_profession*`. The four currency classes similarly register as `honor_1000`, `justice_1000`, `valor_1000`, and `conquest_1000`, not the DB names.
   - No implementation exists anywhere in `Custom/` for the six gold items or five character-service items (level 90, rename, customize, race change, faction change). `custom_reward.cpp` is only a played-time reward and is unrelated.
   - Therefore do not enable `AddSC_boost_profession()` or `AddSC_custom_items()` merely to suppress warnings: 11 items would remain unimplemented and the six existing classes would still not match their DB bindings. Do not remove the bindings either, because that would make intended paid/service items silently inert while hiding the incomplete feature.
   - Correct repair requires an explicit economic/service design decision and complete implementations with transactional item consumption, currency caps, at-login flags, audit logging, and failure rollback. Leave all 17 warnings visible until that feature is restored as a coherent batch.

44. Party/raid stat-buff spell bindings
   - DB bound Mark of the Wild `1126`, Arcane Brilliance `1459`, and Power Word: Fortitude `21562` to obsolete `_stats` script names that do not exist in this core.
   - Verified this core already has complete, registered 5.4.8 handlers for the same spell IDs under `spell_dru_mark_of_the_wild`, `spell_mage_arcane_brilliance`, and `spell_pri_power_word_fortitude`, including party/raid aura propagation.
   - Added and applied `sql/updates/world/2026_07_10_20_world_stat_buff_spell_script_names.sql`, changing only the three exact old bindings to the registered names. No spell effects or core code were changed.
   - DB verification shows one correct binding for each spell.
   - Restart verification passed exactly: missing-core-script warnings dropped `23 -> 20`; all `_stats` names and replacement script errors are zero. Action `124` and `script_waypoint` remain clean.

45. Protection of Elune AuraScript registration
   - DB spell `38528` is bound to `spell_protection_of_elune`, and its complete AuraScript already exists in `boss_archimonde.cpp` with validation plus apply/remove immunity handling.
   - The loader incorrectly instantiated the raw `AuraScript` with `new spell_protection_of_elune()`, which does not register a named script for `spell_script_names` lookup.
   - Replaced it with `new aura_script<spell_protection_of_elune>("spell_protection_of_elune")`, matching this core's standalone AuraScript registration pattern. No DB row or spell behavior was removed.
   - Final `worldserver.exe` compiled successfully in `RelWithDebInfo` x64.
   - Restart verification passed exactly: missing-core-script warnings dropped `20 -> 19`; `spell_protection_of_elune` is absent. Action `124` and `script_waypoint` remain clean.

46. Dreadflame database target effect
   - Startup reported six rejected `spell_target_position` rows. They were not deleted as a batch because several belong to real teleport, summon, and encounter mechanics.
   - Matching TrinityCore 4.3.4 source data identifies Dreadflame spell `100679` on Firelands map `720` as a database destination on effect `0`; the imported local row incorrectly used effect `2`, which the 5.4.8 spell data rejects.
   - Added and applied `sql/updates/world/2026_07_10_21_world_dreadflame_target_position.sql` as a controlled test, changing only `(id=100679, effIndex=2, target_map=720)` to effect `0`.
   - Restart verification disproved cross-version compatibility: this core's 5.4.8 spell data rejects effect `0` as well, and the warning count correctly remained `6`. Therefore the attempted change must not be retained.
   - Added and applied `sql/updates/world/2026_07_10_22_world_revert_dreadflame_target_position.sql`, restoring the original effect `2`. Keep all six warnings visible until matching 5.4.8 evidence is found; do not delete functional destination rows merely to silence validation.

47. Orphan waypoint scripts and missing quest-item triage
   - The 46 orphan `waypoint_scripts` ids are two structured blocks (`57-95` and `147-153`) containing 81 commands. Active `waypoint_data` has zero links to them, and the same disconnected rows already exist in the 2024 local 5.4.8 base dump without useful comments.
   - They cannot execute in the current DB, but were retained because mass deletion would discard the only remaining command data needed if their original routes are later recovered.
   - Audited the eight quests reported with nonexistent objective items. Each quest has exactly one type-1 item objective: `10794/113135`, `29046/68674`, `29048/68676`, `29056/68680`, `29466/71961`, `29554/73366`, `32470/93396`, and `32475/93660`.
   - The apparent collisions with creature ids in newer Trinity data do not prove corruption because item and creature ids are separate namespaces. Several quest names and requested amounts strongly support real quest-item objectives. Do not convert these to creature objectives or delete them; restore matching 5.4.8 `item_template` rows only from a trusted 5.4.8 item source.

48. Orphan achievement reward locales
   - Confirmed exactly 30 `achievement_reward_locale` rows whose achievement ids (`1681`, `1682`, `2145`, `2796`, `3656`, `4784`, and `4785`) have no parent row in `achievement_reward`.
   - These translations cannot be loaded or affect rewards without a parent. Added and applied `sql/updates/world/2026_07_10_23_world_remove_orphan_achievement_reward_locales.sql`, deleting only locale rows selected by a guarded `LEFT JOIN ... WHERE parent IS NULL`.
   - No achievement or reward definition was changed. Restart verification passed: orphan reward-locale warnings dropped `30 -> 0`. Missing-core-script count remains the expected `19`; Action `124` and `script_waypoint` remain clean.

49. Remaining small-category triage
   - Loot warnings include six active creature/gameobject LootIDs with missing templates and three unreachable item-loot templates. Do not clear active LootIDs or delete the only remaining item-loot data without matching 5.4.8 loot sources.
   - Four vehicle carrier templates (`54499`, `57464`, `65476`, `65477`) have accessories but no spell-click rows. They carry scripted/automatic NPC passengers rather than clearly player-clickable seats; do not invent spell-click spells merely to satisfy the generic validation warning.
   - Thirteen old gameobjects (furnaces, portals, and spell-focus objects) reference linked-trap entries `4` or `129` that are not traps. Matching linked-trap templates were not found, so retain the rows until their correct historical templates are recovered.
   - Seventeen achievement criteria use legacy data type `12`, all with `value1=1`. The rows exist in old Trinity TDB SQL, but the corresponding code generation marks type `12` as `REUSE` while historical `T_PLAYER_DEAD` is type `4`; do not assign guessed semantics or register an unsafe handler.
   - The 36 rejected `playercreateinfo_skills` ids mix legacy specialization, class-general, weapon, and racial skill lines. Because rejection is driven by this exact client's SkillLine data and the surviving table still contains other valid class/weapon/racial rows, do not mass-delete or remap them without a matching 5.4.8 player-create dataset.

## Retrospective Safety Audit - 2026-07-13

The repository history from `upstream/master` through local `master` was reviewed for fixes that may silence an error by deleting data, disabling behavior, or removing packet fields instead of repairing the underlying cause. The review covered 82 commits, with particular attention to C++ deletions, SQL `DELETE` statements, SmartAI action substitutions, and fatal-error downgrades.

### 1. Wild battle-pet source spawns were deleted before the runtime cause was repaired

- `sql/updates/world/2026_07_03_00_world_startup_error_cleanup.sql` deletes the listed Forest Moth / Amber Moth source creatures and their `creature_addon` rows because replacement creatures produced invalid runtime Z values.
- This is a content-removal workaround, not a coordinate repair. A later C++ change in `BattlePetSpawnMgr.cpp` provides the better runtime solution: use the creature's DB/home coordinates when its live position is invalid, and skip replacement with a precise error only if both positions are invalid.
- The later C++ fix does not restore the source spawns already deleted by the SQL update. Consequently those battle-pet sources can remain permanently absent even though the core can now handle the original runtime condition.
- The `creature_addon` deletes are also less guarded than the creature deletes. An addon row can be removed even if the corresponding creature no longer has the expected entry or does not match the condition that justified removal.

Recommended repair:

1. Obtain a world database dump from before the first cleanup was applied.
2. Export the original `creature` and `creature_addon` rows for GUIDs `237571`, `240095`, `240186`, `240214`, `240261`, `240384`, `527565`, `527567`, `527568`, `527577`, and `527582`.
3. Compare their entry, map, phase, spawn mask, coordinates, movement, and addon data with a matching 5.4.8 source.
4. Create a new forward-only restoration SQL update. Do not edit or remove an already-applied historical update. Restore only rows proven to belong to the expected battle-pet sources, using complete-column guarded inserts or upserts.
5. Restart with a fresh log and test the affected zones. Confirm the source creatures load, replacement pets use valid coordinates, and no duplicate GUID or invalid-position warning is produced.

### 2. The duplicate-effect SmartAI "no-op" is an active phase-changing action

- `sql/updates/world/2026_07_09_10_world_smartai_duplicate_spell_effect_batch1.sql` describes redundant kill-credit and summon actions as disabled, but changes them to SmartAI Action `22` with parameter `0`.
- In this core Action `22` is `SMART_ACTION_SET_EVENT_PHASE`, not a no-op. If the row executes, it sets the SmartAI event phase to zero and can change which later events are eligible to run.
- Preserving the old spell or creature id in unused `action_param6` does not preserve runtime behavior and is not a reliable rollback mechanism.
- The foreign-spell update in `2026_07_10_02_world_smartai_foreign_spell_actions.sql` additionally converts rows to link events before using Action `22`. Those rows may currently be unreachable if nothing links to them, but Action `22` still must not be documented or treated as a generic disabled action.

Recommended repair:

1. Recover the pre-change SmartAI rows from the original database, including every event/action/target parameter and link field.
2. Verify each complete SmartAI chain, not only the individual warning row. Confirm whether the spell and explicit credit/summon action truly execute in the same gameplay path.
3. Where duplication is proven, rebuild the chain so the redundant action is removed without inserting an active replacement action. If the chain requires an event at that position, link its predecessor directly to the next required timed action or use a core-supported inert representation whose behavior has been verified in `SmartScript.cpp` and validation accepts it.
4. If no safe inert representation exists, retain the original warning until the chain can be reconstructed. A visible validation warning is safer than an undocumented event-phase change.
5. Add targeted in-game tests for entries `48119`, `48121`, and `56686`, checking quest credit, summon count, dialogue links, and later phase-gated events.

### 3. `SMSG_LOGOUT_COMPLETE` was replaced with an empty packet

- Commit `bb69383c` removed the logout-complete bit and packed-GUID payload and replaced it with `WorldPacket data(SMSG_LOGOUT_COMPLETE, 0)` in `WorldSession.cpp`.
- This may avoid a crash caused by an incorrect serializer, but repository-local evidence does not establish that an empty payload is the correct 5.4.8 Build 18414 packet layout.
- Treat this as an unresolved protocol change, not a verified fix.

Recommended repair:

1. Obtain authoritative Build 18414 packet evidence: a compatible sniff, a matching 5.4.8 core implementation, or a confirmed client test that validates both manual logout and forced logout paths.
2. Compare the opcode payload bit-for-bit before changing the implementation.
3. Restore the correct serializer rather than restoring the old payload blindly. Add packet-level logging or a focused serialization test where practical.
4. Test logout to character selection, logout cancellation, disconnect during logout, cinematic/login transitions, and server shutdown. Confirm there is no client hang, malformed-packet disconnect, or crash.

Resolution status:

- Local matching source `C:/wamp64/www/SkyFire_548` independently uses `WorldPacket data(SMSG_LOGOUT_COMPLETE, 0)` for opcode `0x142F`, explicitly identified as 5.4.8 Build 18414.
- SkyFire commit `33e826eaa9` is titled `Fix client stack overflow on login/logout by correcting SMSG_TRIGGER_CINEMATIC and SMSG_LOGOUT_COMPLETE packet structures` and deliberately replaces the old bit/GUID serializer with the empty packet.
- The preserved older source itself questioned the duplicated/incorrect first-bit layout. This is strong local matching-version evidence that the payload removal corrected a malformed packet rather than merely hiding a server error.
- No code rollback is recommended. Keep the empty packet and perform the listed in-game logout/cinematic cases when convenient; gameplay verification is still pending.

### 4. A GameObject owner invariant failure was downgraded from fatal to log-and-continue

- `GameObject::RemoveFromOwner()` now logs `DEBUG` during shutdown or `ERROR` during normal runtime, clears the stale owner GUID, and continues. Previously the same unexpected state caused `TC_LOG_FATAL`.
- Continuing during shutdown is plausibly correct cleanup behavior. During normal runtime, however, clearing the GUID treats the symptom and can hide the code path that removed the owner relationship out of order.

Recommended repair:

1. Keep the non-fatal shutdown handling, but collect enough normal-runtime context to identify the creator spell, owner type/GUID, map, instance, GameObject type, and removal path.
2. Reproduce outside shutdown and trace owner destruction, spell-created GameObject cleanup, and queued object removal ordering.
3. Fix the ordering at the call site that leaves the stale relationship. Only then decide whether normal-runtime recovery should remain an error, assertion in debug builds, or guarded cleanup.
4. Do not delete affected GameObjects or suppress the log globally as a substitute for finding the lifecycle error.

Resolution status:

- Code inspection confirms `TC_LOG_FATAL` is a logging severity macro (`LOG_LEVEL_FATAL`), not the aborting `WPFatal`/`Trinity::Fatal` assertion path. The old code already continued to `SetOwnerGUID(ObjectGuid::Empty)` immediately after logging.
- Therefore the commits did not introduce log-and-continue behavior or delete cleanup logic; they only changed severity to `DEBUG` during `World::IsStopped()` and `ERROR` otherwise.
- The exact message has zero matches in the available current and archived server logs. There is no evidence of a recurring normal-runtime lifecycle fault at present.
- No code change is recommended now. Retain the conditional severity and investigate only if the `ERROR` form occurs during normal runtime; the existing message already records GO GUID/entry, creator spell, linked GO, owner GUID, and owner type.

### Original database comparison requested

The database from before any of these fixes is the preferred evidence source. A full dump is useful, but the first comparison can be limited to these tables to reduce size:

- `creature` and `creature_addon` for the eleven battle-pet GUIDs listed above;
- `smart_scripts` for entries `48119`, `48121`, `56686`, `70021`, and `70034`, plus any timed action lists referenced by their links;
- optionally `waypoint_data`, `waypoints`, `creature_text`, and `conditions` rows referenced by those SmartAI chains.

Keep the original dump read-only. Import it into a separate comparison schema, never over the active world database. Generate a reviewed forward SQL migration from the differences and take a fresh active-DB backup before applying it.

Comparison status for `sql/base/world_548_20240722.sql`:

- The approximately 550 MB dump was inspected read-only with results separated by active `INSERT INTO` table, rather than accepting unqualified numeric-ID matches from unrelated tables.
- It contains the complete original `smart_scripts` chains for entries `48119`, `48121`, `56686`, `70021`, and `70034`, including timed action list `5668600`.
- For `48119` and `48121`, event `0` casts spell `89568` and links to event `1`; event `1` grants explicit credit `48195` and links to event `2`; event `2` says text group `0`. A correct duplicate-credit repair must preserve the link from event `0` to the dialogue event. Replacing event `1` with Action `22` is not correct.
- For `56686`, event `7` casts summon spell `109335` and links to event `8`; event `8` explicitly summons creature `57874` at the stored position. If client spell data and an in-game test confirm that `109335` performs the same summon, the safe chain repair is to terminate event `7` after its cast and remove only the proven redundant event `8`; do not substitute a phase-changing action.
- The dump confirms that `70021` spell `223971` and `70034` spell `215377` were already present in this dataset. It does not prove those spells are valid for Build 18414, because both are absent from the local 5.4.8 spell data. Keep these two rows unresolved until a matching source supplies the intended spells or behavior.
- None of battle-pet GUIDs `237571`, `240095`, `240186`, `240214`, `240261`, `240384`, `527565`, `527567`, `527568`, `527577`, or `527582` exists in this dump's `creature` or `creature_addon` inserts. Numeric matches found elsewhere belong to unrelated tables such as gameobjects or waypoint data and must not be used to reconstruct creature rows.
- The second candidate dump, `sql/base/world_548_20240722 (1)/world_548_20240722.sql`, was checked the same way with table-qualified streaming extraction. It also contains none of the eleven GUIDs in `creature` or `creature_addon`, so it cannot supply the deleted spawn definitions.
- Therefore this dump is sufficient for the targeted SmartAI reconstruction but not for restoring the deleted battle-pet sources. The next required source is the database dump or SQL import from which those eleven creature GUIDs entered the active database. Only the relevant `creature` and `creature_addon` rows are needed; another full import is not required.
- Added `sql/updates/world/2026_07_10_24_world_repair_smartai_pseudo_noops.sql` as a forward-only repair. For `48119` and `48121` it links the verified spell-cast step directly to the existing dialogue and removes only the bypassed duplicate-credit step. For `56686` it terminates the chain after summon spell `109335` and removes only the duplicate explicit summon. It also removes the already-unreachable `46425` text-group-3 step only when no incoming link exists. Every change is guarded by the complete expected event/action/link state; no historical migration was edited.
- A filesystem backup search found the actual pre-cleanup world dump at `C:/Users/Admin/Desktop/world_bt_updates_before_20260703_145145.sql` (created 2026-07-03 14:51). It contains all eleven exact `creature` rows and only two matching `creature_addon` rows, for GUIDs `240214` and `240261`. All stored creature coordinates are valid; the bad Z values were runtime replacement positions, not corrupt DB coordinates.
- Added `sql/updates/world/2026_07_10_25_world_restore_battle_pet_sources.sql` as a forward-only restoration using those exact rows. Each creature insert runs only when its GUID is absent, so a reused GUID is never overwritten. Addon rows are restored only when the expected creature entry exists and the addon GUID is absent. This works with the later `BattlePetSpawnMgr.cpp` DB/home-coordinate fallback instead of deleting source content.
- Manual application was required because the active configuration has `Updates.EnableDatabases = 0`; merely starting worldserver does not run repository SQL updates. Before applying, targeted backups were written to `sql/backup/world_smartai_before_pseudo_noop_repair_20260713_110032.sql` and `sql/backup/world_battle_pet_guids_before_restore_20260713_110032.sql`.
- Both updates were applied manually to the configured world DB. Direct verification passed: all 11 creatures and exactly 2 original addon rows exist, none has Z at or below `-100000`, the four pseudo-noop rows are absent, `48119/48121` cast steps now link directly to dialogue id `2`, and `56686` spell `109335` now ends its chain with link `0`. A subsequent worldserver restart and fresh-log/in-game verification are still required because these tables are loaded into memory at startup.
- Restart verification passed at 2026-07-13 11:02. The fresh startup completed in 30 seconds and loaded 378 battle-pet spawn definitions. There are zero log matches for `48119`, `48121`, the removed `56686` event `8`, the removed `46425` event `12`, `BattlePetSpawnMgr`, or `invalid position`. No invalid-Z replacement error appeared. Remaining warnings that merely mention creature `56686` belong to a different source entry (`55672`) and timed list `5668600`; they are separate duplicate-effect candidates and were not changed by this repair.
- In-game verification is explicitly still pending. Test `48119/48121` for one credit plus continued dialogue, Master Shang Xi `56686` for exactly one Walking Stick summon and continued quest flow, and at least one restored source area for working wild battle-pet replacement without duplicate or missing spawns. Do not mark this repair fully gameplay-verified until those checks pass.
- In-game `48119` SmartAI execution passed: with Smolderthorn Assassin selected, `.cast 89562 triggered` applied `Disciplined` (`89568`) and continued directly to dialogue (`Hey, wait a minute...`). This confirms the repaired cast-to-dialogue link executes. A visible quest-counter check was not available without the corresponding active quest, so the one-credit gameplay assertion remains indirectly supported by the verified spell effect and removal of the explicit duplicate-credit step. Tests for `48121`, `56686`, and battle-pet replacement remain pending.
- In-game `48121` SmartAI execution also passed: Firegut Flamespeaker reacted to `.cast 89562 triggered` and continued to its dialogue (`Me smash! You die!`). Together, both repaired cast-to-dialogue chains now have direct runtime confirmation. Master Shang Xi `56686` and battle-pet replacement tests remain pending.
- Master Shang Xi visibility was also checked. A teleported Paladin and a newly created Monk that skipped the Pandaren quest progression did not see the normal NPC, while GM visibility exposed it. Database inspection shows `29790` is reached through `29787`, followed by both `29788` and `29789`; using `.quest add 29790` also bypasses SmartAI's quest-accepted event. Therefore an authentic `56686` test must accept `29790` from the NPC after completing the preceding chain, not inject the quest directly.
- The subsequent quest `29791` (`The Suffering of Shen-zin Su`) is gameplay-defective and is not a successful end-to-end test. The hot-air-balloon objectives completed, but the flight failed at the end: the player was ejected and died. Track this separately as a vehicle/path/end-of-route dismount defect. Do not treat objective completion as proof that the balloon script works, and do not conflate it with the repaired `56686` duplicate-summon chain.
- TrinityCore/current-web and repository-history search did not locate a separate authoritative 5.4.8 Trinity DB update that repairs `29791`. The current official TrinityCore branches are not 5.4.8, and the repository branch named `Scripts-Add-a-ballon-skip-script` contains unrelated Guardian of the Elders work rather than a balloon landing fix.
- The local implementation nevertheless contains a strong concrete defect candidate. Active creature `55649` is bound to `npc_shang_xi_air_balloon`; at waypoint `12` that script grants credit, adds aura `50550`, and removes all passengers. Spell `50550` is not identified as the core's parachute, while the same source file's alternative `mop_air_balloon` implementation explicitly defines and casts spell `45472` as `SPELL_PARASHUT`. The generic spell module also identifies `45472` as `SPELL_PARACHUTE`. This matches the observed sequence: quest credit succeeds, then the player is ejected and dies from the fall.
- The authentic behavior is an intentional airborne exit followed by parachute descent near Mandori Village, not ordinary ground dismount. The next proposed code repair is therefore to replace only the erroneous `50550` aura application with a triggered cast of verified parachute spell `45472`, preserving waypoint `12`, credit `55939`, and passenger removal. Build and retest `29791` before considering any waypoint rewrite.
- Implemented the minimal repair in `zone_wandering_island_west.cpp`: waypoint `12` now performs a triggered self-cast of parachute spell `45472` instead of applying unrelated aura `50550`. The RelWithDebInfo `worldserver` build completed successfully on 2026-07-13 at 12:19. Runtime verification of the landing/parachute sequence is pending a server restart and replay of quest `29791`.
- Runtime replay confirmed that parachute spell `45472` now activates, so the fall-damage portion is repaired. However, the player was still ejected over the ocean and took approximately 30,000 periodic fatigue/environmental damage while the coast was visible. This is a distinct early-ejection defect.
- Database route inspection proves creature `55649` has 21 `script_waypoint` points and the source SQL labels point `21` as the despawn/end point. The active `npc_shang_xi_air_balloon` C++ handler was still removing NPC passengers at point `11` and the player at point `12`, leaving points `13` through `21` unused for the passenger. Updated those two end events to points `20` and `21`, respectively, preserving the full database route, credit, parachute, and passenger cleanup. After stopping the running server, the RelWithDebInfo build and final `worldserver.exe` link completed successfully at 2026-07-13 12:46. Runtime verification of the extended route and safe landing remains pending.
- Final gameplay verification passed after the 12:46 build. Accepting `29790` now produces exactly one personal Master Shang Xi; no duplicate NPC or duplicate dialogue was observed. Quest `29791` completes its full 21-point balloon route, reaches the intended shore area, ejects the player with a working parachute, and no longer causes fatal fall damage or ocean-fatigue damage. The duplicate-summon and balloon end-route repairs are therefore gameplay-verified.
- Fresh log review after the successful run found two additional startup-validation problems in the same content. Timed action list `5564900` contains 27 legacy SmartAI rows but has exactly zero incoming Action `80` references, while creature `55649` is actively owned by C++ `npc_shang_xi_air_balloon`; its invalid target/group combinations account for missing Ji Firepaw (`56660`) TextGroups `7` through `10`. This list is an unreachable remnant of the alternative SmartAI implementation, not required by the tested C++ flight.
- Creature `56688` is a permanent `Planting Stave Credit` spawn and is referenced once as quest-credit target, but it is incorrectly bound to `npc_master_shang_xi_thousand_staff_escort`. That AI attempts six dialogue phases twice and produces 12 missing `creature_text` warnings because the credit marker correctly has no dialogue rows. Removing only this erroneous ScriptName binding would preserve the spawn and credit use.
- Proposed guarded cleanup: delete timed list `5564900` only while it has zero incoming Action `80` references and `55649` remains bound to `npc_shang_xi_air_balloon`; clear only the exact `npc_master_shang_xi_thousand_staff_escort` ScriptName from credit entry `56688`. Back up both states, restart, and require zero `56660` TextGroup `7–10` and zero `56688` missing-text warnings without altering the now-passing gameplay path.
- Implemented and manually applied guarded update `2026_07_13_01_world_remove_orphan_pandaren_scripts.sql`. Backups are `world_smartai_5564900_before_cleanup_20260713_1310.sql` and `world_creature_template_56688_before_cleanup_20260713_1310.sql`. Direct verification reports zero remaining `5564900` rows and callers, an empty ScriptName for `56688`, and preservation of its one creature spawn plus one SmartAI quest-credit use. A restart is still required to verify removal of the corresponding startup warnings; no additional gameplay code rebuild is needed for this SQL-only cleanup.
- Restart verification at 2026-07-13 13:23 passed for that cleanup: there are zero missing-text matches for `Planting Stave Credit` and zero Ji Firepaw `56660` TextGroup `7–10` warnings. One separate `5668600` duplicate-credit validator warning still mentions credit entry `56688`; it is not a missing-text/ScriptName regression and remains a distinct SmartAI-chain review item.
- Before that restart, gameplay of `29792` (`Bidden to Greatness`) exposed overlapping gates. At the Mandori event the dialogue and first objective completed and a rear door visibly opened, but an identical front door remained closed and blocked passage. DB inspection confirms permanent phased gates already exist at the exact event coordinates: Mandori entries `210965`/`211282` and Pei-Wu entries `210964`/`211283`. The C++ escort additionally summoned personal entries `211294` and `211298` at those same coordinates, creating the observed third overlapping layer and opening only the summoned copy.
- The preserved older SmartAI implementation identifies `210965` and `210964` as the intended objects to activate. Updated `zone_wandering_island_south.cpp` to find and open those existing visible doors instead of summoning duplicate `211294`/`211298` objects. At escort completion it returns the existing doors to `GO_STATE_READY` rather than deleting world spawns. The RelWithDebInfo build and final `worldserver.exe` link completed successfully at 2026-07-13 13:21. Runtime tests must verify timely passage through both Mandori and Pei-Wu gates and both quest credits; the old implementation eventually removed the apparent obstruction after a long delay, but it still blocked the player after the first objective had already completed.
- Runtime testing showed both credits and the NPC sequence worked, but the visible gates stayed closed until a later phase change made them disappear. Both permanent door spawns start in DB state `1`; the C++ event was setting `GO_STATE_ACTIVE` (`1`) again, so no state transition occurred. Corrected both opening actions to `GO_STATE_READY` (`0`) and changed escort cleanup to restore their original `GO_STATE_ACTIVE` state. This requires a rebuild and gameplay retest; the first gate should now move immediately when the first credit is awarded, while the second should open after its intended dialogue sequence.
- The next runtime test revealed that players can see both permanent phased copies at the same coordinates: one copy opens while the other remains closed and continues blocking passage. The paired templates use opposite initial/open-state orientation (`210965` with `211282`, and `210964` with `211283`). Updated the escort to retain and switch both copies together: the phase-2 doors open with `READY`, while the phase-2048/4096 doors open with `ACTIVE`; cleanup restores the inverse starting states. A rebuild and another gameplay test are required.
- Retesting still left one copy closed. The cause is that `FindNearestGameObject` applies phase visibility and therefore could not acquire the second phased object even though the client was receiving both copies through its combined phase mask. Replaced proximity lookup with direct lookup through the map spawn-ID store: Mandori GUIDs `540359`/`540346`, Pei-Wu GUIDs `540026`/`539997`. This bypasses phase filtering for the already loaded paired objects; rebuild and gameplay verification are still required.
- The following test exposed the controlling race rather than another gate spawn: the area trigger launched multiple personal escort groups for the same player (duplicate nearby Aysa and repeated Aysa dialogue were visible). Every Aysa instance controlled and later reset the same permanent gate pair, so one group could close/reset gates while another group was still running; the second-gate sequence could finish while the player remained blocked at Mandori. Added an early guard in `AreaTrigger_at_mandori` that does not summon another group while the player's existing Aysa (`59986`) is alive within 100 yards. Restart testing must begin from a clean process so old manual summons are gone.
- Direct GM testing identified the blocking Mandori copy unambiguously: `.gobject activate 540346` opened its two leaves correctly, while activating `540359` produced no visible change because that copy was already open. Updated the phased copies `540346` and `539997` to use the same real door path (`SetLootState(GO_READY)` plus `UseDoorOrButton`) with a 120-second safety window, rather than raw `SetGoState`. Escort cleanup now calls `ResetDoorOrButton` for the Mandori phased door. This change and the duplicate-escort guard must be built and tested together after a clean restart.
- Video/runtime observation still showed one overlapping copy animating while another closed model retained collision. To make passage deterministic despite the two legacy phased objects, the event now explicitly disables collision on both members of each gate pair at the exact opening step, while retaining the visible opening calls. Collision is restored together with the original states only at escort cleanup. No DB spawn is deleted. This is a global-object workaround and should later be replaced with fully player-personal gate objects if simultaneous multi-player execution must be isolated.
- Frame-by-frame inspection of the 46.23-second NVIDIA recording with FFmpeg corrected the state interpretation. The Mandori arch is visibly open on approach; at roughly 25–26 seconds the event call makes the red leaves descend/close, after which they remain closed through the end of the recording. Thus `.gobject activate 540346` only appeared to be the correct opening operation because it was executed after the script had already toggled that object closed. The actual open pair is the original DB-state combination: `540359`/`540026` in `GO_STATE_ACTIVE`, and `540346`/`539997` in `GO_STATE_READY`. Removed `UseDoorOrButton` from the event and now explicitly applies that open-state combination while disabling collision on both copies.
- A non-GM runtime `.debug phase` at the blocked first gate reported real player phaseMask `1`, proving that the symptom was not caused by GM all-phase visibility or a combined player mask. Live DB inspection then found the actual controller mismatch: summoned Aysa `59986` is `SmartAI` (not `npc_mandori_escort`), and its on-summon action creates entry `210965` directly on top of the permanent `210965` gate before timed list `5998600` ambiguously activates the nearest object with that same entry. The already-working Pei-Wu half uses dedicated personal entry `211298`; C++ historical intent likewise identifies `211294` as the personal Mandori gate. Added guarded update `2026_07_14_00_world_quest_29792_personal_mandori_gate.sql` to summon and activate `211294` instead, with a two-row backup in `sql/backup/world_smartai_quest_29792_mandori_gate_before_fix_20260714.sql`. No permanent gate spawn is deleted.
- Removed the later experimental C++ manipulation of fixed world spawn GUIDs and forced collision. `npc_mandori_escort` was restored to the first, minimal existing-door implementation because live Aysa `59986` does not use that CreatureScript at all. The area-trigger guard against a repeated personal NPC group remains. Quest `29792` gate ownership is now fixed in the actually active SmartAI SQL rather than duplicated across inactive C++ behavior.
- After the personal-entry SmartAI correction and a clean restart, the event copy opened but a permanent copy still remained closed. Earlier direct runtime testing had already isolated that blocker: `.gobject activate 540346` opened the remaining Mandori leaves, while its live DB spawn was stored at state `0`. The analogous Pei-Wu alternate-phase spawn `539997` had the same state. Added guarded update `2026_07_14_01_world_quest_29792_open_phase_gate_states.sql` to store the permanent alternate-phase gates `211282`/`211283` in open state `1`, with a reversible two-row backup. No spawn is deleted; personal SmartAI gates continue to animate the active quest scenario.
- The restart test disproved the preceding state interpretation: with the alternate copies changed to `1`, Mandori became manually clickable/openable and Pei-Wu remained closed after credit. Core `GOState` definitions confirm `GO_STATE_ACTIVE = 0` (open) and `GO_STATE_READY = 1` (closed). The player's post-credit phase report was `6145 = 1 + 2048 + 4096`, explaining why both permanent alternate copies become visible alongside short-lived personal gates at that moment. Added corrective update `2026_07_14_02_world_quest_29792_correct_open_gate_state.sql` to restore GUIDs `540346` and `539997` to open state `0`. The dedicated personal SmartAI entries `211294`/`211298` remain responsible for event animation.
- A temporary `GO_STATE_ACTIVE_ALTERNATIVE` runtime test on permanent Mandori GUID `540346` produced no visible change, while the closed second-gate copy disappeared with the temporary event object. Enabled the existing `scripts.ai` debug logger in the local runtime `worldserver.conf` for one diagnostic restart. The core already logs the exact runtime GUID and entry selected by every `SMART_ACTION_ACTIVATE_GOBJECT`; the next test will establish whether SmartAI activates personal `211294`/`211298` or another nearby copy before any further DB change.
- The diagnostic run proved both active SmartAI targets are correct: runtime GO entry `211294` was activated at Mandori and runtime GO entry `211298` at Pei-Wu. The remaining closed copy is therefore the permanent alternate-phase template, not a failed SmartAI target. Those templates `211282/211283` uniquely had `data0/startOpen=1`, while the working personal templates use `0`; this client-side flag reverses the visible interpretation of the same GO state. Added guarded update `2026_07_14_03_world_quest_29792_gate_template_startopen.sql` to set only those two templates to `data0=0`, with a reversible template backup. Spawns, phase masks and event gates are retained. Disabled the temporary `scripts.ai` debug logger after collecting the evidence.
- The next clean gameplay run exposed a separate Ji Firepaw controller conflict: entry `59988` said only "Let me try", jumped through the still-closed Mandori gate and disappeared instead of continuing to Pei-Wu. Live `creature_template` had both `AIName='SmartAI'` and `ScriptName='npc_ji_forest_escort'`. Entry `59988` already has the complete quest `29792` SmartAI dialogue, waypoint and gate sequence, while that C++ escort follows a different route and overrides SmartAI. Added guarded update `2026_07_14_04_world_quest_29792_restore_ji_smartai.sql` to clear only the conflicting ScriptName and retain SmartAI. The existing C++ class is left unchanged and unbound; it is not reassigned to `60900`, because that entry also already has its own complete SmartAI. A reversible row backup is stored in `sql/backup/world_creature_template_59988_before_smartai_fix_20260714.sql`. A full worldserver restart is required; no C++ rebuild is needed.
- With Ji restored to SmartAI, the full NPC sequence worked, conclusively separating the remaining obstruction from NPC logic. At both locations the dedicated personal scene gate animated correctly, while an overlapping permanent alternate-phase copy remained closed; Mandori's copy could be manually clicked and Pei-Wu's disappeared only after a short phase delay. Live rows showed base world gates `210965/210964` in phase `2`, legacy alternate copies `211282/211283` at the identical coordinates in phases `2048/4096`, and SmartAI explicitly summoning dedicated personal gates `211294/211298`. Added guarded update `2026_07_14_05_world_quest_29792_remove_legacy_phase_gate_duplicates.sql` to remove only legacy GUIDs `540346/539997`. The phase-2 base gates and all personal scenario gates are preserved. Exact restoration inserts are stored in `sql/backup/world_gameobject_quest_29792_legacy_phase_gates_before_fix_20260714.sql`.
- Removing the legacy alternate-phase pair did not change gameplay: Mandori still had one automatically animated copy plus one manually clickable copy, and Pei-Wu still retained a closed copy until the temporary object despawned. This proves the remaining overlap is the phase-2 base gates `210965/210964` plus SmartAI-summoned personal gates `211294/211298`, not the inactive `npc_mandori_escort` C++ AI. Added guarded update `2026_07_14_06_world_quest_29792_use_existing_gates.sql`: the two SmartAI summon actions become linked no-ops, while the existing activation actions target the permanent base gates. Thus each location has one physical gate, and the same NPC timing opens it. The C++ area trigger continues only to create the NPC scene. A reversible four-row SmartAI backup is stored in `sql/backup/world_smartai_quest_29792_personal_gates_before_single_gate_fix_20260714.sql`.
- Runtime disproved update `_06`: with personal summons disabled there were no visible gates and the NPC sequence stopped. `SMART_ACTION_NONE` did not continue the linked on-summon chain, while disappearance of the phase-2 base gates confirmed that aura removal correctly hides them during the scene. Added corrective update `2026_07_14_07_world_quest_29792_restore_personal_gate_chain.sql` to restore personal summons and their activation targets. Legacy alternate world spawns removed by `_05` remain absent. The intended final layout is therefore pre-quest phase-2 base gates outside the scene and exactly one personal gate at each location during quest `29792`.
- Runtime `.gobject near 10` finally identified the surviving copies without ambiguity. Before and during the Mandori scene it reported only permanent GUID `540359`/entry `210965`; after the Pei-Wu event it reported permanent GUID `540026`/entry `210964`. The automatically animated personal gates are runtime summons and are not listed by that command. Thus the apparent duplicates are stale pre-quest phase objects retained by the client after `AreaTrigger_at_mandori` removes auras `59073/59074`; Pei-Wu disappearing later matches a delayed visibility refresh. Added an immediate `player->UpdateObjectVisibility()` after both aura removals. This preserves required closed base gates before the quest and makes the client discard them as soon as the personal gate scene begins. C++ rebuild and a clean worldserver restart are required.
- The forced general visibility refresh produced no gameplay change. The current `npc_mandori_escort` C++ AI was audited as a possible full replacement, but it is not safe to enable: the live paths exist only in `waypoints`, its expected pause point does not match those SmartAI paths, and its custom end handler is not part of the current escort API callback. Replaced the ineffective refresh with targeted per-player `DestroyForPlayer` packets for permanent spawn GUIDs `540359` and `540026` immediately after the phase auras are removed. This does not delete either DB spawn or affect other players; it removes only their stale client copies/collision while the already-working SmartAI personal gates run the scene.
- Clean-restart gameplay also showed no visible change from the targeted `DestroyForPlayer` packets. Quest `29792` is nevertheless completable end to end: the NPC sequence and both credits work, Mandori passage requires manually opening the retained closed copy, and the Pei-Wu closed copy disappears after a short delay. Further gate work is deferred as a known visual/collision defect at the user's request. Do not enable the obsolete C++ escort or make more speculative spawn/phase changes. Preserve the current working SmartAI NPC chain and revisit only with a verified per-player GameObject visibility mechanism or matching Build 18414 source behavior.
- The first replay attempt exposed a separate `29790` defect before reaching the balloon: accepting `Passing Wisdom` spawned two Master Shang Xi copies and executed the dialogue twice. The cause is proven dual ownership of the same trigger. Creature `55672` is bound to C++ `npc_master_shang_xi_thousand_staff::OnQuestAccept`, which summons `56686` with player-specific visibility, while SmartAI row `55672`/source `0`/id `1` also summoned `56686` for quest `29790` without that personalization.
- Added and manually applied guarded update `2026_07_13_00_world_passing_wisdom_duplicate_summon.sql`. It removes only the duplicate SmartAI quest-accept summon when the exact expected row and C++ ScriptName binding both match; it does not delete creature `56686` or any of its dialogue, movement, staff-summon, or credit chain. The removed row was backed up to `sql/backup/world_passing_wisdom_smartai_before_duplicate_fix_20260713_1238.sql`, and direct verification reports zero remaining duplicate trigger rows. A restart and fresh `29790` acceptance are required to verify exactly one personal Master Shang Xi before returning to the `29791` parachute test.

### Fresh startup-log review after gameplay tests

- The current logs are from the 2026-07-13 11:02 startup: `Server.log` is about 55 KB and `DBErrors.log` about 905 KB. The worldserver completed startup; no fatal startup crash is present.
- Concrete high-confidence invalid references include SmartAI for missing creature entry `27754` and missing gameobject entry `96036`, quest starter/ender links to nonexistent quest `32592`, two `game_event_creature` GUIDs absent from `creature`, nonexistent spell links `203754`, `200002`, and `200003`, and several loot-template references whose owning creature/gameobject entry is absent.
- The large `waypoint_scripts` group reporting `SCRIPT_COMMAND_TALK` with `dataint = 0` must not be bulk-deleted. Each script must be reconstructed from an older trusted database or matching script/path evidence because deletion could remove movement-sequence behavior while merely silencing validation.
- `Server.log` also reports two LFG rows for Prince Sarsarun/map `734` without a matching area trigger and an unassigned `SMSG_READ_ITEM_RESULT_FAILED` opcode. These belong to separate LFG/client-protocol investigations and should not be patched speculatively.
- Next safe repair batch: compare the small set of missing SmartAI/object/quest references against the preserved pre-fix databases and create guarded forward SQL only where the intended source row or clear stale-reference provenance can be proven. Keep the active DB unchanged until that comparison is complete.
- Fresh startup review on 2026-07-15 completed in 67 seconds. `DBErrors.log` contains 7,647 lines, dominated by 5,724 pool warnings, 198 SmartAI duplicate-summon warnings and 231 duplicate-credit warnings; these large categories remain intentionally untouched. The small missing-reference set was compared table-by-table against `sql/base/world_548_20240722.sql` and `C:/Users/Admin/Downloads/world.sql`. Both dumps contain the same orphan references but lack quest `32592`, creature GUIDs `77232/136675`, and spells `203754/200002/200003`, proving these were not deleted by the recent repair work.
- Added guarded update `2026_07_15_00_world_remove_proven_orphan_references.sql` for exactly seven proven orphan rows: creature `69782` starter/ender links to missing quest `32592`, event `31` links to two absent creature spawns, and three `spell_linked_spell` rows containing nonexistent spells. Exact restoration inserts are stored in `sql/backup/world_orphan_references_before_20260715_00.sql`. Missing templates `27754` and `96036` and their SmartAI/conditions are not included because they may represent restorable missing content rather than safely removable references.
- Correction after a wider matching-version audit: the seven rows removed by `_00` were not proven orphans. Quest `32592` is genuine MoP content (`I Need a Champion`) and matching SkyFire 5.4.8 data contains its reputation objective. The same full 5.4.8 database contains creature spawns GUID `77232` (entry `22044`, map `530`) and GUID `136675` (entry `32923`, map `603`), so their event links can represent missing base spawn data rather than stale references. The three custom spell links were already documented as unresolved and two are referenced by local battleground code; absence from client SpellInfo alone did not justify deleting them.
- Added corrective forward update `2026_07_15_01_world_restore_unresolved_548_references.sql` and applied it to the active world database. It restores all seven references with `INSERT IGNORE`, preserving later data. Startup warnings for quest `32592` and event GUIDs are expected to remain until their complete source rows are translated from the matching 5.4.8 schema; they must not be silenced by deleting the references again.
- Revised rule for subsequent log work: a reference present in both preserved dumps is not an orphan merely because its target is missing there. Before deletion, also check a matching-version full content database and local C++ consumers. If matching 5.4.8 content exists, restore the missing target from a reviewed source-backed migration; otherwise leave the warning unresolved.
- Restored the two event-31 creature targets from exact matching SkyFire 5.4.8 rows with `2026_07_15_02_world_restore_event31_creature_spawns.sql`: GUID `77232` is Cavern Crawler entry `22044` on map `530`, and GUID `136675` is Dark Rune Commoner entry `32923` on map `603`. Source columns were mapped explicitly to the current schema, current-only columns received neutral defaults, and each insert refuses to overwrite a reused GUID. A restart/fresh-log check is required.
- Restart verification passed on 2026-07-15 at 12:30. World initialization completed in 60 seconds, and the fresh `DBErrors.log` contains no warnings for event creature GUIDs `77232` or `136675`. A direct check made with the Wampserver MySQL 5.7.44 client confirmed server `5.7.44`, two restored creature rows, and two matching event-31 links.
- Quest `32592` remains deliberately unresolved at the base-row level. The matching SFDB proves objective `270242` and local C++ includes `32592` in both legendary-cloak quest sequences, but that SFDB stores no `quest_template` INSERT data from which the current hotfix-style schema can be translated. Do not create an invented partial quest row merely to silence the warning; locate a Build-18414 quest hotfix/source row first.
- A wider quest-32592 source search checked the local project dumps/backups, SkyFire 5.4.8 SQL history, GitHub-indexed SQL results, the core's quest data-loading path, and public quest metadata. Public data confirms `I Need a Champion`, its Black Prince exalted-reputation objective, 250 Black Prince reputation reward, and turn-in event spell, but no complete Build-18414 row matching this project's 100+ column `quest_template` schema was found. `QuestV2.dbc` contains only the small client-side ID/type mapping and cannot reconstruct the missing server row. Therefore no SQL was applied for the quest; its two startup warnings remain preferable to a fabricated definition.
- Missing creature template `27754` was found in the matching SkyFire 5.4.8 base as the second `Drakkari Invader` variant (Build `15595`). Its three display IDs `27079`/`27080`/`27081` already exist in the active database, while four existing SmartAI rows and six Trollgore spell conditions explicitly reference entry `27754`. Added and manually applied guarded update `2026_07_15_03_world_restore_creature_template_27754.sql`, mapping the complete source row into the current schema and storing its models in `creature_template_model`. `AIName='SmartAI'` is used because this project already contains the entry's complete SmartAI controller. Direct MySQL 5.7.44 verification passed: exactly one template, three model links, four SmartAI rows and six conditions are present. A worldserver restart/fresh-log verification is still required.
- Missing gameobject template `96036` remains unresolved. Its SmartAI identifies it as `Shoeshine Seat` and calls timed list `9603600`, which stores the player, sends the target to creature `29703`, and sets data on that creature. The matching full 5.4.8 base contains the scripts but no complete `gameobject_template` row, so neither the template nor its references were invented or deleted.
- Restart verification on 2026-07-15 at 15:54 passed for creature `27754`: world initialization completed in 60 seconds and the fresh `DBErrors.log` contains zero matches for `27754`. The only remaining matches among this reviewed set are two unresolved quest `32592` starter/ender warnings and two numerically coincident `96036` warnings: one concerns pool spawn GUID `96036`, while the other concerns missing `gameobject_template` entry `96036`; these are different identifiers and must not be repaired as if they were one object.
- Detailed inspection of pool warning GUID `96036` shows that GUID itself is valid gameobject entry `176586` on map `0` and agrees with pool `12268`'s `map=0` description. The mixed-map member that actually corrupts pool `12268` is GUID `89526` (entry `1624`) on map `1`; the other three members are on map `0`. Both preserved pre-fix dumps contain this exact malformed four-member pool, proving it predates the current repair work.
- Pool `12268` is not an isolated safe one-row repair. Adjacent generated pools `12260` through `12272` also repeatedly mix map `0` and map `1` members despite a single-map description, matching the thousands of current pool warnings. Moving or removing only GUID `89526` would silence one warning but would not reconstruct its intended geographic pool and could change resource-spawn density. Leave this pool unchanged until the complete GO `2045` pool set can be regenerated by map and spatial grouping, or an authoritative matching-version pool dataset is found.
- The separate missing GO-template warning for `96036` was traced to a duplicated Shoeshine script, not missing content. The real `Shoeshine Seat` is template `194115`, spawn GUID `73279`, located beside Sheddle Glossgleam (`29703`) in Dalaran. It already has `SmartGameObjectAI` and the complete `194115`/`19411500` four-row chain. The invalid `96036`/`9603600` chain is column-for-column equivalent apart from its keys; active creature GUID `96036` is Sheddle himself, showing how the wrong identifier entered the GO SmartAI source. Added and manually applied guarded cleanup `2026_07_15_04_world_remove_duplicate_shoeshine_smartai.sql` with exact restoration backup `world_smartai_shoeshine_96036_before_cleanup_20260715.sql`. Direct MySQL 5.7.44 verification reports zero invalid controller/list rows while preserving one real template, one real spawn, one controller, its three-row timed list, and Sheddle's creature spawn. Restart/fresh-log verification is pending.
- Restart verification at 2026-07-15 16:18 passed for the Shoeshine cleanup. World initialization completed in 27 seconds; the fresh log contains zero missing-template SmartAI errors for entry `96036`, zero `9603600`/Shoeshine errors, and still zero `27754` errors. Exactly one textual `96036` match remains, the independently documented mixed-map `pool_gameobject` warning for GUID `96036` in pool `12268`; this expected remainder confirms the two numeric identities were kept separate.
- The next small validator group consists of three valid quest relations whose existing NPC templates lack only `UNIT_NPC_FLAG_QUESTGIVER` (`0x2`): Gothor Brumn `1362` starts quest `7062`, Ace Longpaw `58507` ends quest `31713`, and Lorewalker Cho `73136` ends quest `33138`. All three templates, quests, relations and world spawns exist. Added and manually applied guarded update `2026_07_15_05_world_fix_linked_questgiver_flags.sql`, which ORs only bit `2` while requiring each exact relation and current flag (`4224`, `1`, and `0`). Existing armorer/vendor/gossip flags are preserved. Exact pre-change flag values are stored in `world_creature_template_questgiver_flags_before_20260715.sql`. Direct MySQL 5.7.44 verification reports final flags `4226`, `3`, and `2`; restart/fresh-log verification is pending.
- Restart verification at 2026-07-15 16:48 passed for the questgiver flags. World initialization completed in 28 seconds and the fresh log contains zero `UNIT_NPC_FLAG_QUESTGIVER` warnings for entries `1362`, `58507`, or `73136`. Previous repairs also remain clean: zero matches for creature `27754`, Shoeshine, timed list `9603600`, or missing GO entry `96036`. The separate expected pool `12268` warning for spawn GUID `96036` remains unchanged.

## Current status summary (2026-07-16)

This section is the short authoritative status view. The dated investigation notes above preserve the full evidence and repair history; later dated conclusions supersede earlier provisional hypotheses.

### Completed and restart-verified

- Restored event-31 creature spawns GUID `77232` and `136675`; their missing-spawn warnings are gone.
- Restored creature template `27754` (Drakkari Invader), its three model links and existing SmartAI/condition ownership; the startup warning is gone.
- Removed only the proven duplicate Shoeshine SmartAI keys `96036`/`9603600` while preserving the real GO template `194115`, spawn GUID `73279`, Sheddle `29703`, and the working `194115` SmartAI chain; the missing-GO warning is gone.
- Added only the missing questgiver flag bit to NPC entries `1362`, `58507`, and `73136`; all three validator warnings are gone.
- Restored the eleven battle-pet source creatures from the pre-cleanup backup and repaired the verified SmartAI pseudo-no-op chains. Startup verification passed; the `48119` and `48121` cast-to-dialogue behavior was confirmed in game.
- Quest `29790` no longer creates duplicate Master Shang Xi copies. Quest `29791` now follows the full balloon route, reaches shore, grants a parachute and completes without fatal fall or ocean-fatigue damage; this was verified in game.

### Working but not fully corrected

- Quest `29792` (`Bidden to Greatness`) is completable and both quest credits/NPC sequence work, but its gate presentation and collision are still imperfect. At Mandori Village a retained gate copy may need a manual click; at Pei-Wu a closed copy can remain briefly before disappearing. Further speculative SmartAI, phase, spawn, or obsolete C++ escort changes are deferred until a verified Build-18414 per-player GameObject visibility solution or matching source behavior is available.
- The normal in-game replacement behavior of every restored wild battle-pet source has not been exhaustively checked even though the startup validation and stored coordinates passed.
- Logout/cinematic packet behavior has matching-version source support and no current log failure, but the listed gameplay cases remain untested.

### Deliberately unresolved; do not silence by deleting data

- Quest `32592` is genuine MoP content and is referenced by local legendary-cloak code, but a complete compatible Build-18414 `quest_template` source row has not been found. Keep its starter/ender warnings until an authoritative row is available.
- Pool `12268` and the broader generated gathering-pool set mix maps. Spawn GUID `96036` is valid; GUID `89526` is the mismatched member in this pool. Do not delete or move a single member merely to remove one warning; the pool category needs an authoritative dataset or complete regeneration by map and spatial grouping.
- Large `waypoint_scripts`, SmartAI duplicate-effect, pool, loot, PvP `ExtendedCost`, and similar validator groups must be repaired only from matching-version evidence, not removed or zeroed in bulk.

### Latest log/database consistency check

- The newest available `DBErrors.log` is still the startup log from `2026-07-15 16:48:40`; it is not a fresh 2026-07-16 run.
- A direct active-database check with Wampserver MySQL `5.7.44` on 2026-07-16 found creature templates `60491` and `62346` present with their own loot IDs, and GameObject templates `218197`, `218577`, `220196`, and `221776` present with their own loot IDs. The active `conditions` table currently has no rows referencing `35431` or `35433` in the checked source/value fields.
- Therefore the corresponding warnings in the 2026-07-15 log are stale relative to the current database. Do not restore, delete, or rewrite these rows again from that old log.
- Required next action: perform one clean worldserver restart, confirm a new log timestamp, then select the next small repair only from warnings that still occur in that fresh log. Back up the exact affected rows before every database change.
- Clean restart verification completed on 2026-07-16 at 09:35. `Server.log` reports `World initialized in 1 minutes 1 seconds`; the completed `DBErrors.log` contains 7,631 lines. Previously verified repairs remain clean: zero matches for `27754`, Shoeshine, `9603600`, and `UNIT_NPC_FLAG_QUESTGIVER`.
- This fresh restart corrects the provisional pre-restart interpretation above. Warnings for creature loot IDs `60491`/`62346`, GameObject loot IDs `218197`/`218577`/`220196`/`221776`, and condition SourceGroups `35431`/`35433` still occur. Direct MySQL 5.7.44 inspection shows that the six owner templates exist and point to those loot IDs, but the corresponding `creature_loot_template`/`gameobject_loot_template` rows are absent. The two condition rows also exist with source type `18`, SourceGroups `35431`/`35433`, SourceEntry spell `66245`; the earlier zero-row statement did not account correctly for their SourceGroup role.
- Sha of Anger `60491` and Galleon `62346` already have complete personal-loot ownership: `personal_loot_template` rows plus 130 and 46 `personal_loot_item` rows respectively, as well as their bonus-roll definitions. A historical 2022 SQL file that duplicates these items into ordinary corpse loot is not considered trustworthy: it assigns a uniform chance and includes suspicious truncated/low item IDs. Do not import it. Do not clear either creature `lootid` until a matching Build-18414 source proves that this is the intended configuration.
- No database change was made from this restart review. The four unnamed GameObject loot sets remain unresolved until exact matching loot rows are found. The `35431`/`35433` condition pair is an orphan candidate because no corresponding creature templates, spawns, or active `npc_spellclick_spells` rows exist, but it must not be deleted merely to silence validation; first establish whether matching 5.4.8 content requires restoration or confirms the historical cleanup.
- The next small missing-reference group was resolved from the matching SkyFire 5.4.8 SFDB full release 24.001 rather than deleted. Eight spell conditions referenced four missing Build-15595 difficulty templates: `31317` Lava Blaze (1), `33906` Focused Eyebeam (1), `33909` Kologarn (1), and `40684` Living Ember (1). SFDB also proves their parent links `30643 -> 31317`, `33632 -> 33906`, `32930 -> 33909`, and `40683 -> 40684`.
- Added and manually applied guarded update `2026_07_16_00_world_restore_missing_difficulty_creature_templates.sql`. It inserts only absent child templates, adds the five verified display models `2172`, `11686`, `1126`, `28638`, and `1070`, and restores each parent `difficulty_entry_1` only from zero after its child exists. A full transaction test was first executed with `ROLLBACK`; it passed without retaining changes. Direct post-apply MySQL 5.7.44 verification reports all four child rows, all five model links, and all four parent links with Build `15595`.
- Pre-change backups are `world_creature_template_difficulty_links_before_20260716.sql`, `world_creature_template_model_difficulty_before_20260716.sql`, and `world_conditions_difficulty_templates_before_20260716.sql`. No rows were deleted. A clean worldserver restart is required to confirm that all eight `ObjectEntryGuid condition has non existing creature template` warnings disappear.

## Recommended Order

1. Preserve and import the original pre-fix database into a separate read-only comparison schema.
2. Restore and test the deleted battle-pet sources now that the core has coordinate fallback handling.
3. Replace the Action `22` pseudo-no-op only after reconstructing and testing each complete SmartAI chain.
4. Verify the Build 18414 logout packet layout before retaining or replacing the empty payload.
5. Instrument and reproduce the normal-runtime GameObject owner lifecycle error; keep shutdown recovery separate.
6. Rotate/clear only the current log files and restart once to get clean per-run counts.
7. Fix `script_waypoint` only where matching C++ scripts already exist or can be ported cleanly.
8. Fix remaining SmartAI text/spell/action warnings by grouping by entry and quest.
9. Fix pool data by pool id and map, starting with empty pools and multi-map parent pools.
10. Fix PvP vendor `ExtendedCost` only after mapping old ids to valid 5.4.8 costs.
11. Re-test Dalaran/Pandaria `creature_text` gaps after each fallback SQL; only add more rows if the server reports a new entry or specific missing `TextGroup`.
12. Fix quest objective and loot-template gaps only from a trusted source, because the local SkyFire 2024 dump is not enough for those rows.

## Verification

After each batch:

1. Apply one SQL/code batch only.
2. Restart worldserver.
3. Compare a fresh `DBErrors.log` category count.
4. In-game test at least one affected quest/vendor/spawn group before moving to the next batch.
