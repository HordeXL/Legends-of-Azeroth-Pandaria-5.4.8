-- DungeonEncounter.dbc: Braun = 1422 (bit 2), Harlan = 1421 (bit 1),
-- Koegler = 1420 (bit 0). Only Koegler had instance_encounters rows, so a
-- completed Normal/Heroic run recorded mask 1 instead of 7.
-- Restore the two missing kill credits; only Koegler finishes the LFG dungeon.
INSERT INTO `instance_encounters`
    (`entry`, `difficulty`, `creditType`, `creditEntry`, `lastEncounterDungeon`, `comment`)
VALUES
    (1422, 'DUNGEON_NORMAL', 0, 59303, 0, 'Houndmaster Braun'),
    (1422, 'DUNGEON_HEROIC', 0, 59303, 0, 'Houndmaster Braun'),
    (1421, 'DUNGEON_NORMAL', 0, 58632, 0, 'Armsmaster Harlan'),
    (1421, 'DUNGEON_HEROIC', 0, 58632, 0, 'Armsmaster Harlan')
ON DUPLICATE KEY UPDATE
    `creditType` = VALUES(`creditType`),
    `creditEntry` = VALUES(`creditEntry`),
    `lastEncounterDungeon` = VALUES(`lastEncounterDungeon`),
    `comment` = VALUES(`comment`);
