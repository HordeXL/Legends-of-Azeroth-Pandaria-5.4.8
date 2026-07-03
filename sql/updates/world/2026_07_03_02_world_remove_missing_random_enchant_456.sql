-- Random enchantment template 456 is referenced by a few items, but this DB
-- does not provide matching item_enchantment_template rows for it.
UPDATE `item_template`
SET `RandomProperty` = 0
WHERE `RandomProperty` = 456;

UPDATE `item_template`
SET `RandomSuffix` = 0
WHERE `RandomSuffix` = 456;
