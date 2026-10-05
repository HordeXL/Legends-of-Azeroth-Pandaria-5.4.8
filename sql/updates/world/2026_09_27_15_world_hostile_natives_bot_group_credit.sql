-- Hostile Natives is a private report, but its credit must work in bot raid groups.
-- Normal quest credit routines otherwise skip both inspection NPC objectives.
UPDATE quest_template SET Flags = Flags | 64 WHERE ID = 29730;
