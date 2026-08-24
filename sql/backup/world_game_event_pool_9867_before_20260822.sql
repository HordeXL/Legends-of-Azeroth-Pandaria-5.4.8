-- Exact preservation of the dangling Winter Veil event-pool link before
-- 2026_08_22_02_world_remove_orphaned_winter_veil_pool_link.sql.
-- Evidence only; do not load during normal updates.

INSERT INTO `game_event_pool` (`eventEntry`, `pool_entry`) VALUES
(2, 9867)
ON DUPLICATE KEY UPDATE `eventEntry` = VALUES(`eventEntry`);
