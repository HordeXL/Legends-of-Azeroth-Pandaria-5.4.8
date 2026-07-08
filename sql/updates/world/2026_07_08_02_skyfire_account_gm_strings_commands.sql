-- SkyFire 5.4.8 selected fix.
--
-- Source: C:\wamp64\www\SkyFire_548\sql\updates\world\2026_01_23_world_00.sql
-- Notes:
-- - Adapted skyfire_string to this project's trinity_string.
-- - Adapted command.permission RBAC IDs to this project's command.security enum.
--   AccountTypes: SEC_PLAYER=0, SEC_MODERATOR=1, SEC_GAMEMASTER=2, SEC_ADMINISTRATOR=3, SEC_CONSOLE=4.

DELETE FROM `trinity_string` WHERE `entry` IN (401, 402, 403, 597, 598, 599);
INSERT INTO `trinity_string` (`entry`, `content_default`) VALUES
(401, 'You change security level of account %s to %i.'),
(402, '%s changed your security level to %i.'),
(403, 'You have low security level for this.'),
(597, 'Current gamemasters:'),
(598, '|    Account    |  GM  |'),
(599, 'No gamemasters.');

DELETE FROM `command` WHERE `name` IN ('account set gmlevel', 'gm list');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('account set gmlevel', 2, 'Syntax: .account set gmlevel [$account] #level [#realmid]\r\n\r\nSet the security level for targeted player (can''t be used at self) or for account $name to a level of #level on the realm #realmID.\r\n\r\n#level may range from 0 to 3.\r\n\r\n#reamID may be -1 for all realms.'),
('gm list', 0, 'Syntax: .gm list\r\n\r\nDisplay a list of all Game Masters accounts and security levels.');
