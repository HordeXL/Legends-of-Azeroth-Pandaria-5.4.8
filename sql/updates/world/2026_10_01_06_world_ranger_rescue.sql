-- Ranger Rescue (30774): correct objective credits, Lin's gossip/scene,
-- and the summoned Longying Rangers' helper AI.

UPDATE `creature_template`
SET `ScriptName` = 'npc_longying_ranger_helper'
WHERE `entry` = 60763;

UPDATE `creature_template`
SET `ScriptName` = 'npc_suna_ranger_rescue_scene'
WHERE `entry` = 60901;

-- Lin's first page describes the body; the existing second page reveals the handkerchief.
DELETE FROM `npc_text` WHERE `ID` = 19746;
INSERT INTO `npc_text`
(`ID`,`text0_0`,`text0_1`,`BroadcastTextID0`,`lang0`,`Probability0`,`EmoteDelay0_0`,`Emote0_0`,`EmoteDelay0_1`,`Emote0_1`,`EmoteDelay0_2`,`Emote0_2`,`VerifiedBuild`) VALUES
(19746,'<The pandaren was recently stripped, beaten, and broken. His body is still growing cold.>','',60364,0,1,0,0,0,0,0,0,18414);

DELETE FROM `gossip_menu` WHERE `MenuID` = 13734;
INSERT INTO `gossip_menu` (`MenuID`,`TextID`,`VerifiedBuild`) VALUES (13734,19746,18414);

UPDATE `creature_template`
SET `gossip_menu_id` = 13734
WHERE `entry` = 60899;

DELETE FROM `creature_text` WHERE `CreatureID` = 60901;
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(60901,0,0,'NOOO!',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - finds Lin'),
(60901,1,0,'Lin, my heart of heart! No, please, NO! It cannot be!',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - grief 1'),
(60901,2,0,'If only I had come sooner! If only Ban had listened to me!',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - grief 2'),
(60901,3,0,'Shhhhhh, my sweet darling, sleep now and be at peace.',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - grief 3'),
(60901,4,0,'Your killers will not go unpunished.',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - grief 4'),
(60901,5,0,'I will see to that.',12,0,100,0,0,0,0,0,0,'Suna Silentstrike - grief 5');
