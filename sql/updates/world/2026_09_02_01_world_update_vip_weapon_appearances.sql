-- Give the VIP1-VIP3 weapon tiers distinct legendary/scythe appearances.
-- Only display IDs are changed; stats, sockets, item class and equip rules stay intact.
--
-- Source appearances:
--   32837 Warglaive of Azzinoth (main hand)  display 45479
--   32838 Warglaive of Azzinoth (off hand)   display 45481
--   95426 Frostscythe of Lord Ahune          display 48878
--   34334 Thori'dal, the Stars' Fury         display 48902
--   96525 Voice of the Quilen                display 119947

UPDATE `item_template`
   SET `displayid` = 45479
 WHERE `entry` IN (990017, 990117, 990217);

UPDATE `item_template`
   SET `displayid` = 45481
 WHERE `entry` IN (990024, 990124, 990224);

UPDATE `item_template`
   SET `displayid` = 48878
 WHERE `entry` IN (990025, 990125, 990225);

UPDATE `item_template`
   SET `displayid` = 48902
 WHERE `entry` IN (990029, 990129, 990229);

UPDATE `item_template`
   SET `displayid` = 119947
 WHERE `entry` IN (990030, 990130, 990230);

SELECT `entry`, `name`, `displayid`
  FROM `item_template`
 WHERE `entry` IN
       (990017, 990024, 990025, 990029, 990030,
        990117, 990124, 990125, 990129, 990130,
        990217, 990224, 990225, 990229, 990230)
 ORDER BY `entry`;
