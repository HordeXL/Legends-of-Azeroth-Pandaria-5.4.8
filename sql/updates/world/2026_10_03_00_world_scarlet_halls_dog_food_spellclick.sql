-- Scarlet Halls: make Bucket of Meaty Dog Food (65379) clickable.
-- Its AI sets UNIT_NPC_FLAG_SPELLCLICK, but Player::CanSeeSpellClickOn
-- hides that flag from the client when no npc_spellclick_spells row exists.
-- Carrying Bucket (128164) grants override bar 391 / Throw Bucket (113029).
-- Cast as the clicking player on themselves; the existing AI consumes the bucket.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 65379 AND `spell_id` = 128164;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
VALUES (65379, 128164, 3, 0);
