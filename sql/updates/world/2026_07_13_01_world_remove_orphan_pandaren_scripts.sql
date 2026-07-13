-- The tested balloon is owned by npc_shang_xi_air_balloon. Timed action list
-- 5564900 is a legacy SmartAI implementation with no Action 80 caller; its
-- invalid text targets generate startup warnings. Remove it only while it is
-- still unreachable and the C++ balloon binding is active.
DELETE `legacy`
FROM `smart_scripts` AS `legacy`
INNER JOIN `creature_template` AS `balloon`
    ON `balloon`.`entry` = 55649
   AND `balloon`.`ScriptName` = 'npc_shang_xi_air_balloon'
LEFT JOIN `smart_scripts` AS `caller`
    ON `caller`.`action_type` = 80
   AND `caller`.`action_param1` = 5564900
WHERE `legacy`.`entryorguid` = 5564900
  AND `legacy`.`source_type` = 9
  AND `caller`.`entryorguid` IS NULL;

-- Entry 56688 is a stationary Planting Stave quest-credit marker, not Master
-- Shang Xi. Keep the creature/template and credit references; clear only the
-- erroneous escort AI binding that attempts dialogue for this textless marker.
UPDATE `creature_template` AS `credit`
SET `credit`.`ScriptName` = ''
WHERE `credit`.`entry` = 56688
  AND `credit`.`name` = 'Planting Stave Credit'
  AND `credit`.`AIName` = ''
  AND `credit`.`ScriptName` = 'npc_master_shang_xi_thousand_staff_escort'
  AND EXISTS
  (
      SELECT 1
      FROM `smart_scripts` AS `usage`
      WHERE `usage`.`action_type` = 33
        AND `usage`.`action_param1` = 56688
  );
