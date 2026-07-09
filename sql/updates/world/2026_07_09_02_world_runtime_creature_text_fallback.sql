-- Runtime CreatureTextMgr cleanup discovered after Dalaran/Pandaria walk-through.
-- Non-destructive: do not delete or replace existing creature_text rows.
-- Exact sniffed text for these entries was not present in local sources during review.
-- Role-specific existing broadcast_text is used where the creature_template role is clear;
-- neutral greeting is used for visitor/flavor NPCs without a clear vendor/trainer role.

INSERT IGNORE INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(29506, 0, 0, 'Welcome to my forge, Blacksmith. Let me share with you a little secret. No one, no one in the world can you trust. Not men, not women, not beasts ... this you can trust, Steel.', 12, 0, 100, 0, 0, 0, 0, 3944, 0, 'Orland Schaeffer - blacksmithing trainer fallback'),
(32709, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Hunaka Greenhoof - neutral fallback greeting'),
(32711, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Warp-Huntress Kula - neutral fallback greeting'),
(32714, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Moon Priestess Nici - neutral fallback greeting'),
(32718, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Disidra Stormglory - neutral fallback greeting'),
(32720, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Violetta - neutral fallback greeting'),
(35497, 0, 0, 'Greetings.  If you are here for leather goods, then you will find my wares well crafted.', 12, 0, 100, 0, 0, 0, 0, 8114, 0, 'Rafael Langrom - leather armor merchant fallback'),
(64077, 0, 0, 'Just browsing my wares or is there something specific I can help you find today?', 12, 0, 100, 0, 0, 0, 0, 3378, 0, 'Kergan Swiftbeard - trade goods fallback'),
(64160, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Frostflower - neutral fallback greeting'),
(65574, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Brad Rhodes - neutral fallback greeting');
