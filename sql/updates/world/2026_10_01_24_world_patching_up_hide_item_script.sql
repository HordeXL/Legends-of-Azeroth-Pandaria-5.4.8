-- Patching Up (11894): handle Uncured Caribou Hide conversion server-side.
-- Client terrain steam effects and spell-focus 1503 are not consistently
-- aligned, so the original use spell can reject valid-looking vents.
DELETE FROM `item_script_names`
WHERE `Id`=35288;

INSERT INTO `item_script_names` (`Id`, `ScriptName`)
VALUES (35288, 'item_uncured_caribou_hide');
