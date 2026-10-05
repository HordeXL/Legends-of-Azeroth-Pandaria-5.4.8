-- Requires the matching worldserver script in zone_uldum.cpp.
-- Restore item activation credit for Do the Honors at Ancient Mechanism.
INSERT IGNORE INTO `spell_script_names` (`spell_id`,`ScriptName`)
VALUES (89314,'spell_uldum_orbs_of_the_stars');
