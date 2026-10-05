-- Mists' Opportunity (30793): restore Jahesh's scripted 40% Bastion phase,
-- correct mistlurker trio and remove the permanent shield/torch visuals.

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_jahesh_mists_opportunity'
WHERE `entry` = 60802;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 60802;

UPDATE `creature_template_addon`
SET `auras` = ''
WHERE `entry` = 60802;

-- Wrong static event actors at Jahesh: Orbiss was duplicated and Golgoss was
-- absent. Jahesh now summons Golgoss and Arconiss and uses the nearby questgiver
-- Orbiss (60622) for the shield-breaking sequence.
DELETE FROM `creature`
WHERE `guid` IN (522358, 522340)
  AND `id` IN (60822, 60824);

DELETE FROM `creature_text`
WHERE `CreatureID` IN (60802, 60881, 60882)
   OR (`CreatureID` = 60622 AND `GroupID` IN (0, 1, 2));

INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(60802,0,0,'$C... you must be the one that''s been helping these pitiful mistlurkers.',14,0,100,0,0,0,60263,0,'Jahesh - aggro'),
(60802,1,0,'That''s enough!',14,0,100,0,0,0,60264,0,'Jahesh - Bastion begins'),
(60802,2,0,'I have enough torches to erase all three of you!',14,0,100,0,0,0,60265,0,'Jahesh - Bastion'),
(60802,3,0,'The elements shield me!',14,0,100,0,0,0,60277,0,'Jahesh - Bastion shield'),
(60802,4,0,'If you refuse to bend to the torch, you will die to the torch!',14,0,100,0,0,0,60266,0,'Jahesh - kills Golgoss'),
(60802,5,0,'You''re next, small one!',14,0,100,0,0,0,60268,0,'Jahesh - kills Arconiss'),
(60802,6,0,'There''s another mistlurker here... I can smell his stink.',12,0,100,0,0,0,60270,0,'Jahesh - finds Orbiss'),
(60802,7,0,'Don''t think I can''t see you back there, hiding in the shadows...',14,0,100,0,0,0,60271,0,'Jahesh - sees Orbiss'),
(60802,8,0,'You resist the power of the torch... why won''t you die, beast?',14,0,100,0,0,0,60272,0,'Jahesh - strikes Orbiss'),
(60802,9,0,'No... NO!',14,0,100,0,0,0,60276,0,'Jahesh - shield broken'),
(60881,0,0,'No...',12,0,100,0,0,0,60267,0,'Golgoss - death'),
(60882,0,0,'Too... strong...',12,0,100,0,0,0,60269,0,'Arconiss - death'),
(60622,0,0,'Because my will...',12,0,100,0,0,0,60273,0,'Orbiss - resists'),
(60622,1,0,'...the will of my people...',12,0,100,0,0,0,60274,0,'Orbiss - resists'),
(60622,2,0,'...is stronger than yours.',12,0,100,15,0,0,60275,0,'Orbiss - breaks Bastion');
