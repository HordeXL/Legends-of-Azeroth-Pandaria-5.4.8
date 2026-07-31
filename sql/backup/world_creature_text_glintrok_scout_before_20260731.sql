-- Roll back 2026_07_31_00_world_restore_glintrok_scout_emote.sql.
-- The verified pre-change state had no creature_text row for entry 64243.
-- Remove only the exact source-backed row inserted by that migration.

START TRANSACTION;

DELETE FROM `creature_text`
WHERE `CreatureID` = 64243
  AND `GroupID` = 0
  AND `ID` = 0
  AND `Text` = 'A Saurok runs down a hidden set of stairs with some of the treasure!'
  AND `Type` = 41
  AND `Language` = 0
  AND `Probability` = 100
  AND `Emote` = 0
  AND `Duration` = 0
  AND `Sound` = 0
  AND `SoundType` = 0
  AND `BroadcastTextId` = 64421
  AND `TextRange` = 0
  AND `comment` = 'Glintrok Scout - treasure escape emote';

COMMIT;
