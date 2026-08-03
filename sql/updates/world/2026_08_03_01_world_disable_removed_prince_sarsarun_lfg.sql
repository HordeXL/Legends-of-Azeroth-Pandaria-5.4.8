-- Prince Sarsarun was available only during the one-time Elemental Unrest
-- event preceding Cataclysm. Its two faction-specific LFG entries remain in
-- the 5.4.8 client DBC but have no valid MoP entrance for event map 734.
-- Preserve all historical DBC/world data and explicitly disable only the
-- obsolete LFG entries through the core's existing disable mechanism.

INSERT IGNORE INTO `disables`
    (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`)
VALUES
    (13, 299, 0, '', '', 'Removed Cataclysm pre-launch Elemental Unrest LFG: Prince Sarsarun'),
    (13, 310, 0, '', '', 'Removed Cataclysm pre-launch Elemental Unrest LFG: Prince Sarsarun');
