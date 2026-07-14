-- Restore the personal-gate SmartAI configuration that preceded
-- 2026_07_14_06_world_quest_29792_use_existing_gates.sql.
UPDATE `smart_scripts` SET `action_type`=50, `action_param1`=211294, `action_param2`=60,
`comment`='Aysa Cloudsinger - On Summoned - Summon Personal Mandori Village Gate'
WHERE `entryorguid`=59986 AND `source_type`=0 AND `id`=0;
UPDATE `smart_scripts` SET `action_type`=50, `action_param1`=211298, `action_param2`=60,
`comment`='Aysa Cloudsinger - Linked To Id 0 - Summon Object Pei-Wu Forest Gate'
WHERE `entryorguid`=59986 AND `source_type`=0 AND `id`=1;
UPDATE `smart_scripts` SET `target_param1`=211294,
`comment`='Aysa Cloudsinger - On Script - Activate Personal Mandori Village Gate'
WHERE `entryorguid`=5998600 AND `source_type`=9 AND `id`=2;
UPDATE `smart_scripts` SET `target_param1`=211298
WHERE `entryorguid`=59989 AND `source_type`=0 AND `id`=9;
