-- Adapted from ProjectSkyfire/SkyFire_548 2026_08_20_world_07.sql.
-- A full row-by-row comparison showed that the current database already has
-- every upstream row except these 14 members of craft suffix groups 415/416.

INSERT IGNORE INTO `item_enchantment_template` (`entry`, `ench`, `chance`) VALUES
(415,131,18.9000),(416,131,18.9000),
(415,132,17.0000),(416,132,17.0000),
(415,133,11.1000),(416,133,11.1000),
(415,134,14.5000),(416,134,14.5000),
(415,135,13.1000),(416,135,13.1000),
(415,136,12.0000),(416,136,12.0000),
(415,137,13.4000),(416,137,13.4000);
