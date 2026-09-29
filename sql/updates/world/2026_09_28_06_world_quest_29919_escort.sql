-- Quest 29919 "Great Minds Drink Alike" (英雄所喝略同): escort completion fix
--
-- Design (matches official POI single-point route):
--   Giver: Chen 56133 (static, at the brewery entrance) -> Ender: Mudmug 56474 ~16yd away.
--   On quest accept: Chen & Li Li walk the short distance to Mudmug, the accepting player
--   receives kill-credit 56571 (escort objective), then they walk back to their posts.
--
-- Root cause: creature 56133 SAI had no ACCEPTED_QUEST hook for 29919 -> nothing ever
-- granted credit 56571 (no spawns of it exist), quest stuck at 0/1 forever.
--
-- SAI chain (Chen 56133):
--   ACCEPTED_QUEST(29919) -> SET_RUN -> MOVE_TO_POS(next to Mudmug, pointId 2991901)
--   -> MOVEMENTINFORM(pointId) -> CALL_KILLEDMONSTER(56571) to quest invoker
--   -> timed 4s -> MOVE_TO_POS back home (pointId 2991902)
-- Li Li 56138 walks along symmetrically (no credit).

-- ============ Chen 56133 (entry-level rows id 0-5 already exist, append 6-10) ============
DELETE FROM smart_scripts WHERE source_type=0 AND entryorguid=56133 AND id BETWEEN 6 AND 10;
INSERT INTO smart_scripts (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_x, target_y, target_z, target_o, comment) VALUES
(56133, 0, 6, 7, 19, 0, 100, 0, 29919, 0, 0, 0, 59, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Chen - Quest Accepted 29919 - Set Run'),
(56133, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 69, 2991901, 0, 0, 0, 0, 0, 0, 0, 0, 0, -699.5, 1270.5, 136.0, 0, 'Chen - Link - Walk To Mudmug (escort)'),
(56133, 0, 8, 9, 34, 0, 100, 0, 8, 2991901, 0, 0, 33, 56571, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached Mudmug - Quest Credit 56571 To Invoker'),
(56133, 0, 9, 0, 61, 0, 100, 0, 0, 0, 0, 0, 67, 2991903, 4000, 4000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Chen - Link - Create Timed 2991903 (Stay 4s)'),
(56133, 0, 10, 0, 59, 0, 100, 0, 2991903, 0, 0, 0, 69, 2991902, 0, 0, 0, 0, 0, 0, 0, 0, 0, -709.307, 1264.69, 136.107, 0, 'Chen - Timed 2991903 - Walk Back Home');

-- ============ Li Li 56138 (entry-level, no rows existed, append 0-3) ============
DELETE FROM smart_scripts WHERE source_type=0 AND entryorguid=56138 AND id BETWEEN 0 AND 3;
INSERT INTO smart_scripts (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_x, target_y, target_z, target_o, comment) VALUES
(56138, 0, 0, 1, 19, 0, 100, 0, 29919, 0, 0, 0, 59, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Li Li - Quest Accepted 29919 - Set Run'),
(56138, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 69, 2991901, 0, 0, 0, 0, 0, 0, 0, 0, 0, -698.0, 1269.0, 136.0, 0, 'Li Li - Link - Walk To Mudmug (escort)'),
(56138, 0, 2, 0, 34, 0, 100, 0, 8, 2991901, 0, 0, 67, 2991904, 4500, 4500, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Li Li - Reached Mudmug - Create Timed 2991904 (Stay 4.5s)'),
(56138, 0, 3, 0, 59, 0, 100, 0, 2991904, 0, 0, 0, 69, 2991902, 0, 0, 0, 0, 0, 0, 0, 0, 0, -695.818, 1253.36, 136.024, 0, 'Li Li - Timed 2991904 - Walk Back Home');
