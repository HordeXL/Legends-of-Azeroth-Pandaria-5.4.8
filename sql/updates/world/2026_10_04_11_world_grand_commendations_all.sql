-- All thirteen Pandaria Grand Commendations use a self-targeted dummy spell.
-- Teach that spell as an account spell; the core maps it back to the matching
-- faction when calculating reputation and when building the reputation UI.
DELETE FROM `spell_script_names`
WHERE `spell_id` IN
(
    135704, 135710, 135711, 135712, 135713, 135714, 135715,
    135716, 135717, 135719, 140226, 140228, 140235
);

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(135704, 'spell_item_grand_commendation'), -- The Anglers
(135710, 'spell_item_grand_commendation'), -- Operation: Shieldwall
(135711, 'spell_item_grand_commendation'), -- Dominance Offensive
(135712, 'spell_item_grand_commendation'), -- The Lorewalkers
(135713, 'spell_item_grand_commendation'), -- Order of the Cloud Serpent
(135714, 'spell_item_grand_commendation'), -- The Tillers
(135715, 'spell_item_grand_commendation'), -- Shado-Pan
(135716, 'spell_item_grand_commendation'), -- The August Celestials
(135717, 'spell_item_grand_commendation'), -- Golden Lotus
(135719, 'spell_item_grand_commendation'), -- The Klaxxi
(140226, 'spell_item_grand_commendation'), -- Kirin Tor Offensive
(140228, 'spell_item_grand_commendation'), -- Sunreaver Onslaught
(140235, 'spell_item_grand_commendation'); -- Shado-Pan Assault

-- The client classifies these as heirloom-quality Battle.net-account items,
-- but the core's mail/trade checks use the legacy bind-to-account item flag.
UPDATE `item_template`
SET `flags` = `flags` | 0x08000000
WHERE `entry` IN
(
    92522, 93215, 93220, 93224, 93225, 93226, 93229,
    93230, 93231, 93232, 95545, 95548, 95559
);
