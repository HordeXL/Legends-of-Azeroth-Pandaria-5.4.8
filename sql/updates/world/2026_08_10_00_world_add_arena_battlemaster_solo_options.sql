-- Add explicit server-side Solo Arena choices to the shared Arena
-- Battlemaster menu. Option IDs 20-22 were verified unused before this update.
-- Option 0 remains the original premade-group Arena registration frontend.

DELETE FROM `gossip_menu_option`
WHERE `MenuID` = 8218 AND `OptionID` IN (20, 21, 22);

INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,
 `OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,
 `BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`) VALUES
(8218,20,9,'Solo Arena 2v2 (automatic teammates and opponents)',0,1,1,0,0,0,0,'',0,18414),
(8218,21,9,'Solo Arena 3v3 (automatic teammates and opponents)',0,1,1,0,0,0,0,'',0,18414),
(8218,22,9,'Solo Arena 5v5 (automatic teammates and opponents)',0,1,1,0,0,0,0,'',0,18414);
