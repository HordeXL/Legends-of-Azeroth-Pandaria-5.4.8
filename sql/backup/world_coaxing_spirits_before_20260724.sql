-- Exact rollback for
-- 2026_07_24_00_world_fix_coaxing_spirits_spell_chain.sql.

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

DELETE FROM `smart_scripts`
WHERE @coaxing_smart_backup_ok = 1
  AND `entryorguid` IN (33001, 33033, 33035, 33037)
  AND `source_type` = 0
  AND `id` IN (0, 1, 2);

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_coaxing_spirits_20260724` AS `backup`
WHERE @coaxing_smart_backup_ok = 1;

DELETE FROM `gossip_menu_option`
WHERE @coaxing_gossip_backup_ok = 1
  AND `MenuID` = 10278
  AND `OptionID` = 0;

INSERT INTO `gossip_menu_option`
SELECT `backup`.*
FROM `_backup_gossip_menu_option_coaxing_spirits_20260724` AS `backup`
WHERE @coaxing_gossip_backup_ok = 1;

COMMIT;
