-- Down Kitty! (29717) is normally offered by An Windfur while she follows the
-- player toward Forest Heart.  That follower event is absent, leaving only a
-- static questgiver on the road.  Also expose the quest on her Dawn's Blossom
-- version so the chain remains discoverable and playable.
INSERT IGNORE INTO `creature_queststarter` (`id`, `quest`)
VALUES (55234, 29717);
