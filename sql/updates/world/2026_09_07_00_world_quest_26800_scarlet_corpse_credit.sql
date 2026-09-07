-- 修复部落任务"清扫战场"(26800)：右键点击血色十字军尸体(49340)无法完成任务计数
-- Fix quest 26800 "Recruitment": right-clicking a Scarlet Corpse (49340) did not advance
-- the quest counter.
--
-- 逻辑检查结论:
-- 1. 任务目标: quest_objective (questId=26800, id=265872, type=0 MONSTER, objectId=49340, amount=6)
--    "Scarlet Corpses gathered"。该类型目标只会通过 Player::KilledMonsterCredit(49340) 计数。
-- 2. 尸体(49340)具有 SPELLCLICK + QUESTGIVER npcflag，且 npc_spellclick_spells 定义了点击法术 91942，
--    右键点击会正常触发 SmartAI::OnSpellClick -> SMART_EVENT_ON_SPELLCLICK (event 73)。
-- 3. 但尸体当前 smart_scripts 只有 "距离(达内尔)触发" 与 "数据设置触发" 事件，没有任何点击事件，
--    也没有 CALL_KILLEDMONSTER 动作 -> 玩家永远拿不到计数。(2021 版脚本有 spellclick + 击杀计数，
--    2022 年改写为距离触发时丢失了计数动作。)
-- 4. 修复: 恢复 spellclick 流程 —— 点击尸体: 给点击者 49340 击杀计数(即任务目标+1) +
--    对达内尔(49337)施放 46598 触发其拾取反应 + 1秒后移除尸体; 保留数据 1 1 清除逻辑。

DELETE FROM `smart_scripts` WHERE `entryorguid` = 49340 AND `source_type` = 0;

INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(49340,0,0,1,73,0,100,1,0,0,0,0,0,33,49340,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Scarlet Corpse - On SpellClick - Give Kill Credit (Quest 26800) to Clicker'),
(49340,0,1,2,61,0,100,0,0,0,0,0,0,11,46598,2,0,0,0,0,19,49337,20,0,0,0,0,0,0,'Scarlet Corpse - On SpellClick (Link) - Cast Spell 46598 on Darnell'),
(49340,0,2,0,61,0,100,0,0,0,0,0,0,41,1000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Scarlet Corpse - On SpellClick (Link) - Despawn Self'),
(49340,0,3,0,38,0,100,1,1,1,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Scarlet Corpse - On Data Set 1 1 - Despawn Self');
