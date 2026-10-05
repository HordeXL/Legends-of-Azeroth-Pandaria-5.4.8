-- Raging Spirits (29591) requires 5 Raging Skeletons, 5 Angered Skeletons
-- and 3 Auchenai Necromancers. Map 558 had only 3 Raging Skeleton spawns,
-- alongside 15 Angered Skeletons and 3 Necromancers, with no summon script
-- supplying the missing Raging Skeletons.
-- Rebalance two existing skeleton packs: 5 Raging, 13 Angered, 3 Necromancers.
-- Preserve positions, phase and normal/heroic spawn masks and total mob count.
UPDATE `creature` SET `id` = 18521
WHERE `guid` IN (80418,80425) AND `id` = 18524 AND `map` = 558;
