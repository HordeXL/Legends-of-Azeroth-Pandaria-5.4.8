-- Small verified batch for startup SmartAI duplicate spell-effect warnings.
-- Do not delete SmartAI rows: keep links/parameters in place and no-op only the redundant action.

-- Blackrock Soldier: spell 89568 already grants kill credit 48195.
UPDATE `smart_scripts`
SET `action_type` = 0,
    `comment` = CONCAT(`comment`, ' - Disabled duplicate kill credit; spell 89568 already grants credit 48195')
WHERE `entryorguid` IN (48119, 48121)
  AND `source_type` = 0
  AND `id` = 1
  AND `action_type` = 33
  AND `action_param1` = 48195;

-- Master Shang Xi: spell 109335 already summons creature 57874.
UPDATE `smart_scripts`
SET `action_type` = 0,
    `comment` = CONCAT(`comment`, ' - Disabled duplicate summon; spell 109335 already summons creature 57874')
WHERE `entryorguid` = 56686
  AND `source_type` = 0
  AND `id` = 8
  AND `action_type` = 12
  AND `action_param1` = 57874;
