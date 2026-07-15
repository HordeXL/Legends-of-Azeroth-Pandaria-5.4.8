-- Remove an invalid duplicate Shoeshine Seat controller keyed as missing GO
-- template 96036. The real GO template is 194115 and retains its equivalent
-- controller/timed list 19411500. Creature spawn GUID 96036 is Sheddle.

START TRANSACTION;

SET @shoeshine_correct_controller := (
  SELECT COUNT(*) FROM `smart_scripts`
  WHERE `entryorguid` = 194115 AND `source_type` = 1
    AND `id` = 0 AND `event_type` = 64
    AND `action_type` = 80 AND `action_param1` = 19411500
);
SET @shoeshine_correct_template := (
  SELECT COUNT(*) FROM `gameobject_template`
  WHERE `entry` = 194115 AND `name` = 'Shoeshine Seat'
);
SET @shoeshine_correct_spawn := (
  SELECT COUNT(*) FROM `gameobject` WHERE `id` = 194115
);

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 96036
  AND `source_type` = 1
  AND `id` = 0
  AND `event_type` = 64
  AND `action_type` = 80
  AND `action_param1` = 9603600
  AND `comment` = 'Shoeshine Seat - On Gossip hello - Action list'
  AND @shoeshine_correct_controller = 1
  AND @shoeshine_correct_template = 1
  AND @shoeshine_correct_spawn > 0;

SET @shoeshine_old_list_callers := (
  SELECT COUNT(*) FROM `smart_scripts`
  WHERE `action_type` = 80 AND `action_param1` = 9603600
);
SET @shoeshine_correct_list_rows := (
  SELECT COUNT(*) FROM `smart_scripts`
  WHERE `entryorguid` = 19411500 AND `source_type` = 9
);

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 9603600
  AND `source_type` = 9
  AND `id` IN (0,1,2)
  AND `comment` LIKE 'Shoeshine Seat - Action list - %'
  AND @shoeshine_old_list_callers = 0
  AND @shoeshine_correct_list_rows = 3;

COMMIT;
