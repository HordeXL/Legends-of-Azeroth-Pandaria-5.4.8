-- Import adaptation: repair difficulty eligibility while preserving the existing drop probability.
UPDATE `creature_loot_template`
SET
    `lootmode`='DUNGEON_NORMAL,DUNGEON_HEROIC'
WHERE `entry`=17796 AND `item`=72574
  AND `lootmode`='DUNGEON_NORMAL' AND `ChanceOrQuestChance`=-7
  AND `groupid`=0 AND `mincountOrRef`=1 AND `maxcount`=1;
