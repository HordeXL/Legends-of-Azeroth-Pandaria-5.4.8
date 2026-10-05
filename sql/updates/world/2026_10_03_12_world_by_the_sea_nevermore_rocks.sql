-- By the Sea, Nevermore (31089/31682): the Ocean-Worn Rocks existed only in
-- phase 1, while this quest chain can place players in any Briny Muck phase.
-- Bind the tuning fork spell so the physical rocks despawn when the hidden
-- event bunny receives the spell; SmartAI continues the awakening sequence.

DELETE FROM `spell_script_names`
WHERE `ScriptName`='spell_by_the_sea_nevermore_tuning_fork';

INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`) VALUES
(122779,'spell_by_the_sea_nevermore_tuning_fork');

-- The tuning fork targets this hidden event bunny. It must share the quest
-- phases with the rocks or the cast has no valid target outside phase 1.
UPDATE `creature`
SET `phaseMask`=7
WHERE `id`=62853 AND `map`=870 AND `zoneId`=6138 AND `areaId`=6391;

UPDATE `gameobject`
SET `phaseMask`=7
WHERE `id`=212294 AND `map`=870 AND `zoneId`=6138 AND `areaId`=6391;
