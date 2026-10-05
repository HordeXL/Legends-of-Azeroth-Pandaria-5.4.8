-- Farmer Yoon (58646): restore the original gossip quest-credit action.
-- A bulk SmartAI conversion changed this row to cast spell 139916, whose
-- summon effect creates hostile Farmer Yoon (70450) at the player.
UPDATE `smart_scripts`
SET `action_type`=33,
    `action_param1`=70454,
    `action_param2`=0,
    `action_param3`=0,
    `action_param4`=0,
    `action_param5`=0,
    `action_param6`=0,
    `target_type`=17,
    `target_param1`=0,
    `target_param2`=100,
    `target_param3`=0,
    `target_x`=0,
    `target_y`=0,
    `target_z`=0,
    `target_o`=0,
    `comment`='[Kill]OnSpeak'
WHERE `entryorguid`=58646
  AND `source_type`=0
  AND `id`=2
  AND `event_type`=64
  AND `action_type`=85
  AND `action_param1`=139916;
