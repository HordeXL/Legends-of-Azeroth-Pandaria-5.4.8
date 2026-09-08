-- Restore missing Siege of Orgrimmar trash dialogue, without replacing rows.
-- Original build-18019 text already exists in broadcast_text.
-- NPC attribution corroborated by:
-- https://warcraft.wiki.gg/wiki/Kor%27kron_Blood_Axe
-- https://www.wowhead.com/mop-classic/npc=72770/korkron-dark-farseer
-- siege_of_orgrimmar.cpp enum Yells: INTRO=0, SPECIAL_1=1, SPECIAL_2=2.
-- Blood Axe: JustEngagedWith -> INTRO (four random combat cries).
-- Dark Farseer: SummonedCreatureDies -> INTRO (wolf death, SAY);
-- ACTION_START_INTRO -> SPECIAL_1 (infusion speech, YELL);
-- ACTION_CORRUPTED_SKULLSPLITTER -> SPECIAL_2 (failed infusion, YELL).
-- Baseline on the target server: no creature_text rows for either NPC.

START TRANSACTION;

INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`,
     `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
     `BroadcastTextId`, `TextRange`, `comment`)
SELECT mapping.CreatureID, mapping.GroupID, mapping.TextID, bt.`Text`,
       mapping.ChatType, bt.LanguageID, 100, 0, 0, 0, 0,
       bt.ID, 0, mapping.Note
FROM (
    SELECT 72728 AS CreatureID, 0 AS GroupID, 0 AS TextID, 75781 AS BroadcastID,
           14 AS ChatType, 'Kor-kron Blood Axe - aggro' AS Note,
           'npc_siege_of_orgrimmar_korkron_blood_axe' AS ScriptName
    UNION ALL SELECT 72728, 0, 1, 75782, 14, 'Kor-kron Blood Axe - aggro', 'npc_siege_of_orgrimmar_korkron_blood_axe'
    UNION ALL SELECT 72728, 0, 2, 75783, 14, 'Kor-kron Blood Axe - aggro', 'npc_siege_of_orgrimmar_korkron_blood_axe'
    UNION ALL SELECT 72728, 0, 3, 75784, 14, 'Kor-kron Blood Axe - aggro', 'npc_siege_of_orgrimmar_korkron_blood_axe'
    UNION ALL SELECT 72770, 0, 0, 75022, 12, 'Kor-kron Dark Farseer - wolf dies', 'npc_siege_of_orgrimmar_korkron_dark_farseer'
    UNION ALL SELECT 72770, 1, 0, 75801, 14, 'Kor-kron Dark Farseer - infusion intro', 'npc_siege_of_orgrimmar_korkron_dark_farseer'
    UNION ALL SELECT 72770, 2, 0, 75800, 14, 'Kor-kron Dark Farseer - corrupted skullsplitter', 'npc_siege_of_orgrimmar_korkron_dark_farseer'
) AS mapping
JOIN `broadcast_text` bt ON bt.ID = mapping.BroadcastID
    AND bt.VerifiedBuild = 18019 AND bt.`Text` <> ''
JOIN `creature_template` ct ON ct.entry = mapping.CreatureID
    AND ct.ScriptName = mapping.ScriptName
WHERE NOT EXISTS (
    SELECT 1 FROM `creature_text` existing
    WHERE existing.CreatureID = mapping.CreatureID
      AND existing.GroupID = mapping.GroupID AND existing.ID = mapping.TextID
);

COMMIT;
