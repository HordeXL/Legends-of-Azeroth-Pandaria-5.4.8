-- Remove an unusable spell-area-trigger script binding from the classic
-- AreaTrigger.dbc-backed table.
--
-- Entry 1282 is the spell area trigger summoned by Proving Grounds spell
-- 147294 (Berserking), not a classic AreaTrigger.dbc record. The current core
-- therefore rejects this row during LoadAreaTriggerScripts and never binds
-- the script from this table. The same invalid row came from an old local
-- error-cleanup SQL; it is absent from SFDB 548 release 25.001.
--
-- No guessed spell_areatrigger_template row is inserted: neither the current
-- 5.4.8 base nor the latest reference SFDB supplies authoritative template
-- geometry for entry 1282. The C++ implementation is retained untouched.

DELETE FROM `areatrigger_scripts`
WHERE `entry` = 1282
  AND `ScriptName` = 'sat_proving_grounds_berserking';
