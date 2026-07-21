-- Restore the missing SmartAI text group used by Meridith the Mermaiden.
-- Trinity's original Meridith SAI explicitly calls SAY group 0 after casting
-- Siren's Song. The matching Blizzard broadcast text is already present as
-- Build-18019 broadcast_text ID 11089. No existing row is deleted or replaced.

START TRANSACTION;

INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`,
     `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
     `BroadcastTextId`, `TextRange`, `comment`)
SELECT
    15526, 0, 0, 'Lovely song, isn''t it?', 12, 0,
    100, 0, 0, 0, 0,
    11089, 0, 'Meridith the Mermaiden'
FROM DUAL
WHERE EXISTS (
    SELECT 1
    FROM `creature_template`
    WHERE `entry` = 15526
      AND `name` = 'Meridith the Mermaiden'
      AND `gossip_menu_id` = 6658
      AND `AIName` = 'SmartAI'
      AND `VerifiedBuild` = 15595
)
AND EXISTS (
    SELECT 1
    FROM `smart_scripts`
    WHERE `entryorguid` = 15526
      AND `source_type` = 0
      AND `id` = 2
      AND `event_type` = 61
      AND `action_type` = 1
      AND `action_param1` = 0
      AND `target_type` = 1
)
AND EXISTS (
    SELECT 1
    FROM `broadcast_text`
    WHERE `ID` = 11089
      AND `LanguageID` = 0
      AND `Text` = ''
      AND `Text1` = 'Lovely song, isn''t it?'
      AND `Flags` = 1
      AND `VerifiedBuild` = 18019
)
AND NOT EXISTS (
    SELECT 1
    FROM `creature_text`
    WHERE `CreatureID` = 15526
      AND `GroupID` = 0
      AND `ID` = 0
);

COMMIT;
