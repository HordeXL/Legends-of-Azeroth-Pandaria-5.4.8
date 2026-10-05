-- Feed or Be Eaten (31092)
--
-- Auto-applying spell 125642 when accepting the quest crashes this 5.4.8
-- core during the spell-area phase update.  The player already retains the
-- Briny Muck phase from spell 59074, whose phase overlaps all required
-- Kaz'tik, Kovok, turtle and Muckscale spawns, so the extra aura is neither
-- required nor safe.

DELETE FROM `spell_area`
WHERE `spell` = 125642
  AND `area` = 6391
  AND `quest_start` = 31092;
