-- Quest 26228 "Livin' the Life": Glubtok is a summoned scene actor.
-- Nearby Jangolode Mine creatures must not be able to engage or kill him
-- while the player watches the event from Two-Shoed Lou's Old House.
UPDATE `creature_template`
SET `unit_flags` = `unit_flags` | 0x00000200
WHERE `entry` = 42492;
