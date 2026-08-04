-- Exact rollback for
-- 2026_08_03_03_world_remove_invalid_cross_faction_spell_links.sql.

INSERT IGNORE INTO `spell_linked_spell`
    (`spell_trigger`, `spell_effect`, `type`, `comment`)
VALUES
    (200002, 200004, 0, 'Alliance to Horde (tick)'),
    (200003, 200005, 0, 'Horde to Alliance (tick)');
