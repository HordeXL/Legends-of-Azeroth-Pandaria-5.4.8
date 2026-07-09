-- Runtime log cleanup for Dalaran NPCs that call CreatureTextMgr without rows.
-- Non-destructive: do not delete or replace existing creature_text rows.
-- Exact sniffed text for these entries was not present in local SkyFire/current DB sources.
-- These rows use existing generic broadcast_text where a role-appropriate text exists,
-- otherwise a neutral greeting is used so missing text calls no longer spam runtime logs.

INSERT IGNORE INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(28703, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Linzy Blackbolt - fallback greeting'),
(28704, 0, 0, 'Another Herbalist, hmm. I doubt your skill is as great as my own so perhaps I can train you in a few proper techniques.', 12, 0, 100, 0, 0, 0, 0, 3337, 0, 'Dorothy Egan - herbalism trainer greeting'),
(29511, 0, 0, 'Welcome to my shop, it''s good to see another Tailor here in Stormwind. Are you here for a lesson perhaps?', 12, 0, 100, 0, 0, 0, 0, 3338, 0, 'Lalla Brightweave - tailoring trainer greeting'),
(32172, 0, 0, 'Just browsing my wares or is there something specific I can help you find today?', 12, 0, 100, 0, 0, 0, 0, 3378, 0, 'Harold Winston - jewelry vendor greeting'),
(32450, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Badluck - neutral fallback greeting'),
(32606, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, '[DND] Cosmetic Book - neutral fallback text'),
(35496, 0, 0, 'Just browsing my wares or is there something specific I can help you find today?', 12, 0, 100, 0, 0, 0, 0, 3378, 0, 'Rueben Lauren - cloth armor merchant greeting'),
(47581, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Archmage Aranhir Starsinger - neutral fallback greeting');
