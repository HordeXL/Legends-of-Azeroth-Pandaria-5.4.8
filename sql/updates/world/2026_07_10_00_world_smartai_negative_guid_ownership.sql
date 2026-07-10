-- Restore the Horde Brewfest Gordok Brew Barker spawn-specific SmartAI owner.
--
-- The imported SAI used spawn GUID 84709, but that GUID currently belongs to
-- Driz Tumblequick (entry 24510).  The actual nearby Horde Gordok Brew Barker
-- is GUID 84711 (entry 23685).  The Dark Iron event generator also retained
-- the stale 84709 target, so both sides of the same event chain must move.
-- No SmartAI rows are deleted.

UPDATE `smart_scripts`
SET `entryorguid` = -84711
WHERE `source_type` = 0
  AND `entryorguid` = -84709
  AND `comment` LIKE 'Gordok Brew Barker%'
  AND EXISTS
  (
      SELECT 1
      FROM `creature`
      WHERE `guid` = 84711
        AND `id` = 23685
  )
  AND NOT EXISTS
  (
      SELECT 1
      FROM
      (
          SELECT `entryorguid`
          FROM `smart_scripts`
          WHERE `source_type` = 0
            AND `entryorguid` = -84711
          LIMIT 1
      ) AS `existing_target_sai`
  );

UPDATE `smart_scripts`
SET `target_param1` = 84711
WHERE `source_type` = 9
  AND `entryorguid` = 2370303
  AND `action_type` = 45
  AND `target_type` = 10
  AND `target_param1` = 84709
  AND `target_param2` = 23685
  AND `comment` LIKE '%Gordok Brew Barker%'
  AND EXISTS
  (
      SELECT 1
      FROM `creature`
      WHERE `guid` = 84711
        AND `id` = 23685
  );
