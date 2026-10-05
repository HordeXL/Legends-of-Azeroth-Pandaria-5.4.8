-- Import adaptation: preserve drop probability; only repair raid-group quest eligibility.
-- Halls of Stone: make dungeon quest progress reliable for bot groups that
-- may be represented as raid groups by the playerbot module.

UPDATE `quest_template`
SET `Flags` = `Flags` | 64 -- QUEST_FLAGS_RAID_GROUP_OK
WHERE `ID` IN (13207, 29848, 29850);

-- The Forlorn Watcher (29848): allow Crystal Tear of Grief from the
-- Maiden of Grief while the item objective is active.  Positive chance plus
-- explicit conditions avoids the raid-group filtering of negative quest loot.
UPDATE `creature_loot_template`
SET `ChanceOrQuestChance` = ABS(`ChanceOrQuestChance`)
WHERE `entry` = 27975
  AND `item` = 74830
  AND `lootmode` IN ('DUNGEON_NORMAL', 'DUNGEON_HEROIC');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 1
  AND `SourceGroup` = 27975
  AND `SourceEntry` = 74830
  AND `SourceId` = 0
  AND `ConditionTypeOrReference` IN (47, 48);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(1, 27975, 74830, 0, 0, 47, 0, 29848, 8, 0, 0, 0, 0, '',
 'Maiden of Grief - Crystal Tear requires The Forlorn Watcher in progress'),
(1, 27975, 74830, 0, 0, 48, 0, 252882, 0, 0, 1, 0, 0, '',
 'Maiden of Grief - Crystal Tear objective must be incomplete');
