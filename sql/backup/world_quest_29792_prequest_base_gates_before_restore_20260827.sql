-- Exact rollback for
-- 2026_08_27_04_world_quest_29792_restore_prequest_base_gates.sql.

DELETE FROM `object_visibility_state`
WHERE `type` = 'GameObject'
  AND `entryorguid` IN (-540359, -540026)
  AND `visibilityQuestID` = 29792
  AND `visibilityQuestState` = 0;

DELETE FROM `gameobject`
WHERE (`guid` = 540359 AND `id` = 210965 AND `map` = 860)
   OR (`guid` = 540026 AND `id` = 210964 AND `map` = 860);
