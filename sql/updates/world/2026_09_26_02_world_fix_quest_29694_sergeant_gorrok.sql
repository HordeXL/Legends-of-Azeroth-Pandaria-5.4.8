-- ==================================================================
-- 任务 29694 (Regroup! / 重组!) - 格罗克中士无法完成营救计数
-- ==================================================================
-- 现象：与格罗克中士（Sergeant Gorrok, 55162）对话时屏幕提示
--       「你在错误的区域中」（SPELL_FAILED_INCORRECT_AREA），
--       任务目标「营救格罗克中士」停留在 0/1。
--
-- 机制：四个营救 NPC（55141/55146/55162/55170）均为 SAI gossip hello
--       → SMART_ACTION_INVOKER_CAST(85) 让玩家施放各自的营救法术
--       （102972/102987/103014/103027），击杀 credited 由法术效果完成。
--       55162 对应的法术 103014 自带 AreaGroupId 区域限制，而服务器
--       区域数据（DBC）下玩家所站位置不在允许列表内 → 施法被
--       SpellInfo::CheckLocation 拒绝，credited 链路中断。
--       （其余三个 NPC 的法术区域校验正常，不受影响。）
--
-- 修复：将 55162 的 SAI 动作从 INVOKER_CAST 改为
--       SMART_ACTION_CALL_KILLEDMONSTER(33)，对话时直接给触发对话的
--       玩家（target_type 7 = ACTION_INVOKER）记 55162 的击杀
--       credited → Player::KilledMonsterCredit 推进任务目标。
--       同时消除错误提示（不再尝试施法）。
--
-- 幂等：仅当当前动作仍为 85/103014 时更新；可重复执行。
-- 生效：重启 worldserver，或游戏内 .reload smart_scripts
-- ==================================================================

UPDATE `smart_scripts`
SET `action_type`   = 33,      -- SMART_ACTION_CALL_KILLEDMONSTER
    `action_param1` = 55162,   -- 击杀 credited 的生物 entry
    `action_param2` = 0,
    `comment`       = 'Sergeant Gorrok - Direct kill credit for quest 29694 (bypass area-restricted rescue spell 103014)'
WHERE `entryorguid` = 55162
  AND `source_type` = 0
  AND `id`          = 0
  AND `event_type`  = 62       -- SMART_EVENT_GOSSIP_HELLO
  AND `action_type` = 85       -- SMART_ACTION_INVOKER_CAST
  AND `action_param1` = 103014;
