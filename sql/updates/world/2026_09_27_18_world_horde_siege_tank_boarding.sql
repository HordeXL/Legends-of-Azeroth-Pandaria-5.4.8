-- Horde Siege Tank (25334), used after Tanks a lot... for The Plains of Nasam.
-- Vehicle 26 seat 0 (365) is its control seat. Restore the missing click-to-board spell.
START TRANSACTION;
UPDATE creature_template SET npcflag = npcflag | 16777216,
    spell1 = 50672, spell2 = 50676
WHERE entry = 25334;
INSERT INTO npc_spellclick_spells (npc_entry,spell_id,cast_flags,user_type)
VALUES (25334,46598,1,0)
ON DUPLICATE KEY UPDATE cast_flags=1,user_type=0;
COMMIT;
