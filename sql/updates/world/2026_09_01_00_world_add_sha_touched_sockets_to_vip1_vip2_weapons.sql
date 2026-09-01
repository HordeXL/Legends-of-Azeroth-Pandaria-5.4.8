-- Give VIP1 and VIP2 real weapon-class items the same genuine MoP
-- Sha-Touched socket already used by the corresponding VIP3 weapons.
-- The socket accepts:
--   89873 Crystallized Dread  (Agility)
--   89881 Crystallized Terror (Strength)
--   89882 Crystallized Horror (Intellect)
--
-- Shields and caster off-hands remain unchanged because they are armor-class
-- off-hands, matching the existing VIP3 behavior.

UPDATE `item_template`
   SET `socketColor_1` = 16,
       `socketContent_1` = 0
 WHERE `entry` IN
       (990017,990018,990019,990020,990021,990024,990025,
        990026,990027,990028,990029,990030,990031,
        990117,990118,990119,990120,990121,990124,990125,
        990126,990127,990128,990129,990130,990131)
   AND `class` = 2
   AND `socketColor_1` = 0
   AND `socketContent_1` = 0;

-- Expected: 13 Sha-Touched weapons at each VIP rank.
SELECT
    SUM(`entry` BETWEEN 990017 AND 990031) AS `vip1_sha_touched_weapons`,
    SUM(`entry` BETWEEN 990117 AND 990131) AS `vip2_sha_touched_weapons`
  FROM `item_template`
 WHERE ((`entry` BETWEEN 990017 AND 990031)
     OR (`entry` BETWEEN 990117 AND 990131))
   AND `class` = 2
   AND `socketColor_1` = 16
   AND `socketContent_1` = 0;

-- Expected: zero; shields and caster off-hands receive no Sha-Touched socket.
SELECT COUNT(*) AS `vip1_vip2_nonweapon_sha_touched_sockets`
  FROM `item_template`
 WHERE `entry` IN (990022,990023,990122,990123)
   AND `socketColor_1` = 16;
