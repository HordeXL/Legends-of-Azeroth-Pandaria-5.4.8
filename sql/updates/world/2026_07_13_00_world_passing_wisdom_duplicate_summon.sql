-- Quest 29790 (Passing Wisdom) was starting the same 56686 sequence twice:
-- npc_master_shang_xi_thousand_staff::OnQuestAccept summons the player-private
-- copy, while this SmartAI row summoned a second non-private copy.
-- Remove only the duplicate DB trigger when the C++ quest script is active and
-- the complete expected SmartAI state still matches.
DELETE `ss`
FROM `smart_scripts` AS `ss`
INNER JOIN `creature_template` AS `ct`
    ON `ct`.`entry` = `ss`.`entryorguid`
WHERE `ct`.`entry` = 55672
  AND `ct`.`ScriptName` = 'npc_master_shang_xi_thousand_staff'
  AND `ss`.`entryorguid` = 55672
  AND `ss`.`source_type` = 0
  AND `ss`.`id` = 1
  AND `ss`.`link` = 0
  AND `ss`.`event_type` = 19
  AND `ss`.`event_param1` = 29790
  AND `ss`.`event_param2` = 0
  AND `ss`.`action_type` = 12
  AND `ss`.`action_param1` = 56686
  AND `ss`.`action_param2` = 8
  AND `ss`.`target_type` = 1;
