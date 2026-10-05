-- Strongarm Private and Medic are active airstrip enemies. A template-wide
-- permanent feign-death aura incorrectly makes every spawn appear dead.
-- Preserve unrelated auras and the Private's swimming flag.
UPDATE `creature_template_addon`
SET `auras` = TRIM(REPLACE(CONCAT(' ', TRIM(`auras`), ' '), ' 29266 ', ' '))
WHERE `entry` IN (65841, 65842)
  AND CONCAT(' ', TRIM(`auras`), ' ') LIKE '% 29266 %';

-- Allow NPC allies/playerbots to fight the normal quest enemy as well.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` & ~512
WHERE `entry` = 65841;
