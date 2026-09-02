-- Rollback for 2026_09_02_03_world_restore_korkron_skullsplitter_text.sql.
-- No row existed for this creature/group/id before the update.

DELETE FROM `creature_text`
WHERE `CreatureID` = 72744 AND `GroupID` = 0 AND `ID` = 0;
