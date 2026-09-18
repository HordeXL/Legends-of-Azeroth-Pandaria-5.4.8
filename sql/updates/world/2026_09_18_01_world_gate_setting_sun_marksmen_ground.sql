-- Gate of the Setting Sun: Serpent's Spine Marksmen are ground-based ambient
-- defenders. The imported movement record disabled ground movement and gravity,
-- causing the first line to remain suspended and converge while engaging gliders.
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Flight`)
VALUES (56484, 1, 0)
ON DUPLICATE KEY UPDATE
    `Ground` = VALUES(`Ground`),
    `Flight` = VALUES(`Flight`);

-- Restore the original formation after the temporary edge-position workaround.
UPDATE `creature`
SET `position_y` = CASE `guid`
    WHEN 541970 THEN 2373.0100
    WHEN 541972 THEN 2373.4400
    WHEN 541965 THEN 2373.3400
    WHEN 541969 THEN 2373.4500
    WHEN 541971 THEN 2373.4300
    WHEN 541966 THEN 2373.1100
    WHEN 541968 THEN 2373.7000
    WHEN 541967 THEN 2373.0000
    WHEN 541973 THEN 2372.6400
    WHEN 541929 THEN 2373.1200
    WHEN 541931 THEN 2373.4700
    WHEN 541928 THEN 2373.5400
    WHEN 541930 THEN 2373.4100
    ELSE `position_y`
END
WHERE `map` = 962
  AND `id` = 56484
  AND `guid` IN
  (
      541965, 541966, 541967, 541968, 541969, 541970, 541971,
      541972, 541973, 541928, 541929, 541930, 541931
  );
