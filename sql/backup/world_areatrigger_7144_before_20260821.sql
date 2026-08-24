-- Exact preservation of the Well of Eternity area-trigger binding before the
-- 2026-08-21 startup-log cleanup. This is evidence/backup data, not a normal
-- update and must not be loaded automatically.

INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES (7144, 'at_well_of_eternity_skip_illidan_intro')
ON DUPLICATE KEY UPDATE `ScriptName` = VALUES(`ScriptName`);
