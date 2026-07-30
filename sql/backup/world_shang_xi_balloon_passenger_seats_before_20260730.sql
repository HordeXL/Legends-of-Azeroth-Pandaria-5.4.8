-- Exact rollback for
-- 2026_07_30_12_world_fix_shang_xi_balloon_passenger_seats.sql.
--
-- Restore only the two swapped rows after verifying their complete original
-- copies and the exact corrected active state.

START TRANSACTION;

SET @shang_xi_seat_backup_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`accessory_entry` = 56661
               AND `seat_id` = 1
               AND `minion` = 1
               AND `description` = 'Aysa'
               AND `summontype` = 8
               AND `summontimer` = 0) = 1
       AND SUM(`accessory_entry` = 56660
               AND `seat_id` = 2
               AND `minion` = 1
               AND `description` = 'Ji Firepaw'
               AND `summontype` = 8
               AND `summontimer` = 0) = 1
    FROM `_backup_vehicle_accessory_shang_xi_seats_20260730`
    WHERE `entry` = 55649
);

SET @shang_xi_new_seats_active :=
(
    SELECT COUNT(*) = 2
       AND SUM(`accessory_entry` = 56660 AND `seat_id` = 1) = 1
       AND SUM(`accessory_entry` = 56661 AND `seat_id` = 2) = 1
    FROM `vehicle_template_accessory`
    WHERE `entry` = 55649
      AND `accessory_entry` IN (56660, 56661)
);

UPDATE `vehicle_template_accessory`
SET `seat_id` = -128
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_new_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56661
  AND `seat_id` = 2
  AND `minion` = 1
  AND `description` = 'Aysa'
  AND `summontype` = 8
  AND `summontimer` = 0;

UPDATE `vehicle_template_accessory`
SET `seat_id` = 2
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_new_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56660
  AND `seat_id` = 1
  AND `minion` = 1
  AND `description` = 'Ji Firepaw'
  AND `summontype` = 8
  AND `summontimer` = 0;

UPDATE `vehicle_template_accessory`
SET `seat_id` = 1
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_new_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56661
  AND `seat_id` = -128
  AND `minion` = 1
  AND `description` = 'Aysa'
  AND `summontype` = 8
  AND `summontimer` = 0;

COMMIT;
