-- GUID 84714 is entry 23696 (Gordok Brew Chief), not entry 23698
-- (Drunken Brewfest Reveler). The two GUID-specific rows were copied with
-- Drunken Brewfest Reveler comments/actions and try to use its text group 1.
--
-- The genuine reveler spawn (GUID 84667, entry 23698) already has the same
-- intended behavior, and entry 23698 owns both creature_text groups.

DELETE FROM `smart_scripts`
WHERE `entryorguid` = -84714
  AND `source_type` = 0
  AND `id` IN (0, 1)
  AND `comment` LIKE 'Drunken Brewfest Reveler%';
