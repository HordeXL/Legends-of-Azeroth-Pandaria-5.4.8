-- Keep the correct Sword and Board bindings on passive 46953 and buff 50227.
-- Devastate 20243 is an active attack with no aura for this AuraScript hook.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 20243
  AND `ScriptName` = 'spell_warr_sword_and_board';
