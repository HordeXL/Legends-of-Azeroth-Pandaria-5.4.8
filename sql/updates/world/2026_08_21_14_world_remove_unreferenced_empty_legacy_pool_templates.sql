-- These 20 templates have no member/hierarchy rows in the active database,
-- both full reference databases, either user backup, or the original base dump.

DELETE `pt`
FROM `pool_template` AS `pt`
WHERE `pt`.`entry` IN
(155,175,192,193,195,329,330,331,1134,1137,1138,1139,1140,1141,1142,1143,
 1240,9868,14139,14140)
  AND NOT EXISTS (SELECT 1 FROM `pool_creature` AS `pc` WHERE `pc`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_gameobject` AS `pg` WHERE `pg`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_quest` AS `pq` WHERE `pq`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_pool` AS `pp` WHERE `pp`.`pool_id`=`pt`.`entry` OR `pp`.`mother_pool`=`pt`.`entry`);
