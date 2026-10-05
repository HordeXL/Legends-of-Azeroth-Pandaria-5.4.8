-- Destroyed Sentinel is a stationary Energy Discharge hazard, not a mobile
-- combatant. Keep its existing respawn spell/aura and all unrelated flags.
START TRANSACTION;

UPDATE creature_template
SET unit_flags = unit_flags | 4
WHERE entry = 21761;

DELETE FROM smart_scripts
WHERE entryorguid = 21761 AND source_type = 0 AND id IN (1, 2, 3);

INSERT INTO smart_scripts
(entryorguid, source_type, id, link, event_type, event_phase_mask,
 event_chance, event_flags, event_param1, event_param2, event_param3,
 event_param4, action_type, action_param1, action_param2, action_param3,
 action_param4, action_param5, action_param6, target_type, target_param1,
 target_param2, target_param3, target_x, target_y, target_z, target_o, comment)
VALUES
(21761,0,1,0,25,0,100,0,0,0,0,0,8,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
 'Destroyed Sentinel - On Reset - Set Passive'),
(21761,0,2,0,25,0,100,0,0,0,0,0,20,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
 'Destroyed Sentinel - On Reset - Disable Auto Attack'),
(21761,0,3,0,25,0,100,0,0,0,0,0,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
 'Destroyed Sentinel - On Reset - Disable Combat Movement');

COMMIT;
