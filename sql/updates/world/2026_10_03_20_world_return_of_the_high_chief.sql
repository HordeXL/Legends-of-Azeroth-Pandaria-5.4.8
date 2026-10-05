-- Return of the High Chief (12069): connect the prison-key interaction to the
-- encounter script and restore Under-King Anub'et'kan's quest loot.

UPDATE `creature_template`
SET `ScriptName` = 'npc_anubar_prison_q12069'
WHERE `entry` = 26656;

UPDATE `creature_template`
SET `lootid` = 26608
WHERE `entry` = 26608;

DELETE FROM `creature_loot_template`
WHERE `entry` = 26608 AND `item` = 36759;

INSERT INTO `creature_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`)
VALUES
    (26608, 36759, -100, 'REGULAR', 0, 1, 1);
