-- Horde Siege Tank: allow crossing subarea boundaries within Borean Tundra.
-- VehicleAI periodically ejects passengers failing source 16 conditions.
UPDATE conditions
SET ConditionTypeOrReference = 4, ConditionValue1 = 3537,
    Comment = 'Horde Siege Tank - Keep passengers within Borean Tundra, allow subarea crossings'
WHERE SourceTypeOrReferenceId = 16 AND SourceGroup = 0 AND SourceEntry = 25334
  AND SourceId = 0 AND ConditionTypeOrReference = 23 AND ConditionValue1 = 4027
  AND NegativeCondition = 0;
