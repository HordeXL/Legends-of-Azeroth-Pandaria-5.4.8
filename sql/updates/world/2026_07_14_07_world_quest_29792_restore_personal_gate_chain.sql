-- Correction for 2026_07_14_06: SMART_ACTION_NONE does not continue the
-- linked on-summon chain here, and the phase-2 base gates correctly disappear
-- when the area trigger removes the pre-quest phase aura. Restore the dedicated
-- personal gates while leaving legacy alternate world spawns removed by _05.

UPDATE `smart_scripts`
SET `action_type` = 50, `action_param1` = 211294, `action_param2` = 60,
    `comment` = 'Aysa Cloudsinger - On Summoned - Summon Personal Mandori Village Gate'
WHERE `entryorguid` = 59986 AND `source_type` = 0 AND `id` = 0
  AND `action_type` = 0;

UPDATE `smart_scripts`
SET `action_type` = 50, `action_param1` = 211298, `action_param2` = 60,
    `comment` = 'Aysa Cloudsinger - Linked To Id 0 - Summon Personal Pei-Wu Forest Gate'
WHERE `entryorguid` = 59986 AND `source_type` = 0 AND `id` = 1
  AND `action_type` = 0;

UPDATE `smart_scripts`
SET `target_param1` = 211294,
    `comment` = 'Aysa Cloudsinger - On Script - Activate Personal Mandori Village Gate'
WHERE `entryorguid` = 5998600 AND `source_type` = 9 AND `id` = 2
  AND `action_type` = 9 AND `target_type` = 20;

UPDATE `smart_scripts`
SET `target_param1` = 211298,
    `comment` = 'Jojo Ironbrow - Linked To Id 8 - Activate Personal Pei-Wu Forest Gate'
WHERE `entryorguid` = 59989 AND `source_type` = 0 AND `id` = 9
  AND `action_type` = 9 AND `target_type` = 20;
