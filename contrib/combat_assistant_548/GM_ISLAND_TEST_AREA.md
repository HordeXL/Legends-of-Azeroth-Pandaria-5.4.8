# GM Island rotation test area

The world update `2026_09_08_01_world_gm_island_rotation_test_dummies.sql`
adds eight level-90 Training Dummies on GM Island (map 1, area 876).
It uses entry 70245, which is attackable, has substantial health and uses
`npc_training_dummy`. No shared creature templates or existing spawns change.

| GM command | Station | Spawn GUIDs |
| --- | --- | --- |
| `.tele GMTest4` | Four dummies in a 4-yard square, for Seed/AoE | 4000110–4000113 |
| `.tele GMTest1` | One isolated dummy, for single-target rotation | 4000114 |
| `.tele GMTest3` | Three dummies in a compact triangle, for multidot | 4000115–4000117 |

The stations are over 70 yards apart. The existing GM Island raid dummy is
over 25 yards from the nearest new dummy. Heights were sampled from the
server's extracted terrain; the cells have no terrain holes. Teleports put
the player in front of each station, facing its targets.

The update inserts only missing reserved GUIDs and teleport names, so it can
run again without duplicating the area. A pre-existing conflicting GUID/name
must be investigated, not overwritten. Normal server startup loads the new
spawns and teleports; updating the database alone does not hot-load spawns
into a running worldserver.

For an Affliction test, enable `/combatlog`, manually engage every dummy in
the chosen station, then use the assistant. Four engaged dummies enable Seed;
three exercise multidot; one exercises the single-target priority. Keep the
same gear, talents and pet between comparisons. Stop logging after each run.
The normal training-dummy AI prevents lethal damage and resets after combat;
this area does not add a forced execute phase or change raid mechanics.
