-- Remove the DB binding for an intentionally disabled Well of Eternity
-- area-trigger script.
--
-- The C++ class still exists, but its AddSC registration is commented out by
-- the instance implementation with a warning that activating this trigger can
-- close the passage when players do not move to the first trash pack, leaving
-- the instance impossible to complete. Keeping the DB row cannot activate the
-- class; it only produces "no core script found" on every startup.
--
-- Well of Eternity and all of its registered encounter/area-trigger scripts
-- remain unchanged. Only the stale binding for the deliberately disabled
-- fallback is removed.

DELETE FROM `areatrigger_scripts`
WHERE `entry` = 7144
  AND `ScriptName` = 'at_well_of_eternity_skip_illidan_intro';
