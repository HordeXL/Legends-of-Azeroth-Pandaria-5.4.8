-- In Search of the Ruby Lilac (12102): make the flower reliably award the
-- required quest item on 5.4.8 while retaining its canonical loot fallback.
UPDATE `gameobject_template`
SET `ScriptName` = 'go_ruby_lilac_12102'
WHERE `entry` = 188489;

UPDATE `gameobject`
SET `spawntimesecs` = 30
WHERE `id` = 188489;

UPDATE `quest_objective`
SET `type` = 1, `objectId` = 36803, `amount` = 1
WHERE `questId` = 12102 AND `index` = 0;

DELETE FROM `gameobject_loot_template`
WHERE `entry` = 188489 AND `item` = 36803;

INSERT INTO `gameobject_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`)
VALUES
    (188489, 36803, -100, '', 0, 1, 1);
