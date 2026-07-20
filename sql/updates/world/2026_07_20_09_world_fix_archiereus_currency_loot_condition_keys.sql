-- Fix the two Archiereus of Flame currency-loot condition keys.
--
-- This core loads a negative loot-table `item` as currency and stores its ID
-- internally as abs(item). Loot conditions must therefore use the positive ID
-- so LootTemplate::addConditionItem can attach them. Preserve the negative
-- creature_loot_template values themselves: they are the currency type marker.
-- No row is deleted or inserted.

START TRANSACTION;

UPDATE `conditions` AS `c`
INNER JOIN `creature_loot_template` AS `l`
        ON `l`.`entry` = `c`.`SourceGroup`
       AND `l`.`item` = `c`.`SourceEntry`
       AND `l`.`ChanceOrQuestChance` = 100
       AND `l`.`lootmode` = 0
       AND `l`.`groupid` = 0
       AND `l`.`mincountOrRef` = 1
       AND ((`l`.`item` = -738 AND `l`.`maxcount` = 10)
         OR (`l`.`item` = -777 AND `l`.`maxcount` = 699))
INNER JOIN `quest_template` AS `q`
        ON `q`.`Id` = 33312
       AND `q`.`LogTitle` = 'Tracking Quest - Daily - Archiereus of Flame'
LEFT JOIN `conditions` AS `existing`
       ON `existing`.`SourceTypeOrReferenceId` = `c`.`SourceTypeOrReferenceId`
      AND `existing`.`SourceGroup` = `c`.`SourceGroup`
      AND `existing`.`SourceEntry` = -`c`.`SourceEntry`
      AND `existing`.`SourceId` = `c`.`SourceId`
      AND `existing`.`ElseGroup` = `c`.`ElseGroup`
      AND `existing`.`ConditionTypeOrReference` = `c`.`ConditionTypeOrReference`
      AND `existing`.`ConditionTarget` = `c`.`ConditionTarget`
      AND `existing`.`ConditionValue1` = `c`.`ConditionValue1`
      AND `existing`.`ConditionValue2` = `c`.`ConditionValue2`
      AND `existing`.`ConditionValue3` = `c`.`ConditionValue3`
SET `c`.`SourceEntry` = -`c`.`SourceEntry`
WHERE `c`.`SourceTypeOrReferenceId` = 1
  AND `c`.`SourceGroup` = 73666
  AND `c`.`SourceEntry` IN (-738, -777)
  AND `c`.`SourceId` = 0
  AND `c`.`ElseGroup` = 0
  AND `c`.`ConditionTypeOrReference` = 43
  AND `c`.`ConditionTarget` = 0
  AND `c`.`ConditionValue1` = 33312
  AND `c`.`ConditionValue2` = 0
  AND `c`.`ConditionValue3` = 0
  AND `c`.`NegativeCondition` = 1
  AND `c`.`ErrorType` = 0
  AND `c`.`ErrorTextId` = 0
  AND `c`.`ScriptName` = ''
  AND `existing`.`SourceTypeOrReferenceId` IS NULL;

COMMIT;
