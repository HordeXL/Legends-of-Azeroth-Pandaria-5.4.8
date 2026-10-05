-- Load'er Up! (11881): bind Jenny's Whistle to the quest follower script.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 46338
  AND `ScriptName` = 'spell_jennys_whistle';

INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`) VALUES
(46338,'spell_jennys_whistle');

UPDATE `creature_template`
SET `ScriptName` = 'npc_jenny'
WHERE `entry` = 25969;

UPDATE `creature_template`
SET `ScriptName` = ''
WHERE `entry` = 25849
  AND `ScriptName` = 'npc_fezzix_geartwist';
