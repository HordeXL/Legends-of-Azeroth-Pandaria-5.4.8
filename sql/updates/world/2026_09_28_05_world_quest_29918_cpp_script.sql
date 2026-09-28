-- Quest 29918 "A Test of Valor": switch Giant White Plainshawk (56171) from SmartAI to C++ AI
-- Script: src/server/scripts/Custom/npc_plainshawk_lasso.cpp (npc_giant_plainshawk_29918)
-- Mechanic: lasso -> dive -> ground ejection (safe) -> grounded combat -> kill = credit.
-- All SAI rows (incl. official instant-credit rows) and helper waypoints are replaced by the script.

-- 1. Remove ALL smart_scripts rows for the hawk: entry-level and per-spawn guid level
DELETE FROM smart_scripts
WHERE source_type = 0
  AND (entryorguid = 56171
       OR entryorguid IN (SELECT -guid FROM creature WHERE id = 56171));

-- 2. Remove helper dive waypoints from previous SAI attempts
DELETE FROM waypoints WHERE entry IN (5617101, 5617102, 5617103, 5617104);

-- 3. Switch creature to the C++ script AI
UPDATE creature_template SET AIName = '', ScriptName = 'npc_giant_plainshawk_29918' WHERE entry = 56171;
