-- Quest 29792 "Bidden to Greatness": Ji Firepaw (59988) already has the
-- complete SmartAI path and dialogue for both gates.  The unrelated
-- npc_ji_forest_escort CreatureScript overrides that SmartAI, makes Ji jump
-- through the first closed gate and then follow another quest's route.
-- Keep the existing SmartAI and remove only the conflicting C++ binding.

UPDATE `creature_template`
SET `ScriptName` = ''
WHERE `entry` = 59988
  AND `AIName` = 'SmartAI'
  AND `ScriptName` = 'npc_ji_forest_escort';
