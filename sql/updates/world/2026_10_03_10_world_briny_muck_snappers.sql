-- Briny Muck: Trained Brineshell Snappers (65330) do not belong in this
-- questing area. Preserve the spawns but use the Feed or Be Eaten turtle
-- (Brineshell Snapper 63981) instead.

UPDATE `creature`
SET `id`=63981
WHERE `id`=65330 AND `map`=870 AND `zoneId`=6138 AND `areaId`=6391;
