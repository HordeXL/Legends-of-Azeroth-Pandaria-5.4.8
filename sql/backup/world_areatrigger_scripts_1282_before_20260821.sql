-- Exact preservation of the rejected AreaTrigger script row before the
-- 2026-08-21 startup-log cleanup. This is evidence/backup data, not an
-- update that should be applied during normal server installation.

INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES (1282, 'sat_proving_grounds_berserking')
ON DUPLICATE KEY UPDATE `ScriptName` = VALUES(`ScriptName`);
