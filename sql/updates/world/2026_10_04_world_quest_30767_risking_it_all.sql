-- ============================================================================
-- Quest 30767 "Risking It All" (孤注一掷) - full scene fix (consolidated)
-- ============================================================================
-- Symptom summary:
--   * Story Aysa (60729) invisible / never talks or walks after accept
--   * CLOSEST_PLAYER / CLOSEST_CREATURE searches silently find nothing
--   * Static Ji (60741) missing from the deck; duplicate Ji next to giver
--   * Aysa's say-text empty ("Aysa Cloudsinger says:" with no content)
--
-- Root causes & fixes (consolidated from 2026_10_03_04..10):
--
-- 1) Story summons were cast via spells 117497/117597 whose
--    SummonProperties.dbc row 3276 carries flag 0x10 (PERSONAL_SPAWN),
--    making them private objects of the NPC caster -> invisible to all
--    players. Fix: restore official SAI action 12 direct summons.
--
-- 2) Story Aysa's JUST_SUMMONED chain sets phasemask 4 before storing the
--    nearby player list; deck players are in phasemask 2 (giver guid 563253
--    mask=2 / 563254 mask=4). 2&4=0 -> player filtered out. Fix: mask 6 (2|4).
--
-- 3) This fork uses dual phase systems (phasemask AND phase-ID set).
--    WorldObject::IsPhased only pairs empty-phase objects with players
--    holding phase id 169; deck players are [171]. Fix: tag giver spawns
--    (guid 563253/563254) with phaseid=171 - Map::SummonCreature copies the
--    summoner's phase-ID set onto summons, so 60729 inherits {171}.
--
-- 4) The scene partner is the STATIC Ji spawn guid 563198 (230.3, 4006.7,
--    87.4, ~4.8yd from Aysa's wp2 stop); the SAI-summoned Ji lands at
--    POSITION(0,0,0) - official dead data (in this fork the zero coords fall
--    back to the caster position, showing a duplicate Ji next to the giver).
--    Static Ji had spawnMask=0 (never loaded) and empty phase-ID set (search
--    rejected like in 3). Fix: spawnMask=1 + phaseid=171; drop the redundant
--    summon row entirely.
--
-- 5) Aysa's broadcast_text rows store text only in the FEMALE column, but
--    model 41667 (giver 56416 + story 60729) was gender=0 (male) in
--    creature_model_info -> empty strings. Fix: gender=1.
--
-- 6) Stale story Aysa from abandoned quests are despawned on re-accept
--    (action 80 list 5641601 on closest 60729 within 100yd). The old
--    60741-cleanup row was removed: it could force-despawn the STATIC Ji
--    (with no respawn timer before the core ForcedDespawn fix).
--
-- Requires core commit: Creature::ForcedDespawn -> RemoveCorpse(!IsSummon())
-- (static creatures keep their respawn timer after SAI action 41).
--
-- After import: ".reload smart_scripts" + restart (spawn/model data is
-- cached at startup).
-- ============================================================================

-- --------------------------------------------------------------------------
-- 1) Giver 56416 quest-accept chain: cleanup stale story-Aysa -> summon her
--    (old rows 11-14 replaced by 12 -> 13)
-- --------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` = 56416 AND `source_type` = 0 AND `id` IN (11, 12, 13, 14);
DELETE FROM `smart_scripts` WHERE `source_type` = 9 AND `entryorguid` IN (5641601, 5641602);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- on accept: despawn stale story Aysa within 100yd, then summon at giver
(56416,0,12,13,19,0,100,0,30767,0,0,0,0,80,5641601,2,0,0,0,0,19,60729,100,0,0,0,0,0,0,'Aysa Cloudsinger - Accepted Quest - Run Despawn List 5641601 on Closest Stale 60729 (100yd)'),
(56416,0,13,0,61,0,100,0,0,0,0,0,0,12,60729,8,0,0,0,0,1,0,0,0,0,0,0,0,0,'Aysa Cloudsinger - Linked - Summon Creature Aysa Cloudsinger 60729 (manual despawn)'),
-- one-shot despawn list for stale story Aysa
(5641601,9,0,0,0,0,100,0,0,0,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Story Aysa Despawn List - Force Despawn (immediate)');

-- --------------------------------------------------------------------------
-- 2) Story Aysa 60729: phasemask 4 -> 6 (deck phases 2|4)
-- --------------------------------------------------------------------------
UPDATE `smart_scripts`
SET `action_param1` = 6,
    `comment` = 'Aysa Cloudsinger - On Summoned - Set Ingame Phase Mask 6 (deck phases 2|4)'
WHERE `entryorguid` = 60729 AND `source_type` = 0 AND `id` = 0 AND `action_type` = 44;

-- --------------------------------------------------------------------------
-- 3) Giver spawns join the deck quest phase (summons inherit phase-ID set)
-- --------------------------------------------------------------------------
UPDATE `creature` SET `phaseid` = 171 WHERE `id` = 56416;

-- --------------------------------------------------------------------------
-- 4) Static Ji 563198: actually spawn and join the scene phase
-- --------------------------------------------------------------------------
UPDATE `creature` SET `spawnMask` = 1, `phaseid` = 171 WHERE `guid` = 563198 AND `id` = 60741;

-- --------------------------------------------------------------------------
-- 5) Aysa Cloudsinger model: female (broadcast text lives in the female column)
-- --------------------------------------------------------------------------
UPDATE `creature_model_info` SET `gender` = 1 WHERE `modelid` = 41667;
