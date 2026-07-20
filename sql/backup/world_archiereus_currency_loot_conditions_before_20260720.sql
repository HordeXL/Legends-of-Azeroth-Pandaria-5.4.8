-- Roll back 2026_07_20_09_world_fix_archiereus_currency_loot_condition_keys.sql.
-- Restore only the two original negative SourceEntry values. The loot rows and
-- daily tracking condition are otherwise left unchanged.

START TRANSACTION;

UPDATE `conditions` AS `c`
INNER JOIN `creature_loot_template` AS `l`
        ON `l`.`entry` = `c`.`SourceGroup`
       AND `l`.`item` = -`c`.`SourceEntry`
       AND `l`.`ChanceOrQuestChance` = 100
       AND `l`.`lootmode` = 0
       AND `l`.`groupid` = 0
       AND `l`.`mincountOrRef` = 1
       AND ((`c`.`SourceEntry` = 738 AND `l`.`maxcount` = 10)
         OR (`c`.`SourceEntry` = 777 AND `l`.`maxcount` = 699))
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
  AND `c`.`SourceEntry` IN (738, 777)
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
