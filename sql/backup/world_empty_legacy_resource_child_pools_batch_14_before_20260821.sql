-- Exact backup before cleanup of three final empty resource child pools.
INSERT IGNORE INTO `pool_template` (`entry`,`max_limit`,`description`) VALUES
(7154,1,'GO 1735,[1733,1734,1732],map=1'),
(7713,1,'GO 1735,[1733,1734,1732],map=1'),
(8808,1,'GO 175404,[2047,2040],map=530');
INSERT IGNORE INTO `pool_pool` (`pool_id`,`mother_pool`,`chance`,`description`) VALUES
(7154,209379,0,''),
(7713,209519,0,''),
(8808,9792,0,'');

