-- Quest 26228 "Livin' the Life": retain the exterior Westfall mine marker
-- and add a separate first-floor Jangolode Mine marker at the crate-use spot.
DELETE FROM `quest_poi_points`
WHERE `QuestID` = 26228 AND `BlobIndex` = 2;
DELETE FROM `quest_poi`
WHERE `QuestID` = 26228 AND `Idx1` = 2;

INSERT INTO `quest_poi`
    (`QuestID`, `Idx1`, `ObjectiveIndex`, `QuestObjectiveId`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
VALUES
    (26228, 2, 16, 0, 0, 39, 1, 0, 7, 0);

INSERT INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
VALUES
    (26228, 2, 2, 0, -9842, 1400, 0);
