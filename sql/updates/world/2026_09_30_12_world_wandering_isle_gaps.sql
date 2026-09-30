-- ============================================================
-- 2026_09_30_12_world_wandering_isle_gaps.sql
-- 迷踪岛(The Wandering Isle, WorldMapAreaId 808)任务链修复
--
-- 发现(2026-09-30 审计):
-- 1. 29407 "The First Sign of Winter"(学院支线, 拾取闪光莲花)
--    无任何发放/交付注册, 玩家无法获取。官方(Wowhead/WoWDB)
--    Start/End 均为 Master Shang Xi(npc 53566), 本库 53566 已刷出
--    (同 entry 承担 29406/29408/29409 学院主线), 补注册即可。
--
-- 记录在案(废弃/绝版, 不修, 与官方一致):
-- - 29404 Much to Learn / 29405 The Lesson of the Iron Staff:
--   被各职业变体 30027-30045 取代, Wowhead 标记 no longer available;
-- - 29703 Barrel of Monkies / 29705 Invasion of the Bottle Snatchers /
--   29773 Wugou, the Spirit of Earth: Blizzard 标记 obsolete/绝版;
-- - 30817 The Healing of Shen-zin Su + 30818 A New Fate:
--   被取代的孤儿副本(29799→29800 New Allies→31450 A New Fate 为 live 链),
--   全库无任何 prev/next/rnext 指向 30817。
--
-- 记录在案(无需修): 29406/29414/29420/29776/29784/29790 缺
-- quest_template_addon 行, 但均经其他任务的 NextQuestID/RewardNextQuest
-- 正确门控(30027-30038 → 29406; 29419/29424 → 29414; 29418/29523 → 29420;
-- 29775 → 29776; 29779/29780/29781 → 29784; 29788/29789 → 29790),
-- official_ref 同样缺这些行, 属官方原始形态。
-- ============================================================

DELETE FROM `creature_queststarter` WHERE `quest` = 29407;
DELETE FROM `creature_questender`   WHERE `quest` = 29407;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (53566, 29407);
INSERT INTO `creature_questender`   (`id`, `quest`) VALUES (53566, 29407);
