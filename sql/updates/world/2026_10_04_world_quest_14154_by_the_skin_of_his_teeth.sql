-- Quest 14154 "By the Skin of His Teeth" (By the Skin of His Teeth) SAI rewrite
--
-- Root causes (verified on this fork):
--   1. Spell 68218 (2-min quest-complete timer aura) has DurationIndex=0 in SpellMisc.dbc
--      -> aura duration 0 -> removed instantly -> PERIODIC_TRIGGER(66915, 119s) never ticks.
--      Same defect exists on upstream TrinityCore (issue #30093), no official fix data.
--   2. Spell 66894 application (the wave/timer driver aura, FORCE_CAST from 66914) is unreliable.
--   3. First attempt used target_type 7 (ACTION_INVOKER) for the completion step inside the
--      timed action list;实测 step5 未生效（波次 1-4 正常），invoker 解析在定时列表中不可靠。
--      改为：接任务瞬间（事件上下文带 unit=player，绝对可靠）用 STORE_TARGET_LIST 把玩家
--      存入 varID=1，step5 用 target 12 (STORED) 取回；另加 CLOSEST_PLAYER 兜底步。
--
-- Fix: pure SmartAI. On quest accept, Crowley starts timed action list 101 (timerType 2 = ALWAYS,
-- so combat doesn't stall it): waves via 66853 (dummy -> spell_scripts summons, verified working
-- with `.cast 66853`) at ~1s / 30s / 59s / 88s, then completes quest 14154 at ~119s for the
-- player stored at accept time (action 15 CALL_AREAEXPLOREDOREVENTHAPPENS needs SpecialFlags=2
-- which 14154 has). Fallback at ~123s: closest player within 50y.

-- 1) Row id 0: start timed action list instead of casting broken 66914; link to id 10 (store invoker)
UPDATE `smart_scripts` SET
  `link` = 10,
  `action_type` = 80,
  `action_param1` = 101,
  `action_param2` = 0,
  `action_param3` = 2,
  `target_type` = 1,
  `comment` = 'Lord Darius Crowley - On Quest (14154) Accept - Start Timed Action List 101 (worgen waves + 2 min completion)'
WHERE `entryorguid` = 35077 AND `source_type` = 0 AND `id` = 0;

-- 2) Linked row: store the quest-accepting player into target list varID 1 (context has invoker here)
DELETE FROM `smart_scripts` WHERE `entryorguid` = 35077 AND `source_type` = 0 AND `id` = 10;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(35077,0,10,0,61,0,100,0,0,0,0,0,0,64,1,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Lord Darius Crowley - On Quest (14154) Accept - Store Action Invoker (player) as Target List 1');

-- 3) Timed action list 101 (source_type 9)
DELETE FROM `smart_scripts` WHERE `source_type` = 9 AND `entryorguid` = 101;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(101,9,1,0,0,0,100,0, 1000, 1000,0,0,0,11,66853,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'List 101 Step 1 - Cast 66853 (first worgen wave)'),
(101,9,2,0,0,0,100,0,29000,29000,0,0,0,11,66853,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'List 101 Step 2 - Cast 66853 (worgen wave 2)'),
(101,9,3,0,0,0,100,0,29000,29000,0,0,0,11,66853,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'List 101 Step 3 - Cast 66853 (worgen wave 3)'),
(101,9,4,0,0,0,100,0,29000,29000,0,0,0,11,66853,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'List 101 Step 4 - Cast 66853 (worgen wave 4)'),
(101,9,5,0,0,0,100,0,31000,31000,0,0,0,15,14154,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'List 101 Step 5 - Complete Quest 14154 for Stored Target 1 (~2 min)'),
(101,9,6,0,0,0,100,0, 4000, 4000,0,0,0,15,14154,0,0,0,0,0,21,50,0,0,0,0,0,0,0,'List 101 Step 6 - Fallback: Complete Quest 14154 for Closest Player in 50y');
