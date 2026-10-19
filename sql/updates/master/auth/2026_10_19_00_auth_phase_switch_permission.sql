-- PhaseSwitch: account whitelist
-- Applied to the auth database (the Lua script reads it with AuthDBQuery).
--
-- Only used when the script's MODE is set to 1 (GM + whitelist).
--   zoneId = 0 -> all zones
--   mask   = 0 -> all phases
-- GM accounts are handled separately and cannot switch phases (they already
-- see every phase through PHASEMASK_ANYWHERE).

CREATE TABLE IF NOT EXISTS `phase_switch_permission` (
  `accountId` int(10) unsigned NOT NULL,
  `zoneId`    mediumint(8) unsigned NOT NULL DEFAULT '0',
  `mask`      int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`accountId`,`zoneId`,`mask`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Example: allow account 1 to switch any phase in the Vale of Eternal Blossoms.
-- INSERT INTO `phase_switch_permission` (`accountId`, `zoneId`, `mask`)
-- VALUES (1, 5841, 0);
