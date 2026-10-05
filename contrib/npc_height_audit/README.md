# NPC height audit — 2026-09-24

Read-only inspection of 315,294 saved creature spawns using the server's
GridMap and VMapManager2 implementations and installed map/vmap data.
No creature positions or scripts were changed by this audit.

## Results

- 28,071 positions were more than 1 yard below the base terrain surface.
- 22,281 of those had a static vmap surface within 5 yards below their saved
  position. Underground rooms and caves make terrain-only comparisons unsafe.
- 13,569 spawns with known templates had no usable terrain height. These
  were excluded, not counted as correctly positioned.
- 13 spawn records referenced absent creature templates; see
  `missing_templates.tsv`. This is separate from elevation.
- The interactive-NPC review filter produced 75 candidates (61 templates),
  including 31 event-linked spawns. These are **not 75 confirmed bugs**.
- 106 templates have both a C++ script binding and SmartAI events. See
  `script_overlap.tsv`. C++ takes priority, but many such bindings are
  intentional replacements; overlap alone is not a reason to remove them.

## Examples requiring review

| Spawn GUID | NPC | Map | Below base terrain (yards) | Context |
| --- | --- | --- | --- | --- |
| 125602 | Warlord Gorchuk | 1 | 16.92 | Event 22 |
| 124544 | Stoneguard Clayhoof | 1 | 13.65 | Event 22 |
| 108999 | Earthen Ring Emissary | 1 | 7.27 | Event 48 |
| 104403 | Earthmender Norsala | 1 | 6.49 | Event 48 |
| 580270 | Jorn Skyseer | 870 | 10.49 | Phase mask 4 |

The Orgrimmar event cluster is suspicious against the installed terrain.
Check event activation and intended locations in-game before relocating it.
Jorn Skyseer's phase and nearby geometry need in-game inspection. Large
underwater differences, especially in Vashj'ir, do not establish a bad spawn.

The initial Colossal Guardians repair addressed an activation-script conflict.
A subsequent runtime crash disproved the assumption that their lower vehicle
base positions were safe: on a saved respawn, the Sun base's terrain-only height
lookup returned -200000, causing InstallAccessory to assert when creating 46041.
Migration 2026_09_24_06 raises the two bases to their authored landing heights.
The earlier vehicle exclusion therefore missed a confirmed fault. Caimas was
also reviewed: its C++ script supplies its own movement and jump, so its
SmartAI overlap does not establish the same fault.

## Method and limits

`interactive_candidates.tsv` retains spawns whose base terrain is more than
1 yard above their saved Z, without a vmap hit within 5 yards below Z, with
gossip or questgiver flags (spawn override, otherwise template), and without
template flight or vehicle configuration. The selection has no upper gap
limit. This prioritizes interactive NPCs; it does not exhaust all possible
bad creature positions or summoned NPCs.

Static vmap rays start at Z+0.5 and Z+15, with ranges of 200 and 215 yards.
The second ray may hit a roof rather than a floor. Neither ray models
dynamic objects, transports, phase-specific terrain selection, or runtime
script movement. Terrain holes and missing collision data can produce false
positives. `vmap_status` is the native tile-load result, not a correctness
verdict. Sentinel heights below -10000 are unavailable data.

No in-game visual verification was performed. Do not turn this candidate
list into an unconditional height update.

## Reproduce the geometry scan

From the repository root, with the existing server build available:

```sh
python3 contrib/npc_height_audit/build_scan.py
mariadb --defaults-extra-file=/path/to/private-db.cnf -N -e 'SELECT guid,id,map,position_x,position_y,position_z FROM creature ORDER BY map,FLOOR(32-position_x/533.33333333),FLOOR(32-position_y/533.33333333),guid;' > /tmp/npc-height-spawns.tsv
/tmp/scan_spawn_heights '/home/server/World of Warcraft 5.4.8' /tmp/npc-height-spawns.tsv > /tmp/npc-height-results.tsv
```

The helper uses existing build libraries, writes results to stdout, and
does not connect to or modify the running world server. The build script
assumes the library layout of this checkout and writes its binary/log to
`/tmp`. Join the geometry results with creature/template flags and event
bindings before interpreting them.
