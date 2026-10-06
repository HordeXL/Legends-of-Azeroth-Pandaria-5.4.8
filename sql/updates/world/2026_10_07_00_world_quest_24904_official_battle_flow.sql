-- ============================================================
-- Quest 24904 "The Battle for Gilneas City" - official battle flow (merged)
-- 吉尔尼斯城保卫战：官方五幕战斗流程（合并版，含相位修复终值）
--
-- 官方流程（Wowhead/Wowpedia 4.x 实机数据）：
--   接任务(Lorna Crowley 37783, 城门) -> 传送进相位城(654) -> 与克雷南对话开战
--   -> 利亚姆率队推进：商业区 -> 军事区(大炮轰憎恶) -> 监狱杀 Gorerot
--   -> 广场终幕：希尔瓦娜斯 25% 触发女王之嚎 RP -> 旅店 Lorna(38611) 交任务
--
-- 合并自（按应用顺序，最终值已直接写入，勿按旧文件重放）：
--   2026_10_06_00_world_quest_24904_official_battle_flow.sql
--   2026_10_06_01_world_quest_24904_battle_script.sql
--   2026_10_07_00_world_quest_24904_phase_fix.sql
--
-- 相位说明（重要）：
--   zone 4714 (Gilneas City) 的 phase_definitions 全部无条件生效，
--   城内玩家 phasemask 恒为 0x7E540E（不含位 1）。
--   战斗演员 phaseMask 必须 = 0x7E540E | 1 = 8279055 (0x7E540F) 才对玩家可见；
--   终幕三人组（希尔瓦娜斯/吉恩/缚魂女妖）保持 phaseMask = 1 隐藏，
--   由 C++ 控制器 npc_battle_liam_gilneas 用 BATTLE_PHASEMASK_VISIBLE 揭示。
-- ============================================================

-- ---------- 1. zhCN 完成日志（官方文案，术语与任务描述保持一致：格雷迈恩） ----------
UPDATE `quest_template_locale`
SET `QuestCompletionLog` = '到吉尔尼斯城的格雷迈恩广场，广场中有间旅店，到旅店里与罗娜·克罗雷交谈。'
WHERE `ID` = 24904 AND `locale` = 'zhCN';

-- ---------- 2. 还原官方双目标：消灭腐血怪 + 完成吉尔尼斯城保卫战 ----------
INSERT INTO `quest_objective` (`questId`,`id`,`index`,`type`,`objectId`,`amount`,`flags`,`description`) VALUES
(24904, 289862, 0, 0, 38331, 1, 0, 'Gorerot slain');

-- 完成信用目标排在第二（官方顺序）
UPDATE `quest_objective` SET `index` = 1 WHERE `id` = 265467;

-- 新目标的本地化
INSERT INTO `quest_objectives_locale` (`ID`,`locale`,`QuestId`,`StorageIndex`,`Description`,`VerifiedBuild`) VALUES
(289862, 'zhCN', 24904, 0, '消灭腐血怪', 0),
(289862, 'zhTW', 24904, 0, '消滅血腐怪', 0);
UPDATE `quest_objectives_locale` SET `StorageIndex` = 1 WHERE `ID` = 265467;

-- ---------- 3. 删除"接任务即发放信用"的临时 hack ----------
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 37783 AND `id` = 0;

-- 传送行由 LINK 改为独立的接任务事件（保留官方接任务传送）
UPDATE `smart_scripts`
SET `event_type` = 19, `event_param1` = 24904, `link` = 0,
    `comment` = 'Lorna Crowley - Quest Accept - Teleport Player into Gilneas City (654)'
WHERE `source_type` = 0 AND `entryorguid` = 37783 AND `id` = 1;

-- ---------- 4. Gorerot：死亡时按官方方式发放战斗胜利信用 ----------
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 38331;

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 38331;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(38331, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0,
 11, 72349, 2, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0, 0,
 'Gorerot - On Death - Cast Battle Complete credit spell 72349 (200y, credit 38854)');

-- ---------- 5. 战斗演员相位（终值 0x7E540F，对城内玩家可见） ----------
UPDATE `creature` SET `phaseMask` = 8279055 WHERE `map` = 654 AND `id` IN (
    37783, -- Lorna Crowley (gate, quest giver 24676/24904)
    38611, -- Lorna Crowley (inn, quest ender 24904/24902/24903)
    38218, -- Prince Liam Greymane (battle controller)
    38144, -- Krennan Aranas (battle starter)
    38149, -- Lord Darius Crowley
    38363, -- Forsaken Invader
    38287, -- Forsaken Catapult
    38616, -- Forsaken Infantry
    38617, -- Forsaken General
    38618, -- Forsaken Sergeant
    38210, -- Forsaken Crossbowman
    38420, -- Vile Abomination
    38464, -- Dark Ranger Elite
    38331, -- Gorerot
    38377, -- Damaged Catapult
    35317, -- Rebel Cannon
    38424, -- Emberstone Cannon
    38221, -- Gilnean Militia
    38348  -- Worgen Warrior
);

-- 终幕三人组：隐藏（phaseMask = 1），由利亚姆控制器在终幕揭示
UPDATE `creature` SET `phaseMask` = 1 WHERE `map` = 654 AND `id` IN (38469, 38470, 38473);

-- ---------- 6. 利亚姆与克雷南移至广场集结点（接任务传送落点） ----------
UPDATE `creature` SET `position_x` = -1672.0, `position_y` = 1633.0, `position_z` = 20.6, `orientation` = 3.9 WHERE `guid` = 222317;
UPDATE `creature` SET `position_x` = -1690.0, `position_y` = 1630.0, `position_z` = 20.6, `orientation` = 3.9 WHERE `guid` = 219336;

-- 删除广场上的重复利亚姆出生点
DELETE FROM `creature` WHERE `guid` = 219446;

-- ---------- 7. 绑定 C++ 脚本 ----------
UPDATE `creature_template` SET `ScriptName` = 'npc_battle_liam_gilneas' WHERE `entry` = 38218;
UPDATE `creature_template` SET `ScriptName` = 'npc_battle_krennan_gilneas' WHERE `entry` = 38144;

-- ---------- 8. 缺失的官方喊话（enUS 源行） ----------
DELETE FROM `creature_text` WHERE `CreatureID` IN (38149, 38144) AND `GroupID` IN (0, 1);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(38149, 0, 0, 'He''s too strong! Use the catapults to bring him down!', 14, 0, 100, 0, 0, 0, 0, 0, 1, 'Lord Darius Crowley - Gorerot fight'),
(38149, 1, 0, 'Let us join your father''s force, Liam. They''ll need our help against Sylvanas.', 14, 0, 100, 0, 0, 0, 0, 0, 1, 'Lord Darius Crowley - after Gorerot'),
(38144, 0, 0, 'It''s time to join the fray! With you on our side the scales will surely tip in our favor!', 14, 0, 100, 0, 0, 0, 0, 0, 1, 'Krennan Aranas - battle start'),
(38144, 1, 0, 'The time to take back Gilneas City is at hand. Let us take back our city!', 12, 0, 100, 0, 0, 0, 0, 0, 1, 'Krennan Aranas - battle talk');

-- ---------- 9. 全部战斗台词的 zhCN 本地化 ----------
DELETE FROM `creature_text_locale` WHERE `Locale` = 'zhCN' AND `CreatureID` IN (38218, 38470, 38469, 38331, 38149, 38144);
INSERT INTO `creature_text_locale` (`CreatureID`, `GroupID`, `ID`, `Locale`, `Text`) VALUES
-- Prince Liam: speech (groups 0-6)
(38218, 0, 0, 'zhCN', '被遗忘者以为我们软弱无能。心灰意冷。他们以为我们会像丧家犬一样投降。'),
(38218, 1, 0, 'zhCN', '他们大错特错了。我们会在旷野上战斗，直到最后一条战壕崩塌，最后一门大炮哑火。'),
(38218, 2, 0, 'zhCN', '我们会在城市中战斗，直到射出最后一颗子弹，然后我们会掘起铺路的石块，砸向他们的脑袋。'),
(38218, 3, 0, 'zhCN', '我们会在巷道里战斗，直到我们用尽最后一丝气力，手中的刀剑崩成碎片。'),
(38218, 4, 0, 'zhCN', '即使被包围，失去武器，身受重伤，毫无希望……我们也会高昂着头，将唾沫啐在敌人的脸上。'),
(38218, 5, 0, 'zhCN', '但是我们……决不投降！！！'),
(38218, 6, 0, 'zhCN', '为吉尔尼斯而战！'),
-- Prince Liam: battle commands (groups 7-11)
(38218, 7, 0, 'zhCN', '进攻！'),
(38218, 8, 0, 'zhCN', '把他们压回去！'),
(38218, 9, 0, 'zhCN', '憎恶封锁了通向军事区的道路！这将会是一场硬仗。'),
(38218, 10, 0, 'zhCN', '看到你真是太好了，罗娜。让大家登上大炮！'),
(38218, 11, 0, 'zhCN', '克罗雷的部队就在前方！继续前进！'),
-- King Genn Greymane
(38470, 0, 0, 'zhCN', '挡住他们的退路，利亚姆！我们把敌人团团围住了！'),
(38470, 1, 0, 'zhCN', '希尔瓦娜斯！！'),
(38470, 2, 0, 'zhCN', '利亚姆！！不！！！'),
-- Lady Sylvanas Windrunner
(38469, 0, 0, 'zhCN', '够了！'),
(38469, 1, 0, 'zhCN', '让我们看看，失去了顽固领袖的吉尔尼斯还能有多勇敢！'),
-- Gorerot
(38331, 0, 0, 'zhCN', '腐血怪要碾碎你们这些弱小的狼人！！'),
-- Lord Darius Crowley
(38149, 0, 0, 'zhCN', '他太强了！用投石车把他轰下来！'),
(38149, 1, 0, 'zhCN', '让我们和你父亲的部队会合吧，利亚姆。他们需要我们帮忙对付希尔瓦娜斯。'),
-- Krennan Aranas
(38144, 0, 0, 'zhCN', '是时候加入战斗了！有你的帮助，胜利的天平一定会向我们倾斜！'),
(38144, 1, 0, 'zhCN', '夺回吉尔尼斯城的时刻到了。让我们夺回我们的城市！');
