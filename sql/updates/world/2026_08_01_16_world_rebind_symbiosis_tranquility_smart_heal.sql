-- Tranquility (Symbiosis) 113277 is the periodic parent aura and has no raid
-- area heal target. It natively triggers 113278, whose two healing effects
-- use TARGET_UNIT_SRC_AREA_ALLY and are the spell named by the C++ smart-heal
-- implementation. Move only the script association to the triggered heal.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 113277
  AND `ScriptName` = 'spell_common_smart_heal_raid_25';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(113278, 'spell_common_smart_heal_raid_25');
