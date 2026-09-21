ALTER TABLE `account_boost`
  ADD COLUMN `boost_level` TINYINT UNSIGNED NOT NULL DEFAULT 0
  COMMENT '0 = legacy promotion, 80/90 = DBC character boost tier'
  AFTER `counter`,
  ADD PRIMARY KEY (`id`, `realmid`);
