# PvE damage druid role protection

Observed on 2026-09-08: Balance Carius cancelled Moonkin Form to cast
Rejuvenation on multiple raid members between pulls. The shared non-combat
druid strategy requests party heals even for nearly full-health members.

## Behaviour

- Group PvE Balance and Feral party healing is restricted at action selection
  (before caster-form prerequisites) and rechecked at execution.
- A rescue heal is allowed only for a living, in-world member of the active
  group, on the same map, in combat and below 20% health, with no living,
  in-world healer on that map. A healer's short interruption is not treated as
  absence. The existing spell, range, mana and healing-target checks remain.
- Rejuvenation, Regrowth, Healing Touch, Lifebloom, Wild Growth, Swiftmend,
  Nourish and the alternate non-full-health Rejuvenation path use this guard.
- Restoration, Guardian, solo and PvP behaviour is unchanged. Resurrection,
  dispelling, self-defensive abilities, Ironbark and Cenarion Ward are not
  disabled by this change.
- Balance restores its learned Moonkin Form in and out of combat. It does
  not reapply an active form or interrupt a spell, mount, flight, swimming or
  teleport. Emergency heals retain their higher priority.

## Verification

`contrib/playerbot_auto_queue_548/test_druid_role.ps1` compiles 37 isolated
checks of the exact production role/form function bodies with lightweight
server mocks and verifies all eight party-heal classes use the guard.
Run in an x64 Visual Studio developer environment. This is not a live LFR test.

Live follow-up: observe a Balance bot between pulls with living healers and
injured party members, then during the next pull. It should retain/restore
Moonkin Form and not start routine party Rejuvenation. Separately verify that
Restoration still heals. No DPS multiplier, rogue/warlock rotation or guardian
pet changes are included here.
