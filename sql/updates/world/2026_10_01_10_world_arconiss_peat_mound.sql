-- Arconiss (30789): the quest version of Arconiss was incorrectly spawned
-- permanently beside an unscripted Peat Mound. The mound now summons a private
-- quest copy and awards the Summon Arconiss objective to the activating player.

UPDATE `gameobject_template`
SET `ScriptName` = 'go_arconiss_peat_mound'
WHERE `entry` = 211515;

DELETE FROM `creature`
WHERE `id` = 60764;
