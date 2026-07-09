-- Fix selected SmartAI references to spell ids that do not exist in the local 5.4.8 Spell.dbc.
-- Only rows with a clear local replacement are changed here.

-- Defias Reaper / Defias Watcher: invalid duplicate Cleave spell 90981 -> valid Cleave 90980.
UPDATE `smart_scripts`
SET `action_param1`=90980
WHERE `entryorguid` IN (47403, 47404) AND `source_type`=0 AND `id`=2
  AND `action_type`=11 AND `action_param1`=90981;

-- Defias Reaper / Defias Watcher: invalid Watch spell 90982 -> valid Watch 90099.
UPDATE `smart_scripts`
SET `action_param1`=90099
WHERE `entryorguid` IN (47403, 47404) AND `source_type`=0 AND `id`=4
  AND `action_type`=11 AND `action_param1`=90982;

-- Mining Monkey: invalid duplicate Throw spell 91039 -> valid Throw 91038.
UPDATE `smart_scripts`
SET `action_param1`=91038
WHERE `entryorguid`=48278 AND `source_type`=0 AND `id` IN (14, 15)
  AND `action_type`=11 AND `action_param1`=91039;

-- Defias Blood Wizard: invalid Bloodwash spell 90947 -> valid Bloodwash 90946.
UPDATE `smart_scripts`
SET `event_param1`=90946,
    `action_param1`=90946
WHERE `entryorguid`=48417 AND `source_type`=0 AND `id`=14
  AND `event_type`=16 AND `event_param1`=90947
  AND `action_type`=11 AND `action_param1`=90947;

-- Defias Envoker / Defias Miner: invalid Renegade Strength variants -> valid Renegade Strength 91009.
UPDATE `smart_scripts`
SET `action_param1`=91009
WHERE `entryorguid`=48418 AND `source_type`=0 AND `id`=14
  AND `action_type`=11 AND `action_param1`=91006;

UPDATE `smart_scripts`
SET `action_param1`=91009
WHERE `entryorguid`=48419 AND `source_type`=0 AND `id`=1
  AND `action_type`=11 AND `action_param1`=91010;

-- Druid of the Flame: duplicate hit event used removed spell id 100101.
-- Keep the existing valid Kneel to the Flame! spell id used by the adjacent row.
UPDATE `smart_scripts`
SET `event_param1`=99705
WHERE `entryorguid`=53619 AND `source_type`=0 AND `id`=10
  AND `event_type`=31 AND `event_param1`=100101;
