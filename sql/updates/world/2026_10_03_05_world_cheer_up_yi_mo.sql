-- Cheer Up, Yi-Mo (30082): restore the personal five-kick rolling event.

START TRANSACTION;

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_cheer_up_yi_mo_starter',
    `npcflag` = `npcflag` | 1
WHERE `entry` = 58376;

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_cheer_up_yi_mo_rolling'
WHERE `entry` = 57310;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` IN (58376, 57310);

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry` = 57310;

INSERT INTO `npc_spellclick_spells`
(`npc_entry`,`spell_id`,`cast_flags`,`user_type`)
VALUES (57310,108175,1,0);

-- The starter uses gossip menu 13354.  The retail response was incorrectly
-- stored on menu 13353, leaving no selectable response on the actual NPC.
DELETE FROM `gossip_menu_option`
WHERE `MenuID` = 13354 AND `OptionID` = 0;

INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,
 `OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,
 `BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`) VALUES
(13354,0,0,'Please, Yi-Mo: your aunt\'s worried sick about you.',56552,
 1,1,0,0,0,0,NULL,0,18414);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 15
  AND `SourceGroup` = 13354 AND `SourceEntry` = 0;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(15,13354,0,0,0,9,0,30082,0,0,0,0,0,'',
 'Yi-Mo Longbrow - Show rolling-event response while Cheer Up, Yi-Mo is active');

COMMIT;
