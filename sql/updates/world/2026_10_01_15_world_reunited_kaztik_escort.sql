-- Reunited (31091)
-- Kaz'tik at the Briny Muck had a quest/chat bubble but no gossip action,
-- while the escort version (64013) had neither AI nor a spawn path.

START TRANSACTION;

UPDATE `creature_template`
SET `npcflag`=(`npcflag` | 1),
    `AIName`='', `ScriptName`='npc_kaztik_reunited_starter'
WHERE `entry`=63876;

UPDATE `creature_template`
SET `AIName`='', `ScriptName`='npc_kaztik_reunited_escort'
WHERE `entry`=64013;

DELETE FROM `creature_text`
WHERE `CreatureID`=64013 AND `GroupID` BETWEEN 0 AND 3;

INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,
 `Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(64013,0,0,'Prepare for battle, Wakener!',12,0,100,0,0,0,64351,0,
 'Kaztik - Reunited wave'),
(64013,1,0,'We\'re here. With this weapon we will lay waste to the Empresses\' army!',12,0,100,0,0,0,63882,0,
 'Kaztik - Reunited escort complete'),
(64013,2,0,'Isn\'t he magnificent?!',12,0,100,0,0,0,64383,0,
 'Kaztik - Reunited reveals Kovok'),
(64013,3,0,'Come to me, Kovok.',12,0,100,0,0,0,64385,0,
 'Kaztik - Reunited calls Kovok');

COMMIT;
