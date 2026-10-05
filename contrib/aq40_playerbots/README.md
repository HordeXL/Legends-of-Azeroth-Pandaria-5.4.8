# AQ40 playerbot encounters

Automatic combat support for Twin Emperors (map 531). No chat
command, database migration, or strategy toggle is required. The new
worldserver binary must be installed and the service restarted.

The custom C'Thun planner is temporarily **disabled by default** following a
live `GetBaseMap(): m_currMap` assertion at 2026-09-21 21:46:50. Ordinary bot
combat runs instead; the boss balance adjustments remain. The old log has no
stack, so the exact caller and the connection to the planner are unconfirmed.
`Playerbots.AQ40.EnableCthunStrategy = true` is an explicit diagnostic opt-in,
not a verified crash fix. The planner details below describe that opt-in mode.
Linux assertion reports now include an invocation stack, and this map
assertion identifies the object's type, entry, GUID and map/instance IDs.
These reports are emitted only upon a fatal assertion.

## Twin Emperors

Both emperors remain on their original platforms: combat chase and the
periodic teleport/threat reset are disabled. Their health multipliers are
487.5, down from 650 (25% less health), via world update
`2026_09_21_03_world_twin_emperors_health.sql`.

All physical DPS goes to Vek'nilash; all magical DPS goes to Vek'lor. Tanks
and healers alternate platforms by GUID within their role. Dead players keep
their roster slot; the next living tank/caster on that side takes over
ownership. Assemble the raid before pulling, since leaving the map/group
changes the roster.

Use tanks, caster damage dealers and healers covering both platforms. The
first living tank on the melee side holds Vek'nilash. The first living caster
holds Vek'lor from range. Other casters throttle against that player's threat,
and physical DPS waits for its tank to pick up Vek'nilash. Standby tanks handle
nearby hostile mutated bugs. Pets stay away from Vek'lor. The planner does not
change threat or immunities.

Blizzard changes the assigned movement destination rather than alternating
between a dodge and the same unsafe position. Human players still need to
respect the two platforms and their assigned roles.

## C'Thun

The first Green Beam after a pull waits 20 seconds to let the initially
clustered raid spread. Subsequent beams and later green phases retain their
three-second timer. This opening grace period also applies to human raids.
Green Beam (26134), also used by giant eye tentacles, hits at most four
targets and gains 25% damage per jump. Clustering still increases damage,
but the chain cannot escalate through the entire raid. Dark Glare rotation,
tentacle spawns, and the stomach/vulnerability cycle retain their mechanics.

Boss and tentacle damage dealt to players is additionally halved and capped
at 35% of the victim's maximum health per hit, through all seven encounter
AI damage hooks. Small hits are never increased. This also covers Dark Glare:
one hit cannot kill a full-health player, but three capped hits without healing
are lethal. Simultaneous attacks and self-cast stomach effects are not a
global damage-per-second limit. This balancing is active with the custom bot
planner disabled. Run `python3 contrib/aq40_playerbots/run_damage_tests.py`.

Ranged/healer slots use staggered 30/44-yard rings, with more than ten yards
between all 40 slots even with a 0.5-yard arrival error on both players. During the
eye phase melee/tanks hold these slots and respond individually to nearby
tentacles; they do not pile onto the eye. A crowded tentacle approach yields
to ranged damage. Melee uses normal boss reach during body vulnerability.
Nearby eye tentacles take priority over claws and the eye. Dark Glare
interrupts attacks/casts in its danger sector and uses short moves around
the eye instead of a line through the boss. Emergency destination changes
replace any pending formation movement without waiting for its movement timer.

During transition, bots hold their positions. During the armoured body phase
they clear tentacles; during the weakened phase they prioritize the body.
Swallowed bots select flesh tentacles and approach from the north to avoid
accidentally touching the exit. At eight Digestive Acid stacks, below 35%
health, or with no flesh tentacles left, they move to the scripted exit pad.
The boss script performs the exit (checked every four seconds); the bot
strategy never teleports players or removes acid.

Generic assist, chase, follow, tank rescue/facing and mana-totem movement yield
to the encounter planner. Automatic distance/invalid-floor catch-up teleports
are suppressed during these encounters, including the stomach. Friendly healing continues once the bot is in
position. Outside these active encounters, ordinary bot behaviour resumes.

## Validation

Run from the repository root:

```sh
python3 contrib/aq40_playerbots/run_tests.py
cmake -S . -B build
cmake --build build --target worldserver -j 4
```

The standalone tests cover spread geometry, glare angle wraparound, acid
thresholds and production planner decisions in a simulated world (including
fixed-platform role assignments, tank pickup, reset, stomach and vulnerability phases).
They do not execute spell effects, server navigation, the live healing engine
or a real raid. In-game acceptance still requires both full encounters,
including both beam directions, tank/caster deaths,
stomach entry/exit and a wipe followed by another pull.
