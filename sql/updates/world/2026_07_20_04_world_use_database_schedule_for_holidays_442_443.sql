-- Holidays 442 and 443 have complete recurring schedules in game_event, but
-- their Build-18414 Holidays.dbc records have no Date[0] or Duration[0].
-- holidayStage=1 asks GameEventMgr to replace the database schedule from that
-- absent DBC data, which can only emit a warning and return. Stage 0 explicitly
-- keeps the complete database schedule and changes no event timing or identity.

SET @old_count := (
    SELECT COUNT(*)
    FROM `game_event`
    WHERE (`eventEntry` = 79
           AND `start_time` = '2012-11-29 18:01:00'
           AND `end_time` = '2012-12-06 16:00:00'
           AND `occurence` = 60480
           AND `length` = 10080
           AND `holiday` = 442
           AND `holidayStage` = 1
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
           AND `holidayStage` = 1
           AND `description` = 'Rated Battleground 25x25'
           AND `world_event` = 0
           AND `announce` = 2
           AND `world_state` = 0
           AND `ScriptName` = '')
);

SET @corrected_count := (
    SELECT COUNT(*)
    FROM `game_event`
    WHERE (`eventEntry` = 79 AND `holiday` = 442 AND `holidayStage` = 0)
       OR (`eventEntry` = 80 AND `holiday` = 443 AND `holidayStage` = 0)
);

UPDATE `game_event`
SET `holidayStage` = 0
WHERE @old_count = 2
  AND @corrected_count = 0
  AND ((`eventEntry` = 79
        AND `start_time` = '2012-11-29 18:01:00'
        AND `end_time` = '2012-12-06 16:00:00'
        AND `occurence` = 60480
        AND `length` = 10080
        AND `holiday` = 442
        AND `holidayStage` = 1
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
        AND `holidayStage` = 1
        AND `description` = 'Rated Battleground 25x25'
        AND `world_event` = 0
        AND `announce` = 2
        AND `world_state` = 0
        AND `ScriptName` = ''));
