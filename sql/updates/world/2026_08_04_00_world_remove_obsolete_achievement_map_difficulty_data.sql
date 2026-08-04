-- Achievement criteria data type 12 (MAP_DIFFICULTY) was retired when the
-- same requirement moved to the client DBC additional-condition fields.
-- SkyFire upstream removed both the handler and all type-12 database rows in
-- commit 0dcd42675454e43c7d8ebc086d0b9cc95da41fd4.
--
-- Limit this migration to the exact 17 inherited rows present in this 5.4.8
-- database. Other achievement criteria data and scripted checks are retained.

DELETE FROM `achievement_criteria_data`
WHERE `type` = 12
  AND `value1` = 1
  AND `value2` = 0
  AND `ScriptName` = ''
  AND `criteria_id` IN
      (6803, 7315, 7318, 7319, 7320, 7361, 7363, 7579, 7583,
       7587, 7590, 7593, 7598, 11789, 12752, 12976, 12993);
