# Kypari Zar (31022)

Sonar Tower 212933 previously cast dummy spell 123531 without a script handler.
Neither the tower nor summoned Korven 63328 had an event script. Quest objectives
267931 and 268179 require creature credits 63286 and 63287 respectively.

The tower now starts a defense for the clicking player. Korven and his attackers
use that player's private-object ownership (group members may also see them).
Repeated clicks cannot start another event for the same player. Tower credit is
granted when Korven spawns; defense credit requires killing all three waves of
Ik'thik Towerguards. This implementation uses waves of three, four and five,
with five-second pauses; these timings/counts are a reconstruction, not verified
retail timings. The expected click/defense sequence is also described in the
[quest reference](https://www.wowhead.com/mop-classic/quest=31022/kypari-zar).

Death, logout, abandoning the quest, leaving an 80-yard radius, an attacker
despawning alive, failed summons, or the three-minute timeout clean up the event
without granting defense credit. Click the tower again to retry. Static Korven
quest givers are unchanged. Event dialogue is English.

## Validation

Run `python3 contrib/kypari_zar/run_tests.py`. The harness compiles the production
callbacks and exercises click gates, failed initial summons, duplicate clicks,
separate players, attack targets, kill-gated waves, single completion credit,
cleanup and retry after eight failure paths. Worldserver also builds successfully.
The harness does not verify client rendering, terrain navigation or live combat.

## Deployment

Apply `sql/updates/world/2026_09_22_02_world_kypari_zar.sql`, install the rebuilt
worldserver, and restart it. The migration is idempotent. In this workspace it
was applied to the configured world database; previous values were saved to
`/tmp/kypari_zar_before.tsv`. Installation and a live gameplay test remain pending.

## Wave recovery and defense NPC

The controller now checks tracked summons for confirmed deaths in addition to
receiving death callbacks, and accepts a dead-corpse despawn as a death. A living
attacker or an unconfirmed disappearance never awards progress. Its stationary
AI clears combat/evade state without resetting the event or starting home movement.

The event Korven takes the initiating player's faction and spawns eight yards
from the tower, away from the static Korven (66774). The static world NPC remains
in place. Attacker spawn positions use collision checks at twelve yards. Tests
cover missing death callbacks, corpse-first cleanup, live attackers, faction and
between-wave evade. Navigation and the full encounter still require a live test.

## Crash when starting the event

The tower's collision-position lookup calls `PathGenerator::CalculatePath` with
a GameObject owner. With navigation loaded, it dereferenced `ToUnit()` when
checking `VisualizePathfinding`, even though that pointer is null for GameObjects.
The check now requires a Unit owner. This is independent of debug log levels.

Run `python3 contrib/kypari_zar/run_path_test.py` for the production-method
regression under UndefinedBehaviorSanitizer. It covers a GameObject with loaded
navigation, missing navigation, invalid coordinates, and Unit owners with path
visualization disabled and enabled. Navigation internals are stubbed; a live
quest test still requires installing the rebuilt server and restarting it.
