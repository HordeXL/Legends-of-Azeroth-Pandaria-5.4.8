-- Fix two remaining SmartAI missing-spell rows with clear local evidence.

-- Fenrick Barlowe: the row comment and old local SAI source show this should summon Enraged Felbat (9521),
-- not cast spell 14252. TempSummonType 4 and 30000 ms duration match the old local SAI source.
UPDATE `smart_scripts`
SET `action_type`=12,
    `action_param1`=9521,
    `action_param2`=4,
    `action_param3`=30000
WHERE `entryorguid`=27842 AND `source_type`=0 AND `id`=2
  AND `event_type`=4 AND `action_type`=11 AND `action_param1`=14252;

-- Ancestral Spirit Wolf: action comment says Self Snare; local 5.4.8 Spell.dbc has Self Snare as 58606.
UPDATE `smart_scripts`
SET `action_param1`=58606
WHERE `entryorguid`=1707700 AND `source_type`=9 AND `id`=2
  AND `action_type`=11 AND `action_param1`=30011;
