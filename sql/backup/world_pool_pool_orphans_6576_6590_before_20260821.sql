-- Exact preservation of two orphaned child-pool links before the 2026-08-21
-- startup-log cleanup. Evidence only; do not load during normal updates.

INSERT INTO `pool_pool` (`pool_id`, `mother_pool`, `chance`, `description`) VALUES
(6576, 9234, 0, ''),
(6590, 9238, 0, '')
ON DUPLICATE KEY UPDATE
  `mother_pool` = VALUES(`mother_pool`),
  `chance` = VALUES(`chance`),
  `description` = VALUES(`description`);
