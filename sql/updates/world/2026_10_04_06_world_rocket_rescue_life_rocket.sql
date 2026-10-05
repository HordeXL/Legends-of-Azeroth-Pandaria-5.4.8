-- Rocket Rescue (24910 / 25050): Deliver Life-Rocket targets the ground, but
-- the quest objective uses a separate credit bunny (38576). Bind the impact
-- script that awards one credit when the missile lands near a survivor.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 75560;

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(75560, 'spell_rocket_rescue_deliver_life_rocket');
