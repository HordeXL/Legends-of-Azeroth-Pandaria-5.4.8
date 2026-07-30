-- Fix the swapped Ji Firepaw and Aysa Cloudsinger passenger seats on
-- Shang Xi's Hot Air Balloon (entry 55649).
--
-- Exact local evidence:
--   * npc_shang_xi_air_balloon calls Ji's text groups 0-6 from seat 1;
--   * it calls Aysa's text groups 0-10 from seat 2;
--   * creature_text 56660 (Ji) has the complete groups 0-6;
--   * creature_text 56661 (Aysa) has the complete groups 0-10;
--   * the inherited accessory rows put Aysa 56661 in seat 1 and Ji 56660
--     in seat 2, causing CreatureTextMgr to request Ji groups 7-10.
--
-- Preserve every accessory and text row. Change only the two seat ids.

CREATE TABLE IF NOT EXISTS
    `_backup_vehicle_accessory_shang_xi_seats_20260730`
LIKE `vehicle_template_accessory`;

INSERT INTO `_backup_vehicle_accessory_shang_xi_seats_20260730`
SELECT `accessory`.*
FROM `vehicle_template_accessory` AS `accessory`
WHERE `accessory`.`entry` = 55649
  AND
      ((`accessory`.`accessory_entry` = 56661
        AND `accessory`.`seat_id` = 1
        AND `accessory`.`minion` = 1
        AND `accessory`.`description` = 'Aysa'
        AND `accessory`.`summontype` = 8
        AND `accessory`.`summontimer` = 0)
       OR
       (`accessory`.`accessory_entry` = 56660
        AND `accessory`.`seat_id` = 2
        AND `accessory`.`minion` = 1
        AND `accessory`.`description` = 'Ji Firepaw'
        AND `accessory`.`summontype` = 8
        AND `accessory`.`summontimer` = 0))
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_vehicle_accessory_shang_xi_seats_20260730` AS `backup`
       WHERE `backup`.`entry` = `accessory`.`entry`
         AND `backup`.`seat_id` = `accessory`.`seat_id`);

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

SET @shang_xi_old_seats_active :=
(
    SELECT COUNT(*) = 2
       AND SUM(`accessory_entry` = 56661 AND `seat_id` = 1) = 1
       AND SUM(`accessory_entry` = 56660 AND `seat_id` = 2) = 1
    FROM `vehicle_template_accessory`
    WHERE `entry` = 55649
      AND `accessory_entry` IN (56660, 56661)
);

-- The primary key is (entry, seat_id), so use one temporary signed tinyint
-- value while swapping the two occupied seats.
UPDATE `vehicle_template_accessory`
SET `seat_id` = -128
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_old_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56660
  AND `seat_id` = 2
  AND `minion` = 1
  AND `description` = 'Ji Firepaw'
  AND `summontype` = 8
  AND `summontimer` = 0;

UPDATE `vehicle_template_accessory`
SET `seat_id` = 2
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_old_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56661
  AND `seat_id` = 1
  AND `minion` = 1
  AND `description` = 'Aysa'
  AND `summontype` = 8
  AND `summontimer` = 0;

UPDATE `vehicle_template_accessory`
SET `seat_id` = 1
WHERE @shang_xi_seat_backup_ok = 1
  AND @shang_xi_old_seats_active = 1
  AND `entry` = 55649
  AND `accessory_entry` = 56660
  AND `seat_id` = -128
  AND `minion` = 1
  AND `description` = 'Ji Firepaw'
  AND `summontype` = 8
  AND `summontimer` = 0;

COMMIT;
