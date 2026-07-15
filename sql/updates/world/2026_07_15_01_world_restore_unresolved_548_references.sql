-- Corrective forward update for 2026_07_15_00.
-- These rows were not proven orphans. Matching 5.4.8 data confirms quest
-- 32592 content and creature GUIDs 77232/136675 exist in a trusted SFDB.
-- Restore references without overwriting any later correction.

INSERT IGNORE INTO `creature_queststarter` (`id`,`quest`) VALUES (69782,32592);
INSERT IGNORE INTO `creature_questender` (`id`,`quest`) VALUES (69782,32592);

INSERT IGNORE INTO `game_event_creature` (`eventEntry`,`guid`) VALUES
(31,77232),
(31,136675);

INSERT IGNORE INTO `spell_linked_spell`
    (`spell_trigger`,`spell_effect`,`type`,`comment`)
VALUES
(123262,203754,0,'Prayer of Mending server-side trigger'),
(200002,200004,0,'Alliance to Horde (tick)'),
(200003,200005,0,'Horde to Alliance (tick)');
