# Group PvE shaman totem lifecycle

Applies to dungeon, raid and world-boss bot activities. PvP and solo behaviors
are not enabled by the new triggers.

- Registers the previously missing `no water totem` trigger. During combat an
  empty/destroyed water slot (or an ordinary totem more than 30 yards away)
  requests Healing Stream, with a learned Mana Spring as a fallback. Normal
  spell checks still enforce learning, resources and cooldowns. This is not a
  promise of uninterrupted Healing Stream uptime.
- Uses owned, living totem objects and created-by-spell IDs. Mana Tide (16190)
  and Healing Tide (108280) are protected even outside normal placement range
  and in the extra Totemic Persistence slot. Neither a regular water totem nor
  the other water cooldown may overwrite them. Once they expire or die, normal
  water placement becomes eligible again.
- Rechecks water replacement at execution, not just when selecting an action.
  Mana Tide also rechecks the group's need after its five-second announcement.
  Healing/mana totems no longer require a selected enemy estimated to live eight
  seconds; their usefulness is not determined by an enemy's lifetime.
- Adds noncombat Totemic Recall, using the learned spell and core refund logic.
  Recall waits for the bot, living loaded group members in the same map, and
  owned totems to leave combat. Active Mana/Healing Tide is preserved. Nearby
  injured members also retain Healing Stream/Spirit Link for recovery.
- Existing pull-safe Searing Totem triggers handle fire-totem re-placement in
  subsequent fights. This does not turn situational air/earth cooldowns into
  permanently maintained buffs, or enable obsolete legacy buff-totem triggers.

## Verification

`contrib/playerbot_auto_queue_548/test_shaman_totems.ps1` verifies registrations
and compiles exact-body mocks of ownership, slot, placement, recall and execution
guards (the runner rejects stale source copies). Run from an x64 VS developer
shell, then run the existing PvE/loadout, druid-role, LFR and pet-pull suites and
build `worldserver` RelWithDebInfo.

A live test is still required: finish one pull, observe recall after recovery,
start the next tank-controlled pull, and observe Searing/Healing Stream return
when available. During Mana Tide check that its full duration is retained and
Healing Stream only returns afterward when its own cooldown permits. The server
is deliberately not started by this change.
