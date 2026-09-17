-- Gate of the Setting Sun: spell 115441 summons this short-lived cave-in
-- while the first gate is breached. The template was missing from the base DB.
-- Display 2230 is the client model WORLD\GOOBER\G_CAVEIN.MDX and matches the
-- neighbouring MoP rock template (211305).
INSERT IGNORE INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `size`, `data1`, `data6`, `VerifiedBuild`)
VALUES
    (211302, 5, 2230, 'Cave In', 1, 0, 0, 18414);
