-- Both provided items already cast the correct DBC spells and consume one
-- charge on use. Their SEND_EVENT effects had no event_scripts handlers,
-- so a successful use removed the blades without awarding the objective.
-- 87388 -> 126787 -> event 33000 -> credit 64835 -> quest 31514 (Normal).
-- 87390 -> 126843 -> event 33001 -> credit 64840 -> quest 31516 (Heroic).
-- The spells require Whitemane's corpse focus (1780). Native quest matching
-- applies credit to the item user, regardless of dungeon difficulty.
-- Do not complete quests on boss death or award credit to other group members.
DELETE FROM `event_scripts` WHERE `id` IN (33000, 33001);
INSERT INTO `event_scripts`
    (`id`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`, `o`)
VALUES
    (33000, 0, 8, 64835, 0, 0, 0, 0, 0, 0),
    (33001, 0, 8, 64840, 0, 0, 0, 0, 0, 0);
