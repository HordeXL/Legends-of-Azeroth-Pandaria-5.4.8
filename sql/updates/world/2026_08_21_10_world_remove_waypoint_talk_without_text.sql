-- Remove legacy waypoint TALK commands whose text id is zero.
-- ObjectMgr rejects these rows during startup, so they cannot produce dialogue.
-- Creature spawns, waypoint paths and the valid emote commands on actions 214-231 remain intact.

START TRANSACTION;

DELETE FROM `waypoint_scripts`
WHERE `command` = 0
  AND `dataint` = 0
  AND `guid` IN
  (1,50,51,98,142,343,143,344,144,345,145,346,146,347,147,348,148,349,
   149,350,150,351,151,352,152,353,153,354,154,355,155,356,156,357,157,358,
   158,359,159,360,160,245,401,415,246,416,402,419,403,417,256,259,
   277,278,279,280,281,282);

-- Clear only actions that now have no script rows at all. This prevents a dead
-- waypoint reference while preserving every movement point and delay.
UPDATE `waypoint_data` AS `wd`
SET `wd`.`action` = 0
WHERE `wd`.`action` IN (1,100,101,154,232,332,333,334,335,443,485,567,568,569,570,571,572)
  AND NOT EXISTS
      (SELECT 1 FROM `waypoint_scripts` AS `ws` WHERE `ws`.`id` = `wd`.`action`);

COMMIT;
