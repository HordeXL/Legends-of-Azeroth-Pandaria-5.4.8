# AQ40 guaranteed creature loot

Creature corpse loot generated on map 531 (Temple of Ahn'Qiraj) uses
`LootRollPolicy::AllDirectItems`. Every direct item and reference roll succeeds,
and every eligible item in a direct loot group is added.

References, including nested references, use `GuaranteedGroups`: each eligible
group selects one random item. Explicit-only groups have their weights normalized
to remove the empty outcome. Groups with equal-chance entries keep their existing
fallback selection. Reference multiplicities and item stack quantities stay as
configured in the database.

Loot-mode filtering, quest requirements, item conditions and group duplicate
filtering remain in effect. Other maps, game objects, pickpocketing, skinning and
item containers keep their existing behavior. There are no shared database edits.
The change applies when loot is generated, not to corpses already containing loot.

Run `python3 contrib/aq40_loot/run_tests.py` from the repository root. The test
compiles the production policy selection and processing methods against small
deterministic loot tables. It covers map/source isolation, direct groups, weighted
and equal-chance reference groups, tiny weights, nested and explicit-group
references, quest markers, duplicate filtering and loot-mode filtering.

After a successful `cmake --build build --target worldserver -j 12`, run
`sudo bash contrib/aq40_loot/deploy.sh`. The script retains a backup, installs the
new executable and restarts the world service, restoring the backup if a command
fails during activation. Check startup logs to confirm the world has finished
loading. Restore the printed backup path and restart to roll back later;
no database rollback is needed.
