-- Horn of the Ancient Mariner (45703) requires spell focus 1493 within 10 yards.
-- The jetty focus must also be visible in the Kvaldir mist phase (2).
UPDATE gameobject SET phaseMask = phaseMask | 3
WHERE id = 187706 AND map = 571;
