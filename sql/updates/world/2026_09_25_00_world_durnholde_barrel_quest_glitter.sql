-- Taretha's Diversion: mark the diversion barrels as quest objects for
-- the current dungeon quest. ActivateToQuest uses goober data1 for sparkle.
-- Completion credit remains handled by the instance's five-barrel event.
UPDATE `gameobject_template` SET `data1`=29598
WHERE `entry`=182589 AND `type`=10 AND `data1`=0
  AND `ScriptName`='go_barrel_old_hillsbrad';
