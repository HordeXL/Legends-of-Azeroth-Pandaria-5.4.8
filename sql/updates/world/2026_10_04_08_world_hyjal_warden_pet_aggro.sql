-- Hyjal Wardens are contested guards but must not passively acquire a
-- player-owned pet when the owner has not attacked them.

UPDATE `creature_template`
SET `ScriptName` = 'npc_hyjal_warden_pet_safe'
WHERE `entry` IN (38915, 53823);
