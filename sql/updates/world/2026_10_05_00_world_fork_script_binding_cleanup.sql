-- Imported C++ scripts replace these SmartAI implementations. Retaining both
-- leaves unused SmartAI rows and startup errors against the existing database.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` IN (55693, 56206, 56209, 56210, 64645);

-- The Hadronox encounter script creates these creatures dynamically. Their
-- disabled duplicate database spawns cannot own or depend on linked respawns.
DELETE lr FROM `linked_respawn` lr
LEFT JOIN `creature` sourceSpawn ON sourceSpawn.`guid` = lr.`guid`
LEFT JOIN `creature` targetSpawn ON targetSpawn.`guid` = lr.`linkedGuid`
WHERE lr.`linkType` = 0
  AND ((sourceSpawn.`map` = 601 AND sourceSpawn.`id` IN (28921,28922,29117,29118) AND sourceSpawn.`spawnMask` = 0)
    OR (targetSpawn.`map` = 601 AND targetSpawn.`id` IN (28921,28922,29117,29118) AND targetSpawn.`spawnMask` = 0));
