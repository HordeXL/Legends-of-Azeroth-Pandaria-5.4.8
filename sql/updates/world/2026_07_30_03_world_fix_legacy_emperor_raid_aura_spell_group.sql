-- Make the raid-area and direct-ally forms of Legacy of the Emperor obey the
-- same exclusive stat-buff rules.
--
-- Source: ProjectSkyfire/SkyFire_548 commit
-- a826a7f12c29f2388a2e640ba6aa3d3b6e726863.
--
-- This project's parent group, subgroup rules and direct-ally aura are
-- already correct. Only the missing Build-18414 raid-area aura is inserted;
-- no active gameplay row is deleted or overwritten.

CREATE TABLE IF NOT EXISTS `_backup_spell_group_legacy_emperor_20260730`
LIKE `spell_group`;

INSERT INTO `_backup_spell_group_legacy_emperor_20260730`
SELECT `group_row`.*
FROM `spell_group` AS `group_row`
WHERE `group_row`.`id` = 1149
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_spell_group_legacy_emperor_20260730` AS `backup`
       WHERE `backup`.`id` = `group_row`.`id`);

START TRANSACTION;

SET @legacy_emperor_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`spell_id` = 117667
               AND `comment` = 'Legacy of the Emperor') = 1
    FROM `_backup_spell_group_legacy_emperor_20260730`
    WHERE `id` = 1149
);

SET @legacy_emperor_group_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`spell_id` = 117667
               AND `comment` = 'Legacy of the Emperor') = 1
    FROM `spell_group`
    WHERE `id` = 1149
);

SET @blessing_of_kings_group_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`spell_id` = 20217) = 1
       AND SUM(`spell_id` = 72586) = 1
    FROM `spell_group`
    WHERE `id` = 1148
);

SET @stats_raid_buff_parent_ok :=
(
    SELECT COUNT(*) = 4
       AND SUM(`spell_id` = -1148) = 1
       AND SUM(`spell_id` = -1149) = 1
       AND SUM(`spell_id` = 1126) = 1
       AND SUM(`spell_id` = 90363) = 1
    FROM `spell_group`
    WHERE `id` = 1118
);

SET @stats_raid_buff_rules_ok :=
(
    SELECT COUNT(*) = 3
       AND SUM(`group_id` = 1118 AND `stack_rule` = 3) = 1
       AND SUM(`group_id` = 1148 AND `stack_rule` = 1) = 1
       AND SUM(`group_id` = 1149 AND `stack_rule` = 1) = 1
    FROM `spell_group_stack_rules`
    WHERE `group_id` IN (1118, 1148, 1149)
);

INSERT INTO `spell_group` (`id`, `spell_id`, `comment`)
SELECT 1149, 117666, 'Legacy of the Emperor'
FROM DUAL
WHERE @legacy_emperor_backup_ok = 1
  AND @legacy_emperor_group_ok = 1
  AND @blessing_of_kings_group_ok = 1
  AND @stats_raid_buff_parent_ok = 1
  AND @stats_raid_buff_rules_ok = 1
  AND NOT EXISTS
      (SELECT 1
       FROM `spell_group`
       WHERE `id` = 1149
         AND `spell_id` = 117666);

COMMIT;
