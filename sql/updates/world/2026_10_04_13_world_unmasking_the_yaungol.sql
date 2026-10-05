-- Unmasking the Yaungol (30690)
-- The Blinding Rage Trap object existed without AI, leaving Kobai active and
-- never granting the retail Steal Mask extra-action spell.

START TRANSACTION;

UPDATE `gameobject_template`
SET `name` = 'Blinding Rage Trap',
    `AIName` = '',
    `ScriptName` = 'go_blinding_rage_trap'
WHERE `entry` = 211671;

DELETE FROM `spell_script_names`
WHERE `spell_id` = 118984;

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (118984, 'spell_unmasking_yaungol_steal_mask');

-- Malevolent Fury must appear only after the trapped Kobai loses his mask.
-- The old permanent spawn allowed the second objective to be bypassed and
-- could leave no Fury available for the player who actually used the trap.
DELETE FROM `creature`
WHERE `id` = 61333 AND `map` = 870;

COMMIT;
