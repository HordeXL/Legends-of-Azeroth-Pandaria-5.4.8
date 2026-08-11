# Playerbot auto-queue patches for MoP 5.4.8

Status: experimental. The active source contains the staged Solo Arena series
through `0023`; `0002` and `0003` remain intentionally unapplied. Runtime work has
already verified the earlier staged login, grouping, queue, entry, combat, exit,
health, protected temporary loadout, and recovery paths. Patch `0021` provides the
Arena Battlemaster 2v2/3v3/5v5 frontend and includes one idempotent world SQL update
plus its exact rollback. Patch `0022` adds no SQL; its first automatic 2v2 victory
cycle is runtime verified. Patch `0023` adds preparation buffs and safe participant
facing without SQL or global Arena-coordinate changes.

The active `Build/bin/RelWithDebInfo/playerbots.conf` currently enables the `0001`
observer with `DryRun = 1`, all three queue categories visible, a five-second check
interval, and `MaxBotsPerCycle = 1`. This records queue counts only and cannot enqueue
bots. Runtime verification passed on 2026-08-05: periodic `dry-run=1` lines reached
`Logs/Server.log`, all empty-queue counters were `0/0`, no related errors occurred,
and no random bots were automatically logged in.

The active configuration also contains the `0004` screening defaults (12 visible
equipped items, average item level 450, and two PvP-stat-bearing items). Patch `0004`
compiled into the active RelWithDebInfo WorldServer on 2026-08-05; its runtime command
passed both Alliance and Horde in-game candidate-selection verification on 2026-08-05.
No preview test logged in or queued a bot.

The observer runs independently of `AiPlayerbot.RandomBotAutologin`. This is
intentional: observing real-player queue demand must not require enabling random-bot
automatic login or changing the set of online bots.

Observer output uses the active `server` logger category so it is written to
`Logs/Server.log`; the local logger configuration filters the module's optional
`playerbots` INFO category.

This patch series is intentionally split into reversible stages. Apply it only after the
server files and all active databases have been backed up. Only `0021` contains world
SQL; staged login/logout and ordinary group create/disband paths can update the
character and group tables, and temporary Arena equipment uses its documented
characters-database recovery journal.

## Why this is a separate MoP implementation

The current module contains configuration remnants such as
`AiPlayerbot.RandomBotJoinLfg` and `AiPlayerbot.RandomBotAutoJoinBG`, but the matching
queue implementation is absent. The modern 3.3.5 playerbot project has LFG and
battleground actions, but its client packet layouts cannot safely be copied into a
5.4.8 core.

The patches therefore reuse the idea from
[mod-playerbots/mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) while
calling this core's own `LFGMgr` and `BattlegroundMgr` APIs. The reviewed upstream
reference was commit `ba46fcde`. A local MoP playerbot source at
`C:\wamp64\www\playerbots_5.4.8` was also checked; its commit was `b91c48a`, and it too
contained the LFG configuration key without the corresponding bot queue implementation.

## Patch order and scope

1. `patches/0001-playerbots-auto-queue-observer.patch`
   - adds disabled-by-default configuration;
   - reports real-player and bot LFG/BG/Arena queue counts;
   - never adds a bot to any queue.
2. `patches/0002-playerbots-lfg-auto-fill.patch`
   - fills only an LFG queue that already contains a real player;
   - selects a random bot of the missing tank/healer/damage role and the same faction;
   - lets the 5.4.8 LFG core validate level, item level, dungeon locks and cooldowns;
   - accepts pending LFG proposals for selected random bots;
   - fixes the shaman restoration specialization typo used by bot role selection.
3. `patches/0003-playerbots-battleground-auto-fill.patch`
   - fills only a battleground queue that already contains a real player;
   - uses the same battleground type and level bracket;
   - fills both factions only to the battleground template's minimum team size;
   - accepts battleground invitations using server-side 5.4.8 APIs.
4. `patches/0004-playerbots-solo-arena-2v2-preview.patch`
   - adds the administrator-only `.soloarena preview` diagnostic command;
   - scans unused offline random-account characters without logging them in;
   - previews one same-faction teammate and two same-faction opponents for a
     possible unranked 2v2 match;
   - requires level 90, an active damage/healer specialization, configurable
     equipment coverage, average item level, and PvP-stat-bearing items;
   - prefers a healer/damage pair on each side and avoids duplicate classes
     inside a pair;
   - only reports candidate names, roles, classes, factions, and equipment
     screening metrics. It does not log in, equip, group, queue, invite,
     teleport, or save any bot.
5. `patches/0005-playerbots-solo-arena-staged-login.patch`
   - adds separately disabled, administrator-only `login`, `status`, and
     `logout` actions to `.soloarena`;
   - logs in exactly the three candidates selected by the verified `0004`
     screening, with no master, group, teleport, or queue request;
   - records those three GUIDs only in WorldServer process memory so cleanup
     cannot target unrelated bots;
   - reports asynchronous loading/online/offline state and whether an unexpected
     group or battleground/queue state exists;
   - refuses cleanup while a bot is still loading or has entered a protected
     group/queue state, and requires the administrator to retry cleanup;
   - uses the core's normal character login/logout path, which can update the
     character database. It is not a database-read-only stage.
6. `patches/0006-playerbots-solo-arena-staged-groups.patch`
   - adds separately disabled `group` and always-available cleanup `ungroup`
     actions to `.soloarena`;
   - creates exactly one normal two-player group for the requester and teammate,
     plus one normal two-bot opponent group;
   - requires the complete tracked `0005` set and refuses any offline, already
     grouped, LFG, battleground, or Arena participant;
   - tracks both exact group IDs and expected member GUIDs in process memory;
   - disbands only a tracked group that still has exactly its two expected members;
     changed membership is protected rather than removed;
   - performs no teleport or queue request. Normal group creation/disbanding writes
     and removes `groups`/`group_member` rows and can reset non-permanent instance
     bindings, so a fresh characters database backup is required.
7. `patches/0007-playerbots-solo-arena-staged-queue.patch`
   - adds separately disabled `queue` and always-available cleanup `unqueue`
     actions to `.soloarena`;
   - validates both exact tracked groups with the core's normal group Arena checks,
     then adds all four participants to `BATTLEGROUND_QUEUE_2v2` as non-rated groups;
   - sends only the normal waiting-in-queue status and deliberately does not call
     `ScheduleQueueUpdate`, so this stage requests no matchmaking, invitation, or
     teleport;
   - verifies both exact queued GUID pairs before cleanup and blocks `ungroup` and
     `logout` until all four staged queue slots have been removed.
8. `patches/0008-playerbots-deduplicate-tracked-players.patch`
   - prevents repeated login callbacks from inserting the same non-random player
     pointer into the observer's `_players` tracker more than once;
   - removes every matching pointer on logout instead of only the first one;
   - fixes inflated observer counts such as four exact staged Arena participants
     being reported as seven after repeated login/logout tests;
   - changes no queue, group, character, or database behavior.
9. `patches/0009-playerbots-solo-arena-invite-only-match.patch`
   - adds separately disabled `.soloarena match` scheduling after the exact verified
     login, group, and non-rated 2v2 queue stages;
   - refuses to schedule unless the queue contains only the two tracked groups and
     exactly four tracked participants, with no existing Arena invitation;
   - schedules one normal core 2v2 queue update so the two groups can receive the
     same Arena-instance invitation;
   - reports both invitation instance IDs through `.soloarena status` and removes
     all four invited queue slots through the existing `.soloarena unqueue` cleanup;
   - does not accept an invitation, teleport, start combat, award rewards, or change
     rating. Never click the client Enter button during this stage.
10. `patches/0010-playerbots-solo-arena-staged-entry.patch`
   - adds separately disabled `.soloarena enter` and always-available `.soloarena
     leave` cleanup;
   - accepts only one shared nonzero invitation belonging to the exact two tracked
     groups and four queued participants from `0009`;
   - submits the same 5.4.8 `CMSG_BATTLEFIELD_PORT` path used when a real client
     presses Enter, so queue removal, entry-point storage, Arena team assignment,
     and teleport remain core-owned operations;
   - tracks the exact entered instance, reports inside/teleporting counts, and blocks
     unqueue, ungroup, and logout until staged Arena cleanup is complete;
   - makes `.soloarena leave` remove every exact tracked participant from either the
     entered Arena or a partially retained queue, then teleports entered participants
     back to their saved entry points;
   - must be cleaned before the 60-second Arena countdown ends. It adds no combat AI,
     completion, rewards, or rating behavior.
11. `patches/0011-playerbots-solo-arena-post-return-health.patch`
   - adds the disabled `StageHealthRestore` gate to the exact `0010` leave path;
   - schedules restoration only after normal Arena exit starts a far return teleport;
   - processes the refill through the core delayed-operation path, after the
     destination map restores normal equipment item levels and maximum health;
   - restores health only for a living exact staged participant and changes no
     queue, combat, reward, rating, schema, or SQL behavior.
12. `patches/0012-playerbots-solo-arena-combat-status.patch`
   - adds the separately disabled `.soloarena combatstatus` diagnostic for only
     the exact tracked Arena instance and original administrator requester;
   - reports the Arena map, lifecycle status, start delay, elapsed time, team and
     alive counts;
   - reports each exact participant's presence, assigned Arena team, life/combat/
     movement state, preparation aura, Playerbot AI state, current victim, and
     coordinates to `Server.log` and the administrator's chat;
   - performs no queue scheduling, invitation, teleport, movement, attack, result,
     reward, rating, schema, or SQL operation.
13. `patches/0013-playerbots-solo-arena-automatic-exit.patch`
   - adds the separately disabled `StageAutomaticExit` gate;
   - watches only the exact tracked Arena instance and four staged participant GUIDs;
   - schedules the existing delayed post-return health operation while a completed
     Arena is in `WAIT_LEAVE`, before client-button or automatic return teleports;
   - also recognizes the requester's normal `CMSG_BATTLEFIELD_LEAVE` before the core
     handler starts the return teleport;
   - clears only the entered-instance tracker after all four participants are outside;
     groups and staged bot logins remain for the existing explicit cleanup;
   - changes no unrelated battleground exit, combat, result, reward, rating, schema,
     or SQL behavior.

Arena combat, completion, rewards, and ratings remain unimplemented. An Arena must
not be treated as an ordinary battleground. Manually entered
instances are also outside this patch series; the LFG patch covers content reached through
the LFG queue manager.

## Validation already performed

- Patches `0001` through `0003` pass sequential `git apply --check`.
- Patch `0004` passed forward apply checking before application. In an isolated
  worktree it was actually removed and reapplied, with both checks and
  `git diff --check` succeeding. After active application its reverse check also
  passes.
- The affected `game` and `modules` targets compile successfully in an isolated
  `RelWithDebInfo` staging worktree with the project's normal PCH configuration.
- The `0004` version of the `modules` target also compiles successfully in an
  isolated 64-bit `RelWithDebInfo` build.
- Patch `0005` passes forward/reverse apply checks and an actual isolated
  reverse/forward cycle. Its final `modules` target compiles successfully in an
  isolated 64-bit `RelWithDebInfo` build.
- Patch `0006` passed forward checking against active HEAD `4011c43e` and reverse
  checking against its isolated applied tree. Its `modules` target compiled in an
  isolated x64 `RelWithDebInfo` build, and the active complete `worldserver` target
  subsequently compiled and linked successfully.
- The active source and configuration now contain patches `0001`, `0004`, `0005`,
  `0006`, and `0007`. The local runtime configuration has `StageLogin = 1`,
  `StageGroup = 1`, and `StageQueue = 1`; `DryRun = 1` remains required. None of
  the staged patches made a schema or direct SQL change.
- Patch `0007` passed a real apply/reverse cycle in an isolated worktree based on
  active HEAD `8b967461`; the worktree returned clean after reverse application.
  Its SHA-256 is
  `829ABFF57C2E81428B6D09C3C8AD209041E365E7D212ED1BE9EBEB04168F3102`.
  Both the `modules` and complete `worldserver` RelWithDebInfo targets compiled
  successfully. The active local configuration has `StageQueue = 1`, while the
  distributed default remains disabled. Its complete runtime queue and cleanup
  cycle passed on 2026-08-06.
- Patch `0008` reverse-checks cleanly against the active source, passes
  `git diff --check`, and its x64 RelWithDebInfo `modules` target compiles
  successfully. Its SHA-256 is
  `38B9CAB0509E1E33A6AD881BC5CD2C6EEA096F43914EAD675602F1FEEEA7FB5D`.
  The complete x64 RelWithDebInfo `worldserver` target also compiled and linked
  successfully. Its runtime test passed: two consecutive queued-state observer
  samples reported exactly four Arena slots, cleanup returned the observer to
  zero, and the group/member database baseline remained clean.
- Patch `0009` reverse-checks cleanly against the active source and passes
  `git diff --check`. Its SHA-256 is
  `ED17FC9F29973DE2FD2A27BB800108168BF69FA97EDC47DB6BDDE39AE510A7E7`.
  The x64 RelWithDebInfo `modules` target and complete `worldserver` target compiled
  and linked successfully on 2026-08-06. Its invite-only runtime and complete
  cleanup verification also passed on 2026-08-06. The local active configuration
  has `StageMatch = 1`; both
  distributed configurations keep the safe default `StageMatch = 0`.
- Patch `0010` reverse-checks cleanly against the active source, passes
  `git diff --check`, and its x64 RelWithDebInfo `modules` target compiles
  successfully. Its SHA-256 is
  `9420C4E64B497D6F60AC48837447F4CB1F1536B87AABCBAB4678CBDBA8250E82`.
  The local active configuration has `StageEnter = 1`; both distributed
  configurations retain `StageEnter = 0`. The complete x64 RelWithDebInfo
  `worldserver` target also compiled and linked successfully. The complete staged
  entry, immediate pre-countdown leave, group cleanup, and bot logout runtime
  verification passed on 2026-08-06.
- Patch `0011` reverse-checks cleanly against the active source and passes
  `git diff --check`. Its SHA-256 is
  `6C47D8CF37C7C1A367DC7896B07677388EA6F5248D19D012C0484B290C63081F`.
  The complete x64 RelWithDebInfo `worldserver` target compiled and linked
  successfully on 2026-08-06. The active local configuration enables
  `StageHealthRestore = 1`; both distributed configurations retain the safe default
  `StageHealthRestore = 0`. The controlled runtime verification passed on
  2026-08-06: all four staged participants entered instance `1`, `.soloarena leave`
  removed all four, the summary reported `health-restore-scheduled=4`, and one
  delayed post-return restoration ran for each of Palstest, Patrie, Alaniel, and
  Idonia. The observer returned to `Arena real/bot=0/0`, and the real player
  arrived alive with full world-map health. Final cleanup also passed: both staged
  groups were disbanded, the character database contained zero matching
  `group_member` and `groups` rows, the three selected bots were offline, and only
  the requester remained online.
- Patch `0012` is applied locally with its active test gate enabled and both
  distributed configurations retaining `StageCombatStatus = 0`. Its SHA-256 is
  `9D3D575C058E2241D9004F9BDABD806010931DBC5A2C8C596BCF967557338FC3`;
  `git diff --check` and reverse apply checking pass. The complete x64
  RelWithDebInfo `worldserver` target compiled and linked successfully on
  2026-08-06. Both `WAIT_JOIN` and `IN_PROGRESS` snapshots, normal combat, four
  participant return, health restoration, and exact cleanup passed at runtime.
- Patch `0013` is applied locally with `StageAutomaticExit = 1` only in the ignored
  active test configuration; both distributed configurations retain the safe
  default `0`. Its revised SHA-256 is
  `D1105A05A7E2124A2FA2BD9F225A1DA613C13003B96DDD895E8BFB60D3ED5049`.
  `git diff --check` and reverse apply checking pass. The initial x64
  RelWithDebInfo build linked successfully on 2026-08-07. Its first runtime pass
  scheduled health restoration for all four participants, the requester's normal
  client Leave button reduced Arena occupancy from `4/0` to `3/0`, and the delayed
  operation restored the requester after the destination teleport. The log prints
  the old health followed by the recalculated maximum (`481409/733409`); the operation
  itself calls `SetFullHealth()`. The three staged bots remained in the completed
  Arena beyond the core 120-second auto-close, so the tracker could not finalize.
  The patch is now revised to call the existing `Player::LeaveBattleground(true)`
  path only for the three exact staged bot GUIDs during `WAIT_LEAVE`; the real
  requester retains the normal client button. The revised x64 RelWithDebInfo target
  compiled and linked successfully on 2026-08-07; runtime retest remains pending.

The user confirmed fresh backups before `0005` was applied. Its first Alliance
runtime test passed on 2026-08-05: the three screened candidates were requested,
all three later logged out with `state=logged-out`, the protection guard rejected
none of them, and the observer remained at `Arena real/bot=0/0` before, during,
and after cleanup. This verifies staged login plus clean ungrouped/unqueued logout;
Arena queueing, teleport, and combat remain unimplemented.

Patch `0006` also passed its first complete Alliance runtime cycle on 2026-08-05.
The server created requester group `1` as `Palstest/Patrie` and opponent group `2`
as `Alaniel/Idonia`, then disbanded both tracked groups and logged out exactly the
three staged bots. Post-test database verification returned `groups=0` and
`group_member=0`, matching the stopped-server baseline, and all three bot character
rows had `online=0`. The final observer line `BG real/bot=3/0` counts occupied queue
slots rather than unique players or groups; staged cleanup had already accepted all
  three bots as unqueued and it did not represent a retained Arena group. Arena
  matchmaking, invitation, teleport, combat, completion, rewards, and ratings are
  still not implemented.

## Apply

Run from the repository root while WorldServer is stopped:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0001-playerbots-auto-queue-observer.patch
git apply contrib/playerbot_auto_queue_548/patches/0001-playerbots-auto-queue-observer.patch
```

Rebuild and initially use observer-only settings in the active `playerbots.conf`:

```ini
AiPlayerbot.AutoQueue.Enabled = 1
AiPlayerbot.AutoQueue.DryRun = 1
AiPlayerbot.AutoQueue.LFG = 1
AiPlayerbot.AutoQueue.Battleground = 1
AiPlayerbot.AutoQueue.Arena = 1
AiPlayerbot.AutoQueue.CheckInterval = 5
AiPlayerbot.AutoQueue.MaxBotsPerCycle = 1
```

After the observer output is verified, apply patch 0002, rebuild, and test LFG first:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0002-playerbots-lfg-auto-fill.patch
git apply contrib/playerbot_auto_queue_548/patches/0002-playerbots-lfg-auto-fill.patch
```

```ini
AiPlayerbot.AutoQueue.DryRun = 0
AiPlayerbot.AutoQueue.LFG = 1
AiPlayerbot.AutoQueue.Battleground = 0
AiPlayerbot.AutoQueue.Arena = 0
AiPlayerbot.AutoQueue.MaxBotsPerCycle = 1
```

Only after LFG works should patch 0003 be applied and battleground filling enabled:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0003-playerbots-battleground-auto-fill.patch
git apply contrib/playerbot_auto_queue_548/patches/0003-playerbots-battleground-auto-fill.patch
```

```ini
AiPlayerbot.AutoQueue.LFG = 0
AiPlayerbot.AutoQueue.Battleground = 1
AiPlayerbot.AutoQueue.Arena = 0
AiPlayerbot.AutoQueue.MaxBotsPerCycle = 2
```

Patch `0004` is independent of functional LFG/BG filling. Keep dry-run enabled,
apply it only while WorldServer is stopped, rebuild, and add the screening values
to the active `playerbots.conf`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0004-playerbots-solo-arena-2v2-preview.patch
git apply contrib/playerbot_auto_queue_548/patches/0004-playerbots-solo-arena-2v2-preview.patch
```

```ini
AiPlayerbot.AutoQueue.Enabled = 1
AiPlayerbot.AutoQueue.DryRun = 1
AiPlayerbot.AutoQueue.Arena = 1
AiPlayerbot.AutoQueue.Arena.MinEquippedItems = 12
AiPlayerbot.AutoQueue.Arena.MinAverageItemLevel = 450
AiPlayerbot.AutoQueue.Arena.MinPvpItems = 2
```

After restart, select the real level-90 character that would enter Arena and run:

```text
.soloarena preview
```

The command must end with a message stating that no bot was changed or queued.
The average item level is a conservative screening average over nonempty visible
equipment slots (shirt and tabard excluded), not the client's displayed item-level
calculation. Review the selected bots in `Logs/Server.log` before considering any
functional Arena stage.

Patch `0005` must be applied only after both faction previews pass and a fresh
character/playerbots database backup exists. Stop WorldServer before applying
and rebuilding it. The feature remains disabled until its explicit gate is set:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0005-playerbots-solo-arena-staged-login.patch
git apply contrib/playerbot_auto_queue_548/patches/0005-playerbots-solo-arena-staged-login.patch
```

```ini
AiPlayerbot.AutoQueue.DryRun = 1
AiPlayerbot.AutoQueue.Arena = 1
AiPlayerbot.AutoQueue.Arena.StageLogin = 1
```

Use this exact manual test sequence from a level-90 administrator character:

```text
.soloarena preview
.soloarena login
.soloarena status
.soloarena logout
.soloarena status
```

Wait several seconds between `login` and `status` because character loading is
asynchronous. The first status must show three online bots with `group=no` and
`queue=no`. The logout result must end with `remaining=0`; retry it if any bot is
still loading. If cleanup reports a protected bot, remove that bot from its group
or queue before retrying. Do not proceed to a grouping patch until this complete
login/logout cycle passes for Alliance and Horde requesters.

Patch `0006` must be applied only after `0005` cleanup passes and a fresh
characters/playerbots backup exists. Stop WorldServer before applying and rebuilding.
Keep `DryRun = 1`; its independent group gate defaults to disabled:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0006-playerbots-solo-arena-staged-groups.patch
git apply contrib/playerbot_auto_queue_548/patches/0006-playerbots-solo-arena-staged-groups.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageLogin = 1
AiPlayerbot.AutoQueue.Arena.StageGroup = 1
```

Use this uninterrupted test sequence; do not restart or stop WorldServer between
`group` and `ungroup`, because the group trackers exist only in process memory:

```text
.soloarena login
.soloarena status
.soloarena group
.soloarena status
.soloarena ungroup
.soloarena status
.soloarena logout
.soloarena status
```

The grouped status must report two tracked groups with two members each. `ungroup`
must report `remaining-groups=0`, the following status must show `group=no` for all
three bots, and logout must finish with `remaining=0`. If membership protection
triggers, do not restart; restore the expected membership or disband the affected
group manually before cleaning up the staged bots.

Patch `0007` must be applied only after the complete `0006` group/cleanup cycle
passes. Stop WorldServer before applying and rebuilding. Keep `DryRun = 1`; the
new queue gate defaults to disabled:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0007-playerbots-solo-arena-staged-queue.patch
git apply contrib/playerbot_auto_queue_548/patches/0007-playerbots-solo-arena-staged-queue.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageLogin = 1
AiPlayerbot.AutoQueue.Arena.StageGroup = 1
AiPlayerbot.AutoQueue.Arena.StageQueue = 1
```

Use this uninterrupted sequence. Do not stop or restart WorldServer after `queue`
until `unqueue`, `ungroup`, and `logout` have all completed:

```text
.soloarena login
.soloarena status
.soloarena group
.soloarena status
.soloarena queue
.soloarena status
.soloarena unqueue
.soloarena status
.soloarena ungroup
.soloarena status
.soloarena logout
.soloarena status
```

After `queue`, the status must show both tracked groups still at two members,
`staged-queue=yes`, `requester-2v2=yes`, and `queue=yes` for each staged bot. No
Arena invitation should be requested by this command. After `unqueue`, all four
2v2 slots must be gone while both groups remain. Only then run `ungroup` and
`logout`. If an invitation appears because another external 2v2 join caused a
queue update, do not enter the Arena; immediately run `unqueue`.

Patch `0008` is a tracker-safety correction discovered during repeated `0007`
tests. Apply it with WorldServer stopped, rebuild, then repeat the same uninterrupted
`0007` sequence twice in one server process:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0008-playerbots-deduplicate-tracked-players.patch
git apply contrib/playerbot_auto_queue_548/patches/0008-playerbots-deduplicate-tracked-players.patch
```

Each queued cycle must report four occupied Arena slots rather than seven, and
each cleanup must return Arena to zero. The patch itself has no configuration key.

Patch `0009` must be applied only after the complete `0008` repeated lifecycle test
passes. Stop WorldServer before applying and rebuilding. Keep `DryRun = 1`; the new
matchmaking gate defaults to disabled:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0009-playerbots-solo-arena-invite-only-match.patch
git apply contrib/playerbot_auto_queue_548/patches/0009-playerbots-solo-arena-invite-only-match.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageLogin = 1
AiPlayerbot.AutoQueue.Arena.StageGroup = 1
AiPlayerbot.AutoQueue.Arena.StageQueue = 1
AiPlayerbot.AutoQueue.Arena.StageMatch = 1
```

Use this uninterrupted invite-only sequence. After `match`, do not click the client
Enter button. Run `status` promptly and then remove the invitation before its normal
timeout:

```text
.soloarena login
.soloarena status
.soloarena group
.soloarena status
.soloarena queue
.soloarena status
.soloarena match
.soloarena status
.soloarena unqueue
.soloarena status
.soloarena ungroup
.soloarena status
.soloarena logout
.soloarena status
```

The status immediately after `match` must show `match-scheduled=yes`, both exact
queues as `yes`, and the same nonzero invitation instance ID for both groups. The
real player may see the normal Arena invitation popup, but it must not be accepted.
`unqueue` must remove all four invited slots and dismiss the popup while retaining
both tracked groups. Only then run `ungroup` and `logout`. If the two invitation IDs
are different, zero, or cleanup refuses, do not enter the Arena or restart the server;
record the status and clean the exact staged state first.

Patch `0010` must be applied only after the complete `0009` invite and cleanup test
passes. Stop WorldServer before applying and rebuilding. Keep `DryRun = 1`; the new
entry gate defaults to disabled while cleanup remains available:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0010-playerbots-solo-arena-staged-entry.patch
git apply contrib/playerbot_auto_queue_548/patches/0010-playerbots-solo-arena-staged-entry.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageLogin = 1
AiPlayerbot.AutoQueue.Arena.StageGroup = 1
AiPlayerbot.AutoQueue.Arena.StageQueue = 1
AiPlayerbot.AutoQueue.Arena.StageMatch = 1
AiPlayerbot.AutoQueue.Arena.StageEnter = 1
```

Use the verified `0009` sequence through `.soloarena match`, then run the following
quickly because the Arena preparation countdown is 60 seconds:

```text
.soloarena enter
.soloarena status
.soloarena leave
.soloarena status
.soloarena ungroup
.soloarena status
.soloarena logout
.soloarena status
```

Wait only until the real player has landed before the first `status`; bots process
their far-teleport acknowledgements automatically. The entered status must report
the tracked nonzero Arena instance and `inside=4`, `teleporting=0`. Do not fight or
wait for the gates to open. Run `leave` immediately; if it reports a participant
still teleporting, wait one or two seconds and retry. After leaving, status must
show `entered-instance=0`, no queue state, and all four participants outside before
normal `ungroup`/`logout` cleanup. Do not stop or restart WorldServer while an
entered-instance tracker exists.

Patch `0011` must be applied only after the complete `0010` entry/leave/cleanup test
passes. Stop WorldServer before applying and rebuilding. The health gate defaults to
disabled:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0011-playerbots-solo-arena-post-return-health.patch
git apply contrib/playerbot_auto_queue_548/patches/0011-playerbots-solo-arena-post-return-health.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageHealthRestore = 1
```

Repeat the verified `0010` sequence. After `.soloarena leave`, the log must report
`health-restore-scheduled=4`, followed by one `Battleground post-return health
restored` line for each exact participant. The real player must arrive alive at full
health after world-map item levels are restored. Continue with the normal status,
ungroup, logout, and database cleanup checks.

Patch `0012` must be applied only after `0011` and its complete cleanup have passed.
It adds no command that starts combat; its gate only enables read-only snapshots:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0012-playerbots-solo-arena-combat-status.patch
git apply contrib/playerbot_auto_queue_548/patches/0012-playerbots-solo-arena-combat-status.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageCombatStatus = 1
```

Use the verified sequence through `.soloarena enter`, then run `.soloarena
combatstatus` once after all four participants land. It must report `WAIT_JOIN`,
four present/alive participants, and the preparation aura. Wait for the normal
60-second countdown without issuing movement or attack commands. Run the diagnostic
again immediately when the gates open; it must report `IN_PROGRESS`, no preparation
aura, and new bot movement/combat/target evidence or coordinates. Immediately run
`.soloarena leave`, verify all return teleports and health restorations, then perform
the normal `ungroup`/`logout` and direct character-database cleanup checks. This test
does not yet validate a completed match, rewards, or ratings.

The controlled `0012` runtime test passed on 2026-08-06. The first snapshot
reported `WAIT_JOIN`, `players=2/2`, `alive=2/2`, preparation on all four exact
participants, and no movement or combat. After the normal countdown, the second
snapshot reported `IN_PROGRESS`, no preparation aura, `ai=combat` for all three
bots, and valid cross-team victims. The opponent bots initially waited until the
real player approached, consistent with their current engagement range. Leaving
removed all four participants, scheduled and completed four health restorations,
and returned the observer to `Arena real/bot=0/0`. Final cleanup disbanded both
groups; direct character-database checks found `groups=0`, no matching
`group_member` rows, all three staged bots offline, and the requester online.
Match completion, rewards, ratings, and proactive opponent engagement remain
outside `0012`.

One completed-match follow-up exposed a separate limitation. The normal client
`Leave Arena` button removed the requester first, reducing the observer from four
to three Arena slots, but it did not pass through the `0011` command-owned delayed
health restoration. A subsequent `.soloarena leave` safely removed the remaining
three bots and restored their health, but could not restore the already-outside
requester. A later patch must cover normal client and automatic post-match exits
without altering unrelated battleground exits.

Patch `0013` is the gated implementation prepared for that limitation. Apply it
only after `0012` and its cleanup have passed:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0013-playerbots-solo-arena-automatic-exit.patch
git apply contrib/playerbot_auto_queue_548/patches/0013-playerbots-solo-arena-automatic-exit.patch
```

```ini
AiPlayerbot.AutoQueue.Arena.StageAutomaticExit = 1
```

Run the verified sequence through a naturally completed match. After the winner is
shown and `WAIT_LEAVE` is confirmed, use the normal client `Leave Arena` button for
the requester and do not use `.soloarena leave`. The three exact staged bots should
leave through `Player::LeaveBattleground(true)` without waiting for or modifying the
global Arena auto-close path. The log must contain four exact automatic health
schedules, three staged-bot exit requests, four delayed restorations, and one
automatic-exit finalization. Then run the normal `ungroup`/`logout` cleanup and direct
database checks. The requester must return at full destination-map health. Abort
with the existing `.soloarena leave` command if the exact staged cleanup stalls.

The first revised-`0013` retest exposed two independent core defects in Tol'viron
Arena. Apply these patches in order after `0013`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0014-battleground-unrated-arena-dampening-crash.patch
git apply contrib/playerbot_auto_queue_548/patches/0014-battleground-unrated-arena-dampening-crash.patch

git apply --check contrib/playerbot_auto_queue_548/patches/0015-battleground-tolviron-object-rotations.patch
git apply contrib/playerbot_auto_queue_548/patches/0015-battleground-tolviron-object-rotations.patch
```

`0014` prevents non-rated Arenas from dereferencing absent rated `ArenaTeam`
objects when dampening updates; it applies dampening to the battleground's actual
participant map instead. `0015` supplies the missing fourth quaternion components
and explicit respawn arguments for Tol'viron's two gates and first buff object.
Together they require a fresh Tol'viron run: verify that both gates open when the
normal countdown ends, then keep the match alive beyond five minutes and verify
that dampening is applied without a crash. These patches add no configuration or
database change.

For repeatable Tol'viron-only regression runs, apply `0016` after `0015`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0016-playerbots-solo-arena-force-tolviron.patch
git apply contrib/playerbot_auto_queue_548/patches/0016-playerbots-solo-arena-force-tolviron.patch
```

Use `.soloarena match tolviron` instead of `.soloarena match` after the exact
four-player queue has been staged. The former keeps matchmaking on the original
`BATTLEGROUND_AA` queue/bracket and supplies a one-shot `BATTLEGROUND_TV`
selection when that exact match is created; the latter deliberately retains the
normal random all-Arena selection. The one-shot selection is consumed after
successful creation and cleared by `.soloarena unqueue`. This is a test-control
change only and makes no database or configuration change.

The same test's equipment audit found no 4/5 or 5/5 coherent set among the 200
configured level-90 random-bot accounts. Do not treat candidate re-sorting as a
5/5 fix. A later separately gated loadout stage must back up and restore every
replaced equipment slot/item instance for the teammate and both opponents.

Patch `0017` is the read-only prerequisite for that later loadout stage. Apply it
after `0016`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0017-playerbots-solo-arena-loadout-audit.patch
git apply contrib/playerbot_auto_queue_548/patches/0017-playerbots-solo-arena-loadout-audit.patch
```

It adds `.soloarena loadout`, which is valid only for the administrator requester
after the exact three staged bots are online. The command maps every supported
level-90 damage/healer specialization to its Season 15 Prideful five-piece set,
uses the matching Alliance or Horde item entries, and validates all five item
templates, ItemSet IDs, armor slots, class restrictions, and live
`Player::CanUseItem` results. It also reports how many matching set pieces are
currently equipped. This command is deliberately audit-only: it creates, moves,
equips, saves, and deletes no item. Run `.soloarena preview`, `.soloarena login`,
wait for `.soloarena status` to show three online bots, then run `.soloarena
loadout`. It must report `valid=5/5` for all four participants before any later
mutation/restore patch is designed. Finish with `.soloarena logout`; no groups or
queues are needed for this test.

Patch `0018` adds the separately gated, reversible temporary equipment stage.
Apply it after `0017`, then execute its character-database migration before
starting WorldServer:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0018-playerbots-solo-arena-temporary-loadout-restore.patch
git apply contrib/playerbot_auto_queue_548/patches/0018-playerbots-solo-arena-temporary-loadout-restore.patch
```

The migration is
`sql/updates/characters/2026_08_07_00_characters_solo_arena_loadout_backup.sql`.
It creates the initially empty InnoDB recovery journal
`solo_arena_loadout_backup`. After `.soloarena login`, use `.soloarena loadout
apply` to replace only nonmatching head, shoulder, chest, leg, and hand slots
with the exact faction/spec Prideful entries validated by `0017`. Every changed
slot records the exact original and temporary item-instance GUIDs before the
swap is saved. Inventory prepared statements run on the asynchronous Character
DB connection and the command waits for each transaction to finish before it
changes the in-memory equipment slot. `.soloarena loadout restore` restores the exact original
instances and deletes only the corresponding temporary instances. Restoration
is also attempted before manual/automatic Arena exit and staged logout.

The first runtime build of `0018` incorrectly used
`DirectCommitTransaction` for `Player::SaveInventoryAndGoldToDB`. Those
inventory statements are prepared only on asynchronous Character DB
connections, so `.soloarena loadout apply` asserted on its first changed bot
slot. The transaction rolled back and left the recovery journal empty; no item
row changed. The current patch uses `AsyncCommitTransaction` and explicitly
waits for its result. Do not test with an older `0018` patch or executable.

The corrected build completed its first full manual runtime cycle on
2026-08-10. All four participants audited as `current=5/5`; the three bots
created 15 recovery rows and equipped 15 temporary pieces. Manual restore then
restored all 15 exact original item instances, removed all temporary instances,
and returned the persistent journal to zero rows without a crash. Automatic
post-match/leave restoration remains a separate runtime test.

If WorldServer stops or crashes while journal rows exist, do not delete items or
the journal table. Start the server, log into the affected real character if
needed, and repeat `.soloarena loadout recover`; random-bot owners are loaded for
recovery and logged out after their protected rows reach zero. New staged login
and loadout apply operations refuse to run while any older recovery row exists.
The schema rollback
`sql/backup/characters_solo_arena_loadout_backup_before_20260807.sql` refuses to
drop a nonempty journal and is harmless when the table is already absent.

The same test showed that staged bots did not visibly apply their available class
buffs to themselves and their Arena teammate during preparation. Treat preparation
buffing as a separate later stage: use each bot's existing spell/action logic,
restrict targets to its exact two-member Arena team, allow it only during
`WAIT_JOIN`, and do not use direct hard-coded spell casts.

Patch `0019` adds a read-only MoP build audit after `0018`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0019-playerbots-solo-arena-build-audit.patch
git apply contrib/playerbot_auto_queue_548/patches/0019-playerbots-solo-arena-build-audit.patch
```

After `.soloarena login` reports all three staged bots online, run `.soloarena
build`. For the requester, teammate, opponent healer, and opponent damage bot it
reports class, level, active spec index, specialization ID, used/unlocked talent
count, selected talent spell IDs, and all six glyph-property slots. It also writes
the same audit to the server log. This stage does not select, learn, reset, apply,
save, or delete any specialization, talent, glyph, item, or database row. Its
output is the required baseline before verified 5.4.8 talent and glyph templates
are designed; the shipped WotLK `.60`/`.80` premade values must not be reused.

The first manual runtime audit completed successfully on 2026-08-10. Palstest
reported six of six talents and six of six glyph properties. Patrie, Alaniel,
and Idonia each reported zero of six talents and zero of six glyph properties,
confirming that the command distinguishes a populated real-player build from
the empty random-bot builds. All three staged bots then logged out normally.

Patch `0020` connects the already runtime-tested Solo Arena stages into one
command-free 2v2 preparation flow:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0020-playerbots-solo-arena-automatic-ui.patch
git apply contrib/playerbot_auto_queue_548/patches/0020-playerbots-solo-arena-automatic-ui.patch
```

It observes a real solo player's normal `CMSG_BATTLEMASTER_JOIN_ARENA` 2v2
request and runs `login -> loadout apply -> group -> queue -> match -> enter`
through the same handlers already tested manually. Every transition verifies
the expected tracked state. Preparation is limited to 120 seconds by default;
on a failed transition it unwinds queue, groups, temporary loadouts, and bot
logins in the safe reverse order. Completed matches use the existing automatic
exit and health restoration before the same final cleanup.

The feature has its own default-off `AiPlayerbot.AutoQueue.Arena.Automatic`
gate. `AutomaticForceTolviron = 1` provides a repeatable exact-map test;
otherwise the core selects a random Arena. All earlier `Stage*` safety gates
must remain enabled. The active local runtime configuration enables automatic
orchestration with random Arena selection; distributed defaults remain disabled.

The x64 RelWithDebInfo WorldServer compiled and linked successfully on
2026-08-10. The first runtime test must be performed without `.soloarena`
commands: while solo and outside all queues/groups, use the normal 2v2 Join
button. If the client keeps that button disabled and sends no packet, this
cannot be repaired purely by the server packet hook; the next frontend will be
a normal in-game Queue Master gossip choice that calls the same automatic
orchestrator rather than adding another GM command.

Patch `0021` implements that frontend at the existing Arena Battlemaster NPCs
and generalizes the automatic orchestrator to all three MoP Arena sizes:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0021-playerbots-arena-battlemaster-2v2-3v3-5v5.patch
git apply contrib/playerbot_auto_queue_548/patches/0021-playerbots-arena-battlemaster-2v2-3v3-5v5.patch
```

The shared menu `8218` retains its original premade-group registration choice
and gains explicit `Solo Arena 2v2`, `Solo Arena 3v3`, and `Solo Arena 5v5`
choices. The world update uses previously unused option IDs `20-22`; its rollback
is `sql/backup/world_arena_battlemaster_solo_options_before_20260810.sql`.
Selecting a size maps to its real `BATTLEGROUND_QUEUE_2v2`, `_3v3`, or `_5v5`
queue. The requester's team uses the requester's faction, the opponent team uses
the opposing faction, each side has one healer, and every remaining slot is
filled by damage players. A healer requester is itself the team's healer.

The automatic participant model, exact group validation, queue validation,
match scheduling, shared invitation acceptance, entry, protected temporary
loadouts, exit, reverse cleanup, and bot logout all use the selected team size.
Only one automatic Solo Arena may run at a time, and an occupied queue of the
selected size is protected rather than mixed into this controlled match. The
distributed configuration keeps `AutomaticBattlemasterSolo = 0`; the ignored
active local test configuration enables it. The x64 RelWithDebInfo WorldServer
compiled and linked successfully on 2026-08-10. The first UI test exposed a
5.4.8 core detail: `GossipMenu::_senderGUID` is never populated, so the visible
choices were silently ignored while the module tried to resolve the
Battlemaster through that empty value. The revised packet hook decodes and
validates the sender GUID directly from `CMSG_GOSSIP_SELECT_OPTION`, matching
the core opcode handler, and reports rejected requests to the player instead
of failing silently. The isolated revised `0021` patch passes forward
application over `0020`, reverse application, and whitespace validation; its
SHA-256 is
`288FC824FCC9796ADA0A8CEA405A8D98CD903004E35F6FBF7EDCE0569F3D7A32`.
Runtime tests for 2v2, 3v3, and 5v5 remain required after a fresh server restart.

Patch `0022` adds configurable automatic-match victory rewards and a MoP-native
baseline build generator for random bots:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0022-playerbots-solo-arena-rewards-spec-builds.patch
git apply contrib/playerbot_auto_queue_548/patches/0022-playerbots-solo-arena-rewards-spec-builds.patch
```

Only the real requester can receive the reward, and only after the tracked
automatic Arena reaches `STATUS_WAIT_LEAVE` with the requester's Arena team as
winner. A loss, draw, disabled reward, zero configured amount, or offline
requester gives no reward. A per-instance guard prevents repeated exit polling
or the client Leave path from paying twice. Distributed defaults keep rewards
disabled; the configurable defaults are 180, 270, and 450 UI conquest points
for 2v2, 3v3, and 5v5 respectively. Currency is awarded through the core's
normal high-precision conquest path and therefore retains its ordinary cap.

The same patch fills missing random-bot talents from the 5.4.8 `Talent.dbc`
rows and fills missing glyph slots only with class-valid, slot-compatible,
non-duplicate glyph properties. Selection scores known specialization spells
and uses a deterministic specialization-sensitive fallback. Existing selected
talent rows and non-empty glyph slots are preserved. This is a valid 5.4.8
baseline, not a hand-tuned best-in-slot PvP build. Automatic Arena staging runs
the build preparation before protected temporary equipment is applied; normal
bot randomization, specialization changes, class-bot creation, and level-up
maintenance also fill missing build choices.

The implementation contains no database schema or data migration. The x64
RelWithDebInfo WorldServer compiles and links successfully. Runtime verification
of all three Arena sizes, reward amounts, duplicate protection, and generated
builds remains required; Codex did not start the server for this patch.

Patch `0023` enables staged bots' existing class/spec non-combat buff strategy
only while the tracked automatic Arena is in `STATUS_WAIT_JOIN`. It records only
the bots for which it added that strategy, removes it when combat begins, and also
removes it on guarded cleanup. No spell ID is hard-coded and the real requester's
AI strategies are never changed. After all participants land, each player is also
faced toward the opposing team's configured start location; this is scoped to the
automatic match and does not modify `battleground_template`:

```powershell
git apply --check contrib/playerbot_auto_queue_548/patches/0023-playerbots-solo-arena-preparation-buffs-facing.patch
git apply contrib/playerbot_auto_queue_548/patches/0023-playerbots-solo-arena-preparation-buffs-facing.patch
```

Both distributed settings remain disabled. The ignored active test configuration
enables `AiPlayerbot.AutoQueue.Arena.PreparationBuffs` and
`AiPlayerbot.AutoQueue.Arena.PreparationFaceOpponent`. The isolated patch passes
forward, reverse, and whitespace checks; its SHA-256 is
`1AFDE3387702713490ADB60BB3D4D7DA29CD0AEC0B642A1412FDDC37FF0279DB`.
The complete x64 RelWithDebInfo WorldServer compiled and linked successfully on
2026-08-11. The resulting `worldserver.exe` is `61,669,888` bytes with SHA-256
`349A8E81AB74A8CBD5F9D1DBB89DD6F42EF9EEC430DB2B5B0632AF26428CA49D`.
Codex did not start or stop WorldServer; no server process was present at link time.

Do not enable LFG and battleground functional testing simultaneously until each has passed
separately. `MaxBotsPerCycle` is shared by both systems.

## Remove

Stop WorldServer, remove only the patches that were applied, in reverse order, then rebuild:

```powershell
git apply -R --check contrib/playerbot_auto_queue_548/patches/0023-playerbots-solo-arena-preparation-buffs-facing.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0023-playerbots-solo-arena-preparation-buffs-facing.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0022-playerbots-solo-arena-rewards-spec-builds.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0022-playerbots-solo-arena-rewards-spec-builds.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0021-playerbots-arena-battlemaster-2v2-3v3-5v5.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0021-playerbots-arena-battlemaster-2v2-3v3-5v5.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0020-playerbots-solo-arena-automatic-ui.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0020-playerbots-solo-arena-automatic-ui.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0019-playerbots-solo-arena-build-audit.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0019-playerbots-solo-arena-build-audit.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0018-playerbots-solo-arena-temporary-loadout-restore.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0018-playerbots-solo-arena-temporary-loadout-restore.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0017-playerbots-solo-arena-loadout-audit.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0017-playerbots-solo-arena-loadout-audit.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0016-playerbots-solo-arena-force-tolviron.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0016-playerbots-solo-arena-force-tolviron.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0015-battleground-tolviron-object-rotations.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0015-battleground-tolviron-object-rotations.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0014-battleground-unrated-arena-dampening-crash.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0014-battleground-unrated-arena-dampening-crash.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0013-playerbots-solo-arena-automatic-exit.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0013-playerbots-solo-arena-automatic-exit.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0012-playerbots-solo-arena-combat-status.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0012-playerbots-solo-arena-combat-status.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0011-playerbots-solo-arena-post-return-health.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0011-playerbots-solo-arena-post-return-health.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0010-playerbots-solo-arena-staged-entry.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0010-playerbots-solo-arena-staged-entry.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0009-playerbots-solo-arena-invite-only-match.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0009-playerbots-solo-arena-invite-only-match.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0008-playerbots-deduplicate-tracked-players.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0008-playerbots-deduplicate-tracked-players.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0007-playerbots-solo-arena-staged-queue.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0007-playerbots-solo-arena-staged-queue.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0006-playerbots-solo-arena-staged-groups.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0006-playerbots-solo-arena-staged-groups.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0005-playerbots-solo-arena-staged-login.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0005-playerbots-solo-arena-staged-login.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0004-playerbots-solo-arena-2v2-preview.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0004-playerbots-solo-arena-2v2-preview.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0003-playerbots-battleground-auto-fill.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0003-playerbots-battleground-auto-fill.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0002-playerbots-lfg-auto-fill.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0002-playerbots-lfg-auto-fill.patch

git apply -R --check contrib/playerbot_auto_queue_548/patches/0001-playerbots-auto-queue-observer.patch
git apply -R contrib/playerbot_auto_queue_548/patches/0001-playerbots-auto-queue-observer.patch
```

The active `playerbots.conf` entries may then be removed manually or left disabled.

## Minimum runtime test checklist

- Observer: a real queue appears in the log, but no bot joins while `DryRun = 1`.
- LFG: test one damage player, then healer/tank players; verify roles, proposal acceptance,
  teleport, group leadership, following, combat and clean dungeon exit.
- LFG restrictions: verify a too-low-level or locked bot is rejected and another candidate
  can be selected on a later cycle.
- BG: test one specific battleground and one random battleground in a single level bracket;
  verify both factions, invitation acceptance, teleport, combat and clean queue removal.
- Arena preview: run `.soloarena preview` from level-90 Alliance and Horde characters;
  verify one teammate and two opponents are reported, roles/classes are sensible, and no
  bot logs in or enters a group/queue. Repeat with thresholds high enough to force a safe
  `no eligible ...` result.
- Arena staged login: with `0005` explicitly enabled, verify all three selected
  bots reach `online`, all report `group=no, queue=no`, and `.soloarena logout`
  returns `remaining=0`. Verify the observer still reports no Arena queue entry.
- Arena staged groups: with `0006` explicitly enabled, verify the requester and
  teammate form one two-member group, both opponents form another, no queue count
  changes, `ungroup` removes both exact groups, and only then log out all staged bots.
- Arena staged queue: with `0007` explicitly enabled, verify exactly four non-rated
  2v2 queue slots appear without an invitation, `unqueue` removes all four while
  retaining both groups, and only then run `ungroup` and `logout`.
- Tracker deduplication: with `0008` applied, repeat the full staged sequence twice
  without restarting and verify that both queued cycles report four Arena slots,
  then return to zero after cleanup.
- Arena invite-only matchmaking: with `0009` explicitly enabled, verify that the
  two exact groups receive one shared nonzero invitation instance, do not accept
  the invitation, and immediately verify that `unqueue` removes all four slots and
  the popup before normal group and login cleanup.
- Arena staged entry: with `0010` explicitly enabled, verify all four exact
  participants enter the same tracked Arena through the normal port handler, then
  leave before the countdown completes; verify return teleport, zero Arena/queue
  state, normal group cleanup, and all three staged bots offline.
- Arena post-return health: with `0011` explicitly enabled, repeat the `0010` cycle
  and verify four delayed restorations plus full real-player health after landing.
- Arena countdown/combat status: with `0012` explicitly enabled, capture one exact
  four-participant `WAIT_JOIN` snapshot, wait for the normal gates to open, capture
  one `IN_PROGRESS` snapshot, and immediately leave and complete all normal cleanup.
- Arena completed-match exit: with `0013` explicitly enabled, finish the staged
  match, press the normal client Leave button, verify the three exact staged-bot
  exit requests, four health restorations, automatic tracker cleanup, zero Arena
  slots, full requester health, zero groups, and all staged bots offline.
- Tol'viron core regression: with `0014` and `0015` applied, verify both gates open
  at `IN_PROGRESS`; keep all four participants alive beyond the five-minute
  dampening boundary and verify no crash plus dampening on all present players.
- Arena loadout audit: with `0017` applied, stage only the three bot logins and
  verify `.soloarena loadout` reports four complete `valid=5/5` plans, preserves
  every equipped item and item-instance GUID, creates no item, and permits normal
  staged logout without requiring a group or queue.
- Arena temporary loadout: with `0018` and its character migration applied,
  stage only the three bot logins, run `.soloarena loadout apply`, and verify all
  four report `current=5/5`. Run `.soloarena loadout restore` before any group or
  queue test and verify every original equipment GUID/entry and inventory
  position is restored, the journal returns to zero rows, and only the exact
  temporary item GUIDs disappear. Repeat through one completed Arena and verify
  the automatic exit path produces the same zero-row, exact-restoration result.
- Arena build audit: with `0019` applied, stage only the three bot logins and run
  `.soloarena build`. Verify four participants are online, the real-player control
  build is reported, empty bot talents/glyphs are exposed without mutation, and
  normal `.soloarena logout` leaves no bot online or queued.
- Automatic Arena UI: with `0020` and every verified `Stage*` gate enabled, remain
  solo and use only the normal 2v2 Join button. Verify automatic state logs reach
  `active`, all four enter one instance, the match completes, exact original
  loadouts and health return, groups/queues reach zero, all three bots log out,
  and the recovery journal is empty. Do not use `.soloarena` during this test.
- Arena Battlemaster sizes: with `0021` and its world update applied, verify that
  every Arena Battlemaster shows the original registration option plus Solo 2v2,
  3v3, and 5v5. Test the sizes separately without `.soloarena` commands. Verify
  exact totals of 4, 6, and 10 participants; one healer per side; same-faction
  teammates; opposing-faction opponents; the matching Arena queue type; normal
  gates/combat/leave; full health; exact original equipment restoration; zero
  recovery rows/groups/queue slots; and all 3, 5, or 9 staged bots offline.
- Arena rewards and bot builds: with `0022` applied, win and lose one automatic
  match of each size. Verify only the real winning requester receives conquest
  (default 180/270/450 for 2v2/3v3/5v5), a loss/draw gives none, and repeated
  exit polling never duplicates the reward. Confirm every staged bot reports
  six talents and six unique, slot-compatible glyphs. Existing non-empty talent
  rows and glyph slots must remain unchanged.
- Arena preparation: with `0023` enabled, verify the real requester and every
  staged bot initially face through their own gate toward the opposing start.
  During `WAIT_JOIN`, verify each class that has a useful buff applies it to itself
  or its own team through the normal bot AI. Verify the temporary `buff` strategy
  is removed at `IN_PROGRESS`, opposing teams do not buff one another, normal
  combat still starts, and guarded cleanup leaves every bot offline.
- Shutdown/restart: verify no bot remains stuck in LFG or battleground queue state.
- Keep `AiPlayerbot.AutoQueue.Arena = 0` during functional LFG/BG testing; enable it
  only for the read-only `0004` preview while `DryRun = 1`.
