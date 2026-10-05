# AQ40 quest audit — 2026-09-22

Scope: the 52 quests started or completed by the six quest NPCs in Temple of
Ahn'Qiraj (map 531), including the C'Thun follow-up completed at Anachronos.
This includes 45 class armor quests, 234 objectives and 85 item templates.
AQ20-only quests that share the same database category were excluded.

## Repairs

1. `Player::ItemAddedQuestCheck` returned after updating the first matching quest.
   Several AQ40 armor quests require the same scarabs/idols, so subsequent quests
   did not receive progress. It now continues through the active quest log.
2. `Player::ReputationChangedQuestCheck` skipped occupied quest slots instead of
   empty slots. It now processes active quests and only reacts to the faction
   belonging to each reputation objective. This handles reaching or losing the
   Neutral/Friendly/Honored requirements for Brood of Nozdormu without treating
   unrelated faction changes as failures.
3. Quests 8789 and 8790 had no `quest_template_addon` rows and were therefore
   treated as non-repeatable. The SQL migration adds the repeatable bit while
   preserving other settings. The correction was applied to the configured
   world database, read back and checked for idempotence.

Repeatability references: [Imperial Qiraji Armaments](https://www.wowhead.com/tbc/quest=8789/imperial-qiraji-armaments)
and [Imperial Qiraji Regalia](https://www.wowhead.com/mop-classic/quest=8790/imperial-qiraji-regalia).
The local `Quest::IsRepeatable` implementation uses `SpecialFlags & 1`.

## Validation

- All 52 quests have a valid starter (NPC or item) and turn-in NPC.
- NPC questgiver flags, map/spawn masks and phase masks were checked, including
  Anachronos outside the raid.
- Required items and rewards exist; loot references were traversed from actual
  AQ40 creature and chest loot tables. All required raid items are obtainable.
  Elementium Ingot is intentionally external and has a Blackwing Technician
  loot source in Blackwing Lair.
- Class restrictions, item objective indices, reputation thresholds, C'Thun's
  prerequisite/follow-up links and source-item counts passed the audit.
- The repeatable Mortal Champions/Secrets of the Qiraji settings were already
  correct. No disabling entries or additional acceptance conditions were found.
- The existing Andorgos gossip script remains attached. It handles teleport
  selections and leaves ordinary quest interaction to the core.
- Regression tests reproduce the shared-item failure before the patch and pass
  afterward. They cover shared item counts/caps, unrelated items, empty slots,
  reputation gains/losses, unrelated factions, and maximum-reputation objectives.
- The `worldserver` target built successfully after the repairs.

These are database, code and simulated regression checks, not an in-game
completion run of every quest. Existing characters' quest history and inventory
were not modified. Previously saved item counters were not migrated.

## Reproduce

```bash
python3 contrib/aq40_quests/capture_snapshot.py
python3 contrib/aq40_quests/audit.py contrib/aq40_quests/snapshot.json
python3 contrib/aq40_quests/run_tests.py
```

The capture reads the database connection from `/usr/local/etc/worldserver.conf`.
It queries only world data, never accounts or characters. The checked snapshot
reflects the database after the repeatable-quest repair.

## Activation

The SQL correction is saved in the database. The core fixes are in
`build/src/server/worldserver/worldserver`, but automated installation was denied
because sudo requires a password. From the repository root, run:

```bash
cd build
sudo make install
sudo systemctl restart mop-world.service
```

After startup, test two armor quests sharing scarabs, cross a Brood reputation
threshold, repeat each Imperial Qiraji weapon quest, and complete the C'Thun
follow-up at Anachronos. Bring three Elementium Ingots for each weapon turn-in.
