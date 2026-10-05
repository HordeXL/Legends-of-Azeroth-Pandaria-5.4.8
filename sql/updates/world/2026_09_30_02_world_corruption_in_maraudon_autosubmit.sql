-- Corruption in Maraudon (27697) is completed remotely from the quest log
-- after Lord Vyletongue is slain. Without AUTO_SUBMIT the server rejects the
-- client's Complete button because Zaetar's Spirit is not present as an NPC.
UPDATE `quest_template`
SET `Flags` = `Flags` | 0x00100000
WHERE `ID` = 27697;
