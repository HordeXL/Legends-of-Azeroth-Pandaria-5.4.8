-- Throne of the Tides: Neptulon's Cache is spawned by the instance script
-- after Ozumat is defeated. MoP uses difficulty 1 for normal and 2 for
-- heroic, so their spawn masks are 2 and 4 respectively (1 << difficulty).
UPDATE `gameobject`
SET `spawnMask` = 2
WHERE `map` = 643 AND `id` = 205216;

UPDATE `gameobject`
SET `spawnMask` = 4
WHERE `map` = 643 AND `id` = 207973;
