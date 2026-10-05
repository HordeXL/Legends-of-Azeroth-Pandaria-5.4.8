-- Protect stationary report quest givers; combat scene actors remain attackable.
UPDATE creature_template SET unit_flags = unit_flags | 770
WHERE entry IN (55647,55648);
UPDATE creature SET unit_flags = unit_flags | 770
WHERE id IN (55647,55648);
