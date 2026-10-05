-- Farmhand Freedom (30571): slaves are rescued by killing their overseer.
-- Keep incidental player AoE and nearby hostile NPCs from killing them first.
UPDATE creature_template
SET faction = 35,
    unit_flags = unit_flags | 256 | 512
WHERE entry = 59577;
