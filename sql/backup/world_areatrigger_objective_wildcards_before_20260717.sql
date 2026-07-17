-- Exact rollback for the 64 relation-backed type-10 quest objectives repaired
-- by 2026_07_17_03_world_fix_areatrigger_objective_wildcards.sql.
-- Captured 2026-07-17 with Wampserver MySQL 5.7.44.
-- Every listed row had objectId=0 before the repair. No relation row changed.

START TRANSACTION;

UPDATE `quest_objective`
SET `objectId` = 0
WHERE `type` = 10
  AND `objectId` = -1
  AND `id` IN
  (
      251660, 251678, 251754, 251893, 252033, 252075, 252154, 252542,
      252850, 252924, 253363, 253622, 253678, 253696, 253700, 254036,
      254066, 254264, 254343, 254909, 255104, 255155, 255657, 255658,
      255698, 255887, 256168, 256289, 256295, 256531, 256652, 257178,
      257269, 257382, 257501, 257948, 257978, 258177, 258219, 258340,
      258539, 259967, 260375, 260455, 260771, 260849, 260924, 261620,
      261661, 262110, 262375, 262524, 263342, 263613, 264398, 264415,
      264441, 266217, 266334, 266465, 266552, 267090, 267510, 267649
  );

COMMIT;
