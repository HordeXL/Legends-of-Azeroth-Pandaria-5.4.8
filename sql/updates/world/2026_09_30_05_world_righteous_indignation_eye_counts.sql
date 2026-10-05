-- Righteous Indignation (27479): regular Mossflayer trolls have two eyes.
-- Preserve the verified quest-drop chances, but restore the Build-18414
-- quantity ranges for Mossflayer Eye (61313).
UPDATE `creature_loot_template`
SET `mincountOrRef` = 2,
    `maxcount` = 2
WHERE `item` = 61313
  AND `entry` IN (8560, 8561, 8562, 10822);

UPDATE `creature_loot_template`
SET `mincountOrRef` = 1,
    `maxcount` = 2
WHERE `item` = 61313
  AND `entry` = 12261;
