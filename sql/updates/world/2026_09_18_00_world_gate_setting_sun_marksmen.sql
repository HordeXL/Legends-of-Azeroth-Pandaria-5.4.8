-- Gate of the Setting Sun: keep the first ambient marksman line on the
-- northern wall walkway instead of just beyond its visible outer edge.
UPDATE `creature`
SET `position_y` = 2369.0000
WHERE `map` = 962
  AND `id` = 56484
  AND `guid` IN
  (
      541965, 541966, 541967, 541968, 541969, 541970, 541971,
      541972, 541973, 541928, 541929, 541930, 541931
  );
