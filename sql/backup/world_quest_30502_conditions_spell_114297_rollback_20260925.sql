-- 回滚脚本：移除天神灵玉(114297)的目标限制条件
-- 对应更新：2026_09_25_01_world_limit_spell_114297_target_30502.sql
-- 应用后执行 .reload conditions

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 17 AND `SourceEntry` = 114297;
