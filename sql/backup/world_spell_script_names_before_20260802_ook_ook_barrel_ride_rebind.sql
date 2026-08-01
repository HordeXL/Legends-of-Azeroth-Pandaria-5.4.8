-- Exact rollback for the Ook-Ook Barrel Ride association moved by
-- 2026_08_02_00_world_rebind_ook_ook_barrel_ride.sql.
--
-- The inherited row binds spell_ook_ook_barrel_ride to non-aura spell 122169.
-- Restoring it will also restore both startup AuraScript hook mismatches.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 106614
  AND `ScriptName` = 'spell_ook_ook_barrel_ride';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(122169, 'spell_ook_ook_barrel_ride');
