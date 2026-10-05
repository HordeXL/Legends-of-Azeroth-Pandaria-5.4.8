-- Feed or Be Eaten (31092): move Kovok's feeding/follow behavior to C++ so
-- the companion resumes following after each Delicious Filet animation.

UPDATE `creature_template`
SET `AIName`='', `ScriptName`='npc_feed_or_be_eaten_kovok'
WHERE `entry`=62542;

DELETE FROM `smart_scripts`
WHERE `entryorguid`=62542 AND `source_type`=0;
