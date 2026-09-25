-- ============================================================
-- Rollback for: 2026_09_25_00_world_fix_quest_29753_beast_spirit.sql
-- Restores pre-fix state of quest 29753 related data.
-- ============================================================

-- Restore Raging Beast Spirit without kill credit
UPDATE `creature_template` SET `KillCredit1` = 0 WHERE `entry` = 55790;

-- Restore Peaceful Beast Spirit without AI
UPDATE `creature_template` SET `AIName` = '' WHERE `entry` = 55787;

-- Remove the despawn script
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 55787;

-- SpellEffect.dbc: restore original file if needed:
--   copy "F:/LOA-Pandaria-5.4.8-Release/Data/dbc/SpellEffect.dbc.bak_20260925_q29753"
--   over    "F:/LOA-Pandaria-5.4.8-Release/Data/dbc/SpellEffect.dbc"
--   and restart worldserver.
