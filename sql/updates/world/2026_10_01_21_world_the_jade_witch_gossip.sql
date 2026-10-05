-- The Jade Witch (29723): Widow Greenpaw had the correct gossip option under
-- menu 55368, but her template pointed at menu 0.  Her gossip SmartAI also
-- awarded credit for 55381 while the quest objective requires 55368.
UPDATE `creature_template`
SET `gossip_menu_id`=55368
WHERE `entry`=55368
  AND `gossip_menu_id`=0;

UPDATE `smart_scripts`
SET `action_param1`=55368,
    `comment`='Widow Greenpaw - On Gossip Hello - Grant The Jade Witch credit'
WHERE `entryorguid`=55368
  AND `source_type`=0
  AND `id`=0
  AND `event_type`=64
  AND `action_type`=33
  AND `action_param1`=55381;
