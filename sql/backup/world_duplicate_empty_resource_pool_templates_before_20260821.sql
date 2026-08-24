-- Exact preservation of the 27 empty pool_template rows removed by
-- 2026_08_21_15_world_remove_duplicate_empty_resource_pool_templates.sql.
--
-- The Pandaria resource spawns themselves are not stored here and are not
-- removed by the forward migration.  They remain active in their populated
-- replacement pools (for example 30130 Trillium Pandaria and 30131 Golden
-- Lotus Pandaria).

INSERT INTO `pool_template` (`entry`, `max_limit`, `description`) VALUES
(30053, 5, 'Glimmering Jewel Danio Pool (218652)'),
(30058, 3, 'Vale of Eternal Blossoms (5840) - Rich Trillium Vein (209330)'),
(30059, 5, 'Vale of Eternal Blossoms (5840) - Trillium Vein (209313)'),
(30062, 5, 'Vale of Eternal Blossoms (5840) - Golden Lotus (209354)'),
(30065, 6, 'Dread Wastes (6138) - Rich Trillium Vein (209330)'),
(30066, 10, 'Dread Wastes (6138) - Trillium Vein (209313)'),
(30071, 6, 'Dread Wastes (6138) - Golden Lotus (209354)'),
(30075, 6, 'Townlong Steppes (5842) - Rich Trillium Vein (209330)'),
(30076, 10, 'Townlong Steppes (5842) - Trillium Vein (209313)'),
(30081, 6, 'Townlong Steppes (5842) - Golden Lotus (209354)'),
(30085, 2, 'The Jade Forest (5785) - Rich Trillium Vein (209330)'),
(30086, 3, 'The Jade Forest (5785) - Trillium Vein (209313)'),
(30088, 70, 'The Jade Forest (5785) - Rich Ghost Iron Deposit (209328)'),
(30090, 6, 'The Jade Forest (5785) - Golden Lotus (209354)'),
(30096, 3, 'Valley of the Four Winds (5805) - Rich Trillium Vein (209330)'),
(30097, 3, 'Valley of the Four Winds (5805) - Trillium Vein (209313)'),
(30100, 6, 'Valley of the Four Winds (5805) - Golden Lotus 209354'),
(30106, 2, 'Krasarang Wilds (6134) - Golden Lotus 209354'),
(30109, 50, 'Kun-Lai Summit (5841) - Trillium Vein (209313)'),
(30110, 6, 'Kun-Lai Summit (5841) - Trillium Vein (209313)'),
(30112, 50, 'Kun-Lai Summit (5841) - Golden Lotus (209354)'),
(30114, 6, 'Kun-Lai Summit (5841) - Green Tea Leaf (209349)'),
(30121, 40, 'The Veiled Stair (6006) - Snow Lily (209351)'),
(30124, 5, 'The Jade Forest (5785) - Rain Poppy (215408)'),
(30125, 3, 'Kun-Lai Summit(5841) - Snow Lily (215407)'),
(30126, 5, 'Dread Wastes (6138) - Sha-Touched Herb (215412)'),
(30184, 1, 'Misiones semanales - Transfiguración')
ON DUPLICATE KEY UPDATE
  `max_limit` = VALUES(`max_limit`),
  `description` = VALUES(`description`);
