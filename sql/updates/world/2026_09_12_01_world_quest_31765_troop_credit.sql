-- Quest 31765 "Paint it Red!" (血染滩头!) - count the whole Thunder Hold camp
-- toward the "击败雷霆要塞部队" (troops) objective, not just the Soldier (66200).
--
-- KillCredit2 = 66200 on the ten camp variants, so any kill credits the troops
-- objective (66200) additively via KillRewarder::RewardKillCredit ->
-- Player::KilledMonster (own entry + KillCredit1 + KillCredit2).
-- KillCredit2 is used because 66286/66287/66348/66395 already carry
-- KillCredit1 = 66285 (Infantryman) for quest 31767 - that row must stay so
-- killing them keeps counting toward "击杀雷霆要塞步兵" (66285 x15).
-- Barrage HITS (not only kills) credit through spell_gunship_turret_barrage,
-- which was extended to treat these entries as troops (zone_the_jade_forest.cpp).
--
-- Entries (from the camp spawn table, see 2026_09_12_00 migration comments):
--   66284 Laborer          66285 Infantryman (q31767)   66286 Mender
--   66287 Lieutenant       66348 Armsman                66395 Cannoneer
--   66647 Sharp-Shooter    66649 Mender                 66650 Infantryman
--   66651 Laborer

UPDATE `creature_template`
   SET `KillCredit2` = 66200
 WHERE `entry` IN (66284, 66285, 66286, 66287, 66348, 66395, 66647, 66649, 66650, 66651);
