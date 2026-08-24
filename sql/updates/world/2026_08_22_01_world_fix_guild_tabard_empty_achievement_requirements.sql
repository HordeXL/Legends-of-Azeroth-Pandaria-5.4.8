-- Items 69209 (Illustrious Guild Tabard) and 69210 (Renowned Guild Tabard)
-- are gated by guild reputation, not by an achievement. The legacy string
-- sentinel '0' is parsed as achievement ID 0 and produces a false startup
-- error; current SFDB represents the absence of a requirement as an empty
-- string.

UPDATE `guild_rewards`
SET `achievements` = ''
WHERE `entry` IN (69209, 69210)
  AND `achievements` = '0';
