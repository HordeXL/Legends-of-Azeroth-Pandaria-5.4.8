-- The Horn of Elemental Fury (11695): make the Lower Horn Half path reliable.
-- Chieftain Gurgleboggle and his bauble were restricted to phase mask 1 and
-- could be absent for players in another Borean Tundra phase.  The horn half
-- also depended entirely on the bauble's lock interaction.
UPDATE `creature`
SET `phaseMask` = 65535,
    `spawntimesecs` = 30
WHERE `guid` = 102613
  AND `id` = 25725;

UPDATE `gameobject`
SET `phaseMask` = 65535,
    `spawntimesecs` = 30
WHERE `guid` = 47240
  AND `id` = 187885;

UPDATE `creature_template`
SET `questItem2` = 34963
WHERE `entry` = 25725;

DELETE FROM `creature_loot_template`
WHERE `Entry` = 25725
  AND `Item` = 34963;

INSERT INTO `creature_loot_template`
(`Entry`,`Item`,`ChanceOrQuestChance`,`LootMode`,`GroupId`,`MinCountOrRef`,`MaxCount`)
VALUES
(25725,34963,-100,1,0,1,1);
