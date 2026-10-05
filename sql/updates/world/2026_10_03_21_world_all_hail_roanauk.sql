-- All Hail Roanauk! (12140): attach the missing Blood Oath ceremony and
-- objective-credit script to Roanauk Icemist at Agmar's Hammer.

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_roanauk_all_hail'
WHERE `entry` = 26810;
