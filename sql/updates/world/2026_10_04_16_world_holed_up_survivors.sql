-- Holed Up (30682): the four survivors had gossip text but no action that
-- granted rescue credit or created their follower versions.

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_holed_up_survivor'
WHERE `entry` IN (60178, 60187, 60189, 60190);
