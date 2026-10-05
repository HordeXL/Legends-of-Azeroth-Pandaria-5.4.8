-- Back on Their Feet (30892)
-- Injured Gao-Ran Blackguards were assigned a hostile faction and had no AI,
-- making them attack targets instead of valid targets for the quest bandage
-- and class healing spells.

START TRANSACTION;

UPDATE `creature_template`
SET `faction`=35,
    `unit_flags`=(`unit_flags` | 2 | 512),
    `RegenHealth`=0,
    `AIName`='',
    `ScriptName`='npc_injured_gao_ran_blackguard'
WHERE `entry`=61692;

-- Keep the item restricted to the specifically injured quest NPC.  Ordinary
-- Gao-Ran Blackguards must neither accept the bandage nor award credit.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=17 AND `SourceEntry`=120573;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(17,0,120573,0,0,31,1,3,61692,0,0,0,0,'',
 'Citron-Infused Bandages - Target must be Injured Gao-Ran Blackguard');

COMMIT;
