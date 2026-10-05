-- Halion is created by the Ruby Sanctum encounter script.  Static controller
-- and Twilight Halion rows duplicate those summons, producing multiple bosses
-- when the controller intro or Twilight Phasing runs.

START TRANSACTION;

DELETE FROM `creature`
WHERE (`guid` = 43221 AND `id` = 40146)
   OR (`guid` IN (43241, 349107) AND `id` = 40142);

-- Keep the otherwise-unused second entrance portal functional if a spell or
-- future data update selects it.
UPDATE `gameobject_template`
SET `ScriptName` = 'go_twilight_portal'
WHERE `entry` = 202795;

COMMIT;
