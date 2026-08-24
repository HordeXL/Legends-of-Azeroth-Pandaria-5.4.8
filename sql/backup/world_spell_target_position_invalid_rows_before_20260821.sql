-- Exact data snapshot taken before the 2026-08-21 removal of five rejected
-- spell_target_position rows. This is a preservation backup, not an update
-- that is loaded automatically by the server.
--
-- Build-18414 SpellEffect.dbc and the owning scripts prove that these keys do
-- not describe database destinations. The rows are retained here verbatim so
-- the historical source data is not lost.

INSERT INTO `spell_target_position`
    (`id`, `effIndex`, `target_map`, `target_position_x`, `target_position_y`,
     `target_position_z`, `target_orientation`)
VALUES
    (49986,  1, 571,  478.952, -5941.53, 308.75,  0.419872),
    (66836,  0, 654, -1620.98,   1509.19,  67.1041, 0),
    (66925,  0, 654, -1636.29,   1481.84,  70.948,  0),
    (100679, 2, 720,  1041.25,    -57.4478, 55.5,    0),
    (105002, 0, 860,   915.559,  4563.67, 231.083,  2.29809)
ON DUPLICATE KEY UPDATE
    `target_map` = VALUES(`target_map`),
    `target_position_x` = VALUES(`target_position_x`),
    `target_position_y` = VALUES(`target_position_y`),
    `target_position_z` = VALUES(`target_position_z`),
    `target_orientation` = VALUES(`target_orientation`);
