-- Quest 29792 "Bidden to Greatness" uses personal, animated scene gates.
-- Keep the two phase-2 base gates visible before the quest, but hide them for
-- each player as soon as quest 29792 is accepted.  This prevents a stale
-- closed base gate (and its collision) from remaining over the animated gate.
-- Negative entryorguid values address one exact gameobject spawn GUID.

DELETE FROM `object_visibility_state`
WHERE `type` = 'GameObject'
  AND `entryorguid` IN (-540359, -540026);

INSERT INTO `object_visibility_state`
    (`type`, `entryorguid`, `visibilityQuestID`, `visibilityQuestState`)
VALUES
    ('GameObject', -540359, 29792, 0), -- Mandori Village base gate
    ('GameObject', -540026, 29792, 0); -- Pei-Wu Forest base gate
