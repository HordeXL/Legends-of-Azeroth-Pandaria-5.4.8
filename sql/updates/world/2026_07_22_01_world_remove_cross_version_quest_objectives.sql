-- Remove three quest objectives that belong to later reused quest data and
-- cannot exist in this MoP 5.4.8 world/client combination.
--
-- Quest 10794 is the Burning Crusade rogue quest "Rogues of the Shattered
-- Hand".  The matching SkyFire 5.4.8 source has no item objective; it only
-- asks the player to speak with Shenthul.  Item 113135 is absent from the
-- local Build-18414 Item.db2/Item-sparse.db2 data.
--
-- Quest 11997 is the Wrath travel quest "REUSE".  The matching SkyFire 5.4.8
-- source has no objectives.  Its active "Mage Portal Taken" and "Obtain
-- Felo'melorn" objectives reference Legion-era creature entries 99418 and
-- 100290, both absent from this 5.4.8 world.
--
-- The seven other startup warnings for missing quest-objective items are not
-- changed here: their objectives occur in the matching 5.4.8 source, but an
-- authoritative item_template replacement has not yet been recovered.

-- CREATE TABLE implicitly commits in MySQL 5.7, so create the persistent
-- exact-row backup before beginning the data transaction.
CREATE TABLE IF NOT EXISTS `_backup_quest_objective_cross_version_20260722`
LIKE `quest_objective`;

START TRANSACTION;

INSERT IGNORE INTO `_backup_quest_objective_cross_version_20260722`
SELECT *
FROM `quest_objective`
WHERE (`questId` = 10794 AND `id` = 273866 AND `index` = 0
       AND `type` = 1 AND `objectId` = 113135 AND `amount` = 1)
   OR (`questId` = 11997 AND `id` = 280563 AND `index` = 0
       AND `type` = 0 AND `objectId` = 99418 AND `amount` = 1
       AND `description` = 'Mage Portal Taken')
   OR (`questId` = 11997 AND `id` = 280564 AND `index` = 1
       AND `type` = 0 AND `objectId` = 100290 AND `amount` = 1
       AND `description` = 'Obtain Felo\'melorn');

SET @cross_version_quest_objective_backup_ok :=
(
    SELECT COUNT(*) = 3
       AND SUM(`questId` = 10794 AND `id` = 273866 AND `objectId` = 113135) = 1
       AND SUM(`questId` = 11997 AND `id` = 280563 AND `objectId` = 99418) = 1
       AND SUM(`questId` = 11997 AND `id` = 280564 AND `objectId` = 100290) = 1
    FROM `_backup_quest_objective_cross_version_20260722`
);

DELETE FROM `quest_objective`
WHERE @cross_version_quest_objective_backup_ok = 1
  AND
  (
      (`questId` = 10794 AND `id` = 273866 AND `index` = 0
       AND `type` = 1 AND `objectId` = 113135 AND `amount` = 1)
   OR (`questId` = 11997 AND `id` = 280563 AND `index` = 0
       AND `type` = 0 AND `objectId` = 99418 AND `amount` = 1
       AND `description` = 'Mage Portal Taken')
   OR (`questId` = 11997 AND `id` = 280564 AND `index` = 1
       AND `type` = 0 AND `objectId` = 100290 AND `amount` = 1
       AND `description` = 'Obtain Felo\'melorn')
  );

COMMIT;
