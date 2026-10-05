-- The Battle of Darrowshire (5721 / 27390): Joseph Redpath must grant the
-- "Accept Redpath's Forgiveness" objective when the player speaks to him.
UPDATE `creature_template`
SET `ScriptName` = 'npc_joseph_redpath'
WHERE `entry` = 10936;
