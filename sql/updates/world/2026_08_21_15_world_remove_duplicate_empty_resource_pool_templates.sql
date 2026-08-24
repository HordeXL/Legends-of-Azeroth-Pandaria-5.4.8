-- Remove 27 inert pool_template shells which have no creature, gameobject,
-- quest, child-pool, or parent-pool references.
--
-- The named 5.4.8 Pandaria resource nodes are retained.  Active DB auditing
-- shows their spawns are already assigned to populated replacement pools,
-- including 30130 (Trillium Pandaria), 30131 (Golden Lotus Pandaria), and the
-- populated zone-specific herb/ore pools.  Pool 30184 is an unrelated stale
-- custom weekly-transmog shell with no members or references.
--
-- Safety: each row is deleted only while it still has no reference in any
-- pool membership/hierarchy table.  If later content has attached a member,
-- that template is deliberately left untouched.

DELETE FROM `pool_template`
WHERE `entry` IN
(
  30053, 30058, 30059, 30062, 30065, 30066, 30071, 30075, 30076,
  30081, 30085, 30086, 30088, 30090, 30096, 30097, 30100, 30106,
  30109, 30110, 30112, 30114, 30121, 30124, 30125, 30126, 30184
)
AND NOT EXISTS
(
  SELECT 1 FROM `pool_creature` pc WHERE pc.`pool_entry` = `pool_template`.`entry`
)
AND NOT EXISTS
(
  SELECT 1 FROM `pool_gameobject` pg WHERE pg.`pool_entry` = `pool_template`.`entry`
)
AND NOT EXISTS
(
  SELECT 1 FROM `pool_quest` pq WHERE pq.`pool_entry` = `pool_template`.`entry`
)
AND NOT EXISTS
(
  SELECT 1 FROM `pool_pool` pp WHERE pp.`pool_id` = `pool_template`.`entry`
)
AND NOT EXISTS
(
  SELECT 1 FROM `pool_pool` pp WHERE pp.`mother_pool` = `pool_template`.`entry`
);
