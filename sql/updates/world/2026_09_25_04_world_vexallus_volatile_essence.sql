-- Import adaptation: repair difficulty eligibility while preserving the existing drop probability.
UPDATE `creature_loot_template`
SET
    `lootmode`='DUNGEON_NORMAL,DUNGEON_HEROIC'
WHERE `entry`=24744 AND `item`=73084
  AND `lootmode`='DUNGEON_NORMAL' AND `ChanceOrQuestChance`=-5
  AND `groupid`=0 AND `mincountOrRef`=1 AND `maxcount`=1;
