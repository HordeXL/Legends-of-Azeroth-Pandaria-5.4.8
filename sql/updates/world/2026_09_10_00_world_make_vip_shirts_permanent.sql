-- The VIP shirts were cloned from a temporary shirt and retained its
-- three-hour lifetime.  Once that played-time countdown reached zero the
-- core correctly expired and destroyed the paid/custom item.

UPDATE `item_template`
   SET `Duration` = 0
 WHERE `entry` IN (990003, 990103, 990203)
   AND `Duration` <> 0;

-- Expected: every VIP shirt is permanent.
SELECT COUNT(*) AS `temporary_vip_shirts`
  FROM `item_template`
 WHERE `entry` IN (990003, 990103, 990203)
   AND `Duration` <> 0;
