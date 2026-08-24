-- Exact backup before final legacy resource child-pool cleanup batch 13.
INSERT IGNORE INTO `pool_template` (`entry`,`max_limit`,`description`) VALUES
(2871,1,'GO 181555,181557 map=530'),
(2872,1,'GO 181555,181557 map=530'),
(2873,1,'GO 181555,181557 map=530'),
(2874,1,'GO 181555,181557 map=530'),
(2876,1,'GO 181555,181557 map=530'),
(2877,1,'GO 181555,181557 map=530'),
(2879,1,'GO 181555,181557 map=530'),
(2880,1,'GO 181555,181557 map=530'),
(2881,1,'GO 181555,181557 map=530');
INSERT IGNORE INTO `pool_pool` (`pool_id`,`mother_pool`,`chance`,`description`) VALUES
(2871,5245,0,''),
(2872,5245,0,''),
(2873,5245,0,''),
(2874,5244,0,''),
(2876,5244,0,''),
(2877,5244,0,''),
(2879,5243,0,''),
(2880,5243,0,''),
(2881,5243,0,'');

