# Diamond-marked PvE main tank

Place the purple diamond raid marker on the player or bot who should control
taunts. The server uses raid icon index 2 (the third icon in the client).
The marker is a manual choice; this does not replace the Boss Caller's existing
square marker automatically.

- The marked member must have a tank specialization and be in the same active
  group and map. A marker on an NPC, DPS, healer, disconnected member, or member
  on another map does not designate a main tank.
- While that tank is alive, only that tank's bot AI may cast taunts. Other tank
  bots continue their ordinary attacks and defensive abilities, without single
  or mass taunts, even if an enemy is currently attacking a healer or DPS.
- When the marked tank dies, other tank bots may taunt immediately. When the
  marked tank revives, or the diamond moves to another living tank, the restriction
  is checked again. A backup warrior's active Mocking Banner aura is also removed
  on its next AI update so it stops issuing periodic taunts.
- Without a valid diamond, the existing single-target rescue policy remains:
  bots avoid taunting an enemy already attacking another living group tank.
- The policy covers direct taunt effects, triggered effects, Mocking Banner and
  script-triggered Death Grip/Provoke, at action selection and both final AI cast paths.
  Battleground and arena behavior is unchanged. Real players' manual casts are
  not restricted.

This is taunt coordination, not a threat multiplier adjustment. An off-tank can
still gain aggro through ordinary damage. It does not implement encounter-specific
tank swaps: move the diamond when a living main tank needs to hand over the boss.
Moving the marker does not erase threat or immediately cancel existing taunt
debuffs on enemies.

## Verification (2026-09-08)

- Full RelWithDebInfo worldserver build: succeeded, 0 compiler warnings/errors.
- An isolated C++ harness using the three production function bodies passed 34
  checks: taunt detection, scripted/triggered taunts, live/dead/revived main tank,
  marker changes, invalid markers, self-targeted mass taunts, instance-group
  priority, non-tanks, normal damage, PvP bypass and bounded trigger recursion.
- This is not an in-game raid test. Verify with two tanks: mark the real tank,
  pull a pack, confirm the backup has no Taunt/Mocking Banner casts; then verify
  death takeover and revival/marker transfer. Check the combat log rather than
  assuming that all aggro changes are caused by taunts.
