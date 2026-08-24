-- Item 46693 (Small Paper Zeppelin) is a Children's Week quest item sold by
-- Jepetto Joybuzz and Clockwork Assistant only while event 10 is active.
-- The current DB had it permanently in npc_vendor.  Matching SkyFire 5.4.8
-- data uses game_event_npc_vendor, but its old spawn GUIDs cannot be copied;
-- use this world's verified current GUIDs instead:
--   96037 = Jepetto Joybuzz (entry 29478)
--   98251 = Clockwork Assistant (entry 29716)

DELETE FROM `npc_vendor`
WHERE `entry` IN (29478, 29716)
  AND `item` = 46693
  AND `ExtendedCost` = 0
  AND `type` = 1;

INSERT INTO `game_event_npc_vendor`
(`eventEntry`, `guid`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`) VALUES
(10, 96037, 0, 46693, 0, 0, 0, 1),
(10, 98251, 0, 46693, 0, 0, 0, 1)
ON DUPLICATE KEY UPDATE
  `eventEntry` = VALUES(`eventEntry`),
  `slot` = VALUES(`slot`),
  `maxcount` = VALUES(`maxcount`),
  `incrtime` = VALUES(`incrtime`);
