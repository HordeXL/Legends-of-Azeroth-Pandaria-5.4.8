-- PhaseSwitch: player-facing phase catalog
-- Applied to the world database.
--
-- The server script only allows switching to masks listed here (and enabled = 1).
-- Fill this table with masks that actually exist in `phase_definitions` for the
-- target zone. Inspect the real values first:
--
--   SELECT zoneId, entry, phasemask, phaseId, flags, comment
--   FROM phase_definitions WHERE zoneId = <zoneId> ORDER BY entry;
--
-- name / description must not contain the protocol separators | ; :
-- (they are validated and sanitized by the Lua script at load time).

CREATE TABLE IF NOT EXISTS `phase_switch_entry` (
  `zoneId`      mediumint(8) unsigned NOT NULL,
  `mask`        int(10) unsigned     NOT NULL,
  `name`        varchar(32)          NOT NULL DEFAULT '',
  `description` varchar(96)          NOT NULL DEFAULT '',
  `sortOrder`   smallint(5) unsigned NOT NULL DEFAULT '0',
  `enabled`     tinyint(1) unsigned  NOT NULL DEFAULT '1',
  `minLevel`    tinyint(3) unsigned  NOT NULL DEFAULT '0',
  PRIMARY KEY (`zoneId`,`mask`),
  KEY `idx_zone_enabled` (`zoneId`,`enabled`,`sortOrder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Example rows for the Vale of Eternal Blossoms (zoneId 5841).
-- Disabled by default: replace the masks with values that exist on your server,
-- then set enabled = 1.
INSERT INTO `phase_switch_entry`
    (`zoneId`, `mask`, `name`, `description`, `sortOrder`, `enabled`, `minLevel`)
VALUES
    (5841,  1, '正常位面',        '默认位面 · 全部玩家与 NPC 可见', 0, 0, 0),
    (5841,  2, '金色山谷',        '前置任务完成后开放',             1, 0, 0),
    (5841,  4, '锦绣谷 · 煞染',   '煞之侵蚀阶段 · 仅事件期间生效',   2, 0, 0),
    (5841,  8, '魔古山宝库',      '团队副本前置位面 · 需 90 级',     3, 0, 90),
    (5841, 16, '影踪禅院',        '剧情位面 · 完成影踪的试炼',       4, 0, 0),
    (5841, 32, '卡拉克西 · 封印', '螳螂妖封印阶段 · 声望解锁',      5, 0, 0)
ON DUPLICATE KEY UPDATE
    `name`        = VALUES(`name`),
    `description` = VALUES(`description`),
    `sortOrder`   = VALUES(`sortOrder`),
    `enabled`     = VALUES(`enabled`),
    `minLevel`    = VALUES(`minLevel`);
