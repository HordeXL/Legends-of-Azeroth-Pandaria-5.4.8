-- Sarathstra, Scourge of the North (12097): restore Rokhan's call-down event
-- and make the Frozen Heart's 100% quest drop eligible in regular loot mode.

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_rokhan_sarathstra'
WHERE `entry` = 26859;

UPDATE `creature_template`
SET `lootid` = 26858
WHERE `entry` = 26858;

UPDATE `creature_loot_template`
SET `ChanceOrQuestChance` = -100,
    `lootmode` = 'REGULAR',
    `groupid` = 0,
    `mincountOrRef` = 1,
    `maxcount` = 1
WHERE `entry` = 26858 AND `item` = 36793;
