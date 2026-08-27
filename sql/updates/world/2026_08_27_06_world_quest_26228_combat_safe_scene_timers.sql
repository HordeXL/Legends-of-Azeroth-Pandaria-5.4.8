-- Quest 26228 "Livin' the Life": the scene takes place among hostile mine
-- creatures. Run every timed action list in all states so incidental combat
-- cannot pause the dialogue before it grants quest credit.
UPDATE `smart_scripts`
SET `action_param3` = 2
WHERE `source_type` = 0
  AND `action_type` = 80
  AND (
        (`entryorguid` = 42500 AND `id` = 0 AND `action_param1` = 4250000)
     OR (`entryorguid` = 42515 AND `id` = 5 AND `action_param1` = 4251500)
     OR (`entryorguid` = 42515 AND `id` = 7 AND `action_param1` = 4251501)
     OR (`entryorguid` = 42492 AND `id` = 5 AND `action_param1` = 4249200)
  );
