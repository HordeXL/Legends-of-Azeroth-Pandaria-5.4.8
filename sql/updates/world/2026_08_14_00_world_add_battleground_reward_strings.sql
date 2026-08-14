-- Missing strings used by Player::AddTotalBGCount for the enabled periodic
-- battleground reward mails. INSERT IGNORE preserves any existing/localized
-- server text and makes this update safe to run more than once.
INSERT IGNORE INTO `trinity_string` (`entry`, `content_default`) VALUES
(12528, 'Battleground participation reward'),
(12529, 'Special battleground reward'),
(12530, 'Battlegrounds completed: %u\nBattlegrounds won: %u');
