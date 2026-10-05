# The Poisoned Mind (31211)

Xaril 62151 had no boarding gossip/script. The Klaxxi Flyer templates had no
vehicle data or abilities, no route existed, and only one of the bombing target
entries had a permanent spawn anywhere on the map. Accepting the quest alone
could not start its flight.

Start outside the Amber Womb at Dread Wastes **28.7, 42.2**. Xaril at
Klaxxi'vess offers **Take me to the Amber Womb entrance** for active quest holders.
Talk to the Xaril there and select **I am ready to fly.** The private 63675 vehicle
uses existing vehicle 156 (control seat 0) and the original Venom Bomb 124201,
Paralyzing Serum 126308 and return action 124206. The AI retains control of the
flight while the passenger uses the vehicle abilities.

This is a reconstructed three-stop route west of the Amber Womb,
not a verified retail spline or dialogue scene. The route pauses for 20 seconds
at each stop and repeats. Each stop has 80 private mantid and one kunchong;
terrain heights are resolved from above the surface before spawning. Boarding
is followed by separate straight ascent, cruise and descent legs; smooth spline
overshoot and the previous fixed Z=100 descent are avoided. The bombing circuit
uses a common altitude at least 25 yards above sampled intervening terrain.
There is no fixed Z=700 ascent. Flight speed is now 6x base instead of 3x base,
with walking disabled. The original start spawns and their other quests remain.
Only actual kills grant objectives. Targets are assigned to the passenger for
normal kill rewards, with a death-callback fallback that fills missing objective
progress only after checking whether the core already credited it. Repeated
callbacks and kills by unrelated units do not grant extra credit. Boarding awards
only the talk objective. Existing kill progress is kept.

Completion, the return ability, manual exit, abandoning the quest, failed
boarding/summons/terrain checks, death, logout or a 20-minute timeout cleans up
the summons. Online living passengers return to their original boarding point
where Xaril accepts the turn-in. The original return-button tooltip refers to
Klaxxi'vess; this implementation returns to whichever Xaril started the flight.
No permanent bombing targets, phasing changes or debug logging are introduced.

Validation: `python3 contrib/poisoned_mind/run_tests.py` compiles the production
vehicle callbacks against a fixture. It checks deferred boarding, staged ascent,
above-surface target placement, target counts, circuit transitions, death-only
credit, duplicate/core-awarded credit, completion,
cancellation, cleanup and failed terrain/summons. This does not test client
vehicle UI, missile targeting, real terrain navigation or server kill credit;
these require a live playthrough after installation.

Apply `sql/patches/world/2026_09_25_11_world_poisoned_mind.sql`, build using
`make -j16` from `build`, install and restart worldserver. The migration also
appears at the end of the clean-install world archive.

[Quest description and objectives](https://www.wowhead.com/mop-classic/quest=31211/the-poisoned-mind).

## Verified outdoor route (2026-09-26)

The earlier centers near Y=4350 were inside/beneath the palace: two saved NPC
positions at Z=44.7 had vmap floors around 44.6 but terrain at Z=216–268. They
were not valid outdoor bombing anchors. Both questgiver spawns were at Klaxxi'vess.
The 63606 spawn at -93.3,4423.9 is also underground, not the cave entrance.

New centers: (-90,4650), (-160,4650), (-230,4650). Using the installed GridMap
and VMapManager2, all 243 targets have surface heights near Z=67.5–73.6;
the circuit flies at Z=98.6094, maximum shot distance 33.0275 yards, with zero
blocked static vmap sight lines. The boarding surface is Z=80.673. Both bomb
and serum have a 500-yard maximum range in the installed SpellRange.dbc.

Reproduce from the repository root:

```sh
python3 contrib/poisoned_mind/build_geometry.py
/tmp/xaril_geometry
python3 contrib/poisoned_mind/run_tests.py
```

The geometry tool uses the three authored centers and the installed data path;
update it alongside route changes. It validates static geometry, not the client
vehicle camera/UI or live missile behavior. Apply the additional migration
`sql/patches/world/2026_09_26_02_world_xaril_start.sql` before installing and
restarting the rebuilt server. The flight remains a reconstructed encounter.

Dark Skies (31216) uses the same tested route and vehicle as the introductory quest.
The vehicle keeps the selected quest and its own objective IDs for kill-credit
fallback and completion cleanup. SQL patch 2026_09_26_03 requires rewarded 31211
and removes the incorrect upper reputation cap. Pool 608 still rotates this daily
with Rampage Against the Machine; unlocking does not guarantee today's selection.
The regression fixture runs both quests, including cleanup and credit isolation.
