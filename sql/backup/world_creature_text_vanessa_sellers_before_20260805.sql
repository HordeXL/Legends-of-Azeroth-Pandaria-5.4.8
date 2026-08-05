-- Exact rollback for
-- sql/updates/world/2026_08_05_00_world_add_vanessa_sellers_shop_greetings.sql
--
-- Before the update, creature 32514 had no creature_text rows.  Removing the
-- seven inserted group-0 greetings therefore restores the verified pre-update
-- state without changing the creature spawn, vendor inventory, or aura 60913.
DELETE FROM `creature_text`
WHERE `CreatureID` = 32514
  AND `GroupID` = 0
  AND `ID` BETWEEN 0 AND 6;
