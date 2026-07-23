-- Restore the source-backed Howling Gale effect handler in The Vortex
-- Pinnacle.  The NPC AI already casts the gale pulses itself; the old 85084
-- aura-script binding points to an intentionally inactive legacy handler.
--
-- Build-18414 SpellEffect.dbc confirms that spell 85159 has:
--   effect 0 = SPELL_EFFECT_KNOCK_BACK
--   effect 1 = SPELL_EFFECT_APPLY_AURA
-- These are the two effects suppressed by the C++ handler after the gale has
-- been deactivated.

CREATE TABLE IF NOT EXISTS `_backup_spell_script_names_howling_gale_20260723`
LIKE `spell_script_names`;

SET @howling_gale_backup_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_spell_script_names_howling_gale_20260723`
);

INSERT IGNORE INTO `_backup_spell_script_names_howling_gale_20260723`
SELECT `ssn`.*
FROM `spell_script_names` AS `ssn`
WHERE @howling_gale_backup_empty = 1
  AND `ssn`.`spell_id` IN (85084, 85159);

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
  AND `spell_id` = 85084
  AND `ScriptName` = 'spell_howling_gale_howling_gale';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
SELECT 85159, 'spell_vortex_pinnacle_howling_gale_eff'
FROM DUAL
WHERE @howling_gale_backup_ok = 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM `spell_script_names`
      WHERE `spell_id` = 85159
        AND `ScriptName` = 'spell_vortex_pinnacle_howling_gale_eff'
  );

COMMIT;
