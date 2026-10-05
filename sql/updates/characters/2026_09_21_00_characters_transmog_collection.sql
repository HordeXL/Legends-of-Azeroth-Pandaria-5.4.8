-- Permanent account collection. Never delete entries when source items go away.
CREATE TABLE IF NOT EXISTS account_transmog_appearances (
    accountId INT UNSIGNED NOT NULL,
    itemEntry MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (accountId, itemEntry)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
