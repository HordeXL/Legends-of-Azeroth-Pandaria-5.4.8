-- Quest 14212 "Sacrifices" (Gilneas): fix Crowley's Horse click-to-mount
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
