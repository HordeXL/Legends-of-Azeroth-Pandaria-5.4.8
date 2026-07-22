-- Fix the Plump Virmen aggro TALK action so that the Virmen, rather than its
-- current victim, owns and sends creature_text group 0.
--
-- The old Wandering Isle import used target_type 2 (victim) even though entry
-- 55483 owns the four authentic text rows.  When a Dai-Lo Farmer is attacked,
-- that mistake asks CreatureTextMgr for group 0 on entries 56241/65473.
-- No creature_text row is added, replaced or deleted.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_plump_virmen_talk_20260722`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_plump_virmen_talk_20260722`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`source_type` = 0
  AND `s`.`entryorguid` IN
      (55483, -562577, -562655, -562663, -562695, -562724,
       -563630, -563644, -563645, -563646, -563647, -563648)
  AND `s`.`event_type` = 4
  AND `s`.`action_type` = 1
  AND `s`.`action_param1` = 0
  AND `s`.`target_type` = 2
  AND `s`.`target_param1` = 0
  AND `s`.`comment` = 'Plump Virmen - On Aggro - Say Text Line 0';

START TRANSACTION;

SET @plump_virmen_backup_ok :=
(
    SELECT COUNT(*) = 12
    FROM `_backup_smart_scripts_plump_virmen_talk_20260722`
);

SET @plump_virmen_text_ok :=
(
    SELECT COUNT(*) = 4
       AND MIN(`GroupID`) = 0
       AND MAX(`GroupID`) = 0
    FROM `creature_text`
    WHERE `CreatureID` = 55483
);

UPDATE `smart_scripts`
SET `target_type` = 1
WHERE @plump_virmen_backup_ok = 1
  AND @plump_virmen_text_ok = 1
  AND `source_type` = 0
  AND `entryorguid` IN
      (55483, -562577, -562655, -562663, -562695, -562724,
       -563630, -563644, -563645, -563646, -563647, -563648)
  AND `event_type` = 4
  AND `action_type` = 1
  AND `action_param1` = 0
  AND `target_type` = 2
  AND `target_param1` = 0
  AND `comment` = 'Plump Virmen - On Aggro - Say Text Line 0';

COMMIT;
