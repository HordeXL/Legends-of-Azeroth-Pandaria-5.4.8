-- Kypari Zar: bind the Sonar Tower and the quest's summoned Korven.
-- Existing static Korven quest givers and other quests are unaffected.
START TRANSACTION;
UPDATE gameobject_template SET ScriptName = 'go_kypari_zar_sonar_tower' WHERE entry = 212933;
UPDATE creature_template SET AIName = '', ScriptName = 'npc_korven_kypari_zar',
    name = 'Korven the Prime' WHERE entry = 63328;
COMMIT;
