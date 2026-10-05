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
