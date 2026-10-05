-- Allow regular players to access .server info.
UPDATE `command` SET `security` = 0 WHERE `name` IN ('server', 'server info');
