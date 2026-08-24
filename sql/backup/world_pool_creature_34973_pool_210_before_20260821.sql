-- Exact preservation of obsolete pool 210 before the 2026-08-21 startup-log
-- cleanup. Evidence only; do not load during normal updates.

INSERT INTO `pool_template` (`entry`, `max_limit`, `description`) VALUES
(210, 1, '')
ON DUPLICATE KEY UPDATE
  `max_limit` = VALUES(`max_limit`),
  `description` = VALUES(`description`);

INSERT INTO `pool_creature` (`guid`, `pool_entry`, `chance`, `description`) VALUES
(34973, 210, 0, 'null'),
(53202, 210, 12, '5831 Swiftmane')
ON DUPLICATE KEY UPDATE
  `pool_entry` = VALUES(`pool_entry`),
  `chance` = VALUES(`chance`),
  `description` = VALUES(`description`);
