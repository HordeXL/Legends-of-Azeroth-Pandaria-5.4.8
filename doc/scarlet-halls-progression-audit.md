# Scarlet Halls NPC progression audit — 2026-10-03

The reported encounter is Houndmaster Braun. The live world database has 255
static creature rows on map 1001. The exit formation consists of ten Scarlet
Guardians (59299, GUIDs 538029–538038) and Sergeant Verdone (59302, GUID 538028),
at approximately (1038, 510, 13.5), immediately beyond Braun. These NPCs are
present before the boss fight; they are not a pack meant to appear afterward.
The six Obedient Hounds (59309) clear this formation during the boss outro.

The guardians have aura 127352, **Phalanx Defense**, in `creature_template_addon`.
The installed 5.4.8 `Spell.dbc` and `SpellEffect.dbc` identify its effect as aura
87 with base points -95: a 95% damage reduction. This protection was retained.
The expected dog/guard sequence is also described in the
[Houndmaster Braun encounter account](https://warcraft.wiki.gg/wiki/Houndmaster_Braun).

## Placement and timing

| Area / NPCs | Expected timing | Audit result |
| --- | --- | --- |
| Entrance Hooded Crusader, 6 food buckets, 5 watchmen, 25 starving and 18 angry hounds | Available on initial dungeon load | Static rows and matching scripts reviewed; no boss-death spawn gate |
| 3 reinforced archery targets, 8 master archers, Commander Lindon | Initial archery encounter before Braun | Lindon's separate encounter and door state now survive save/load |
| Braun and 6 Obedient Hounds | Boss present initially; one unused live dog activates at each 90/80/70/60% threshold | Threshold code previously incremented a counter without activating any dog; activation restored |
| 10 Scarlet Guardians and Sergeant Verdone | Stand at the exit before Braun; die to the dogs after Braun | Dog movement now clears combat and threat first; completed instances remove these actors on later grid loads |
| Myrmidons, Scourge Hewers, Evangelists, Evokers, normal Defenders and cannon actors between Braun and Harlan | Preplaced trash beyond the progression gate | No boss-death spawning or damage gate found in their C++ scripts |
| Harlan's Scarlet Defenders (58998) | Summoned during combat, first at 10–11 seconds and then every 20–25 seconds | No static rows for this summon entry; distinct from normal Scarlet Defenders (58676) |
| Hall Guardians, Treasurers, Scholars and Pupils | Preplaced armory/library trash | No need to hide these until a boss dies |
| Library Hooded Crusader (64738, GUID 538235) | Hidden until Koegler dies | Visibility now belongs to instance creation/state callbacks, independent of boss/NPC load order |
| Book cases, books, stakes and invisible helpers | Encounter scenery or spell targets | Not treated as additional combat packs |

This is a source/database audit, not a claim that every coordinate or patrol was
verified against a retail capture. The quest NPC's entrance and library spawns
remain distinct. No spawn positions or database rows were changed.

## Corrected failure paths

- Braun's dogs previously received `MovePoint` while retaining their combat
  state. Their passive `UpdateVictim` can enter evade when the threat list empties,
  replacing the move to the guards with a return home. The outro now stops combat,
  clears threat, restores passive/non-attackable behavior, and runs to the exit.
- Threshold checks account for the incoming hit; lethal damage cannot bypass the
  scripted outro. Dead or already activated dogs are not selected. Wipes reset
  surviving dogs and respawn dead encounter dogs.
- Completed Braun saves remove late-loaded gate guards/hounds, preventing the
  old formation from reappearing on a grid reload or server restart.
- Lindon used boss index 4 while the instance has only three bosses. He now uses
  a separate saved event state. His gate requires his defeat, closes during Braun,
  and reopens after a Braun wipe/death. Three-boss legacy saves remain readable;
  Braun completion or a loaded Lindon corpse recovers the old miniboss completion.
- The save reader now reads exactly three boss states and initializes/validates
  input. It previously attempted a fourth extraction from a three-state save.
- Koegler no longer unconditionally hides the library quest NPC when his own AI
  initializes. The instance sets visibility on NPC creation and boss transitions.

## Validation and deployment

`contrib/scarlet_halls_548/test_progression.ps1` compiles callbacks extracted from
the production sources against small engine doubles. It covers fresh/completed
NPC creation, legacy/new saves, invalid states, Lindon/Braun gate transitions,
dog selection and thresholds, lethal hits, combat cleanup, and the guard-killing
movement callback. It does not simulate map pathfinding or a full client fight.

The scripts and RelWithDebInfo worldserver compiled successfully. After the
previous server process stopped, the new executable/PDB were installed with
checksum verification. The previous pair is backed up under
`Build/server-before-scarlet-halls-20261003-114504`.

A startup check of the installed executable, bound to localhost port 18086 with
separate logs, validated 4,525 spell scripts and reached `World initialized` in
24 seconds. `Build/scarlet-halls-smoke/DBErrors.log` remained empty. The check
was shut down normally using `server shutdown 0` and exited with code 0. The
server is left stopped, ready for a normal launch with its regular configuration.

For a later reinstall, `contrib/scarlet_halls_548/install_staged_server.ps1`
backs up the executable/PDB and verifies copied checksums; it refuses to install
over a running worldserver.

In-game follow-up: use a fresh instance to test Lindon, a Braun wipe, four dog
activations, and the outro. The exit formation should die automatically when
the surviving dogs arrive. Reload an already completed Braun instance to check
that the formation stays gone; kill Koegler to check the library quest NPC.

## Dog Food follow-up

The player's October 3 combat log shows four Starving Hounds casting 122929
(`Dog Leap Boss`) at Vigilant Watchman at 11:27:06.926. No hound damage follows;
the player attacks the same surviving watchman at 11:30:27. This confirms that
the bucket hit callback ran, but the intended attack sequence did not.

Local `SpellEffect.dbc` identifies 111894 (Dog Food) as a dummy effect, not an
aura. The old hound AI polled `HasAura(111894)` and therefore never entered its
attack branch. The spell callback only stopped a movement spline and cast a
leap; it neither replaced the patrol generator nor selected a melee target.

The hit callback now passes the exact watchman's GUID to nearby living hounds.
The hound clears its old combat/threat/patrol state, uses faction 1665 (friendly
to players and explicitly hostile to the watchman's monster faction 14), and
starts attacking that watchman. It resumes chasing after the leap and keeps the
food target instead of selecting an old player/pet threat target. The watchman's
patrol is also replaced with idle movement. When the watchman dies or disappears,
the hounds leave combat, become neutral/friendly (35), and sleep in place.
Reset restores their original faction, standing state and normal combat AI.

Regression coverage executes the production hit callback and complete hound AI
against engine doubles: the bucket-to-attack-to-sleep sequence, old threat,
repeat hits, missing/dead/wrong targets, reset and target filtering. It also
checks the actual installed faction DBC for player friendliness and NPC hostility;
two neutral NPC factions cannot normally attack one another in this core.
Full client combat/pathfinding still needs an in-game retest.

The follow-up build was installed with executable/PDB checksum verification;
its predecessor is in `Build/server-before-scarlet-halls-20261003-120108`.
The installed build's separate startup check reached `World initialized` in
23 seconds with zero `DBErrors.log` bytes and shut down normally. Logs are in
`Build/scarlet-halls-dog-food-smoke`.

## LFG druid stuck at entrance (2026-10-05)

The observed party assigned Finarie (499) Guardian/tank and Baldro (411)
Balance/damage. Baldro's saved aura included Bear Form (5487); the staging log
confirmed his switch to specialization 102. He repeatedly attempted Moonkin
Form without following the requester. A short debug trace captured repeated
`Baldro cast: moonkin form` without the corresponding spell preparation.

The shipped spell 24858 has attributes 0x50010, including
`SPELL_ATTR0_NOT_SHAPESHIFT`. The combat strategy supplies a caster-form
prerequisite, but direct LFG preparation and the non-combat action do not.
Moonkin's action now removes the prior shapeshift aura before casting, without
depending on the old specialization's learned spell list or a mana threshold.
Playerbot casting also preserves `prepare()`'s strict failure result: a later
`CheckCast(false)` previously skipped the form check and falsely reported
success, allowing the same high-priority failed action to starve following.

`contrib/playerbot_auto_queue_548/test_druid_form.ps1` executes the production
action and cast-result block with narrow doubles. It covers Bear/Cat/caster
transitions, insufficient mana, preserving an existing Moonkin form, and strict
cast failure propagation. The previous inherited action fails the negative
control. A rate-limited LFG form diagnostic records unresolved mismatches
without enabling global debug logging. Live group retesting remains pending.

During diagnosis, `server set loglevel l root 2` exposed a separate server
crash at 15:05:32: `Condition::ToString` streamed a null source name for terrain
swap source type 29. The source-name table stopped at 26; sparse condition
names were also unguarded. The table now includes source types 27–30, and both
lookups guard missing names and invalid indexes. This was a worldserver crash,
distinct from the previously resolved client exit crash. Evidence is preserved
in `Build/condition-log-crash-20261005`.

`contrib/condition_logging_548/test.ps1` runs the actual production tables,
enums and formatter across every source/condition index, including sparse
custom conditions and invalid indexes. The original source fails on a missing
name. The fixed game target and staged x64 server build passed; the first
installed build initialized in 23 seconds, produced an empty DBErrors log,
and shut down cleanly.

The final build, including the druid changes, was installed with backup
`Build/server-before-logout-response-20261005-151547`. Its isolated smoke run
in `Build/druid-form-smoke` enabled only the `condition` debug logger. It
initialized in 23 seconds, logged more than 30,000 terrain-swap source-29
descriptions (including the original entry 1066) without crashing, and kept
DBErrors.log empty. Normal configuration retains `Logger.root=5`.

## Fed hound return movement (2026-10-05)

At the user's request, each Starving Hound now remembers its own position and
orientation when Dog Food selects the watchman. After the watchman dies or
disappears, the hound clears combat and threat, becomes friendly/passive and
pacified, then takes a path back to that saved patrol position. It sleeps only
on the matching point-arrival callback and restores its original facing.
It does not resume continuous patrol. Late leap callbacks and arrival callbacks
after an AI reset cannot put the wrong state to sleep.

The return uses point movement, not evade/home movement, to avoid resetting
the fed state and restoring hostility. Regression coverage executes the actual
AI and verifies the destination, standing during travel, arrival-only sleep,
duplicate feeding, missing targets and reset/callback ordering. All existing
Scarlet Halls progression and installed-faction checks also pass.

The [Wowhead dungeon guide](https://www.wowhead.com/mop-classic/guide/dungeon/scarlet-halls-heroic-boss-strategy-loot)
supports attacking the watchman and then sleeping, but does not establish an
original return route. Returning to the pre-attack position is the requested
behavior, not a claim of a verified retail waypoint sequence.

The x64 scripts/server build was installed with backup
`Build/server-before-logout-response-20261005-152019`. In-game pathfinding still
requires a retest with a fresh group of unfed hounds.
The isolated smoke run in `Build/hound-return-smoke` initialized in 23 seconds,
kept DBErrors.log empty and shut down cleanly.

## Sleeping pose and Zzz visual (2026-10-05)

The user's Wowhead screenshot shows prone hounds with green Zzz effects.
Stand state alone did not request a cosmetic spell visual. On return-point
arrival the AI now keeps `UNIT_STAND_STATE_SLEEP`, casts Sleeping Dog (113114)
for the dog animation and Cosmetic - Sleep Zzz (55474) for the head effect.
Reset removes both auras before restoring the standing/hostile state.

The installed 5.4.8 data distinguishes these effects: spell 113114 uses visual
23098, persistent kit 23126 and animation kit 1974, with no head effect; spell
55474 uses visual 12147, persistent kit 11223 and head effect 4742, whose model
is `Spells\Sleep_State_Head.mdx`. Both spells are self-targeted dummy auras with
unlimited duration. Field interpretation follows the 5.0.1–5.4.8 layout in
[WoWDBDefs SpellVisualKit](https://github.com/wowdev/WoWDBDefs/blob/master/definitions/SpellVisualKit.dbd).

The production-AI regression verifies that neither cosmetic is applied during
return movement, both appear on arrival, duplicate arrival notifications do
not repeat the animation cast, and reset removes both. The screenshot does not
establish original patrol coordinates, so the previously requested per-hound
return position is retained. Actual rendering still needs client verification.

The x64 build was installed with backup
`Build/server-before-logout-response-20261005-152621`.
Its isolated smoke run in `Build/hound-sleep-visual-smoke` initialized in
23 seconds, produced an empty DBErrors.log and shut down normally.

## Eaten watchman's blood pool (2026-10-05)

When a feeding hound kills its selected Vigilant Watchman, `KilledUnit` creates
one stationary invisible world trigger at the watchman's death coordinates and
applies cosmetic Blood Pool (146012). Only the killing hound does this; other
pack members merely finish feeding and return. Normal kills, living targets,
unrelated victims and missing targets do not create pools. The killing hound
then clears its food target, preventing duplicate callbacks from creating more.

The installed data resolves spell 146012 to visual 33170, persistent visual kit
35889, model attachment 22965 and effect 17156:
`spells\sloppy_blood_pool_nofade.mdx`. Its only effect is a self-targeted dummy
aura, with no damage, stun or feign-death behavior. It cannot target a dead unit,
so the visual lives on a friendly passive trigger instead of the corpse. The
trigger expires after the watchman's configured corpse delay (minimum one
second), and therefore cannot leave a permanent cosmetic actor behind.

Production-AI regression checks cover the single pool, death position, lifetime,
alive/unrelated target exclusions, duplicate callbacks and missing targets,
alongside the existing return/sleep and dungeon progression checks. The scripts
and x64 server build pass. Installed backup:
`Build/server-before-logout-response-20261005-153156`. Client rendering and the
exact size/appearance compared with the screenshot still require an in-game
check; this is an implementation using a verified cosmetic model, not evidence
of the original encounter's exact spell ID.
The isolated smoke run in `Build/hound-blood-pool-smoke` initialized in
24 seconds, kept DBErrors.log empty and shut down normally.

## Reinforced Archery Target pickup (2026-10-05)

The user could select the glowing targets but could not pick them up. Entry
59163 had no `npc_spellclick_spells` row. Although the AI enabled SPELLCLICK,
`Player::CanSeeSpellClickOn` hid it from the client when the lookup was empty,
just as with the previously fixed food buckets.

Migration `2026_10_05_00_world_scarlet_halls_archery_spellclick.sql` adds Heroic
Defense (113436). The target casts it on the clicking player. Cast flags 6
preserve the target as the aura caster: the empty owner GUID of these static
NPCs falls back to the actual caster in `Spell::Spell`. Flags 2 would instead
attribute the aura to the player, preventing `HandleAuraControlVehicle` from
boarding the target because caster and vehicle owner would be the same unit.
Preserving the NPC caster also keeps the existing aura-removal despawn working.

The installed DBC defines 113399 as SET_VEHICLE_ID 2037 and 113436 effect 0 as
CONTROL_VEHICLE, seat amount 1. The target already supplies 113399 through its
500 ms periodic override aura. Click conditions require this carrying aura and
exclude players who already carry a shield. The AI now acknowledges the
database cast only if this target's own Heroic Defense aura exists on the
clicker. It no longer casts twice or consumes a target after a failed cast.

The production visibility/AI regression reproduces the missing-row failure,
checks condition-based visibility, failed and foreign-caster pickup attempts,
single successful pickup, duplicate callbacks and reset. Existing dungeon and
dog-food regressions also pass, as does the x64 build. The migration was applied
twice to verify idempotence. Pre-change DB rows are saved in
`Build/archery-target-db-before-20261005.tsv`; installed binary backup is
`Build/server-before-logout-response-20261005-155316`.
Actual carrying visuals and arrow interception still require an in-game test.
The isolated smoke run in `Build/archery-target-smoke` initialized in 23 seconds, kept DBErrors.log empty and shut down cleanly (exit 0).

## Archery target remains unclickable after approaching (2026-10-06)

The follow-up client report exposed a missing update after the spellclick row
was installed. The live database still contains the expected 113436 binding,
cast flags 6 and both aura conditions. At initial creature visibility, the
player is normally outside the 113399 proximity aura, so
`Unit::BuildValuesUpdate` strips SPELLCLICK using `Player::CanSeeSpellClickOn`.
Receiving that aura later only changes the player; it does not dirty the target's
`UNIT_FIELD_NPC_FLAGS`. Consequently the client keeps its original non-clickable
value while the cosmetic sparkle remains visible.

The target's 500 ms proximity callback now marks its NPC flags for a values
update after casting 113399. The existing serialization re-evaluates both aura
conditions for each recipient. It also handles expiry, approaching again and
players already carrying another target, without restoring the flag on a
consumed target. The callback prevents the default periodic action because it
already casts the configured trigger itself; it now casts once per tick.
No spellclick conditions, spell validation or diagnostics are removed.

The regression executes the production periodic callback and visibility
predicate with engine doubles, including cached client visibility outside and
inside the radius. Substituting the previous production callback fails at
`player.vehicleAura && player.clientCanClick`; the fixed callback passes.
The complete Scarlet Halls progression, dog-food and archery suite passes,
as does the Win64 RelWithDebInfo scripts build and staged worldserver link.
Actual client attachment, carrying movement and arrow interception still need
an in-game check after installing the new executable.

## Rank and File kill credit (2026-10-06)

Both quest versions, 31490 and 31495, require 50 monster credits for proxy
64964. The installed Scarlet Halls combat templates had both KillCredit fields
empty, and no instance hook, SmartAI action or client credit spell awarded the
proxy. Killing crusaders therefore left the objective at zero.

Migration `2026_10_06_00_world_scarlet_halls_rank_and_file.sql` fills the empty
primary credit for 19 hostile crusader templates, including the three bosses,
Vigilant Watchmen, Master Archers, summoned Scarlet Cannoneers and Harlan's
summoned defenders. Dogs, cannon triggers, friendly unused defender templates,
archery targets and the Hooded Crusader are excluded. These combatants share
their base templates between Normal and Heroic; the installed spawn masks
include 87 eligible static spawns in each difficulty, plus the summoned types.

The existing `KillRewarder::RewardKillCredit` -> `Player::KilledMonster` path
awards the proxy through normal solo/group reward rules. `KilledMonsterCredit`
matches either active quest's objective and caps progress at its required 50.
No player quest counters, completed kills, objectives or automatic completion
rules are changed. Progress starts with eligible kills after the template reload.

Deployment validation compared every field of all 19 templates before/after:
only `KillCredit1` changed, from 0 to 64964. Applying the migration a second time
changed zero rows. The complete template snapshots and a guarded rollback are
saved in `Build/rank-and-file-fix-20261006`. Existing servers can activate it
without a binary replacement by running:

```text
reload creature_template 58632 58676 58683 58684 58685 58756 58898 58998 59150 59175 59191 59240 59241 59293 59299 59302 59303 59372 59373
```

Prefix the command with a dot when entering it in the game chat. Verify an
eligible crusader increments the active quest, a hound does not, and progress
stops at 50 before turning the quest in to the Hooded Crusader.

## Remaining accepted quests and instance eligibility (2026-10-06)

Grotroz (2215) has all four Scarlet Halls quests active and incomplete: 31490,
31493, 31495 and 31497. Their four saved objective counters are zero. The two
Rank and File versions share the corrected 64964 kill credit. The two Just for
Safekeeping, Of Course versions require different items:

| Quest | Objective | Source after correction |
| --- | --- | --- |
| 31493, level 31 | Codex of the Crusade 87267, quantity 1 | Koegler, Normal or Heroic |
| 31497, level 90 Heroic | Codex of the Crusade 87268, quantity 1 | Koegler, Heroic |

The normal Codex was restricted to Normal, preventing completion of the accepted
lower-level quest during a Heroic run. Normal dungeon quests can also be
completed on Heroic, as documented in the
[Scarlet Halls quest guide](https://www.wowhead.com/mop-classic/guide/dungeon/scarlet-halls-heroic-boss-strategy-loot#quests-in-scarlet-halls).
Migration `2026_10_06_01_world_scarlet_halls_codex_quest.sql` adds Heroic only to
item 87267's existing loot row. Item 87268 retains its Heroic restriction.

Both rows retain -100 quest-only chance, quantity 1 and group 0. Both item
templates exist, have PARTY_LOOT set and no custom quest-status bypass. The
native loot eligibility check requires an outstanding objective for the item,
and another group member looting it does not consume the player's copy. All
four quest starter/ender relations point to questgiver 64738. The entrance
spawn is visible immediately; the library spawn is shown after Koegler's DONE
state, including when its grid loads late. Existing progression regressions
cover these visibility transitions. Quest reward texts and both item-request
texts exist; none of these four templates references a missing item reward.

Deployment comparison of every Koegler loot field confirmed that only the
normal Codex's mode changed. A second application changed zero rows. Snapshots
and rollback are in `Build/scarlet-halls-quest-audit-20261006`. No character
quest progress or inventory was edited. Actual quest turn-in still requires
the player's dungeon run and looting Koegler.

At the same check, WorldServer was stopped and Grotroz was offline on map 870
with instance_id 0. There were zero personal Scarlet Halls binds, zero matching
group binds, zero saved map-1001 instances and zero active hourly instance
entries on the account. No lockout deletion was needed. Starting the server
loads the updated loot data and allows a fresh Scarlet Halls run.

## Completed Heroic run audit (2026-10-06)

After the player's run, all four quests (31490, 31493, 31495, 31497) are in
`character_queststatus_rewarded`, with no remaining active objective rows.
Achievements 7413 (Scarlet Halls) and 6760 (Heroic: Scarlet Halls) were earned
at 16:02:27 local server time. The Heroic instance save contains
`S H 3 3 3 3`: all three bosses and Commander Lindon are DONE. The current
server log records successful recruitment and cleanup of all four LFG bots.
DBErrors.log is empty and the current Server.log contains no recorded errors.
These records confirm quest turn-in and completion rewards, but do not record
every combat mechanic, client visual or individual equipment loot result.

The separate completed-encounter mask was only 1. The installed
DungeonEncounter.dbc assigns bit 2 to Braun (1422), bit 1 to Harlan (1421) and
bit 0 to Koegler (1420), so all three kills should produce 7. Both Normal and
Heroic lacked the Braun and Harlan rows in `instance_encounters`; only Koegler
was registered. `KillRewarder::Reward` calls `UpdateEncounterState`, which
matches these rows independently of the script's boss DONE states.

Migration `2026_10_06_02_world_scarlet_halls_encounter_credit.sql` supplies the
four missing kill-credit rows. Koegler remains the only final encounter, with
LFG dungeon IDs 163 (Normal) and 473 (Heroic). Verification compares the rows
against the installed DBC and creature templates, checks mask 7 and one final
encounter per difficulty, and reapplies the migration to check idempotence.
The full table snapshots and guarded rollback are stored in
`Build/scarlet-halls-run-audit-20261006`.

Encounter definitions load at server startup and have no reload command in
this core. The database fix therefore takes effect for subsequent kills after
the next WorldServer restart. The currently running instance's saved mask is
left intact; the migration does not rewrite historical character progress.
