-- Type-10 quest objectives may use objectId=-1 as a wildcard when the exact
-- AreaTrigger IDs are stored in areatrigger_involvedrelation. Trinity's
-- runtime explicitly supports this representation, including quests reached
-- by more than one AreaTrigger. objectId=0 is neither a valid DBC trigger nor
-- that wildcard and causes a startup validation error.
--
-- Restrict the conversion to the exact pre-audited objective IDs and require
-- an existing relation for the same quest. The 28 type-10 objectives without
-- a relation are intentionally left unchanged pending source reconstruction.

UPDATE `quest_objective` AS `qo`
SET `qo`.`objectId` = -1
WHERE `qo`.`type` = 10
  AND `qo`.`objectId` = 0
  AND `qo`.`id` IN
  (
      251660, 251678, 251754, 251893, 252033, 252075, 252154, 252542,
      252850, 252924, 253363, 253622, 253678, 253696, 253700, 254036,
      254066, 254264, 254343, 254909, 255104, 255155, 255657, 255658,
      255698, 255887, 256168, 256289, 256295, 256531, 256652, 257178,
      257269, 257382, 257501, 257948, 257978, 258177, 258219, 258340,
      258539, 259967, 260375, 260455, 260771, 260849, 260924, 261620,
      261661, 262110, 262375, 262524, 263342, 263613, 264398, 264415,
      264441, 266217, 266334, 266465, 266552, 267090, 267510, 267649
  )
  AND EXISTS
      (SELECT 1
       FROM `areatrigger_involvedrelation` AS `air`
       WHERE `air`.`quest` = `qo`.`questId`);
