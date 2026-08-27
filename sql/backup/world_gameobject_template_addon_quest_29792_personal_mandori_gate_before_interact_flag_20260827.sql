-- Exact rollback for
-- 2026_08_27_03_world_quest_29792_personal_mandori_gate_interact_flag.sql.

UPDATE `gameobject_template_addon`
SET `flags` = 0
WHERE `entry` = 211294
  AND `flags` = 4;
