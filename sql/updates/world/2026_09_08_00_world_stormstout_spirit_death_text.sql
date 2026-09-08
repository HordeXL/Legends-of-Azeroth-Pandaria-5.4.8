-- Both spirit scripts call Talk(0) when their death damages the linked Hozen.
-- Broadcast 59598 already describes that mechanic in the build-18019 data.
-- Restore it as an encounter notification, not a spoken Hozen dialogue.
-- The NPC/group mapping is inferred from the scripts and broadcast wording;
-- it is not a newly verified retail packet capture. Preserve existing groups.

START TRANSACTION;

INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`,
     `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
     `BroadcastTextId`, `TextRange`, `comment`)
SELECT
    ct.`entry`, 0, 0, bt.`Text`, 41, bt.`LanguageID`,
    100, 0, 0, 0, 0,
    bt.`ID`, 0, CONCAT(ct.`name`, ' - illusion removed notification')
FROM `creature_template` ct
JOIN `broadcast_text` bt ON bt.`ID` = 59598
WHERE ((ct.`entry` = 56865 AND ct.`ScriptName` = 'npc_aqua_dancer')
    OR (ct.`entry` = 56867 AND ct.`ScriptName` = 'npc_fiery_trickster'))
  AND bt.`Text` = 'Removing the spirit''s illusion damages the hozen''s fragile mind!'
  AND NOT EXISTS (
      SELECT 1 FROM `creature_text` existing
      WHERE existing.`CreatureID` = ct.`entry` AND existing.`GroupID` = 0
  );

COMMIT;
