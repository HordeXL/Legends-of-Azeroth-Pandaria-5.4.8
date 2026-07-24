-- Backup and rollback for:
-- sql/updates/world/2026_07_23_05_world_restore_quest_objective_items.sql
--
-- The backup table intentionally remains empty when the seven item templates
-- did not exist before the repair. This still makes the rollback safe if the
-- script is applied to a database where one of the rows already exists.

CREATE TABLE IF NOT EXISTS `_backup_item_template_quest_objectives_20260723`
LIKE `item_template`;

INSERT IGNORE INTO `_backup_item_template_quest_objectives_20260723`
SELECT *
FROM `item_template`
WHERE `entry` IN (68674, 68676, 68680, 71961, 73366, 93396, 93660);

-- Rollback:
-- DELETE FROM `item_template`
-- WHERE `entry` IN (68674, 68676, 68680, 71961, 73366, 93396, 93660);
--
-- INSERT IGNORE INTO `item_template`
-- SELECT *
-- FROM `_backup_item_template_quest_objectives_20260723`;
