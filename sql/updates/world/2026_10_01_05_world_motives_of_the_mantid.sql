-- The Motives of the Mantid (30921): restore Tai Ho's Kri'vess investigation.
UPDATE `creature_template`
SET `ScriptName` = 'npc_tai_ho_motives'
WHERE `entry` = 61390;

DELETE FROM `creature_text` WHERE `CreatureID` = 61390;
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(61390,0,0,"You take them out. I'll hide in the shadows and search their bodies.",12,0,100,0,0,0,0,61672,0,'Tai Ho - summoned at Kri\'vess'),
(61390,1,0,'The color has just... left its body.',12,0,100,0,0,0,0,60788,0,'Tai Ho - first clue 1'),
(61390,2,0,"There's no doubt about it. These creatures have been affected by sha.",12,0,100,0,0,0,0,60789,0,'Tai Ho - first clue 2'),
(61390,3,0,'Look at the size of these! This one is definitely a breeding male.',12,0,100,0,0,0,0,60790,0,'Tai Ho - second clue 1'),
(61390,4,0,'That means the mantid queen is involved in this... somehow.',12,0,100,0,0,0,0,60791,0,'Tai Ho - second clue 2'),
(61390,5,0,"His body - it's covered with scars. Old scars.",12,0,100,0,0,0,0,60792,0,'Tai Ho - third clue 1'),
(61390,6,0,'Not just any scars, either. These were created by pandaren weapons.',12,0,100,0,0,0,0,60793,0,'Tai Ho - third clue 2'),
(61390,7,0,"Here it is! This is what we've been looking for!",12,0,100,0,0,0,0,60794,0,'Tai Ho - fourth clue 1'),
(61390,8,0,'Yak hair.',12,0,100,0,0,0,0,60795,0,'Tai Ho - fourth clue 2'),
(61390,9,0,'Come back to camp when you are finished. We have much to discuss.',12,0,100,0,0,0,0,62135,0,'Tai Ho - investigation complete'),
(61390,10,0,'Nothing here. Keep moving.',12,0,25,0,0,0,0,60801,0,'Tai Ho - no clue'),
(61390,10,1,'Nothing on this one.',12,0,25,0,0,0,0,60802,0,'Tai Ho - no clue'),
(61390,10,2,"There's nothing here. Let's keep looking.",12,0,25,0,0,0,0,60803,0,'Tai Ho - no clue'),
(61390,10,3,'No... nothing of note here. Keep looking.',12,0,25,0,0,0,0,60804,0,'Tai Ho - no clue');
