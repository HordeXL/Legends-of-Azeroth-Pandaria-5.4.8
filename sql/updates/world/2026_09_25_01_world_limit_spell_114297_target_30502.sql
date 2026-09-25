-- =============================================
-- 任务 30502《灵玉之心》——限制天神灵玉的使用目标
-- 2026-09-25
-- =============================================
-- 需求：物品 80074「天神灵玉」施放的法术 114297「纯净能量」只能对
--       邪煞残影（creature 59434）与残影本体（creature 59454）使用。
--
-- 机制：Spell::CheckCast (Spell.cpp:6403) 对显式目标检查
--       CONDITION_SOURCE_TYPE_SPELL(17) 条件，ConditionTarget=1
--       对应 ConditionSourceInfo(m_caster, m_targets.GetObjectTarget())
--       的第 2 个对象（玩家选中的目标）。
--       条件类型 31 = CONDITION_OBJECT_ENTRY_GUID：
--         ConditionValue1 = TypeID（3 = TYPEID_UNIT）
--         ConditionValue2 = entry
--         ConditionValue3 = guid（0 = 任意）
--       不同 ElseGroup 之间为 OR 关系 → "目标是 59434 或 59454"。
--       条件不满足时未设置 ErrorType，默认返回 SPELL_FAILED_BAD_TARGETS
--       （客户端提示"无效的目标"）。
--
-- 说明：SPELL_IMPLICIT_TARGET(13) 条件只作用于隐式/区域目标搜索，
--       对 TARGET_UNIT_TARGET_ENEMY 显式单体目标无效，故必须用源类型 17。
--
-- 热更：.reload conditions
-- 回滚：sql/backup/world_quest_30502_conditions_spell_114297_rollback_20260925.sql
-- =============================================

-- 幂等：先清掉本法术旧的限制条件再插入
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 17 AND `SourceEntry` = 114297;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
-- 目标是邪煞残影 59434
(17, 0, 114297, 0, 0, 31, 1, 3, 59434, 0, 0, 0, 0, '', '30502: 纯净能量只能对邪煞残影(59434)使用'),
-- 目标是残影本体 59454
(17, 0, 114297, 0, 1, 31, 1, 3, 59454, 0, 0, 0, 0, '', '30502: 纯净能量只能对邪煞残影本体(59454)使用');
