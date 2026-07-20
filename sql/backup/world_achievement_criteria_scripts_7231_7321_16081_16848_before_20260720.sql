-- Roll back 2026_07_20_08_world_restore_achievement_criteria_scripts.sql.
-- This restores only the four ScriptName values changed by that update.

START TRANSACTION;

UPDATE `achievement_criteria_data`
SET `ScriptName` = ''
WHERE (`criteria_id` = 7231  AND `type` = 11 AND `value1` = 0 AND `value2` = 0 AND `ScriptName` = 'achievement_on_the_rocks')
   OR (`criteria_id` = 7321  AND `type` = 11 AND `value1` = 0 AND `value2` = 0 AND `ScriptName` = 'achievement_shatter_resistant')
   OR (`criteria_id` = 16081 AND `type` = 11 AND `value1` = 0 AND `value2` = 0 AND `ScriptName` = 'achievement_pardon_denied')
   OR (`criteria_id` = 16848 AND `type` = 11 AND `value1` = 0 AND `value2` = 0 AND `ScriptName` = 'achievement_ohganot_so_fast');

COMMIT;
