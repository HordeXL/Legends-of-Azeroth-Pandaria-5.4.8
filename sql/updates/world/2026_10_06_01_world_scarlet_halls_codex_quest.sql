-- Just for Safekeeping, Of Course (31493): the normal dungeon quest can also
-- be completed on Heroic. Its Codex (87267) was restricted to Normal, leaving
-- players who carried this quest into Heroic unable to obtain the objective.
-- Keep the 100% quest-only, one-item drop and native per-player quest checks.
-- The Heroic quest (31497) still requires its separate Heroic Codex (87268).
UPDATE `creature_loot_template`
SET `lootmode` = 'DUNGEON_NORMAL,DUNGEON_HEROIC'
WHERE `entry` = 59150 AND `item` = 87267
  AND `lootmode` = 'DUNGEON_NORMAL'
  AND `ChanceOrQuestChance` = -100
  AND `groupid` = 0 AND `mincountOrRef` = 1 AND `maxcount` = 1;
