-- Allow GMs who can use .learn to also use the recipe helper command.
UPDATE `command`
SET `security` = 4
WHERE `name` = 'learn all recipes';
