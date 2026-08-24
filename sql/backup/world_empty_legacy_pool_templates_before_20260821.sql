-- Exact preservation copy made before 2026-08-21 startup-log fix 14.

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`) VALUES
(155,1,''),(175,1,''),(192,1,''),(193,1,''),(195,1,''),
(329,1,'NPC=14887'),(330,1,'NPC=6109'),(331,1,'NPC=14889'),
(1134,1,''),(1137,1,''),(1138,1,''),(1139,1,''),(1140,1,''),(1141,1,''),(1142,1,''),(1143,1,''),
(1240,1,''),(9868,1,'Minigob Manabonk (32838)'),
(14139,20,'GO=182355'),(14140,12,'GO=191568')
ON DUPLICATE KEY UPDATE
`max_limit`=VALUES(`max_limit`),`description`=VALUES(`description`);
