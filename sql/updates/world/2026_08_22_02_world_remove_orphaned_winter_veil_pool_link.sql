-- Remove a non-functional Feast of Winter Veil pool link inherited from the
-- old 2024 base. Pool 9867 has no pool_template row and no creature,
-- gameobject, quest, or child-pool members, so GameEventMgr's INNER JOIN has
-- always ignored this row and reported that zero event pools were loaded.
--
-- The same dangling row exists in the preserved base/recovery schemas. The
-- current SFDB 5.4.8 snapshot omits it. This removes only the unreachable
-- reference; event 2 and all other Winter Veil data remain unchanged.

DELETE FROM `game_event_pool`
WHERE `eventEntry` = 2
  AND `pool_entry` = 9867
  AND NOT EXISTS (SELECT 1 FROM `pool_template` WHERE `entry` = 9867)
  AND NOT EXISTS (SELECT 1 FROM `pool_creature` WHERE `pool_entry` = 9867)
  AND NOT EXISTS (SELECT 1 FROM `pool_gameobject` WHERE `pool_entry` = 9867)
  AND NOT EXISTS (SELECT 1 FROM `pool_quest` WHERE `pool_entry` = 9867)
  AND NOT EXISTS (SELECT 1 FROM `pool_pool` WHERE `pool_id` = 9867 OR `mother_pool` = 9867);
