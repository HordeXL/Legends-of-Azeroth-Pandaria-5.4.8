-- Quest "Coaxing the Spirits": use the client Build-18414 spell chains
-- instead of duplicating their effects with manual SmartAI actions.
--
-- Each first spell grants the matching creature credit and triggers the
-- visual/summon chain:
--   62094 -> 62145 -> 62149 -> 33002
--   62150 -> 62151 -> 62152 -> 33034
--   62153 -> 62154 -> 62155 -> 33036
--   62156 -> 62159 -> 62160 -> 33038
--
-- The exact original rows are retained in backup tables.  Only the four
-- proven duplicate credit/summon chains and Taldan's copied gossip text are
-- changed.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_coaxing_spirits_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_coaxing_spirits_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` IN (33001, 33033, 33035, 33037)
  AND `s`.`source_type` = 0
  AND
  (
      (`s`.`id` = 0 AND `s`.`link` = 1 AND `s`.`event_type` = 62
       AND `s`.`action_type` = 33 AND `s`.`action_param1` = `s`.`entryorguid`
       AND `s`.`target_type` = 7) OR
      (`s`.`id` = 1 AND `s`.`link` = 2 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 72 AND `s`.`target_type` = 7) OR
      (`s`.`id` = 2 AND `s`.`link` = 0 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`target_type` = 1
       AND
       (
           (`s`.`entryorguid` = 33001 AND `s`.`action_param1` = 33002) OR
           (`s`.`entryorguid` = 33033 AND `s`.`action_param1` = 33034) OR
           (`s`.`entryorguid` = 33035 AND `s`.`action_param1` = 33036) OR
           (`s`.`entryorguid` = 33037 AND `s`.`action_param1` = 33038)
       ))
  );

CREATE TABLE IF NOT EXISTS `_backup_gossip_menu_option_coaxing_spirits_20260724`
LIKE `gossip_menu_option`;

INSERT IGNORE INTO `_backup_gossip_menu_option_coaxing_spirits_20260724`
SELECT `g`.*
FROM `gossip_menu_option` AS `g`
WHERE `g`.`MenuID` = 10278
  AND `g`.`OptionID` = 0;

START TRANSACTION;

SET @coaxing_smart_backup_ok :=
(
    SELECT COUNT(*) = 12
    FROM `_backup_smart_scripts_coaxing_spirits_20260724`
);

SET @coaxing_gossip_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_gossip_menu_option_coaxing_spirits_20260724`
);

-- Replace only the four exact direct-credit actions with their Build-18414
-- credit/visual/summon spell.  Target 7 remains the gossip invoker.
UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` =
        CASE `entryorguid`
            WHEN 33001 THEN 62094
            WHEN 33033 THEN 62150
            WHEN 33035 THEN 62153
            WHEN 33037 THEN 62156
        END,
    `action_param2` = 0,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` =
        CASE `entryorguid`
            WHEN 33001 THEN 'Thundris Windweaver - On Gossip Select - Cast Coax Thundris Windweaver'
            WHEN 33033 THEN 'Sentinel Elissa Starbreeze - On Gossip Select - Cast Coax Sentinel Elissa Starbreeze'
            WHEN 33035 THEN 'Taldan - On Gossip Select - Cast Coax Taldan'
            WHEN 33037 THEN 'Caylais Moonfeather - On Gossip Select - Cast Coax Caylais Moonfeather'
        END
WHERE @coaxing_smart_backup_ok = 1
  AND `entryorguid` IN (33001, 33033, 33035, 33037)
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `action_type` = 33
  AND `action_param1` = `entryorguid`
  AND `target_type` = 7;

-- The spell now performs the summon, so close gossip and end the chain.
UPDATE `smart_scripts`
SET `link` = 0
WHERE @coaxing_smart_backup_ok = 1
  AND `entryorguid` IN (33001, 33033, 33035, 33037)
  AND `source_type` = 0
  AND `id` = 1
  AND `link` = 2
  AND `event_type` = 61
  AND `action_type` = 72
  AND `target_type` = 7;

DELETE FROM `smart_scripts`
WHERE @coaxing_smart_backup_ok = 1
  AND `entryorguid` IN (33001, 33033, 33035, 33037)
  AND `source_type` = 0
  AND `id` = 2
  AND `link` = 0
  AND `event_type` = 61
  AND `action_type` = 12
  AND
  (
      (`entryorguid` = 33001 AND `action_param1` = 33002) OR
      (`entryorguid` = 33033 AND `action_param1` = 33034) OR
      (`entryorguid` = 33035 AND `action_param1` = 33036) OR
      (`entryorguid` = 33037 AND `action_param1` = 33038)
  )
  AND `target_type` = 1;

-- The active 10278 row was copied from Sentinel Elissa Starbreeze.  Matching
-- TDB 4.3.4 text and active Build-18019 BroadcastText 33209 identify Taldan.
UPDATE `gossip_menu_option`
SET `OptionText` = 'Coax Taldan''s corpse to give up its spirit.',
    `OptionBroadcastTextID` = 33209
WHERE @coaxing_gossip_backup_ok = 1
  AND `MenuID` = 10278
  AND `OptionID` = 0
  AND `OptionText` = 'Coax the spirit out of Sentinel Elissa Starbreeze''s corpse.'
  AND `OptionBroadcastTextID` = 33207;

COMMIT;
