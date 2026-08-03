-- Exact rollback for
-- 2026_08_03_02_world_remove_wrong_prayer_of_mending_link.sql.

INSERT IGNORE INTO `spell_linked_spell`
    (`spell_trigger`, `spell_effect`, `type`, `comment`)
VALUES
    (123262, 203754, 0, 'Prayer of Mending server-side trigger');
