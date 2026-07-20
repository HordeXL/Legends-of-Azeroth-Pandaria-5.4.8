-- Restore quest 31765 (Paint it Red!) from the matching SkyFire 5.4.8 data.
-- Build-18414 spell 130994 already contains kill-credit effects for creatures
-- 66200 and 66203, targeted at the caster and its vehicle passengers (target
-- type 105).  The spell_scripts rows on missile spell 130973 can never run
-- because effect 0 is TRIGGER_MISSILE, not DUMMY/SCRIPT_EFFECT.  The two
-- quest-accept SmartAI actions are an unrelated shortcut that awards both
-- objectives before the turret is used.  Remove only those four exact stale
-- workaround rows after restoring the source-backed objective totals 80/9.

START TRANSACTION;

SET @old_objectives := (
    SELECT COUNT(*)
    FROM `quest_objective`
    WHERE (`questId` = 31765 AND `id` = 269073 AND `index` = 0
           AND `type` = 0 AND `objectId` = 66200 AND `amount` = 1
           AND `flags` = 0 AND `description` = 'Thunder Hold troops slain')
       OR (`questId` = 31765 AND `id` = 269074 AND `index` = 1
           AND `type` = 0 AND `objectId` = 66203 AND `amount` = 1
           AND `flags` = 0 AND `description` = 'Thunder Hold cannons destroyed')
);

SET @corrected_objectives := (
    SELECT COUNT(*)
    FROM `quest_objective`
    WHERE (`questId` = 31765 AND `id` = 269073 AND `index` = 0
           AND `type` = 0 AND `objectId` = 66200 AND `amount` = 80
           AND `flags` = 0 AND `description` = 'Thunder Hold troops slain')
       OR (`questId` = 31765 AND `id` = 269074 AND `index` = 1
           AND `type` = 0 AND `objectId` = 66203 AND `amount` = 9
           AND `flags` = 0 AND `description` = 'Thunder Hold cannons destroyed')
);

SET @stale_spell_scripts := (
    SELECT COUNT(*)
    FROM `spell_scripts`
    WHERE `id` = 130973 AND `effIndex` = 0 AND `delay` = 0
      AND `command` = 8 AND `datalong` IN (66200, 66203)
      AND `datalong2` = 0 AND `dataint` = 0
      AND `x` = 0 AND `y` = 0 AND `z` = 0 AND `o` = 0
);

SET @stale_accept_actions := (
    SELECT COUNT(*)
    FROM `smart_scripts`
    WHERE (`entryorguid` = 55135 AND `source_type` = 0 AND `id` = 0 AND `link` = 1
           AND `event_type` = 19 AND `event_phase_mask` = 0 AND `event_chance` = 100
           AND `event_flags` = 0 AND `event_param1` = 31765 AND `event_param2` = 0
           AND `event_param3` = 0 AND `event_param4` = 0 AND `event_param5` = 0
           AND `action_type` = 33 AND `action_param1` = 66200
           AND `action_param2` = 0 AND `action_param3` = 0 AND `action_param4` = 0
           AND `action_param5` = 0 AND `action_param6` = 0 AND `target_type` = 7
           AND `target_param1` = 0 AND `target_param2` = 0 AND `target_param3` = 0
           AND `target_param4` = 0 AND `target_x` = 0 AND `target_y` = 0
           AND `target_z` = 0 AND `target_o` = 0 AND `comment` = 'General Nazgrim')
       OR (`entryorguid` = 55135 AND `source_type` = 0 AND `id` = 1 AND `link` = 0
           AND `event_type` = 61 AND `event_phase_mask` = 0 AND `event_chance` = 100
           AND `event_flags` = 0 AND `event_param1` = 0 AND `event_param2` = 0
           AND `event_param3` = 0 AND `event_param4` = 0 AND `event_param5` = 0
           AND `action_type` = 33 AND `action_param1` = 66203
           AND `action_param2` = 0 AND `action_param3` = 0 AND `action_param4` = 0
           AND `action_param5` = 0 AND `action_param6` = 0 AND `target_type` = 7
           AND `target_param1` = 0 AND `target_param2` = 0 AND `target_param3` = 0
           AND `target_param4` = 0 AND `target_x` = 0 AND `target_y` = 0
           AND `target_z` = 0 AND `target_o` = 0 AND `comment` = 'General Nazgrim')
);

SET @can_repair := (@old_objectives = 2 AND @corrected_objectives = 0
                    AND @stale_spell_scripts = 2 AND @stale_accept_actions = 2);

UPDATE `quest_objective`
SET `amount` = CASE `id` WHEN 269073 THEN 80 WHEN 269074 THEN 9 END
WHERE @can_repair
  AND `questId` = 31765
  AND ((`id` = 269073 AND `index` = 0 AND `type` = 0 AND `objectId` = 66200
        AND `amount` = 1 AND `flags` = 0 AND `description` = 'Thunder Hold troops slain')
    OR (`id` = 269074 AND `index` = 1 AND `type` = 0 AND `objectId` = 66203
        AND `amount` = 1 AND `flags` = 0 AND `description` = 'Thunder Hold cannons destroyed'));

DELETE FROM `spell_scripts`
WHERE @can_repair
  AND `id` = 130973 AND `effIndex` = 0 AND `delay` = 0
  AND `command` = 8 AND `datalong` IN (66200, 66203)
  AND `datalong2` = 0 AND `dataint` = 0
  AND `x` = 0 AND `y` = 0 AND `z` = 0 AND `o` = 0;

DELETE FROM `smart_scripts`
WHERE @can_repair AND `entryorguid` = 55135 AND `source_type` = 0
  AND ((`id` = 0 AND `link` = 1 AND `event_type` = 19 AND `event_param1` = 31765
        AND `action_type` = 33 AND `action_param1` = 66200)
    OR (`id` = 1 AND `link` = 0 AND `event_type` = 61 AND `event_param1` = 0
        AND `action_type` = 33 AND `action_param1` = 66203));

COMMIT;
