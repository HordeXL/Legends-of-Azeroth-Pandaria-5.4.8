-- Whitemane (3977) is shared by Scarlet Monastery of Old (189) and the
-- Pandaria dungeon (1004). Loot template 3977 contains the old dungeon's
-- items, including Hand of Righteousness (7721), with unrestricted modes.
-- Restrict these rows to their original map, including all three references.
-- The modern final encounter already awards two difficulty-specific items
-- from Durand's pool (60040 -> 81265 Heroic / 88294 Normal).
-- Preserve both pools, all probabilities, counts and the rare Heroic weapon.
-- Requires reference-condition evaluation in LootTemplate::Process.
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
SELECT DISTINCT 1, 3977, `item`, 0, 0, 22, 0, 189, 0, 0, 0, 0, 0, '',
    'Whitemane: legacy loot belongs to Scarlet Monastery of Old (map 189)'
FROM `creature_loot_template`
WHERE `entry` = 3977
  AND `item` IN (1707, 1708, 1710, 3787, 3827, 3832, 3864, 4022,
                 4306, 4338, 4636, 4637, 7720, 7721, 7722, 71635)
ON DUPLICATE KEY UPDATE `NegativeCondition` = 0, `Comment` = VALUES(`Comment`);
