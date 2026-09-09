# Shared Affliction rotation — 2026-09-09

Group PvE Affliction bots now use the same live snapshot, priority selector and
checked spell path as the player's CombatAssistant. Previously they waited for
DoTs/Haunt to disappear, had no Soulburn/Soul Swap damage sequence or shard
reserve, and could start a second Haunt before the first projectile landed.
Natarea's September 9 Sha log shows the second Haunt starting at 16:44:08.400,
before the first aura appeared at 16:44:09.412.

The shared selector provides owned DoT/Pandemic refreshes, cast/travel-aware
Haunt timing, last-shard reservation outside burst/execute, learned Soulburn
overrides, up to three-target DoT maintenance, safe four-target Seed, glyph-aware
Life Tap, and Malefic Grasp/Drain Soul channel tick preservation. Bots use their
AI's current target explicitly; the adapter does not change selection to apply
secondary DoTs. Actual spells remain untriggered and check resources, GCD,
cooldown, movement, range and line of sight.

`AfflictionRotationAction` runs at ordinary damage priority and checks again
after 100 ms, allowing the existing engine to revisit active damage channels.
A mode-dependent multiplier suppresses competing legacy warlock ST/AoE/resource
actions, including actions already queued before entry to group PvE. Existing
movement, encounter avoidance, pet control and coordinated interrupts retain
their priorities. The shared selector handles damage and personal survival;
it does not give the bot a new automatic resurrection target.

Each action owns its projectile/damage runtime. Bot worker threads do not use
the player's addon state map. Pending Haunt timers age by elapsed milliseconds,
including gaps between action executions. The shared cast boundary checks bot
pull authorization, protected group members, breakable CC and area safety after
resolving Soulburn overrides, during probes and again before actual casts.
Dungeon, raid and Caller world-boss bots are covered. Other specs, solo bot
rotations and PvP remain on their existing paths. The player's priority rules
are unchanged; talents/glyphs still come from each character's own learned spells
and active auras.

## Verification

From an x64 Visual Studio Developer PowerShell:

```powershell
./contrib/combat_assistant_548/test_affliction.ps1
./contrib/combat_assistant_548/test_affliction_bot.ps1
./contrib/playerbot_auto_queue_548/test_pve_rotation.ps1
```

The priority suite covers 134 cases. The bot suite compiles current production
cast/adapter/multiplier bodies against controlled engine mocks and covers
runtime isolation, projectile timers, normal casts, Soulburn overrides, failed
channel replacement, mode changes and final target/pull/area guards. It does not
mock the full live snapshot or simulate the server scheduler. The existing PvE
suite covers 1028 profile/rotation conditions. A complete RelWithDebInfo x64
worldserver build also passes.

Live acceptance remains a new single-target and gathered-pack combat log after
starting the updated server. Verify Haunt is not duplicated in flight, DoTs stay
active, Soulburn/Soul Swap appear, and channel ticks/Seed follow their conditions.
These checks do not establish DPS equality with Grotroz: gear, learned abilities,
target uptime and encounter movement still differ.
