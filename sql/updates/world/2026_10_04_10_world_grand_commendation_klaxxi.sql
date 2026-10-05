-- Grand Commendation of the Klaxxi (item 92522 / spell 135719) is a dummy
-- spell in the client and requires a server script to unlock its account-wide
-- reputation bonus.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 135719 AND `ScriptName` = 'spell_item_grand_commendation_of_the_klaxxi';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(135719, 'spell_item_grand_commendation_of_the_klaxxi');
