-- Marks only the locally configured Pandaria Boss Bot Callers as strategy-ready.
-- The corresponding C++ actions cover Galleon adds, Sha domination spacing,
-- Nalak tether/cloud movement, Oondasta beam spacing, Celestial mechanics,
-- Ordos Burning Soul, generic ground-effect avoidance, PvE build preparation,
-- raid buffs, wipe recovery and guarded dismissal.

UPDATE `playerbot_world_boss_caller`
SET `strategy_ready` = 1,
    `comment` = CASE `boss_entry`
        WHEN 62346 THEN 'Galleon; staged PvE raid and boss strategy enabled'
        WHEN 60491 THEN 'Sha of Anger; staged PvE raid and boss strategy enabled'
        WHEN 69099 THEN 'Nalak; staged PvE raid and boss strategy enabled'
        WHEN 69161 THEN 'Oondasta; staged PvE raid and boss strategy enabled'
        WHEN 71952 THEN 'Chi-Ji; staged PvE raid and boss strategy enabled'
        WHEN 71953 THEN 'Xuen; staged PvE raid and boss strategy enabled'
        WHEN 71954 THEN 'Niuzao; staged PvE raid and boss strategy enabled'
        WHEN 71955 THEN 'Yu-lon; staged PvE raid and boss strategy enabled'
        WHEN 72057 THEN 'Ordos; staged PvE raid and boss strategy enabled'
        ELSE `comment`
    END
WHERE `boss_entry` IN (62346,60491,69099,69161,71952,71953,71954,71955,72057);
