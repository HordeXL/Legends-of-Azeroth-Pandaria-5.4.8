-- Exact rollback for
-- 2026_07_23_01_world_restore_howling_gale_spell_script.sql.

START TRANSACTION;

SET @howling_gale_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`spell_id` = 85084
           AND `ScriptName` = 'spell_howling_gale_howling_gale') = 1
    FROM `_backup_spell_script_names_howling_gale_20260723`
);

DELETE FROM `spell_script_names`
WHERE @howling_gale_backup_ok = 1
  AND
  (
      (`spell_id` = 85084
       AND `ScriptName` = 'spell_howling_gale_howling_gale')
      OR
      (`spell_id` = 85159
       AND `ScriptName` = 'spell_vortex_pinnacle_howling_gale_eff')
  );

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`)
SELECT `spell_id`, `ScriptName`
FROM `_backup_spell_script_names_howling_gale_20260723`
WHERE @howling_gale_backup_ok = 1;

COMMIT;
