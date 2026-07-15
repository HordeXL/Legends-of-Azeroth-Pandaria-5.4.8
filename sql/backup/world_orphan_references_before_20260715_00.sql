-- Exact rows removed by 2026_07_15_00_world_remove_proven_orphan_references.sql.
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (69782,32592);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (69782,32592);
INSERT INTO `game_event_creature` (`eventEntry`,`guid`) VALUES (31,77232),(31,136675);
INSERT INTO `spell_linked_spell` (`spell_trigger`,`spell_effect`,`type`,`comment`) VALUES
(123262,203754,0,'Prayer of Mending server-side trigger'),
(200002,200004,0,'Alliance to Horde (tick)'),
(200003,200005,0,'Horde to Alliance (tick)');
