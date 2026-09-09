-- The VIP utility trainer's historical Thrown entry (256) is absent from
-- the 5.4.8 Spell store. The scripted weapon menu is corrected separately.
-- Preserve every other trainer and every valid VIP training offer.
DELETE FROM `npc_trainer` WHERE `entry` = 900100 AND `spell` = 256;
