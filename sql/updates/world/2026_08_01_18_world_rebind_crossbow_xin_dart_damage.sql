-- Build 18414 defines 120124 as a self-targeted 20% heal. It cannot execute
-- spell_crossbow_xin's area-target hook and is used by world NPC SmartAI as a
-- healing spell.
--
-- The encounter source names SPELL_DART_DAMAGE as 120142, validates that
-- exact spell in spell_crossbow_xin, and Build 18414 defines its effect 0 with
-- TARGET_UNIT_SRC_AREA_ENEMY (15), exactly matching the script hook. Move only
-- this script association; preserve both spells and all SmartAI data.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 120124
  AND `ScriptName` = 'spell_crossbow_xin';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(120142, 'spell_crossbow_xin');
