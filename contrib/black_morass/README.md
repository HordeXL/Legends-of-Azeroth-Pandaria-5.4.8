# Black Morass audit (normal and heroic)

Sa'at 20201 already had questgiver flags, his script, and starter/ender relations
for 10297. The quest was hidden behind 10296 and ultimately the old attunement.
Removing the dungeon entrance requirement did not remove this independent chain.
The SQL patch removes both the forward and backward prerequisite links for
10297 while keeping saved player progress, quest 10298 and existing relations.
Quest 29672 is flagged deprecated in this database and is not re-enabled.

Code changes:

- Beacon menus are cleared and requests re-check quest eligibility, distance and
  ownership (including bank inventory); completed quest holders may obtain one.
- Wipes/empty instances and Medivh death reset the event after ten seconds,
  remove tracked event summons, restore Medivh and start again at portal zero
  with 100 percent shield. Old timers are cleared. Failed portal/boss summons
  also fail the event rather than permanently stalling it.
- Duplicate starts preserve active timers. Late arrivals receive current shield
  and portal world states. No portal beyond 18 can be spawned by the scheduler.
- Aeonus completion awards the existing quest once and persists completed state
  across instance reloads. Unfinished runs load as not started.
- Boss resets clear spell timers. Deja, Temporus and Aeonus explicitly choose
  their existing heroic spell variants. Temporus casts Mortal Wound on his victim.

Validation: `python3 contrib/black_morass/run_tests.py` compiles extracted
production state transitions. It covers all 18 portals, boss slots 6/12/18,
duplicate starts, late joins, single completion credit, save/load, wipe and
shield failure, cleanup and retry. Full worldserver build uses `make -j16` in
`build`. Creature combat, client dialogue and both difficulty runs still need
live verification; this is not a claim that every encounter mechanic is complete.

Apply `sql/patches/world/2026_09_26_01_world_black_morass_quest.sql`, install the
rebuilt server and restart. The separate access patch continues to allow entry
without Return to Andormu on both difficulties.
