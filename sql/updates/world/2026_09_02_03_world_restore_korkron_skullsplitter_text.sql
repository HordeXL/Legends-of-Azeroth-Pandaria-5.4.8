-- Restore the combat line requested by
-- npc_siege_of_orgrimmar_korkron_skull_splitter::JustEngagedWith().
-- BroadcastText 74956 is present in the 5.4.8 client data.

DELETE FROM `creature_text`
WHERE `CreatureID` = 72744 AND `GroupID` = 0 AND `ID` = 0;

INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(72744,0,0,'Rage is power!',12,1,100,0,0,0,0,74956,0,'Kor''kron Skullsplitter - combat aggro');
