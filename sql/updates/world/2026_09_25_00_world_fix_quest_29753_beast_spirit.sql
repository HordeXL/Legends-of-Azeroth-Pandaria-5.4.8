-- ============================================================
-- Fix Quest 29753 "Back to Nature" (重归自然)
-- Date: 2026-09-25
--
-- Problems:
--   1) Killing Raging Beast Spirit (55790) never counted toward
--      the quest objective 55462 "Beast Spirit Kill Credit" (0/8)
--      because the creature template had no KillCredit.
--   2) Using Spirit Bottles (item 74808, spell 104737 -> 104740)
--      summoned nothing: SpellEffect.dbc row for spell 104740
--      effect index 1 had Effect = 0 (none) and no effect index 2
--      existed, so the ScriptEffect had nothing to summon with.
--      (Summon part is fixed by patching SpellEffect.dbc, see
--      SpellEffect.dbc.bak_20260925_q29753 backup.)
--
-- Changes in this file (idempotent):
--   A) creature_template 55790: KillCredit1 = 55462
--      -> killing Raging Beast Spirit now counts 0/8 objective.
--   B) creature_template 55787: AIName = 'SmartAI'
--   C) smart_scripts 55787: despawn itself 45s after summon
--      (peaceful spirit is pure ambience, must not persist forever
--      now that every bottle throw summons one)
--
-- Note: server-side SpellEffect.dbc patch requires a worldserver
--       restart; the DB changes support `.reload creature_template`
--       and `.reload smart_scripts`.
-- ============================================================

-- A) Kill credit for Raging Beast Spirit -> Beast Spirit Kill Credit
UPDATE `creature_template`
SET `KillCredit1` = 55462
WHERE `entry` = 55790
  AND (`KillCredit1` = 0 OR `KillCredit1` IS NULL);

-- B) Enable SmartAI for Peaceful Beast Spirit
UPDATE `creature_template`
SET `AIName` = 'SmartAI'
WHERE `entry` = 55787
  AND (`AIName` = '' OR `AIName` IS NULL);

-- C) Peaceful Beast Spirit: despawn itself after ~45s OOC
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 55787;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(55787, 0, 0, 0, 1, 0, 100, 0,
 45, 45, 0, 0, 0,
 41, 0, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0,
 'Peaceful Beast Spirit - Out of Combat 45s - Force Despawn');
