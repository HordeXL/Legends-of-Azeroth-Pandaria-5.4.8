-- ==================================================================
-- Quest 31765 (Paint it Red! / 血染滩头) - complete fix (merged)
-- ==================================================================
-- Merges four fixes for quest 31765 (originally 2026_09_26_00..03):
--   [1] Turret could not be mounted (spellclick missing)
--   [2] Garrison NPC kill credit extended to quest 31765
--   [3] Turret cannon shot dealt no damage (spell chain broken)
--   [4] Second batch of garrison NPC kill credit (laborers)
--
-- Blizzard mechanism: the player right-clicks a Gunship Turret on the
-- deck of Hellscream's Fist, mounts it as a controlled vehicle
-- (VehicleId 2455) and shells Thunder Hold from the vehicle action bar.
-- Cannon fire kills Thunder Hold troops (66200) and destroys Thunder
-- Hold Cannons (66203); credit is granted through the cannon impact
-- spell's kill-credit effects (spell 130994, target type 105 = caster
-- + vehicle passengers) plus the regular Unit::Kill credit path.
--
-- ------------------------------------------------------------------
-- [1] Turret mountable: 66183 had npcflag = 0 (no
--     UNIT_NPC_FLAG_SPELLCLICK -> client never sends CMSG_SPELLCLICK)
--     and no row in npc_spellclick_spells (Unit::HandleSpellClick
--     would find no click info).  Mirror the proven configuration of
--     working gunship cannons (Alliance Gunship Cannon 36838 =
--     spellclick 70510; Scarlet Cannon 28833 = spellclick 52447)
--     using the core's hardcoded ride spell 46598
--     (VEHICLE_SPELL_RIDE_HARDCODED, SPELL_AURA_CONTROL_VEHICLE).
-- ------------------------------------------------------------------

START TRANSACTION;

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 0x01000000  -- UNIT_NPC_FLAG_SPELLCLICK
WHERE `entry` = 66183
  AND `VehicleId` = 2455;

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 66183, 46598, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM `npc_spellclick_spells` WHERE `npc_entry` = 66183);

-- ------------------------------------------------------------------
-- [3] Cannon shot damage: verified against real client data
--     (SpellEffect.db2 / SpellMisc.db2):
--       130163 (turret button spell): only effect is APPLY_AURA with
--         aura type 48 (SPELL_AURA_48), TriggerSpell 130162.  This
--         fork implements aura 48 as AuraEffect::HandleNULL (no-op),
--         so casting 130163 does nothing at all.
--       130162: the actual AoE damage shot (SCHOOL_DAMAGE at dest).
--       130973: instant, range 0-50000yd, TRIGGER_MISSILE -> 130994;
--         nothing in the spell store triggers 130973, so it is the
--         projectile launcher.
--       130994: impact - SCHOOL_DAMAGE at dest area +
--         SPELL_EFFECT_KILL_CREDIT x3 (creature 66200, troops) and
--         x1 (creature 66203, cannons), implicit target 105
--         (caster + vehicle passengers).
--     On live the client-side aura 48 chain produces the shot; since
--     aura 48 is unimplemented server-side, point the turret action
--     bar button straight at the projectile spell 130973 instead:
--     same missile visual, impact damage, and the built-in quest kill
--     credit effects all fire.
-- ------------------------------------------------------------------

UPDATE `creature_template`
SET `spell1` = 130973
WHERE `entry` IN (66183, 66674, 66676, 66677)
  AND `name` = 'Gunship Turret'
  AND `spell1` = 130163;

-- ------------------------------------------------------------------
-- [2]+[4] Garrison NPC kill credit: the beach garrison is a
--     kill-credit family.  Mender (66286), Lieutenant (66287),
--     Armsman (66348) and Cannoneer (66395) already forward their
--     kill credit to Infantryman (66285) via KillCredit1 (feeding
--     quest 31767 x15), but none counted toward quest 31765's
--     objective "Thunder Hold troops slain" (creature 66200 x80).
--     Infantryman (66285), Sharp-Shooter (66647), Laborers
--     (66284, 66651) and Mender (66649) had no link to 66200 either.
--     Set KillCredit2 = 66200 on all nine entries so killing any of
--     them also grants quest 31765 credit through the standard
--     Player::KilledMonster -> Player::KilledMonsterCredit path.
--     66200 is only referenced by quest 31765, so no other quest is
--     affected.
-- ------------------------------------------------------------------

UPDATE `creature_template`
SET `KillCredit2` = 66200
WHERE `entry` IN (66284, 66285, 66286, 66287, 66348, 66395, 66647, 66649, 66651)
  AND `KillCredit2` = 0;

COMMIT;

-- Idempotency: [1] guarded by VehicleId + NOT EXISTS, [2]/[3]/[4]
-- guarded by current-value checks; safe to re-run.
-- Takes effect after worldserver restart (creature_template and
-- npc_spellclick_spells are loaded at startup).
