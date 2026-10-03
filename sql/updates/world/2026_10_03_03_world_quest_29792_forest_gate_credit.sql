-- ============================================================================
-- Quest 29792 "通往卓越" (Path to Greatness) - Pei-Wu Forest Gate credit fix
-- Applied: 2026-10-03
-- ============================================================================
-- Symptom: during the escort, the Pei-Wu Forest Gate visually opens (Jojo
-- Ironbrow activates GO 211298) but the second quest objective never counts
-- ("打开悲雾林大门" stays 0/1).  The first objective (Mandori Village Gate,
-- credit 59946) works because it is granted inside Aysa's opening script
-- (timed actionlist 5998600) while the player is still stored in target
-- list 1.
--
-- Official credit chain for the second gate:
--   1) Jojo Ironbrow (59989) reaches waypoint 12, pauses 3s, timed event 500ms
--   2) -> play emote 36 -> activate GO 211298 (gate opens)
--   3) -> SMART_ACTION_SET_DATA(0, 1) to CLOSEST_CREATURE(59986, 10yd)  [id 10]
--   4) -> SMART_ACTION_SET_DATA(0, 3) to CLOSEST_CREATURE(59988, 10yd)  [id 11]
--   5) Aysa (59986) on Data Set 0 1:
--        - removes player aura 78517 (Cliffwalker Post phase)
--        - SMART_ACTION_CALL_KILLEDMONSTER 59947 to STORED target list 1
--
-- Root cause: the two escort paths use asymmetric pauses (Jojo waits 22s at
-- his waypoint 11 while Aysa only waits 20s at hers and departs earlier).
-- Timeline simulation of both waypoint paths shows that at the moment Jojo
-- activates the gate, Aysa is already 13.5yd (walk speed) to 22.4yd (run
-- speed) away - beyond the 10yd CLOSEST_CREATURE search radius.  The target
-- resolution silently fails, Aysa never receives Data 0 1, and neither the
-- kill credit nor the player phase-aura removal executes.
--
-- Fix: widen the search radius of both SET_DATA targets from 10yd to 50yd.
-- Entries 59986/59988 only exist as temp summons of this escort scene, so a
-- 50yd radius cannot resolve to a wrong creature.  Takes effect after
-- `.reload smart_scripts` + re-accepting the quest (escort NPCs are
-- summoned fresh on each attempt).
-- ============================================================================

-- SECTION 1: Jojo Ironbrow - widen SET_DATA target radius (10 -> 50yd)
UPDATE `smart_scripts` SET `target_param2` = 50
WHERE `source_type` = 0 AND `entryorguid` = 59989 AND `id` IN (10, 11)
  AND `action_type` = 45;

-- Verification (expect target_param2 = 50 on both rows):
SELECT `id`, `action_type`, `target_type`, `target_param1`, `target_param2`, `comment`
FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 59989 AND `id` IN (10, 11);
