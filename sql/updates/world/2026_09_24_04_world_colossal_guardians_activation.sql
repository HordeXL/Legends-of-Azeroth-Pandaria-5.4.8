-- Colossal Guardians (27623): restore the existing SmartAI spellclick sequence.
-- CreatureAISelector gives ScriptName priority over AIName. The legacy C++ AI
-- only calls ExitVehicle(), whose default exit position is the vehicle origin
-- below the guardian's intended landing height. It also hides the SmartAI
-- spellclick handler and therefore skips action lists 4604100 / 4604200.
-- Those lists eject the guardian, jump to its explicit landing position,
-- play Thunderclap/dialogue and enable combat; the linked event locks clicking.
-- Keep spellclick spell 89185 and its quest condition unchanged.
-- Vehicle accessories are non-minions, so they survive the vehicle despawn.
-- Restart worldserver to recreate the guardians with the correct AI.
UPDATE `creature_template`
SET `AIName` = 'SmartAI', `ScriptName` = ''
WHERE `entry` IN (46041, 46042)
  AND `ScriptName` = 'npc_sun_moon_colossus';
