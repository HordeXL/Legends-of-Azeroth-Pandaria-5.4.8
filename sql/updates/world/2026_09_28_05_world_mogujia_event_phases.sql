-- Deanimate the Reanimated (30593/30594) and Mogu?! Oh No-gu!
-- (30619/30620): keep the later level-90 Mogujia faction events out of
-- the ordinary level-87 quest phase.
START TRANSACTION;

DELETE FROM phase_definitions
WHERE zoneId = 5841 AND entry IN (1, 2);

INSERT INTO phase_definitions
    (zoneId, entry, phasemask, phaseId, terrainswapmap, worldMapArea, flags, comment)
VALUES
    (5841, 1, 1073741824, 0, 0, 0, 0, 'Mogujia - Horde To Mogujia event'),
    (5841, 2,  536870912, 0, 0, 0, 0, 'Mogujia - Alliance To Mogujia event');

DELETE FROM conditions
WHERE SourceTypeOrReferenceId = 25
  AND SourceGroup = 5841
  AND SourceEntry IN (1, 2);

-- Preserve the event phase while the breadcrumb is incomplete, complete but
-- not yet turned in, or rewarded so its follow-up quests remain playable.
INSERT INTO conditions
    (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup,
     ConditionTypeOrReference, ConditionTarget, ConditionValue1,
     ConditionValue2, ConditionValue3, NegativeCondition, ErrorType,
     ErrorTextId, ScriptName, Comment)
VALUES
    (25, 5841, 1, 0, 0,  9, 0, 32190, 0, 0, 0, 0, 0, '', 'Horde Mogujia - To Mogujia active'),
    (25, 5841, 1, 0, 1, 28, 0, 32190, 0, 0, 0, 0, 0, '', 'Horde Mogujia - To Mogujia complete'),
    (25, 5841, 1, 0, 2,  8, 0, 32190, 0, 0, 0, 0, 0, '', 'Horde Mogujia - To Mogujia rewarded'),
    (25, 5841, 2, 0, 0,  9, 0, 32193, 0, 0, 0, 0, 0, '', 'Alliance Mogujia - To Mogujia active'),
    (25, 5841, 2, 0, 1, 28, 0, 32193, 0, 0, 0, 0, 0, '', 'Alliance Mogujia - To Mogujia complete'),
    (25, 5841, 2, 0, 2,  8, 0, 32193, 0, 0, 0, 0, 0, '', 'Alliance Mogujia - To Mogujia rewarded');

UPDATE creature
SET phaseMask = 1073741824
WHERE map = 870 AND areaId = 6114
  AND id IN
  (67574, 67580, 67581, 67582, 67584, 67585, 67593, 67597,
   67600, 67603, 67604);

UPDATE creature
SET phaseMask = 536870912
WHERE map = 870 AND areaId = 6114
  AND id IN
  (67682, 67684, 67716, 67724, 67734, 67780, 67781, 67790,
   67804, 67805, 67806);

COMMIT;
