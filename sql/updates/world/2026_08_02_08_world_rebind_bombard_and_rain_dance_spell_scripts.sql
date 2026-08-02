-- The Build-18414 spell data puts the area target on Bombard 120202, which is
-- triggered by the periodic Bombard aura 120559. Keep the aura script on
-- 120559 and bind its target filter to the actual triggered spell.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 120202
  AND `ScriptName` = 'spell_rimok_saboteur_bombard_target';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (120202, 'spell_rimok_saboteur_bombard_target');

-- Rain Dance 124860 only applies periodic trigger auras. Its triggered spell
-- 124864 owns the TARGET_DEST_CASTER_RANDOM destination that the C++ script
-- relocates to the appropriate Brawler's Guild arena.
DELETE FROM `spell_script_names`
WHERE (`spell_id` = 124860 OR `spell_id` = 124864)
  AND `ScriptName` = 'spell_brawlers_guild_rain_dance';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (124864, 'spell_brawlers_guild_rain_dance');
