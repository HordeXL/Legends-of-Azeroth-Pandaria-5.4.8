-- These six quest pairs have distinct Normal and Heroic versions sharing
-- the same in-dungeon questgivers. Source 19 gates both visibility and accept,
-- including quest sharing. Type 81 alone means Dungeon, not Normal-only:
-- keep shared quests (and quests in Heroic-only dungeons) available as before.
-- The audit of spawned NPC/GO questgivers found no other active paired versions.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 19 AND `SourceGroup` = 0 AND `SourceId` = 0
  AND `SourceEntry` IN (31440, 31442, 31447, 31448, 31490, 31493,
                        31495, 31497, 31513, 31514, 31515, 31516)
  AND `ConditionTypeOrReference` = 49;
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (19, 0, 31440, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'The Four Tomes: Normal dungeon only'),
    (19, 0, 31442, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'The Four Tomes: Heroic dungeon only'),
    (19, 0, 31447, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'An End to the Suffering: Normal dungeon only'),
    (19, 0, 31448, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'An End to the Suffering: Heroic dungeon only'),
    (19, 0, 31490, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'Rank and File: Normal dungeon only'),
    (19, 0, 31495, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'Rank and File: Heroic dungeon only'),
    (19, 0, 31493, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'Just for Safekeeping, Of Course: Normal dungeon only'),
    (19, 0, 31497, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'Just for Safekeeping, Of Course: Heroic dungeon only'),
    (19, 0, 31513, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'Blades of the Anointed: Normal dungeon only'),
    (19, 0, 31515, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'Blades of the Anointed: Heroic dungeon only'),
    (19, 0, 31514, 0, 0, 49, 0, 1, 0, 0, 0, 0, 0, '', 'Unto Dust Thou Shalt Return: Normal dungeon only'),
    (19, 0, 31516, 0, 0, 49, 0, 2, 0, 0, 0, 0, 0, '', 'Unto Dust Thou Shalt Return: Heroic dungeon only');

-- Overlapping first-blade chests previously spawned in both modes, giving
-- the wrong quest item depending on which copy the player clicked.
UPDATE `gameobject` SET `spawnMask` = 2 WHERE `map` = 1004 AND `id` = 214284;
UPDATE `gameobject` SET `spawnMask` = 4 WHERE `map` = 1004 AND `id` = 214296;
UPDATE `gameobject_loot_template` SET `ChanceOrQuestChance` = -100, `lootmode` = 2
WHERE `entry` = 43122 AND `item` = 87282;
UPDATE `gameobject_loot_template` SET `ChanceOrQuestChance` = -100, `lootmode` = 4
WHERE `entry` = 43126 AND `item` = 87389;
