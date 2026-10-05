-- Import adaptation: repair difficulty eligibility while preserving the existing drop probability.
UPDATE `creature_loot_template`
SET
    `lootmode`='DUNGEON_NORMAL,DUNGEON_HEROIC'
WHERE `entry`=19428 AND `item`=72480
  AND `lootmode`='DUNGEON_NORMAL' AND `ChanceOrQuestChance`=-8
  AND `groupid`=0 AND `mincountOrRef`=1 AND `maxcount`=1;
