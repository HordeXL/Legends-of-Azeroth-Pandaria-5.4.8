-- Disable two proven foreign/corrupted spell actions while preserving their
-- SmartAI rows and original parameters for provenance.
--
-- 223971 is not a spell in the local 5.4.8 client data (and is also used as a
-- local gameobject entry). The imported batch assigned it as "Hunter's Rush"
-- to many unrelated Isle of Giants creatures. Entry 70021 retains its valid
-- Skycall action (138817); only the invalid imported action becomes a no-op.
--
-- 215377 is likewise outside the local 5.4.8 spell data. The same import
-- labelled it "The Maw Must Feed" on unrelated Arnold Raygun, Gormali
-- Incinerator, and Scarlet Sentry entries, proving it is not a trustworthy
-- per-creature 5.4.8 action.

UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 223971,
    `comment` = 'Pterrorwing Skyscreamer - Disabled foreign Hunter''s Rush spell 223971 (not in 5.4.8)'
WHERE `entryorguid` = 70021
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 2
  AND `action_type` = 11
  AND `action_param1` = 223971;

UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 215377,
    `comment` = 'Arnold Raygun - Disabled foreign The Maw Must Feed spell 215377 (not in 5.4.8)'
WHERE `entryorguid` = 70034
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 0
  AND `action_type` = 11
  AND `action_param1` = 215377;
