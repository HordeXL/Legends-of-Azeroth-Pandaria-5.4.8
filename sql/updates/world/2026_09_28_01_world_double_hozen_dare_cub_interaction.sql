-- The Double Hozen Dare (29716): make Scared Pandaren Cubs interactable.
-- Their SmartAI already handles menu 55267 / option 0 and casts Save Cub
-- (103181), but the creature template exposes neither that menu nor gossip.
UPDATE creature_template
SET gossip_menu_id = 55267,
    npcflag = npcflag | 1
WHERE entry = 55267;

UPDATE gossip_menu_option
SET OptionText = 'It''s safe now. You can come down.',
    OptionNpcflag = 1
WHERE MenuID = 55267 AND OptionID = 0;

-- Do not let players who are not actively rescuing cubs consume the spawn.
DELETE FROM conditions
WHERE SourceTypeOrReferenceId = 15
  AND SourceGroup = 55267
  AND SourceEntry = 0
  AND SourceId = 0;

INSERT INTO conditions
    (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup,
     ConditionTypeOrReference, ConditionTarget, ConditionValue1,
     ConditionValue2, ConditionValue3, NegativeCondition, ErrorType,
     ErrorTextId, ScriptName, Comment)
VALUES
    (15, 55267, 0, 0, 0, 9, 0, 29716, 0, 0, 0, 0, 0, '',
     'Show the rescue option while The Double Hozen Dare is incomplete');
