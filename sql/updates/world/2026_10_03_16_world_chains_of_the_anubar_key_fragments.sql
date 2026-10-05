-- Chains of the Anub'ar (12064): the three quest-only key fragments had an
-- empty loot mode, so their nominal 100% quest drops were never eligible.

UPDATE `creature_loot_template`
SET `ChanceOrQuestChance` = -100,
    `lootmode` = 'REGULAR',
    `groupid` = 0,
    `mincountOrRef` = 1,
    `maxcount` = 1
WHERE (`entry` = 26769 AND `item` = 36752)
   OR (`entry` = 26770 AND `item` = 36753)
   OR (`entry` = 26771 AND `item` = 36754);
