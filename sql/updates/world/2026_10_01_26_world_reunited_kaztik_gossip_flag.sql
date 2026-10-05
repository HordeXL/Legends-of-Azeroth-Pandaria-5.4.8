-- Reunited (31091)
-- The starter script supplies the "begin escort" gossip option, but the
-- client gossip request is rejected by the core unless Kaz'tik also has the
-- UNIT_NPC_FLAG_GOSSIP flag in addition to QUESTGIVER.

UPDATE `creature_template`
SET `npcflag` = (`npcflag` | 1)
WHERE `entry` = 63876;
