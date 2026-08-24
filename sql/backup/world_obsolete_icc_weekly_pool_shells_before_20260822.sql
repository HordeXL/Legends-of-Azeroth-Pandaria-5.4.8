-- Exact backup of the six obsolete ICC weekly quest pool shells.
-- These quests were removed by Blizzard in patch 4.0.3a and must not be
-- activated on a 5.4.8 realm.  This backup preserves only the stale pool
-- metadata that remained in the project base; no pool_quest rows existed.
INSERT IGNORE INTO `pool_template` (`entry`,`max_limit`,`description`) VALUES
(517,1,'ICC weeklies'),
(518,2,'Blood Quickening'),
(519,2,'Deprogramming'),
(520,2,'Residue Rendezvous'),
(521,2,'Respite for a Tormented Soul'),
(522,4,'Securing the Ramparts');

INSERT IGNORE INTO `pool_pool` (`pool_id`,`mother_pool`,`chance`,`description`) VALUES
(518,517,0,'Blood Quickening'),
(519,517,0,'Deprogramming'),
(520,517,0,'Residue Rendezvous'),
(521,517,0,'Respite for a Tormented Soul'),
(522,517,0,'Securing the Ramparts');
