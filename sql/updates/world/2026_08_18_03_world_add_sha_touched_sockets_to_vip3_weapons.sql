-- Allow the existing MoP legendary gems to be inserted into VIP3 weapons:
--   89873 Crystallized Dread  (Agility)
--   89881 Crystallized Terror (Strength)
--   89882 Crystallized Horror (Intellect)
--
-- MoP 5.4.8 source evidence: genuine Sha-Touched weapons such as entries
-- 86226, 86227, 86321, 86328, 86331, 86335, 86386, 86387 and 86391 use
-- socketColor_1=16. The three gems use GemProperties 2400-2402 and the
-- shared ItemLimitCategory 207.
--
-- Only real weapon-class items are changed. VIP3 shield 990222 and caster
-- off-hand 990223 deliberately remain unchanged because they are armor-class
-- off-hands, not Sha-Touched weapons.

UPDATE `item_template`
   SET `socketColor_1` = 16,
       `socketContent_1` = 0
 WHERE `entry` IN
       (990217,990218,990219,990220,990221,990224,990225,
        990226,990227,990228,990229,990230,990231)
   AND `class` = 2
   AND `socketColor_1` = 0
   AND `socketContent_1` = 0;

-- Expected: 13 VIP3 weapons with one empty Sha-Touched socket.
SELECT COUNT(*) AS `vip3_sha_touched_weapons`
  FROM `item_template`
 WHERE `entry` IN
       (990217,990218,990219,990220,990221,990224,990225,
        990226,990227,990228,990229,990230,990231)
   AND `class` = 2
   AND `socketColor_1` = 16
   AND `socketContent_1` = 0;

-- Expected: shield and caster off-hand still have no Sha-Touched socket.
SELECT COUNT(*) AS `vip3_nonweapon_sha_touched_sockets`
  FROM `item_template`
 WHERE `entry` IN (990222,990223)
   AND `socketColor_1` = 16;
