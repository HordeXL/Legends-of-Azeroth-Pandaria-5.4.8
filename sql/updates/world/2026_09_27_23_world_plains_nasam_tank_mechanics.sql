-- Restore tank rescue and selected-target cannon aiming for The Plains of Nasam.
START TRANSACTION;
UPDATE creature_template SET spell3 = 47962 WHERE entry=25334;
DELETE FROM spell_script_names WHERE spell_id IN (47962,50672)
 AND ScriptName IN ('spell_nasam_rescue_soldier','spell_nasam_demoralizer_aim');
INSERT INTO spell_script_names (spell_id,ScriptName) VALUES
(47962,'spell_nasam_rescue_soldier'),(50672,'spell_nasam_demoralizer_aim');
-- Reuse existing ground-checked positions rather than invent new spawn positions.
UPDATE creature SET spawntimesecs=30
WHERE map=571 AND id IN (25332,25333,25469,25619,25622)
 AND position_x BETWEEN 2200 AND 2750 AND position_y BETWEEN 6300 AND 6750;
UPDATE creature SET spawntimesecs=60
WHERE map=571 AND id IN (27106,27107,27108,27110)
 AND position_x BETWEEN 2200 AND 2750 AND position_y BETWEEN 6300 AND 6750;
COMMIT;
