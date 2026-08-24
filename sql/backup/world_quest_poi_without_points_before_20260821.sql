-- Exact preservation of 11 incomplete quest POI headers before the
-- 2026-08-21 startup-log cleanup. Evidence only; do not load during normal
-- updates.

INSERT INTO `quest_poi`
(`QuestID`, `Idx1`, `ObjectiveIndex`, `QuestObjectiveId`, `MapID`,
 `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(3379,  1, -1,      0,   0,  28, 0, 0, 3, 0),
(6922,  0,  4,      0,   1,  43, 0, 0, 7, 0),
(10216, 1,  1,      0, 530, 478, 0, 0, 7, 0),
(11078, 6,  4,      0, 530, 475, 0, 0, 3, 0),
(24591, 2, -1,      0,   1, 607, 0, 0, 7, 0),
(27228, 2, -1,      0, 329, 765, 1, 0, 7, 0),
(28170, 1,  1,      0,   0, 700, 0, 0, 7, 0),
(29151, 0, -1,      0,   0, 673, 0, 0, 7, 0),
(29178, 0, -1,      0, 568, 781, 0, 0, 7, 0),
(29763, 1,  4,      0, 574, 523, 1, 0, 7, 0),
(32944, 1,  0, 270693, 870, 807, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
  `ObjectiveIndex` = VALUES(`ObjectiveIndex`),
  `QuestObjectiveId` = VALUES(`QuestObjectiveId`),
  `MapID` = VALUES(`MapID`),
  `WorldMapAreaId` = VALUES(`WorldMapAreaId`),
  `Floor` = VALUES(`Floor`),
  `Priority` = VALUES(`Priority`),
  `Flags` = VALUES(`Flags`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);
