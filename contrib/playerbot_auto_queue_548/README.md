# Playerbot auto-queue patches for MoP 5.4.8

Status: experimental. Patches `0001`, `0004`, `0005`, `0006`, `0007`, `0008`, `0009`, `0010`, and `0011` are applied to
the active source and compiled; patches `0002` and `0003` are not applied. None
contains SQL. The explicitly gated `0005` login, `0006` grouping, and `0007`
non-rated queue stages use normal core paths and can therefore save character/group
state or temporarily change in-memory queue state. Patch `0009` adds an additional
invite-only matchmaking diagnostic. Patch `0010` adds a separately gated staged
accept/teleport diagnostic plus exact pre-countdown cleanup. Patch `0011` adds a
separately gated post-return health refill after destination-map stat recalculation.

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
server files and all active databases have been backed up. None of these patches contains
SQL, but staged login/logout and ordinary group create/disband paths can update the
character and group tables.

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

Do not enable LFG and battleground functional testing simultaneously until each has passed
separately. `MaxBotsPerCycle` is shared by both systems.

## Remove

Stop WorldServer, remove only the patches that were applied, in reverse order, then rebuild:

```powershell
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
- Shutdown/restart: verify no bot remains stuck in LFG or battleground queue state.
- Keep `AiPlayerbot.AutoQueue.Arena = 0` during functional LFG/BG testing; enable it
  only for the read-only `0004` preview while `DryRun = 1`.
