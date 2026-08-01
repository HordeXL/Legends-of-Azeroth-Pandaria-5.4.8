-- Exact rollback for 2026_08_01_16_world_rebind_symbiosis_tranquility_smart_heal.sql.
-- Restores the inherited parent-aura association and removes the corrected
-- triggered-heal association.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 113278
  AND `ScriptName` = 'spell_common_smart_heal_raid_25';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(113277, 'spell_common_smart_heal_raid_25');
