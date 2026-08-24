-- Exact pre-change backup for guild reward rows corrected by
-- 2026_08_22_01_world_fix_guild_tabard_empty_achievement_requirements.sql.

DELETE FROM `guild_rewards` WHERE `entry` IN (69209, 69210);
INSERT INTO `guild_rewards` (`entry`, `standing`, `racemask`, `price`, `achievements`) VALUES
(69209, 4, -1, 1250000, '0'),
(69210, 5, -1, 2500000, '0');
