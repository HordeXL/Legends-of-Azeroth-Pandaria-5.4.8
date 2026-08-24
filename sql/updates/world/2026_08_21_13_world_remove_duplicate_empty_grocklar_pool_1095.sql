-- Grocklar's six current GUIDs already belong to active pool 143 in this DB.
-- Pool 1095 is therefore an empty source-GUID-era duplicate. Its exact original
-- template is preserved by world_pool_templates_..._1095_before_20260821.sql.

DELETE `pt`
FROM `pool_template` AS `pt`
WHERE `pt`.`entry`=1095
  AND NOT EXISTS (SELECT 1 FROM `pool_creature` AS `pc` WHERE `pc`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_gameobject` AS `pg` WHERE `pg`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_quest` AS `pq` WHERE `pq`.`pool_entry`=`pt`.`entry`)
  AND NOT EXISTS (SELECT 1 FROM `pool_pool` AS `pp` WHERE `pp`.`pool_id`=`pt`.`entry` OR `pp`.`mother_pool`=`pt`.`entry`);
