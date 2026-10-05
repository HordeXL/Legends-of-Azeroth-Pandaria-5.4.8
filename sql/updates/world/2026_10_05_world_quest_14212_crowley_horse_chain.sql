-- Quest 14212 "Sacrifices" (Gilneas): Crowley's Horse ride chain - complete fix
-- (merged from crowleys_horse / crowley_mount_loopfix / crowley_reride_horse /
--  horse_combat_flags; apply statements in order - later steps depend on the
--  state produced by earlier ones)

-- ============================================================================
-- Part 1: fix Crowley's Horse click-to-mount
--
-- Problem:
--   The standing horse next to Lord Crowley was 44427 (npcflag SPELLCLICK,
--   VehicleId=0 -> no vehicle kit, structurally impossible to mount).
--   Its spellclick spell 67766 (cast_flags=TARGET_CLICKER) force-cast 67001
--   on the player, summoning a NEW scripted horse 35231 on every click;
--   that horse's SAI then summoned Crowley (35230). The player was never
--   seated -> "mount fails, every click spawns Crowley".
--
-- Fix (retail parity: one horse, click it, player + Crowley ride):
--   1) Remove the duplicate unmountable horse 44427 (spawn + spellclick row).
--   2) Keep 35231 as the only standing horse. It has VehicleId=463 (vehicle
--      kit auto-grants the SPELLCLICK cursor) and spellclick 46598 with
--      cast_flags=CASTER_CLICKER, so clicking it mounts the player in the
--      control seat (action bar with spell1 67063).
--   3) Add a SpellHit hook (event 8, spell 46598) on 35231 that starts the
--      existing timed action list 3523100: summons Crowley (67003, plain
--      TempSummon since DBC patch MiscValueB 61->181) who boards the free
--      passenger seat, then the horse starts waypoint path 35231 after 5s.
--      Re-clicking the horse after the ride re-runs the scene (retail:
--      "hop back on his mount and he'll make another run").

DELETE FROM `creature` WHERE `guid`=219682 AND `id`=44427;
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry`=44427;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=35231 AND `id`=8;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(35231,0,8,0,8,0,100,0,46598,0,0,0,0,80,3523100,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Crowley''s Horse - On Spellhit 46598 (Ride Vehicle) - Start Ride Script');

-- ============================================================================
-- Part 2: break the Crowley summon feedback loop
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

-- ============================================================================
-- Part 3: make the parked re-ride horse (44429) mountable
--
-- Symptom: after the scripted ride ends at the cathedral, re-clicking the
-- parked "Crowley's Horse" (44429, standing at -1539,1570 = path 35231's last
-- waypoint) failed to mount. Its spellclick 82992 only summoned 44428, which
-- is an empty shell in this DB (no VehicleId, no SAI, no spellclick) - a dead
-- retail chain.
--
-- Fix: promote 44429 itself to a full rideable horse (same treatment as
-- 35231):
--   1) creature_template: VehicleId 0 -> 463 (vehicle kit + SPELLCLICK
--      cursor), AIName -> SmartVehicleAI.
--   2) npc_spellclick_spells: 82992 -> 46598 (cast_flags=1, player mounts).
--   3) Clone 35231's creature SAI rows onto 44429 (incl. the SpellHit(46598)
--      -> start-list row, wp jumps/quotes, wp33 dismount, Crowley despawn).
--      Both horses share the timed list 3523100 (all actions are SELF-
--      relative) and the same waypoint path 35231.
--   4) Crowley's mount action (list 3523000) now targets OWNER_OR_SUMMONER
--      (target_type 23) instead of "nearest 35231 within 10yd", so he boards
--      whichever horse summoned him (35231 for the first ride, 44429 for
--      re-rides) even if the other horse stands nearby.

UPDATE `creature_template` SET `VehicleId`=463, `AIName`='SmartVehicleAI'
WHERE `entry`=44429 AND `VehicleId`=0;

UPDATE `npc_spellclick_spells` SET `spell_id`=46598
WHERE `npc_entry`=44429 AND `spell_id`=82992;

UPDATE `smart_scripts` SET `target_type`=23, `target_param1`=0, `target_param2`=0, `target_param3`=0
WHERE `source_type`=9 AND `entryorguid`=3523000 AND `id`=0 AND `action_type`=11 AND `action_param1`=47020;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=44429;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
SELECT 44429, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`
FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=35231;

-- ============================================================================
-- Part 4: vehicle spell usability (Throw Torch 67063)
--
-- Root cause 1: 35231 unit_flags=0x8300 contained IMMUNE_TO_PC(0x100) +
--   IMMUNE_TO_NPC(0x200). Unit::IsValidAttackTarget rejects any caster vs an
--   IMMUNE_TO_NPC target (non-WORLD_TRIGGER), so the AoE 67063 (TA=8 area
--   enemies) always hit 0 targets -> no damage, no SpellHit, no quest credit.
--   Fix: strip both immune flags, keep only CAN_SWIM(0x8000). The horse's
--   faction is 35 (friendly to all); nothing attacks it while unmanned, and
--   SetCharmedBy switches it to the rider's faction while mounted.
-- Root cause 2: 44429 (the re-ride horse promoted in Part 3) had no spell1,
--   so its vehicle action bar was empty. Set 67063 to match 35231.

UPDATE creature_template SET unit_flags=32768 WHERE entry=35231 AND unit_flags=33536;
UPDATE creature_template SET spell1=67063 WHERE entry=44429;
