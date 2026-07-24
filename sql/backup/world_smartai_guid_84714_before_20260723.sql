-- Backup captured before 2026-07-23 cleanup of incorrectly assigned SmartAI.
--
-- Creature GUID 84714 is entry 23696 (Gordok Brew Chief), but these rows
-- describe entry 23698 (Drunken Brewfest Reveler). Run this file only to
-- restore the exact pre-fix state.

DELETE FROM `smart_scripts`
WHERE `entryorguid` = -84714
  AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
 `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
 `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`,
 `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`,
 `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
 `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-84714, 0, 0, 0, 1, 0, 100, 0, 10000, 45000, 180000, 240000, 0,
 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 'Drunken Brewfest Reveler - Out of Combat - Say Line 1 (random)'),
(-84714, 0, 1, 0, 1, 0, 100, 0, 10000, 45000, 180000, 240000, 0,
 11, 67468, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 'Drunken Brewfest Reveler - Out of Combat - Cast Drunken Vomit');
