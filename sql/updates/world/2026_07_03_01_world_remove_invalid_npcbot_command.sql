-- This core registers `npcbot` as a single command handler that parses its
-- arguments internally. The nested DB command entry is from a different
-- command-tree layout and is rejected by the command loader.
DELETE FROM `command` WHERE `name` = 'npcbot log clear';
