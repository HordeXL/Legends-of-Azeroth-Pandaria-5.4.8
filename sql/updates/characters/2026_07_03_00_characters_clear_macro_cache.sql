-- Clear server-side macro cache that can keep broken client macro UI state alive
-- even after deleting local Cache/WTF folders.
DELETE FROM `account_data` WHERE `type` IN (4, 5);
DELETE FROM `character_account_data` WHERE `type` IN (4, 5);
