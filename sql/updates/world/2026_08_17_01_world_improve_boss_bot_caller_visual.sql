-- Make the shared Boss Bot Caller visually distinctive without changing its
-- gossip, faction, combat safety or configured boss mapping.
-- Display 45941 is the local 5.4.8 Celestial Form model.
-- Aura 49414 is an existing non-combat spirit visual used by friendly Pandaria NPCs.

UPDATE `creature_template`
SET `scale` = 2.25
WHERE `entry` = 990912
  AND `ScriptName` = 'npc_world_boss_bot_caller';

DELETE FROM `creature_template_model`
WHERE `CreatureID` = 990912;

INSERT INTO `creature_template_model`
    (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
    (990912,0,45941,1,1,18414);

DELETE FROM `creature_template_addon`
WHERE `entry` = 990912;

INSERT INTO `creature_template_addon`
    (`entry`,`path_id`,`mount`,`MountCreatureID`,`StandState`,`AnimTier`,
     `VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,
     `movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`)
VALUES
    (990912,0,0,0,0,0,0,1,0,0,0,0,0,0,'49414');
