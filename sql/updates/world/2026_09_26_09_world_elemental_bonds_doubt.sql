-- Cyclonas takes players on Elemental Bonds: Doubt (29327) to Thrall's terrace.
-- The original invisible Thrall credit (53518) has no scene script here, so
-- count the 20 Essence of Doubt kills that make up the encounter instead.
UPDATE `creature_template`
SET `ScriptName` = 'npc_elemental_bonds_cyclonas'
WHERE `entry` = 53524;

UPDATE `quest_objective`
SET `objectId` = 53516, `amount` = 20
WHERE `questId` = 29327 AND `id` = 257042 AND `objectId` IN (53518, 53516);
