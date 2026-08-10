-- Roll back the Solo Arena equipment journal schema only when no recovery
-- rows remain. A nonempty table means original item instances still require
-- restoration and must never be dropped automatically.

SET @solo_arena_loadout_table_exists := (
  SELECT COUNT(*)
  FROM `information_schema`.`TABLES`
  WHERE `TABLE_SCHEMA` = DATABASE()
    AND `TABLE_NAME` = 'solo_arena_loadout_backup'
);
SET @solo_arena_loadout_count_sql := IF(
  @solo_arena_loadout_table_exists = 1,
  'SELECT COUNT(*) INTO @solo_arena_loadout_rows FROM `solo_arena_loadout_backup`',
  'SET @solo_arena_loadout_rows := 0'
);
PREPARE solo_arena_loadout_count_stmt FROM @solo_arena_loadout_count_sql;
EXECUTE solo_arena_loadout_count_stmt;
DEALLOCATE PREPARE solo_arena_loadout_count_stmt;

SET @solo_arena_loadout_rollback := CASE
  WHEN @solo_arena_loadout_table_exists = 0 THEN
    'SELECT ''NO ACTION: solo_arena_loadout_backup does not exist'' AS rollback_status'
  WHEN @solo_arena_loadout_rows = 0 THEN
    'DROP TABLE `solo_arena_loadout_backup`'
  ELSE
    'SELECT ''REFUSED: solo_arena_loadout_backup still contains recovery rows'' AS rollback_status'
END;
PREPARE solo_arena_loadout_stmt FROM @solo_arena_loadout_rollback;
EXECUTE solo_arena_loadout_stmt;
DEALLOCATE PREPARE solo_arena_loadout_stmt;
