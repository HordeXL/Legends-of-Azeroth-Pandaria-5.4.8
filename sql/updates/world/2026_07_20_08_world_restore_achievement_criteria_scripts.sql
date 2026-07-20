-- Restore the script names for four 5.4.8 dungeon achievement criteria.
-- The matching C++ AchievementCriteriaScript implementations are registered
-- in the corresponding boss scripts. No rows are deleted or inserted.

START TRANSACTION;

UPDATE `achievement_criteria_data`
SET `ScriptName` = CASE `criteria_id`
    WHEN 7231  THEN 'achievement_on_the_rocks'
    WHEN 7321  THEN 'achievement_shatter_resistant'
    WHEN 16081 THEN 'achievement_pardon_denied'
    WHEN 16848 THEN 'achievement_ohganot_so_fast'
END
WHERE `criteria_id` IN (7231, 7321, 16081, 16848)
  AND `type` = 11
  AND `value1` = 0
  AND `value2` = 0
  AND `ScriptName` = '';

COMMIT;
