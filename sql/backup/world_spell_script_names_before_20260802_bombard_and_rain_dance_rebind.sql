-- Exact rollback for
-- 2026_08_02_08_world_rebind_bombard_and_rain_dance_spell_scripts.sql.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 120202
  AND `ScriptName` = 'spell_rimok_saboteur_bombard_target';

DELETE FROM `spell_script_names`
WHERE (`spell_id` = 124860 OR `spell_id` = 124864)
  AND `ScriptName` = 'spell_brawlers_guild_rain_dance';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (124860, 'spell_brawlers_guild_rain_dance');
