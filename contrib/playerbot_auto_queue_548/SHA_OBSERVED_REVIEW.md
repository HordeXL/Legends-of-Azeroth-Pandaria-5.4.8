# Sha test observations, 2026-09-09

The requester confirmed GM mode was enabled. The combat sample is not a
baseline for ordinary threat, targeting, damage taken or complete raid
participation. Do not change pull behavior based on that sample alone.

Three code-backed issues were addressed:

- `Server.log` contained 182 `Item::RemoveFromUpdate - owner not found`
  messages for 11 staged bots, mainly during summons and five during cleanup.
  `Player::RemoveFromWorld` calls `Unit::RemoveFromWorld` before removing its
  inventory, so `FindPlayer` rejects the still-registered owner. Item update
  removal now uses `FindConnectedPlayer`, which retains access to its map
  through this lifecycle transition. Actual missing-owner/map errors remain
  reported; the log category is not suppressed.
- Affliction's secondary-target scan could choose a hostile group member
  under Sha's faction-changing Aggressive Behavior. It now excludes members
  and their pets, vetoes Seed near hostile members, and rejects a selected
  group member as an automatic damage target. This is an assistant restriction,
  not a change to encounter mechanics, manual casts or existing debuffs.
- Corent cast Aspect of the Iron Hawk 124 times during the boss window,
  although its aura was applied only once. Spell lookup upgrades the legacy
  Hawk action name, but generic aura lookup matches the old name literally.
  The Hawk action now checks the desired aura ID, preventing repeated casts
  while still allowing initial application, replacement and reapplication.

Observed participation: 17 bots damaged the boss; Gordon, Renataris and Gerna
provided healing without boss damage. Corent only repeated the aspect;
Teranie had no cast, Helaina only applied Deadly Poison, and Therek only cast
Commanding Shout twice. These last three require a new GM-off observation;
no unverified forced-attack behavior was added.

Validation: 134 Affliction policy checks; 132 Hunter checks compiling the
actual action method with spell/aura availability stubbed; full server build.
The Hunter test is `test_hunter_aspect.ps1` (VS x64 developer environment).
Repeat staged-bot summon/cleanup and combat with GM off to confirm runtime
logs and behavior. Neither isolated test claims an in-game DPS improvement.
