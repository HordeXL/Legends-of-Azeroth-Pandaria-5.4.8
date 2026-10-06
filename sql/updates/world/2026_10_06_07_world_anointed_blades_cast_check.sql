-- Check the matching active quest, instance, difficulty and Whitemane corpse
-- before a successful cast can consume either version of the quest item.
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (126787, 126843) AND `ScriptName` = 'spell_sc_blades_of_the_anointed';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES
    (126787, 'spell_sc_blades_of_the_anointed'),
    (126843, 'spell_sc_blades_of_the_anointed');
