# Observed PvE loadout and rotation corrections (2026-09-08)

The September 8 LFR comparison found unequal base weapon levels, healing-only
proc trinkets on caster DPS, Shadow/Ret healing detours, and no Windwalker
Fists of Fury or Tigereye Brew casts in the observed window. Absence from that
window is not, by itself, proof that every cast was blocked.

## Changes

- Managed level-90 genuine PvE equipment uses a base weapon floor of 559 (before
  upgrades), or the existing armor-relative floor if higher. Both selection paths
  and the check that retains existing equipment use it. Main hand, off-hand and
  shields remain specialization-checked; stronger valid equipment is retained.
  Armor/jewelry minimums are not raised. Lower levels and PvP do not receive 559.
- Trinket inspection recognizes script-driven healing proc IDs shared across
  difficulty variants, plus triggered Spirit buffs. Existing role, passive-only,
  and primary-stat checks still apply. This repairs affected equipment during
  the next managed preparation, not through an offline blanket inventory edit.
- Generic healing actions check the DPS role before form prerequisites and again
  at execution. Group PvE DPS only rescue a living party member below 20% HP in
  combat when no living healer is in the same map. Expel Harm remains available
  as a self-targeted Chi generator. Tank/healer roles, solo and PvP are unchanged.
- Windwalker avoids repeatedly buying an already-active Tiger Power, and reserves
  Chi for a learned, ready, area-safe Fists of Fury. Free Combo Breakers remain
  usable. Tigereye Brew distinguishes saved stacks (125195) from its active
  damage buff (116740), spending at ten stacks in combat. PvP keeps old conditions.
- PvE Agony uses the same eight-second lifetime threshold as the other basic
  DoT triggers instead of twenty seconds. PvP retains twenty seconds dynamically.
  Existing target, ownership and area/pull safety checks remain in place.

## Verification and limits

Run `contrib/playerbot_auto_queue_548/test_pve_loadout_observed.ps1` from an x64
Visual Studio developer shell. It compiles the production equipment policy and
exact-body mocks of the eight modified action/trigger bodies, rejecting stale
copies. Also run the druid-role, LFR-observed, pet-pull and PvE-rotation suites,
and build the worldserver RelWithDebInfo target.

These checks do not simulate a live raid or establish equal class DPS. Weapon
upgrades, cloak procs, set bonuses, target lifetime and fight mechanics can still
produce differences. The next live test should requeue the bots, inspect both
hands and trinkets, then log a sustained single-target fight and a tank-collected
pack. Check FoF/Brew usage and whether Shadow/Ret retain their DPS role. Do not
start the server automatically while the user controls its visible session.
