-- Track leader identification as one visit to the original area trigger 4963.
-- Matching PlayerScript supplies credit for drivers without a client trigger event.
UPDATE quest_objective SET objectId=4963, amount=1,
 description='Scourge leader identified'
WHERE questId=11652 AND id=262375 AND type=10;
