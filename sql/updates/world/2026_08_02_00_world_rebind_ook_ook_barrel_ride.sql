-- Build 18414 defines 122169 as a non-aura effect that triggers 122163, so it
-- cannot execute spell_ook_ook_barrel_ride's CONTROL_VEHICLE AuraScript.
--
-- The Stormstout Brewery source defines Barrel Ride as 106614 and the barrel
-- NPC casts that exact spell when clicked. Build 18414 defines 106614 effect 0
-- as SPELL_AURA_CONTROL_VEHICLE (236), exactly matching both script hooks.
-- Keep the existing spell_brew_barrel_ride association on 106614 as well;
-- it handles the spell's distinct periodic effect 2.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 122169
  AND `ScriptName` = 'spell_ook_ook_barrel_ride';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(106614, 'spell_ook_ook_barrel_ride');
