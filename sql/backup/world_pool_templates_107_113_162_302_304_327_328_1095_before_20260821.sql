-- Exact template state before 2026-08-21 startup-log fix 12.
-- The corresponding member tables contained no rows for these eight pools.

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`) VALUES
(107,1,''),(113,1,''),(162,1,''),(302,1,''),
(304,1,'Infinite Corruptor'),(327,1,'NPC=14890'),(328,1,'NPC=14888'),
(1095,40,'GO=180248')
ON DUPLICATE KEY UPDATE
`max_limit`=VALUES(`max_limit`),`description`=VALUES(`description`);
