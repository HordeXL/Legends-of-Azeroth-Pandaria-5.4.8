-- Lost in Action (29563): Greenthumb's objective pointed at Bite's cage,
-- and Bite had no objective POI. Keep the turn-in POI (Idx1 = 0).
DELETE FROM `quest_poi_points` WHERE `QuestID` = 29563 AND `Idx1` IN (1, 2);
DELETE FROM `quest_poi` WHERE `QuestID` = 29563 AND `Idx1` IN (1, 2);

INSERT INTO `quest_poi`
    (`QuestID`, `Idx1`, `ObjectiveIndex`, `QuestObjectiveId`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
VALUES
    (29563, 1, 1, 257387, 547, 728, 1, 0, 7, 0), -- Weeder Greenthumb
    (29563, 2, 0, 257386, 547, 728, 1, 0, 7, 0); -- Naturalist Bite

INSERT INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
VALUES
    (29563, 1, 1, 0, -303, -382, 0), -- Greenthumb spawn: -303.454, -381.544
    (29563, 2, 2, 0, -197, -799, 0); -- Bite spawn: -197.198, -799.336
