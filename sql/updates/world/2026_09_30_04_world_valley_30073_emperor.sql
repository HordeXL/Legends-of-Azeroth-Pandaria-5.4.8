-- 2026_09_30_04_world_valley_30073_emperor.sql
-- 四风谷任务链审计（300 任务）修复：补「帝王酒」(The Emperor, 30073) 的汇聚行。
--
-- 官方行为（Wowpedia The Emperor）：Previous = Stormstout's Hops (30055) +
-- The Chen Taste Test (30047) + Barreling Along (30172) —— 三条线（酿酒花/谷物/水）
-- 全部完成后才能接。Wowpedia Progression:
--   Chen's Resolution(30046) → Complete all of:
--     Hops:  Hop Hunting(30053) → Stormstout's Hops(30055)
--     Grain: Li Li and the Grain(30048) → Taste Test(30031) → The Quest for Better Barley(30032) → The Chen Taste Test(30047)
--     Water: Doesn't Hold Water(30049) → The Great Water Hunt(30051) → Barreling Along(30172)
--   → The Emperor(30073) → Knocking on the Door(30074)
--
-- 本地问题：组 -30073 的三个成员行都在（30047/30055/30172，均 ExclusiveGroup=-30073），
-- 但 30073 自己没有 quest_template_addon 行（无 PrevQuestID、无 ExclusiveGroup），
-- 核心 each-from-all 检查（Player.cpp SatisfyQuestPrevChain: ExclusiveGroup<0 要求
-- 组内全部任务已完成+已奖励）不会触发。现状：
--   - 完成 30047 或 30172 任一条（RewardNextQuest=30073）即可接 → 跳过第三条线；
--   - 只完成 30055 酿酒花线则永远接不到。
--
-- 修复：PrevQuestID=30047（作为 prev 链入口）+ ExclusiveGroup=-30073。
-- 接取时核心将要求 30055 与 30172 也已完成，恢复官方三线汇聚。

DELETE FROM `quest_template_addon` WHERE `ID` = 30073;
INSERT INTO `quest_template_addon`
  (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`, `ExclusiveGroup`, `SpecialFlags`)
VALUES
  (30073, 0, 0, 0, 30047, 0, -30073, 0);
