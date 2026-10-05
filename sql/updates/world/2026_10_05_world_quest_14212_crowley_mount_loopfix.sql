-- Quest 14212 "Sacrifices": break the Crowley summon feedback loop
--
-- Symptom (after making the static horse 35231 clickable + SAI SpellHit hook):
--   Clicking the horse failed to seat the player and spawned many Crowley
--   (35230) NPCs, each casting a ride spell.
--
-- Root cause:
--   The SAI hook listens for SpellHit(46598). The player's click casts 46598
--   (one hit), but CROWLEY's own mount action (timed list 3523000) also cast
--   46598 on the horse -> another SpellHit -> another 67003 summon -> another
--   Crowley -> ... infinite feedback loop. Additionally, each new 46598 aura
--   from a different caster replaced the previous one on the horse, and the
--   aura-removal handler kicked the previous rider (ultimately the player)
--   out of the vehicle -> "mount always fails".
--
-- Fix:
--   Crowley now mounts with spell 47020 instead of 46598. 47020 is
--   structure-identical to 46598 (E0: apply aura 236 CONTROL_VEHICLE,
--   TargetA=25, bp 0/0; E1: aura 4 dummy on self), is already used by other
--   npc_spellclick_spells entries in this DB (proven), and is referenced by
--   no SAI rows. The player's click-spell stays 46598, so exactly one
--   SpellHit(46598) fires per click and the loop is gone.

UPDATE `smart_scripts` SET `action_param1`=47020
WHERE `source_type`=9 AND `entryorguid`=3523000 AND `id`=0
  AND `action_type`=11 AND `action_param1`=46598;
