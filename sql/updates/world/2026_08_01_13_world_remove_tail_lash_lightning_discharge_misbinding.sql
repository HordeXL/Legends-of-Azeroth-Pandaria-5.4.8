-- Remove only the erroneous Lightning Discharge handler from Tail Lash.
-- The four real Lightning Discharge bindings on 77939/77942/77943/77944 and
-- spell 77827 itself remain unchanged.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 77827
  AND `ScriptName` = 'spell_onyxia_lightning_discharge';
