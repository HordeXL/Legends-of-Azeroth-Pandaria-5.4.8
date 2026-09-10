# Celestial Court shared Boss Bot Caller

Grotroz (warlock, character GUID 2215) requested this placement on 2026-09-10.
Keep this captured location even if Grotroz subsequently moves:

| Field | Saved value |
| --- | ---: |
| Map | 870 |
| Zone / area | 6757 / 6830 |
| X | -750.005 |
| Y | -5016.65 |
| Z | -6.27724 |
| Orientation | 0.0679426 |
| Caller template / spawn GUID | 990912 / 4000118 |
| Boss search radius | 250 yards |

The coordinates came from the character's saved database position at the request.
The spawn migration is
`sql/updates/world/2026_09_10_00_world_celestial_court_shared_bot_caller.sql`.
It adds one shared caller and preserves the existing boss-specific callers.
Apply it together with the matching worldserver build; the old executable does
not understand the `boss_entry=0` automatic Celestial configuration. A server
restart loads the persistent creature spawn. The migration does not log in bots.

The caller scans Chi-Ji (71952), Xuen (71953), Niuzao (71954), and Yu'lon (71955).
It selects exactly one living, visible-phase, attackable boss with faction 31.
The corner bosses, the entrance introduction, friendly victory outro, and evade
are excluded from new Calls. Zero or multiple eligible bosses show a waiting
menu without Call/Preview. The local Shaohao script shuffles the rotation; no
fixed order is assumed. Existing fixed Celestial callers also reject inactive
bosses.

Call/Preview menus carry the displayed creature's GUID counter. If selection
changes before a click, the caller refreshes the menu and requires a new click.
Call 10/25 prepares the usual PvE raid and summons every bot on the requester's
known-valid ground position. Bots hold there while preparation buffs are cast,
then follow in one compact pack. They do not use roster-angle offsets or random
movement before the pull. The selected boss's first combat starts the persistent
rear-half combat formation; incidental targets cannot start or anchor that
formation. Wipe recovery returns the bots to the same compact preparation flow.
The coordinator retains the full selected creature GUID throughout the session,
including login, summon, combat, wipe recovery, and dismissal. It does not switch
an existing raid to the next boss. If that Celestial becomes unavailable during
assembly or rotates before combat is observed, the pending raid is dismissed.

The four local boss scripts handle lethal damage by changing to friendly faction
35, ending combat, and despawning 13 seconds later. After observing combat, the
caller recognizes that friendly state as victory and dismisses the raid after
10 seconds. The observed victory persists across despawn. A missing boss alone
is never victory; evade/wipe keeps faction 31 and permits the existing recovery.
Normal world bosses continue to use actual death. Rebuff, status, and dismissal
remain available between bosses. A new boss needs a fresh Call.

Run `test_celestial_caller.ps1` from an x64 Visual Studio Developer PowerShell.
It compiles the current production selector and lifecycle predicates against
controlled creature states, including all four rotation positions, duplicate
spawns, stale menus, nonlethal victory, despawn, and wipe.
Run `test_spawn_migration.ps1` to check the exact SQL against the local schema in
a disposable test database. It checks placement, reapplication, preservation,
and GUID collisions, then removes only that test database.

Validated and installed locally on 2026-09-10: 199 C++ regression checks and four
SQL checks passed; the RelWithDebInfo worldserver build completed with zero
warnings/errors. The executable and PDB were installed while worldserver was
stopped, and persistent spawn/configuration 4000118 was verified in the world
database. All 13 earlier caller configurations were preserved. The old binary
and an installation manifest are in
`Build/server-before-celestial-caller-20260910-091954/`.
The new spawn is available on the next normal worldserver start; live combat
validation has not been performed.

After installing and restarting, verify in game with Grotroz: open caller at the
saved spot, compare its active boss name with the arena, preview the pool, then
Call the desired raid size. Check a victory and a wipe separately; confirm that
the next boss requires a fresh Call. These live encounter checks require actual
gameplay and are separate from the automated regression/build checks.
