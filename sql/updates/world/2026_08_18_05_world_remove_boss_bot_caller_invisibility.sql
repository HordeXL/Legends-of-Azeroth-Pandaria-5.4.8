-- Boss Bot Caller entry 990912 was given spell 49414 as a supposed visual.
-- In this 5.4.8 core spell 49414 is Generic Quest Invisibility 1, so callers
-- were visible to a GM (who can see invisible units) but not to normal players.
-- The distinctive display 45941 already supplies the intended spectral glow.
-- Remove only the exact erroneous single-aura assignment and preserve every
-- other template-addon field.

UPDATE `creature_template_addon`
SET `auras` = ''
WHERE `entry` = 990912
  AND TRIM(`auras`) = '49414';

