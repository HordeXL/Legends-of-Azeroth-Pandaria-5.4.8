-- Exact pre-change backup for the Small Paper Zeppelin vendor placement
-- corrected by
-- 2026_08_22_03_world_make_small_paper_zeppelin_childrens_week_only.sql.
--
-- Before the change the item was permanently present on both creature-template
-- vendor lists, and neither current creature GUID had an event-vendor row.

DELETE FROM `game_event_npc_vendor`
WHERE `guid` IN (96037, 98251)
  AND `item` = 46693
  AND `ExtendedCost` = 0
  AND `type` = 1;

DELETE FROM `npc_vendor`
WHERE `entry` IN (29478, 29716)
  AND `item` = 46693
  AND `ExtendedCost` = 0
  AND `type` = 1;

INSERT INTO `npc_vendor`
(`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`) VALUES
(29478, 0, 46693, 0, 0, 0, 1),
(29716, 0, 46693, 0, 0, 0, 1);
