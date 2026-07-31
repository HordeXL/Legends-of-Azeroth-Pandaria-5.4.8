-- 26013 is Deserter in client build 18414, not Crane Wings.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 26013
  AND `ScriptName` = 'spell_timeless_isle_crane_wings';

-- The local script explicitly implements the direct casts 55342 and 110621.
-- SkyFire 5.4.8 also removes the three nonmatching auxiliary spell bindings.
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (63093, 88091, 88092)
  AND `ScriptName` = 'spell_mage_mirror_image';
