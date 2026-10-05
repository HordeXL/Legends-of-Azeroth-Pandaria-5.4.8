-- The functional Powder Keg fallback leaves the player at Khartut's Tomb
-- rather than playing the original cinematic/relocation to Harrison 45180.
-- Allow the starting Harrison (44860) beside the keg to accept completion.
-- Retain the original southern turn-in and subsequent quest starters.
INSERT IGNORE INTO `creature_questender` (`id`,`quest`) VALUES (44860,27141);
