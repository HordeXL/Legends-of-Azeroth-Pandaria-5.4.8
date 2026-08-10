-- Persistent recovery journal for temporary Solo Arena equipment.
-- This table contains only active, not-yet-restored slot swaps. Rows are
-- deleted only after the original item instance has been restored.

CREATE TABLE IF NOT EXISTS `solo_arena_loadout_backup` (
  `owner_guid` INT UNSIGNED NOT NULL,
  `requester_guid` INT UNSIGNED NOT NULL,
  `equipment_slot` TINYINT UNSIGNED NOT NULL,
  `original_item_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `original_item_entry` INT UNSIGNED NOT NULL DEFAULT 0,
  `storage_bag` TINYINT UNSIGNED NOT NULL,
  `storage_slot` TINYINT UNSIGNED NOT NULL,
  `temporary_item_guid` INT UNSIGNED NOT NULL,
  `temporary_item_entry` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`owner_guid`, `equipment_slot`),
  UNIQUE KEY `uq_solo_arena_loadout_temporary_item` (`temporary_item_guid`),
  KEY `idx_solo_arena_loadout_requester` (`requester_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Crash-safe journal for reversible Solo Arena equipment';
