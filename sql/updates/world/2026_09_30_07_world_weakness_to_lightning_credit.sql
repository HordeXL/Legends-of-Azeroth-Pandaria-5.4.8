-- Quest 11896 "Weakness to Lightning": every weakened robot must award credit.
--
-- The old death action cast credit spell 46443 on the action invoker.  When a
-- guardian or pet landed the killing blow, the invoker was not a Player and
-- SPELL_EFFECT_KILL_CREDIT therefore discarded the credit.  Award objective
-- 26082 through the robot's loot recipient instead; this also uses the normal
-- group-credit path exactly once per kill.
UPDATE `smart_scripts`
SET `action_type` = 33,
    `action_param1` = 26082,
    `action_param2` = 0,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 1,
    `target_param1` = 0,
    `target_param2` = 0,
    `target_param3` = 0,
    `comment` = CONCAT(SUBSTRING_INDEX(`comment`, ' - On Just Died', 1),
                       ' - On Just Died after Lightning Rod - Award Weakness to Lightning credit')
WHERE `source_type` = 0
  AND `entryorguid` IN (25752,25753,25758,25792)
  AND `event_type` = 6
  AND `event_phase_mask` = 1
  AND `action_type` = 11
  AND `action_param1` = 46443;

-- 55-D Collect-a-tron is an allowed target of Sage's Lightning Rod, but its
-- SmartAI lacked both the weakened phase transition and the death credit.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 25793
  AND `source_type` = 0
  AND `id` IN (1,2);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(25793,0,1,0,8,0,100,0,46432,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,
 '55-D Collect-a-tron - On Spellhit Power of the Storm - Set Event Phase 1'),
(25793,0,2,0,6,1,100,0,0,0,0,0,0,33,26082,0,0,0,0,0,1,0,0,0,0,0,0,0,
 '55-D Collect-a-tron - On Just Died after Lightning Rod - Award Weakness to Lightning credit');
