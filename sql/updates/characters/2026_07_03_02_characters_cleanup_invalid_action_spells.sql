-- Remove action bar spell buttons for spells the character does not know.
-- The core rejects these at login and deletes them for loaded characters; this
-- applies the same cleanup globally so startup/login logs stay clean.
DELETE a
FROM `character_action` a
LEFT JOIN `character_spell` s
  ON s.`guid` = a.`guid`
 AND s.`spell` = a.`action`
 AND s.`active` = 1
WHERE a.`type` = 0
  AND s.`spell` IS NULL;
