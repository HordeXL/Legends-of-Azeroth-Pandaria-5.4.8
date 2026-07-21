-- Roll back 2026_07_21_01_world_restore_meridith_creature_text.sql.
-- The exact pre-change state had no creature_text row for Meridith. Remove
-- only the exact row inserted by that migration; no other text is affected.

START TRANSACTION;

DELETE FROM `creature_text`
WHERE `CreatureID` = 15526
  AND `GroupID` = 0
  AND `ID` = 0
  AND `Text` = 'Lovely song, isn''t it?'
  AND `Type` = 12
  AND `Language` = 0
  AND `Probability` = 100
  AND `Emote` = 0
  AND `Duration` = 0
  AND `Sound` = 0
  AND `SoundType` = 0
  AND `BroadcastTextId` = 11089
  AND `TextRange` = 0
  AND `comment` = 'Meridith the Mermaiden';

COMMIT;
