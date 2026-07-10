-- Numeric strings are import artifacts, not registered script names.
UPDATE `conditions`
SET `ScriptName`=''
WHERE `ScriptName`='0'
  AND (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`) IN
  (
    (17,0,52410,0,0),
    (17,0,52418,0,0),
    (17,0,117866,0,0),
    (17,0,126845,0,0),
    (17,0,139603,0,0)
  );

UPDATE `gameobject`
SET `ScriptName`=''
WHERE `guid`=20936 AND `id`=200004 AND `ScriptName`='1';
