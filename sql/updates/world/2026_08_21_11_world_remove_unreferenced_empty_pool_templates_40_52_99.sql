-- Remove empty pool containers that have no members and no hierarchy links.
-- The templates themselves exist in inherited databases, but no checked source
-- contains content for these IDs and the core cannot spawn them.

DELETE `pt`
FROM `pool_template` AS `pt`
WHERE (`pt`.`entry` = 40 OR `pt`.`entry` BETWEEN 52 AND 99)
  AND NOT EXISTS (SELECT 1 FROM `pool_creature` AS `pc` WHERE `pc`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_gameobject` AS `pg` WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_quest` AS `pq` WHERE `pq`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_pool` AS `pp` WHERE `pp`.`pool_id` = `pt`.`entry` OR `pp`.`mother_pool` = `pt`.`entry`);
