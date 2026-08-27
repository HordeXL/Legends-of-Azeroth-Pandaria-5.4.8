-- Quest 29792 "Bidden to Greatness": the personal Mandori gate is opened by
-- SmartAI and must not offer manual player interaction. Match the working
-- personal Pei-Wu gate (211298), which uses GO_FLAG_INTERACT_COND (0x04).

UPDATE `gameobject_template_addon`
SET `flags` = 4
WHERE `entry` = 211294
  AND `flags` = 0;
