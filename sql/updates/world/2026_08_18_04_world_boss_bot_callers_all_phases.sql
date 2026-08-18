-- Boss Bot Callers are public neutral coordinators, not quest-phased actors.
-- GM mode temporarily gives a player PHASEMASK_ANYWHERE, which previously hid
-- this defect: every caller had phaseMask=1 and could disappear again after
-- `.gm off` restored the character's real phase mask.
--
-- Limit the update to caller spawns that also have an explicit coordinator
-- configuration. The gossip script still requires its configured world boss to
-- be alive nearby before it permits Preview or Call, so cross-phase visibility
-- cannot start a raid against a missing boss.

UPDATE `creature` AS `c`
INNER JOIN `playerbot_world_boss_caller` AS `wbc`
        ON `wbc`.`guid` = `c`.`guid`
SET `c`.`phaseMask` = 4294967295,
    `c`.`phaseId` = 0,
    `c`.`phaseGroup` = 0
WHERE `c`.`id` = 990912;

