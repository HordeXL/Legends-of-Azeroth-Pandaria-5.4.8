-- Corruption Runs Deep (31441)
--
-- The reveal script changed Kor'ik (64813) into Klaxxi Traitor (64583), but
-- the traitor template was friendly.  A separate permanent friendly traitor
-- was also spawned at Duskroot Fen, while the Hisek standing beside the event
-- had no quest relation or reveal script.

START TRANSACTION;

-- The revealed creature must become hostile when its entry changes.
UPDATE `creature_template`
SET `faction`=14,
    `unit_flags`=(`unit_flags` & ~2 & ~256),
    `AIName`=''
WHERE `entry`=64583;

-- Remove the permanent friendly objective impostor.  The personal reveal
-- scene summons Kor'ik and transforms that summon into entry 64583 instead.
DELETE FROM `creature`
WHERE `guid`=530517 AND `id`=64583;

-- The Duskroot Fen copy of Hisek is the event NPC players are directed to.
UPDATE `creature_template`
SET `npcflag`=(`npcflag` | 2),
    `AIName`='',
    `ScriptName`='npc_hisek_the_swarmkeeper'
WHERE `entry`=64645;

DELETE FROM `creature_queststarter`
WHERE `id`=64645 AND `quest`=31441;
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (64645,31441);

DELETE FROM `creature_questender`
WHERE `id`=64645 AND `quest`=31441;
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (64645,31441);

COMMIT;
