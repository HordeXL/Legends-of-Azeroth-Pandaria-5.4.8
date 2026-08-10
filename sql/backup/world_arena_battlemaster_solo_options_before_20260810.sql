-- Rollback for 2026_08_10_00_world_add_arena_battlemaster_solo_options.sql.
-- The pre-change audit found no rows in menu 8218 with option IDs 20, 21 or 22.
-- The original Arena registration option (8218, 0) is intentionally untouched.

DELETE FROM `gossip_menu_option`
WHERE `MenuID` = 8218 AND `OptionID` IN (20, 21, 22);
