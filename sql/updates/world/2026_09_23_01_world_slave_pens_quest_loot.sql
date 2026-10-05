-- The Heart of the Matter (29565): boss quest items must be available in
-- both dungeon difficulties. Negative chance keeps them quest-only.
-- Replace all mode variants of these two drops so rerunning is safe.
DELETE FROM `creature_loot_template`
WHERE (`entry` = 17991 AND `item` = 72118)
   OR (`entry` = 17942 AND `item` = 72119);

INSERT INTO `creature_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`)
VALUES
    (17991, 72118, -100, 'DUNGEON_NORMAL,DUNGEON_HEROIC', 0, 1, 1), -- The Invader's Claw: Rokmar
    (17942, 72119, -100, 'DUNGEON_NORMAL,DUNGEON_HEROIC', 0, 1, 1); -- The Slave Master's Eye: Quagmirran
