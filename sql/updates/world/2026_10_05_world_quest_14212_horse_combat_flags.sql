-- 14212 牺牲任务：Crowley's Horse 载具技能无法使用修复
-- 根因 1：35231 unit_flags=0x8300 含 IMMUNE_TO_PC(0x100)+IMMUNE_TO_NPC(0x200)。
--   Unit::IsValidAttackTarget 对 IMMUNE_TO_NPC 施法者直接判非法攻击目标（Unit.cpp,
--   "GetEntry() != WORLD_TRIGGER && !target->PVP_ATTACKABLE && HasFlag(IMMUNE_TO_NPC)"），
--   载具践踏 67063（TA=8 范围敌人）永远命中 0 目标 → 无伤害、无 SpellHit、无任务计数。
--   修复：剥掉两位免疫标志，仅保留 CAN_SWIM(0x8000)。马阵营为 35（全友善），
--   非乘坐期无 NPC/玩家会攻击它；乘坐期阵营被 SetCharmedBy 切为玩家阵营，可正常敌对。
-- 根因 2：44429（终点再骑马，上轮已升级为 VehicleId=463+SmartVehicleAI）漏配 spell1，
--   技能栏为空。补 67063 与 35231 一致。
UPDATE creature_template SET unit_flags=32768 WHERE entry=35231 AND unit_flags=33536;
UPDATE creature_template SET spell1=67063 WHERE entry=44429;
