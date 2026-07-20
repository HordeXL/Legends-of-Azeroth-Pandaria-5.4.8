-- Exact rollback for game events 79 and 80 before the 2026-07-20 repair.
-- Restores the invalid DBC-stage request only when both corrected rows still
-- retain the complete original database schedules.

SET @corrected_count := (
    SELECT COUNT(*)
    FROM `game_event`
    WHERE (`eventEntry` = 79
           AND `start_time` = '2012-11-29 18:01:00'
           AND `end_time` = '2012-12-06 16:00:00'
           AND `occurence` = 60480
           AND `length` = 10080
           AND `holiday` = 442
           AND `holidayStage` = 0
           AND `description` = 'Rated Battleground 15x15'
           AND `world_event` = 0
           AND `announce` = 2
           AND `world_state` = 0
           AND `ScriptName` = '')
       OR (`eventEntry` = 80
           AND `start_time` = '2012-12-06 18:01:00'
           AND `end_time` = '2012-12-13 16:00:00'
           AND `occurence` = 60480
           AND `length` = 10080
           AND `holiday` = 443
           AND `holidayStage` = 0
           AND `description` = 'Rated Battleground 25x25'
           AND `world_event` = 0
           AND `announce` = 2
           AND `world_state` = 0
           AND `ScriptName` = '')
);

SET @old_count := (
    SELECT COUNT(*)
    FROM `game_event`
    WHERE (`eventEntry` = 79 AND `holiday` = 442 AND `holidayStage` = 1)
       OR (`eventEntry` = 80 AND `holiday` = 443 AND `holidayStage` = 1)
);

UPDATE `game_event`
SET `holidayStage` = 1
WHERE @corrected_count = 2
  AND @old_count = 0
  AND ((`eventEntry` = 79
        AND `start_time` = '2012-11-29 18:01:00'
        AND `end_time` = '2012-12-06 16:00:00'
        AND `occurence` = 60480
        AND `length` = 10080
        AND `holiday` = 442
        AND `holidayStage` = 0
        AND `description` = 'Rated Battleground 15x15'
        AND `world_event` = 0
        AND `announce` = 2
        AND `world_state` = 0
        AND `ScriptName` = '')
    OR (`eventEntry` = 80
        AND `start_time` = '2012-12-06 18:01:00'
        AND `end_time` = '2012-12-13 16:00:00'
        AND `occurence` = 60480
        AND `length` = 10080
        AND `holiday` = 443
        AND `holidayStage` = 0
        AND `description` = 'Rated Battleground 25x25'
        AND `world_event` = 0
        AND `announce` = 2
        AND `world_state` = 0
        AND `ScriptName` = ''));
