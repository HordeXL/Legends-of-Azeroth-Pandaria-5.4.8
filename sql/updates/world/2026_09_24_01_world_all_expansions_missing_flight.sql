-- Restore missing flight movement across all expansions, including summoned NPCs.
-- Source: world_548_20240722.sql, creature_template.InhabitType.
-- Uses the bitmask conversion from 2024_07_24_00_world.sql:
-- Ground = bit 1, Swim = bit 2, Flight = 1 (air only) or 2 (ground + air),
-- Rooted = bit 8. INSERT IGNORE preserves every existing movement record.
-- The Pandaria outdoor restoration is handled by the preceding update.
-- Reload creature templates and respawn affected creatures, or restart worldserver.
INSERT IGNORE INTO `creature_template_movement`
    (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`)
VALUES
    (154, 1, 0, 2, 0), -- Greater Fleshripper
    (199, 1, 0, 2, 0), -- Young Fleshripper
    (1109, 1, 0, 2, 0), -- Fleshripper
    (1513, 0, 0, 1, 0), -- Mangy Duskbat
    (1553, 0, 0, 1, 0), -- Greater Duskbat
    (1809, 1, 0, 2, 0), -- Carrion Vulture
    (1862, 0, 0, 1, 0), -- Lesser Netherwalker
    (1997, 1, 0, 2, 0), -- Strigid Hunter
    (2578, 1, 0, 2, 0), -- Young Mesa Buzzard
    (2579, 1, 0, 2, 0), -- Mesa Buzzard
    (2726, 1, 0, 2, 0), -- Scorched Guardian
    (2830, 1, 0, 2, 0), -- Parched Buzzard
    (2931, 1, 0, 2, 0), -- Zaricotl
    (4068, 1, 0, 2, 0), -- Serpent Messenger
    (4339, 1, 0, 2, 0), -- Brimgore
    (4346, 1, 0, 2, 0), -- Noxious Flayer
    (4347, 1, 0, 2, 0), -- Noxious Reaver
    (4348, 1, 0, 2, 0), -- Noxious Shredder
    (4957, 0, 0, 1, 0), -- Theramore Combat Dummy 4
    (5278, 0, 0, 1, 0), -- Sprite Darter
    (5300, 1, 0, 2, 0), -- Frayfeather Hippogryph
    (5304, 1, 0, 2, 0), -- Frayfeather Stagwing
    (5347, 1, 0, 2, 0), -- Antilus the Soarer
    (6013, 1, 0, 2, 0), -- Wayward Buzzard
    (6377, 1, 0, 2, 0), -- Thunderhead Stagwing
    (7047, 1, 0, 2, 0), -- Black Broodling
    (7186, 0, 0, 1, 0), -- A
    (7226, 0, 0, 1, 0), -- Sand Storm
    (7558, 0, 0, 1, 0), -- Cottontail Rabbit
    (7898, 0, 0, 1, 0), -- Pirate treasure trigger mob
    (8207, 1, 0, 2, 0), -- Emberwing
    (8600, 1, 0, 2, 0), -- Plaguebat
    (8601, 1, 0, 2, 0), -- Noxious Plaguebat
    (8602, 1, 0, 2, 0), -- Monstrous Plaguebat
    (9180, 0, 0, 1, 0), -- World Event Generator
    (9600, 1, 1, 2, 0), -- Parrot
    (11897, 0, 0, 1, 0), -- Duskwing
    (12434, 0, 0, 1, 0), -- Monster Generator (Blackwing)
    (13477, 0, 0, 1, 0), -- Noxxion Trigger
    (13620, 0, 0, 1, 0), -- Gizlock
    (13876, 0, 0, 1, 0), -- Mekgineer Trigger
    (13916, 0, 0, 1, 0), -- Dire Maul Crystal Totem
    (14026, 0, 0, 1, 0), -- Trigger Guse
    (14027, 0, 0, 1, 0), -- Trigger Mulverick
    (14028, 0, 0, 1, 0), -- Trigger Jeztor
    (14029, 0, 0, 1, 0), -- Trigger Ichman
    (14030, 0, 0, 1, 0), -- Trigger Slidore
    (14031, 0, 0, 1, 0), -- Trigger Vipore
    (14307, 0, 0, 1, 0), -- Black Drakonid Spawner
    (14309, 0, 0, 1, 0), -- Red Drakonid Spawner
    (14310, 0, 0, 1, 0), -- Green Drakonid Spawner
    (14311, 0, 0, 1, 0), -- Bronze Drakonid Spawner
    (14312, 0, 0, 1, 0), -- Blue Drakonid Spawner
    (14343, 1, 0, 2, 0), -- Olm the Wise
    (14366, 0, 0, 1, 0), -- Warpwood Spores
    (14391, 0, 0, 1, 0), -- Dire Maul Reaver Post
    (14443, 0, 0, 1, 0), -- Doomguard Tap Trigger
    (14459, 0, 0, 1, 0), -- Nefarian's Troops
    (14641, 0, 0, 1, 0), -- [PH] Horde spell thrower
    (14642, 0, 0, 1, 0), -- [PH] Alliance Spell thrower
    (14646, 0, 0, 1, 0), -- Stratholme Trigger
    (14667, 0, 0, 1, 0), -- Corrupted Totem
    (14668, 0, 0, 1, 0), -- Corrupted Infernal
    (14682, 0, 0, 1, 0), -- Sever
    (14758, 0, 0, 1, 0), -- Zul'Gurub Trigger
    (14989, 0, 0, 1, 0), -- Poisonous Cloud
    (14994, 0, 0, 1, 0), -- Zandalarian Event Generator
    (15091, 0, 0, 1, 0), -- Zul'Gurub Panther Trigger
    (15139, 0, 0, 1, 0), -- Gahz'ranka Herald
    (15164, 0, 0, 1, 0), -- Mulgore Trigger
    (15198, 0, 0, 1, 0), -- Blackwing
    (15224, 0, 0, 1, 0), -- Dream Fog
    (15362, 1, 1, 2, 0), -- Malfurion Stormrage
    (15425, 0, 0, 1, 0), -- Debug Point
    (15427, 0, 0, 1, 0), -- Merithra's Wake
    (15454, 0, 0, 1, 0), -- Anachronos Quest Trigger Invisible
    (15468, 0, 0, 1, 0), -- Sunstrider Mana Tap Counter
    (15649, 1, 0, 2, 0), -- Feral Dragonhawk Hatchling
    (15872, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (BLUE)
    (15873, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (RED)
    (15874, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (GREEN)
    (15875, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (PURPLE)
    (15876, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (WHITE)
    (15877, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (YELLOW)
    (15878, 0, 0, 1, 0), -- Warcaller Finster
    (15879, 0, 0, 1, 0), -- Pat's Firework Guy - BLUE
    (15880, 0, 0, 1, 0), -- Pat's Firework Guy - GREEN
    (15881, 0, 0, 1, 0), -- Pat's Firework Guy - PURPLE
    (15882, 0, 0, 1, 0), -- Pat's Firework Guy - RED
    (15883, 0, 0, 1, 0), -- Pat's Firework Guy - YELLOW
    (15884, 0, 0, 1, 0), -- Pat's Firework Guy - WHITE
    (15885, 0, 0, 1, 0), -- Pat's Firework Guy - BLUE BIG
    (15886, 0, 0, 1, 0), -- Pat's Firework Guy - GREEN BIG
    (15887, 0, 0, 1, 0), -- Pat's Firework Guy - PURPLE BIG
    (15888, 0, 0, 1, 0), -- Pat's Firework Guy - RED BIG
    (15889, 0, 0, 1, 0), -- Pat's Firework Guy - WHITE BIG
    (15890, 0, 0, 1, 0), -- Pat's Firework Guy - YELLOW BIG
    (15893, 0, 0, 1, 0), -- Lunar Firework Credit Marker
    (15894, 0, 0, 1, 0), -- Lunar Cluster Credit Marker
    (15911, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (BLUE BIG)
    (15912, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (GREEN BIG)
    (15913, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (PURPLE BIG)
    (15914, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (RED BIG)
    (15915, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (WHITE BIG)
    (15916, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (YELLOW BIG)
    (15918, 0, 0, 1, 0), -- Pat's Firework Cluster Guy (ELUNE)
    (15933, 0, 0, 1, 0), -- Poison Cloud
    (16006, 0, 0, 1, 0), -- InCombat Trigger
    (16044, 0, 0, 1, 0), -- Mor Grayhoof Trigger
    (16045, 0, 0, 1, 0), -- Isalien Trigger
    (16046, 0, 0, 1, 0), -- Jarien and Sothos Trigger
    (16047, 0, 0, 1, 0), -- Kormok Trigger
    (16048, 0, 0, 1, 0), -- Lord Valthalak Trigger
    (16079, 0, 0, 1, 0), -- Theldren Trigger
    (16082, 0, 0, 1, 0), -- Naxxramas Trigger
    (16084, 0, 0, 1, 0), -- picnic blanket
    (16086, 0, 0, 1, 0), -- Flower Shower
    (16092, 0, 0, 1, 0), -- Silithis Teleporter
    (16100, 0, 0, 1, 0), -- Ysida's Trigger
    (16182, 0, 0, 1, 0), -- Crystal Zapper
    (16214, 0, 0, 1, 0), -- Necropolis Controller
    (16306, 0, 0, 1, 0), -- Scourge Invasion Minion, spawner, Ghost/Ghoul
    (16336, 0, 0, 1, 0), -- Scourge Invasion Minion, spawner, Ghost/Skeleton
    (16338, 0, 0, 1, 0), -- Scourge Invasion Minion, spawner, Ghoul/Skeleton
    (16353, 1, 0, 2, 0), -- Mistbat
    (16354, 1, 0, 2, 0), -- Vampiric Mistbat
    (16356, 0, 0, 1, 0), -- Scourge Invasion Minion, finder
    (16401, 0, 0, 1, 0), -- Necropolis
    (16421, 0, 0, 1, 0), -- Necropolis health
    (16430, 0, 0, 1, 0), -- Ashbringer Trigger
    (16465, 0, 0, 1, 0), -- Raw Meat Rack Trigger
    (16466, 0, 0, 1, 0), -- Smoked Meat Rack Trigger
    (16467, 0, 0, 1, 0), -- Fresh Fish Rack Trigger
    (16520, 1, 0, 2, 0), -- Vale Moth
    (16604, 0, 0, 1, 0), -- Blackwing Spell Marker
    (16606, 0, 0, 1, 0), -- Midsummer Bonfire Despawner
    (16955, 0, 0, 1, 0), -- Chained Trickster
    (16956, 0, 0, 1, 0), -- Dust Hopper
    (16957, 0, 0, 1, 0), -- Nether Imp
    (17034, 1, 0, 2, 0), -- Female Kaliri Hatchling
    (17039, 1, 0, 2, 0), -- Male Kaliri Hatchling
    (17060, 1, 1, 2, 0), -- Hellfire Combat Dummy Small
    (17074, 0, 0, 1, 0), -- Cenarion Scout
    (17090, 0, 0, 1, 0), -- Silithus Dust Turnin Quest Doodad
    (17124, 0, 0, 1, 0), -- Captured Tarantula Trigger
    (17125, 0, 0, 1, 0), -- Captured Jaguar Trigger
    (17126, 0, 0, 1, 0), -- Captured Crocolisk Trigger
    (17128, 1, 0, 2, 0), -- Windroc
    (17129, 1, 0, 2, 0), -- Greater Windroc
    (17161, 0, 0, 1, 0), -- Blizzard (Shade of Aran)
    (17208, 0, 0, 1, 0), -- Chess Square, WHITE (DND)
    (17231, 0, 0, 1, 0), -- Garden Gas
    (17234, 0, 0, 1, 0), -- [Unused] Tunneler Visual
    (17239, 0, 0, 1, 0), -- [PH] Plaguelands Herald
    (17260, 0, 0, 1, 0), -- Nightbane Helper Target
    (17302, 0, 0, 1, 0), -- Hellfire Military Hard Mode Timer
    (17305, 0, 0, 1, 0), -- Chess Square, BLACK (DND)
    (17317, 0, 0, 1, 0), -- Chess Square, OUSIDE WHITE (DND)
    (17350, 1, 0, 2, 0), -- Royal Blue Flutterer
    (17407, 0, 0, 1, 0), -- Felmist
    (17413, 0, 0, 1, 0), -- Sedai Quest Credit Marker
    (17459, 0, 0, 1, 0), -- Chess Waiting Room (DND)
    (17473, 0, 0, 1, 0), -- Shadowmoon Summon Visual
    (17516, 0, 0, 1, 0), -- Magtheridon's Room
    (17529, 0, 0, 1, 0), -- [PH]Channel Target
    (17615, 0, 0, 1, 0), -- Azuremyst Elekk Mob Generator (Ravager)
    (17662, 0, 0, 1, 0), -- Broggok Poison Cloud
    (17665, 0, 0, 1, 0), -- Arcanagos Credit Marker
    (17677, 0, 0, 1, 0), -- Arcanagos Spell Dummy
    (17687, 0, 0, 1, 0), -- Flame Arrow
    (17689, 0, 0, 1, 0), -- <TXT>Crown Guard Capture Quest Doodad
    (17690, 0, 0, 1, 0), -- <TXT>Eastwall Capture Quest Doodad
    (17691, 0, 0, 1, 0), -- Eastwall Horde Capture Quest Doodad
    (17696, 0, 0, 1, 0), -- <TXT>Northpass Capture Quest Doodad
    (17697, 0, 0, 1, 0), -- Northpass Horde Capture Quest Doodad
    (17698, 0, 0, 1, 0), -- <TXT>Plaguewood Capture Quest Doodad
    (17699, 0, 0, 1, 0), -- Plaguewood Horde Capture Quest Doodad
    (17794, 0, 0, 1, 0), -- Alliance Tower Buffer
    (17795, 0, 0, 1, 0), -- Horde Tower Buffer
    (17838, 1, 1, 2, 0), -- Time Rift
    (17847, 0, 0, 1, 0), -- [PH]Ye Olde Channel Imp
    (17861, 0, 0, 1, 0), -- Waterpump Investigation Credit Marker
    (17868, 0, 0, 1, 0), -- Silithus Spice Worm Mortar Target
    (17869, 0, 0, 1, 0), -- Silithus Spice Sandworm Mortar Target
    (17949, 0, 0, 1, 0), -- Malfurion Stormrage
    (17973, 0, 0, 1, 0), -- Ysiel's Presence
    (17985, 0, 0, 1, 0), -- As the Crow Flies Credit Marker
    (17998, 0, 0, 1, 0), -- Umbrafen Steam Pump Credit Marker
    (17999, 0, 0, 1, 0), -- Lagoon Steam Pump Credit Marker
    (18000, 0, 0, 1, 0), -- Serpent Steam Pump Credit Marker
    (18002, 0, 0, 1, 0), -- Marshlight Steam Pump Credit Marker
    (18078, 0, 0, 1, 0), -- The Evil Rabbit
    (18095, 0, 0, 1, 0), -- Doomfire
    (18104, 0, 0, 1, 0), -- Doomfire Spirit
    (18155, 1, 0, 2, 0), -- Bloodfalcon
    (18156, 0, 0, 1, 0), -- Silvermoon City Target Dummy Left
    (18157, 0, 0, 1, 0), -- Silvermoon City Target Dummy Middle
    (18158, 0, 0, 1, 0), -- Silvermoon City Target Dummy Right
    (18161, 0, 0, 1, 0), -- Underground Well Credit Marker
    (18162, 0, 0, 1, 0), -- Underground Pond Credit Marker
    (18199, 0, 0, 1, 0), -- Silithus Dust Turnin Quest Doodad Horde
    (18220, 1, 0, 2, 0), -- Ravenous Windroc
    (18257, 1, 0, 2, 0), -- Gutripper
    (18304, 0, 0, 1, 0), -- Building
    (18306, 0, 0, 1, 0), -- Burning Blade Pyre (02)
    (18307, 0, 0, 1, 0), -- Burning Blade Pyre (03)
    (18342, 0, 0, 1, 0), -- Theatre Spotlight
    (18410, 0, 0, 1, 0), -- Hyjal Despawn Trigger Unit
    (18458, 0, 0, 1, 0), -- Veil Shalas Ward
    (18470, 1, 0, 2, 0), -- Bonelasher
    (18479, 0, 0, 1, 0), -- Vazruden Fire Trap
    (18491, 0, 0, 1, 0), -- Veil Shalas Totem
    (18551, 0, 0, 1, 0), -- Altruis Kill Credit
    (18553, 0, 0, 1, 0), -- Dark Portal Black Crystal Invisible Stalker
    (18555, 0, 0, 1, 0), -- Dark Portal Beam Invisible Stalker
    (18582, 0, 0, 1, 0), -- Dark Portal Emitter Invisible Stalker
    (18625, 0, 0, 1, 0), -- Dark Portal Dummy
    (18654, 0, 0, 1, 0), -- Crowd Murmur Helper
    (18707, 1, 0, 2, 0), -- Torgos
    (18757, 0, 0, 1, 0), -- Zangarmarsh PvP Beam (Red)
    (18838, 0, 0, 1, 0), -- Nightlord Malphas
    (18877, 1, 0, 2, 0), -- Nether Drake
    (18928, 0, 0, 1, 0), -- Astromancer Solarian Spotlight
    (18955, 0, 0, 1, 0), -- Camera Shaker - 30-90 seconds
    (18978, 0, 0, 1, 0), -- Heckling Fel Sprite
    (19028, 0, 0, 1, 0), -- The Overlook Capture Credit Marker
    (19029, 0, 0, 1, 0), -- The Stadium Capture Credit Marker
    (19032, 0, 0, 1, 0), -- Broken Hill Capture Credit Marker
    (19041, 0, 0, 1, 0), -- Jump-a-tron 4000
    (19179, 0, 0, 1, 0), -- Formation Marker
    (19198, 0, 0, 1, 0), -- Invisible Tractor Beam Source
    (19215, 0, 0, 1, 0), -- Infernal Relay (Hellfire)
    (19276, 0, 0, 1, 0), -- Legion Antenna: Spite
    (19277, 0, 0, 1, 0), -- Legion Antenna: Rage
    (19278, 0, 0, 1, 0), -- Legion Antenna: Hate
    (19279, 0, 0, 1, 0), -- Legion Antenna: Fear
    (19291, 0, 0, 1, 0), -- Legion Transporter: Alpha
    (19292, 0, 0, 1, 0), -- Legion Transporter: Beta
    (19326, 0, 0, 1, 0), -- Legion Antenna: Oblivion
    (19327, 0, 0, 1, 0), -- Spore Cloud
    (19328, 0, 0, 1, 0), -- Legion Antenna: Gehenna
    (19329, 0, 0, 1, 0), -- Legion Antenna: Mageddon
    (19358, 0, 0, 1, 0), -- Legion Transporter: Alpha (Alliance)
    (19359, 0, 0, 1, 0), -- Legion Transporter: Beta (Alliance)
    (19381, 0, 0, 1, 0), -- Flame Wave
    (19433, 0, 0, 1, 0), -- CoT Hillsbrad Despawn Trigger Unit
    (19482, 0, 0, 1, 0), -- Sagan
    (19523, 0, 0, 1, 0), -- O'mrogg's Left Head
    (19524, 0, 0, 1, 0), -- O'mrogg's Right Head
    (19525, 0, 0, 1, 0), -- Stage Spotlight
    (19563, 0, 0, 1, 0), -- Dimensius Quest Enabler
    (19577, 0, 0, 1, 0), -- Arcane Orb Target
    (19618, 0, 0, 1, 0), -- Warpmaster Lyssendra Credit
    (19619, 0, 0, 1, 0), -- Commander Dawnforge Credit
    (19620, 0, 0, 1, 0), -- Arcanist Ardonis Credit
    (19652, 0, 0, 1, 0), -- Disrupt the Communications Quest Credit Marker North
    (19654, 0, 0, 1, 0), -- Area 52 Analyzer Bunny
    (19680, 0, 0, 1, 0), -- Aldor Spawn Controller
    (19717, 0, 0, 1, 0), -- Disrupt the Communications Quest Credit Marker South
    (19723, 0, 0, 1, 0), -- Invis BE Ballista
    (19724, 0, 0, 1, 0), -- Invis BE Tent
    (19750, 0, 0, 1, 0), -- Chilled Ground
    (19759, 0, 0, 1, 0), -- Newly Crafted Infernal
    (19845, 0, 0, 1, 0), -- Area 52 Fireworks Controller
    (19870, 0, 0, 1, 0), -- Invis KV Shield Generator
    (19939, 0, 0, 1, 0), -- Netherstorm Nether Beast Target
    (20003, 0, 0, 1, 0), -- Blade's Edge Kneel Target 01
    (20023, 0, 0, 1, 0), -- Blade's Edge Kneel Target 02
    (20024, 0, 0, 1, 0), -- Blade's Edge Kneel Target 03
    (20038, 1, 0, 2, 0), -- Phoenix-Hawk Hatchling
    (20085, 0, 0, 1, 0), -- Infernal Invasion Hero Say Director
    (20086, 0, 0, 1, 0), -- Netherstorm Triangulation Point One Trigger
    (20093, 0, 0, 1, 0), -- Blade's Edge - Arakkoa Spell Origin
    (20114, 0, 0, 1, 0), -- Netherstorm Triangulation Point Two Trigger
    (20128, 0, 0, 1, 0), -- Netherstorm Triangulation Point Three Trigger
    (20160, 0, 0, 1, 0), -- Infernal Defender
    (20239, 0, 0, 1, 0), -- Neutralizing Emote Placeholder
    (20286, 0, 0, 1, 0), -- Illadari Point - Succubi Spell Orgin 001
    (20288, 0, 0, 1, 0), -- Illadari Point - Succubi Caster Position 01
    (20289, 0, 0, 1, 0), -- Illadari Point - Succubi Caster Position 02
    (20296, 0, 0, 1, 0), -- Teleporter Explosion Trigger
    (20333, 0, 0, 1, 0), -- Northern Pipe Credit Marker
    (20336, 0, 0, 1, 0), -- Eastern Pipe Credit Marker
    (20337, 0, 0, 1, 0), -- Southern Pipe Credit Marker
    (20338, 0, 0, 1, 0), -- Western Pipe Credit Marker
    (20391, 0, 0, 1, 0), -- Event Generator Old Hillsbrad
    (20462, 0, 0, 1, 0), -- Toxic Fumes
    (20472, 0, 0, 1, 0), -- Brown Rabbit
    (20473, 0, 0, 1, 0), -- Surveying Marker One
    (20475, 0, 0, 1, 0), -- Surveying Marker Two
    (20476, 0, 0, 1, 0), -- Surveying Marker Three
    (20502, 1, 0, 2, 0), -- Eclipsion Dragonhawk
    (20562, 0, 0, 1, 0), -- Invisible Stalker (Scale x5)
    (20602, 0, 0, 1, 0), -- Flame Patch (Al'ar)
    (20605, 0, 0, 1, 0), -- Dr. Boom
    (20608, 0, 0, 1, 0), -- Ya-six Spell Generator
    (20675, 0, 0, 1, 0), -- Legion Hold - Infernal Dummy
    (20725, 0, 0, 1, 0), -- Bat
    (20863, 0, 0, 1, 0), -- Pet Book DEM
    (20932, 1, 0, 2, 0), -- Nuramoc
    (20978, 0, 0, 1, 0), -- Wrath-Scryer's Felfire
    (21003, 0, 0, 1, 0), -- QA Test Dummy 73 Raid Debuff (High Armor)
    (21074, 0, 0, 1, 0), -- Living Grove Defender Trigger
    (21080, 0, 0, 1, 0), -- Dormant Infernal
    (21093, 0, 0, 1, 0), -- Dancing Sword
    (21095, 0, 0, 1, 0), -- Credit Marker: Water
    (21119, 0, 0, 1, 0), -- Doomsaw
    (21120, 0, 0, 1, 0), -- Doomsaw Target
    (21176, 0, 0, 1, 0), -- Bloodmaul Dire Wolf Trigger
    (21203, 0, 0, 1, 0), -- Blade's Edge - Rock Flayer Target
    (21234, 0, 0, 1, 0), -- Blade's Edge Invisible Stalker
    (21241, 0, 0, 1, 0), -- Bloodmaul Brutebane Stout Trigger
    (21281, 0, 0, 1, 0), -- Designer Island Gnome Spell Target
    (21288, 0, 0, 1, 0), -- (PH) Neophyte Combatant
    (21290, 0, 0, 1, 0), -- Arcane Explosion
    (21308, 0, 0, 1, 0), -- Cursed Scarab Summoner
    (21321, 0, 0, 1, 0), -- Vision Guide Kill Credit Trigger
    (21334, 0, 0, 1, 0), -- Veneratus Spawn Node
    (21347, 0, 0, 1, 0), -- Shadowmoon Valley Tuber Node
    (21351, 0, 0, 1, 0), -- Ogre Building Bunny Large
    (21360, 0, 0, 1, 0), -- Terokkar - Bone Wastes - Nether Orb Blue
    (21418, 0, 0, 1, 0), -- Invis Infernal Target
    (21422, 0, 0, 1, 0), -- Blade's Edge - Toshley's - Invisible Stalker - Atk Target
    (21447, 0, 0, 1, 0), -- Blade's Edge - Toshley's - Def Gun Attack Origin
    (21457, 0, 0, 1, 0), -- [Unused] Greater Crust Burster Visual
    (21473, 0, 0, 1, 0), -- Bone Wastes - Beam Target 01
    (21498, 0, 0, 1, 0), -- Ogre Building Cursed Spirit Bunny
    (21511, 0, 0, 1, 0), -- [DND]Kaliri Aura Dispel
    (21515, 1, 0, 2, 0), -- Trachela
    (21641, 0, 0, 1, 0), -- Lament of the Highborne Spell Bunny
    (21654, 0, 0, 1, 0), -- Skettis Followers Spawner
    (21713, 0, 0, 1, 0), -- [DND]Mok'Nathal Wand 1
    (21714, 0, 0, 1, 0), -- [DND]Mok'Nathal Wand 2
    (21715, 0, 0, 1, 0), -- [DND]Mok'Nathal Wand 3
    (21716, 0, 0, 1, 0), -- [DND]Mok'Nathal Wand 4
    (21756, 0, 0, 1, 0), -- Shadowmoon Mark of Kael
    (21791, 0, 0, 1, 0), -- Skettis Kneel Target 01
    (21792, 0, 0, 1, 0), -- Skettis Kneel Target 02
    (21793, 0, 0, 1, 0), -- Skettis Kneel Target 03
    (21794, 0, 0, 1, 0), -- Skettis Arakkoa Spell Origin 01
    (21796, 0, 0, 1, 0), -- Wyrm from Beyond
    (21800, 0, 0, 1, 0), -- Singing Ridge Summon Bunny
    (21804, 1, 0, 2, 0), -- Skettis Kaliri
    (21814, 0, 0, 1, 0), -- Nether Drake Egg Bunny
    (21819, 0, 0, 1, 0), -- Blade's Edge - Toshley's - Invisible Stalker - Def Gun Target
    (21851, 0, 0, 1, 0), -- The Voice of the Raven God
    (21855, 0, 0, 1, 0), -- Skettis Arakkoa Spell Origin 02
    (21856, 0, 0, 1, 0), -- Skettis Kneel Target 04
    (21880, 0, 0, 1, 0), -- Exploding Rune
    (21892, 0, 0, 1, 0), -- Azaloth Credit Marker
    (21901, 1, 1, 2, 0), -- Netherskate
    (21910, 0, 0, 1, 0), -- Ride the Lightning Kill Credit Trigger
    (21926, 0, 0, 1, 0), -- Multi-Spectrum Light Trap Bunny
    (21929, 0, 0, 1, 0), -- Trapping the Light Kill Credit Trigger
    (21946, 0, 0, 1, 0), -- Gnome Spirit Orb
    (21947, 0, 0, 1, 0), -- Collection of Souls Glow Trigger
    (21957, 0, 0, 1, 0), -- Terokkar Forest - Shadow Council Invisible Stalker
    (21967, 0, 0, 1, 0), -- Auchenai Death-Spirit
    (22008, 0, 0, 1, 0), -- Sky Marker
    (22021, 0, 0, 1, 0), -- O'Mally's Instrument Bunny
    (22057, 0, 0, 1, 0), -- Coilfang Raid Control Emote Stalker
    (22104, 0, 0, 1, 0), -- Cyclone (Karathress)
    (22111, 0, 0, 1, 0), -- Zeth'Gor Must Burn Bunny
    (22117, 0, 0, 1, 0), -- [DND]Whisper Spying Credit Marker 2
    (22118, 0, 0, 1, 0), -- [DND]Whisper Spying Credit Marker 3
    (22121, 0, 0, 1, 0), -- Felfire Summoner
    (22131, 0, 0, 1, 0), -- Netherwing Event Pinger
    (22203, 0, 0, 1, 0), -- Infernal
    (22224, 0, 0, 1, 0), -- Voice of Grillok
    (22228, 0, 0, 1, 0), -- Flame Wave II
    (22230, 0, 0, 1, 0), -- Shadowmoon Fel Orc Attack Trigger
    (22240, 0, 0, 1, 0), -- Leafbeard Flavor Event Channel Bunny
    (22246, 0, 0, 1, 0), -- Leafbeard Flavor Event Particle Bunny
    (22260, 0, 0, 1, 0), -- Magic Sucker Device Spawner
    (22265, 1, 0, 2, 0), -- Shadowwing Owl
    (22267, 0, 0, 1, 0), -- Magic Sucker Device Buttress
    (22269, 0, 0, 1, 0), -- Black Drake Corpse
    (22335, 0, 0, 1, 0), -- Mushrom Spell Effect
    (22337, 1, 0, 2, 0), -- Malevolent Hatchling
    (22349, 0, 0, 1, 0), -- [DND]Green Spot Grog Keg Relay
    (22356, 0, 0, 1, 0), -- [DND]Green Spot Grog Keg Credit
    (22366, 0, 0, 1, 0), -- Demoniac Visitation
    (22367, 0, 0, 1, 0), -- [DND]Ripe Moonshine Keg Credit
    (22368, 0, 0, 1, 0), -- [DND]Fermented Seed Beer Keg Credit
    (22383, 0, 0, 1, 0), -- [DND]Bloodmaul Chatter Credit
    (22422, 0, 0, 1, 0), -- Blade's Edge - Legion - Anger Camp - Invis Bunny
    (22428, 0, 0, 1, 0), -- Smoke Beacon Bunny
    (22434, 0, 0, 1, 0), -- [DND]Ogre Pike Planted Credit
    (22435, 0, 0, 1, 0), -- [DND]Rexxar's Wyvern Freed Credit
    (22441, 1, 0, 2, 0), -- Teribus the Cursed
    (22447, 0, 0, 1, 0), -- [DND]Sablemane's Trap Target
    (22449, 0, 0, 1, 0), -- Sha'tari Fire
    (22470, 0, 0, 1, 0), -- Death's Door Warp-Gate Controller
    (22471, 0, 0, 1, 0), -- Death's Door North Warp-Gate
    (22472, 0, 0, 1, 0), -- Death's Door South Warp-Gate
    (22503, 0, 0, 1, 0), -- Warp-Gate North Kill Bunny
    (22504, 0, 0, 1, 0), -- Warp-Gate South Kill Bunny
    (22507, 1, 1, 2, 0), -- Darkness Released
    (22519, 0, 0, 1, 0), -- Chess Piece: Karazhan Invisible Stalker
    (22520, 0, 0, 1, 0), -- Chess Piece: Status Bar
    (22521, 0, 0, 1, 0), -- Karazhan - Chess, Medivh CHEAT: Fury of Medivh Visual (DND)
    (22522, 0, 0, 1, 0), -- Unkillable Test Dummy 73 Warrior RAID SPECIAL
    (22523, 0, 0, 1, 0), -- Karazhan - Chess, Victory Dummy Tool
    (22524, 0, 0, 1, 0), -- Karazhan - Chess, Victory Controller
    (22833, 0, 0, 1, 0), -- Outland Children's Week Dark Portal Trigger
    (22867, 0, 0, 1, 0), -- Outland Children's Week Silvermoon 02 Trigger
    (22888, 0, 0, 1, 0), -- Vengeful Harbinger Event Starter
    (22903, 0, 0, 1, 0), -- Unkillable Test Dummy 72 Warrior
    (22912, 0, 0, 1, 0), -- Sundered Spirit
    (22925, 0, 0, 1, 0), -- Rain of Fire Bunny (Alliance)
    (22926, 0, 0, 1, 0), -- Poison Cloud Bunny (Horde)
    (22934, 0, 0, 1, 0), -- Black Temple Battle Sensor
    (22986, 0, 0, 1, 0), -- Skettis - Invis Raven Stone
    (23019, 0, 0, 1, 0), -- The Soulgrinder
    (23040, 0, 0, 1, 0), -- Vim'gol's Circle Bunny
    (23043, 0, 0, 1, 0), -- Invis Guardian Caster
    (23044, 0, 0, 1, 0), -- Karabor Infernal
    (23056, 0, 0, 1, 0), -- Ogre Drum Bunny
    (23059, 0, 0, 1, 0), -- Legion Ring Event InvisMan
    (23063, 0, 0, 1, 0), -- Overseer Shartuul
    (23078, 0, 0, 1, 0), -- Fel Imp Defender
    (23080, 0, 0, 1, 0), -- Coilskar Geyser
    (23081, 0, 0, 1, 0), -- Vim'gol's Circle Summon Visual Bunny
    (23102, 1, 1, 2, 0), -- Terokkar Trigger
    (23116, 0, 0, 1, 0), -- Warp-Gate Shield
    (23117, 0, 0, 1, 0), -- crystal man
    (23118, 0, 0, 1, 0), -- Bombing Run Target Bunny
    (23119, 0, 0, 1, 0), -- Bombing Run Explosion Bunny
    (23138, 0, 0, 1, 0), -- [PH]Fel Hound
    (23155, 0, 0, 1, 0), -- Invisible Stalker (Scale x3)
    (23173, 0, 0, 1, 0), -- Felhound Defender
    (23199, 0, 0, 1, 0), -- Gan'arg Underling
    (23209, 0, 0, 1, 0), -- Dragonmaw Peon Kill Credit
    (23212, 0, 0, 1, 0), -- Mo'arg Tormenter
    (23228, 0, 0, 1, 0), -- Eye of Shartuul
    (23255, 0, 0, 1, 0), -- Kronk's Book Bunny
    (23260, 0, 0, 1, 0), -- Legion Ring Event InvisMan Lg
    (23275, 0, 0, 1, 0), -- Dreadmaw
    (23277, 0, 0, 1, 0), -- Skyguard Target
    (23278, 0, 0, 1, 0), -- Portable Fel Cannon
    (23289, 0, 0, 1, 0), -- Mine Car
    (23301, 0, 0, 1, 0), -- Dragon Bunny
    (23308, 0, 0, 1, 0), -- Dragonmaw Peon Work Node
    (23310, 0, 0, 1, 0), -- Fel Portal Alarm
    (23312, 0, 0, 1, 0), -- Legion Ring - Stun Field
    (23313, 0, 0, 1, 0), -- Legion Ring - Stun Rope Dummy
    (23315, 0, 0, 1, 0), -- [PH] PvP Cannon Shot Target
    (23317, 0, 0, 1, 0), -- [PH] PvP Cannon Targetting Reticle
    (23322, 0, 0, 1, 0), -- Banishing Crystal Bunny 01
    (23323, 0, 0, 1, 0), -- Fel Eye Stalk
    (23325, 0, 0, 1, 0), -- Dragonmaw Flight Instructor Target
    (23327, 0, 0, 1, 0), -- Banishing Crystal Bunny 02
    (23328, 0, 0, 1, 0), -- Legion Ring - Eredar Breath Target
    (23356, 0, 0, 1, 0), -- Dragonmaw Race: Oldie's Target
    (23357, 0, 0, 1, 0), -- Dragonmaw Race: Trope's Target
    (23358, 0, 0, 1, 0), -- Dragonmaw Race: Corlok's Target
    (23359, 0, 0, 1, 0), -- Dragonmaw Race: Ichman's Target
    (23360, 0, 0, 1, 0), -- Dragonmaw Race: Mulverick's Target
    (23361, 0, 0, 1, 0), -- Dragonmaw Race: Skyshatter's Target
    (23369, 0, 0, 1, 0), -- Whirling Blade
    (23379, 0, 0, 1, 0), -- Black Temple - Houndmaster Flare Dummy
    (23395, 0, 0, 1, 0), -- Bash'ir Landing Boss Bunny
    (23398, 0, 0, 1, 0), -- Angered Soul Fragment
    (23409, 0, 0, 1, 0), -- Invisible Stalker - Large AOI (Scale x3)
    (23429, 0, 0, 1, 0), -- Arcane Charge
    (23438, 0, 0, 1, 0), -- Nether Ray Feed Credit
    (23442, 0, 0, 1, 0), -- Nether Ray Desummoner
    (23500, 0, 0, 1, 0), -- Legion Ring Shield Zapper InvisMan
    (23503, 0, 0, 1, 0), -- Shadowy Vortex
    (23512, 0, 0, 1, 0), -- Crystalforge Bunny
    (23569, 1, 1, 2, 0), -- Renn McGill
    (23583, 0, 0, 1, 0), -- Evidence Marker
    (23682, 1, 1, 2, 0), -- Headless Horseman
    (23688, 1, 0, 2, 0), -- Proto-Whelp
    (23703, 0, 0, 1, 0), -- [DND] Brewfest Dark Iron Event Generator
    (23750, 0, 0, 1, 0), -- Proto-Whelp Hatchling
    (23789, 0, 0, 1, 0), -- Smolderwing
    (23806, 0, 0, 1, 0), -- Dragonflayer Blaze
    (23807, 0, 0, 1, 0), -- Zul'Aman - Bear God Invisman
    (23808, 1, 1, 2, 0), -- [DND] Brewfest Keg Move to Target
    (23810, 0, 0, 1, 0), -- Blockade Explosion Bunny
    (23813, 0, 0, 1, 0), -- Zul'Aman - Dragonhawk God Invisman
    (23814, 0, 0, 1, 0), -- Zul'Aman - Eagle God Invisman
    (23821, 0, 0, 1, 0), -- Valgarde Harpoon Target
    (23826, 0, 0, 1, 0), -- Creeping Flames
    (23832, 0, 0, 1, 0), -- Zeppelin Power Core
    (23893, 0, 0, 1, 0), -- Invis Lighthouse Light
    (23894, 0, 0, 1, 0), -- [DND] Brewfest Dark Iron Spawn Bunny
    (23920, 0, 0, 1, 0), -- Fire Bomb (Zul'Aman)
    (23921, 0, 0, 1, 0), -- Halgrind Torch Bunny 01
    (23922, 0, 0, 1, 0), -- Halgrind Torch Bunny 02
    (23923, 0, 0, 1, 0), -- Halgrind Torch Bunny 03
    (23924, 0, 0, 1, 0), -- Halgrind Torch Bunny 04
    (23974, 0, 0, 1, 0), -- Whisper Gulch Ore Bunny
    (24000, 0, 0, 1, 0), -- Hungry Plaguehound Counter
    (24008, 0, 0, 1, 0), -- Fallen Combatant
    (24039, 0, 0, 1, 0), -- Sundered Ghost
    (24087, 0, 0, 1, 0), -- Skorn Tower NW Bunny
    (24092, 0, 0, 1, 0), -- Skorn Tower E Bunny
    (24093, 0, 0, 1, 0), -- Skorn Tower SW Bunny
    (24094, 0, 0, 1, 0), -- Skorn Tower SE Bunny
    (24095, 0, 0, 1, 0), -- Winterskorn Vrykul Dismembering Bunny
    (24098, 0, 0, 1, 0), -- Skorn Longhouse NW Bunny
    (24100, 0, 0, 1, 0), -- Skorn Longhouse NE Bunny
    (24101, 0, 0, 1, 0), -- Skorn Longhouse SW Bunny
    (24102, 0, 0, 1, 0), -- Skorn Barracks Bunny
    (24109, 0, 0, 1, 0), -- [DND] Brewfest Target Dummy Move To Target
    (24121, 0, 0, 1, 0), -- North Fleet Reservist Credit
    (24136, 0, 0, 1, 0), -- Feather Vortex
    (24158, 0, 0, 1, 0), -- Dragonflayer Oracle Target
    (24165, 0, 0, 1, 0), -- Ulf Credit Marker
    (24166, 0, 0, 1, 0), -- Oric Credit Marker
    (24167, 0, 0, 1, 0), -- Gunnar Credit Marker
    (24170, 0, 0, 1, 0), -- Draconis Gastritis Bunny
    (24182, 0, 0, 1, 0), -- Winterskorn Dwelling Credit
    (24183, 0, 0, 1, 0), -- Winterskorn Watchtower Credit
    (24184, 0, 0, 1, 0), -- Winterskorn Barracks Credit
    (24185, 0, 0, 1, 0), -- Winterskorn Bridge Credit
    (24193, 0, 0, 1, 0), -- Baleheim Fire Bunny
    (24194, 0, 0, 1, 0), -- Baleheim Fire Bunny Large
    (24202, 0, 0, 1, 0), -- [DND] Brewfest Barker Bunny 1
    (24203, 0, 0, 1, 0), -- [DND] Brewfest Barker Bunny 2
    (24204, 0, 0, 1, 0), -- [DND] Brewfest Barker Bunny 3
    (24205, 0, 0, 1, 0), -- [DND] Brewfest Barker Bunny 4
    (24230, 0, 0, 1, 0), -- Feknut's Firecrackers Bunny
    (24263, 0, 0, 1, 0), -- [DND] Brewfest Speed Bunny Green
    (24264, 0, 0, 1, 0), -- [DND] Brewfest Speed Bunny Yellow
    (24265, 0, 0, 1, 0), -- [DND] Brewfest Speed Bunny Red
    (24269, 0, 0, 1, 0), -- The Cleansing Bunny [reuse me]
    (24289, 0, 0, 1, 0), -- Invisible Westguard Fire
    (24290, 0, 0, 1, 0), -- New Agamand Plague Tank Bunny
    (24335, 0, 0, 1, 0), -- Runed Orb
    (24337, 0, 0, 1, 0), -- [DND] Brewfest Delivery Bunny
    (24363, 0, 0, 1, 0), -- Hex Lord Malacrass
    (24377, 0, 0, 1, 0), -- [UNUSED]Vazruden Kill Credit
    (24378, 0, 0, 1, 0), -- [UNUSED]Nazan Kill Credit
    (24382, 0, 0, 1, 0), -- [VO]Nalorakk
    (24383, 0, 0, 1, 0), -- [VO]Akil'Zon
    (24384, 0, 0, 1, 0), -- [VO]Halazzi
    (24386, 0, 0, 1, 0), -- [VO]Jan'alai
    (24391, 0, 0, 1, 0), -- Old Puttery
    (24438, 0, 0, 1, 0), -- Steel Gate - Grapple Target
    (24449, 0, 0, 1, 0), -- Invisible Charge Target 1
    (24450, 0, 0, 1, 0), -- Invisible Charge Target 2
    (24454, 0, 0, 1, 0), -- Steel Gate Dynamite
    (24465, 0, 0, 1, 0), -- Blue Floating Rune Channel Bunny 01
    (24466, 0, 0, 1, 0), -- Blue Floating Rune Channel Bunny 02
    (24505, 0, 0, 1, 0), -- Unkillable Test Dummy 73 Paladin
    (24513, 0, 0, 1, 0), -- Vrykul Harpoon Controller 001 View
    (24515, 0, 0, 1, 0), -- Spotted Hippogryph Hatchling
    (24526, 0, 0, 1, 0), -- Invisible Stalker (Floating) (5.00)
    (24533, 1, 0, 2, 0), -- Dragonflayer Defender
    (24538, 0, 0, 1, 0), -- Dragonflayer Installation I
    (24550, 0, 0, 1, 0), -- Throw Targeting (mob)
    (24645, 0, 0, 1, 0), -- Mirror Frame
    (24646, 0, 0, 1, 0), -- Dragonflayer Installation II
    (24647, 0, 0, 1, 0), -- Dragonflayer Installation III
    (24648, 0, 0, 1, 0), -- Invisible Stalker (Scale x2)
    (24651, 0, 0, 1, 0), -- Reflection of Flame
    (24652, 0, 0, 1, 0), -- Harpoon Surfboard
    (24655, 0, 0, 1, 0), -- Reflection Bounce Target
    (24665, 0, 0, 1, 0), -- Lieutenant Icehammer
    (24704, 0, 0, 1, 0), -- Invisible Vehicle (Floating)
    (24705, 0, 0, 1, 0), -- Rope Swing Invisible Vehicle Stalker
    (24725, 0, 0, 1, 0), -- Dog Sled
    (24756, 0, 0, 1, 0), -- Reflection of Magic
    (24766, 0, 0, 1, 0), -- [DND] Brewfest Face Me Bunny
    (24771, 0, 0, 1, 0), -- Coldarra Invisman
    (24778, 0, 0, 1, 0), -- Missile Target Flare
    (24826, 0, 0, 1, 0), -- Transport Bot A1->A2
    (24827, 0, 0, 1, 0), -- Transport Bot B1->B2
    (24828, 0, 0, 1, 0), -- Transport Bot C1->C2
    (24829, 0, 0, 1, 0), -- Transport Bot D1->D2
    (24831, 0, 0, 1, 0), -- Transport Bot D2
    (24832, 0, 0, 1, 0), -- Transport Bot D3
    (24845, 0, 0, 1, 0), -- Baelgun's Event Generator (Cave)
    (24853, 0, 0, 1, 0), -- Wheelbarrow
    (24858, 1, 0, 2, 0), -- Soaring Eagle
    (24861, 0, 0, 1, 0), -- Crystal Beam
    (24862, 0, 0, 1, 0), -- Mage Hunter Target
    (24865, 0, 0, 1, 0), -- Crystal Beam Relay
    (24874, 0, 0, 1, 0), -- Fengir the Disgraced
    (24888, 0, 0, 1, 0), -- Isuldof Quest Credit
    (24890, 0, 0, 1, 0), -- Windan Quest Credit
    (24915, 0, 0, 1, 0), -- Snowball Stampede
    (24925, 0, 0, 1, 0), -- Boss Portal: Purple (3.00)
    (24983, 0, 0, 1, 0), -- Tainted Magnataur Spirit
    (25168, 0, 0, 1, 0), -- Kite Lightning Bunny
    (25212, 0, 0, 1, 0), -- Kite Sky Lightning Bunny
    (25297, 0, 0, 1, 0), -- Drill Dummy
    (25402, 0, 0, 1, 0), -- Nerub'ar Sinkhole (South)
    (25403, 0, 0, 1, 0), -- Nerub'ar Sinkhole (East)
    (25404, 0, 0, 1, 0), -- Nerub'ar Sinkhole (West)
    (25405, 0, 0, 1, 0), -- Nerub'ar Sinkhole (North)
    (25431, 0, 0, 1, 0), -- Kaskala Ancestor
    (25436, 0, 0, 1, 0), -- Elder Tuskarr Spirit
    (25441, 0, 0, 1, 0), -- North Platform
    (25442, 0, 0, 1, 0), -- East Platform
    (25443, 0, 0, 1, 0), -- West Platform
    (25456, 1, 0, 2, 0), -- Vision of Kaganishu
    (25471, 0, 0, 1, 0), -- Temple A
    (25472, 0, 0, 1, 0), -- Temple B
    (25473, 0, 0, 1, 0), -- Temple C
    (25490, 0, 0, 1, 0), -- East En'kilah Cauldron
    (25492, 0, 0, 1, 0), -- Central En'kilah Cauldron
    (25493, 0, 0, 1, 0), -- West En'kilah Cauldron
    (25669, 0, 0, 1, 0), -- Warsong Grainery Credit
    (25670, 0, 0, 1, 0), -- ELM General Purpose Bunny (scale x3)
    (25671, 0, 0, 1, 0), -- Torp's Farm Credit
    (25672, 0, 0, 1, 0), -- Warsong Slaughterhouse Credit
    (25676, 0, 0, 1, 0), -- Storm Cloud
    (25698, 0, 0, 1, 0), -- Kodo Saved Credit
    (25739, 0, 0, 1, 0), -- Steam Vent
    (25748, 0, 0, 1, 0), -- Oil-covered Hawk
    (25768, 0, 0, 1, 0), -- Lord Kryxix
    (25771, 0, 0, 1, 0), -- Ice Elemental Target
    (25817, 0, 0, 1, 0), -- Oiled Fledgeling
    (25845, 0, 0, 1, 0), -- Northwest Crash
    (25846, 0, 0, 1, 0), -- South Crash
    (25847, 0, 0, 1, 0), -- East Crash
    (25995, 0, 0, 1, 0), -- Stampede Exit Point
    (26041, 0, 0, 1, 0), -- Lightning Target
    (26086, 0, 0, 1, 0), -- Transport Orb
    (26093, 0, 0, 1, 0), -- Naxxanar Target
    (26094, 0, 0, 1, 0), -- Naxxanar Caster
    (26098, 0, 0, 1, 0), -- Bess
    (26105, 0, 0, 1, 0), -- Quest Invisman - Buying Time
    (26129, 0, 0, 1, 0), -- Quest InvisMan - Buying Time - Effect Caster
    (26130, 0, 0, 1, 0), -- Quest InvisMan - Buying Time - Effect Target
    (26162, 0, 0, 1, 0), -- Transborea Generator 001
    (26175, 0, 0, 1, 0), -- Coldarra - Drake Hunt Invisman
    (26193, 0, 0, 1, 0), -- Nexus 70 - Buying Time - Kill Credit
    (26231, 1, 0, 2, 0), -- Saragosa
    (26264, 0, 0, 1, 0), -- Boulder Target
    (26265, 0, 0, 1, 0), -- Saragosa's End Invisman
    (26297, 0, 0, 1, 0), -- Voice of Keristrasza
    (26370, 0, 0, 1, 0), -- Arcanimus
    (26373, 0, 0, 1, 0), -- Coldarra Spell FX InvisMan
    (26430, 0, 0, 1, 0), -- Ducal's Passenger Seat
    (26444, 0, 0, 1, 0), -- Quest Invisman - Filling the Cages
    (26445, 0, 0, 1, 0), -- Rune Plate
    (26475, 1, 0, 2, 0), -- Magmawyrm
    (26498, 0, 0, 1, 0), -- Drakuru's Bunny 01
    (26559, 0, 0, 1, 0), -- Drakuru's Bunny 02
    (26591, 0, 0, 1, 0), -- Pacer Bunny - Drak Theron Exterior
    (26612, 0, 0, 1, 0), -- Burninate Kill Credit
    (26675, 0, 0, 1, 0), -- Spider Summon Target
    (26700, 0, 0, 1, 0), -- Drakuru's Bunny 03
    (26732, 0, 0, 1, 0), -- [dnd] Fizzcrank Paratrooper Bunny
    (26784, 0, 0, 1, 0), -- Dan's Test Dummy
    (26785, 0, 0, 1, 0), -- Directional Rune
    (26789, 0, 0, 1, 0), -- Drakuru's Bunny 04
    (26804, 0, 0, 1, 0), -- Fizzcrank Bomber Invisible Bunny
    (26807, 1, 0, 2, 0), -- Fizzcrank Bomber Flyby 01
    (26867, 0, 0, 1, 0), -- Mummy Effect Bunny
    (26899, 0, 0, 1, 0), -- Riding Drake, Red
    (26927, 0, 0, 1, 0), -- Warlord Jin'gom Kill Credit
    (26937, 0, 0, 1, 0), -- Gong Bunny
    (27047, 0, 0, 1, 0), -- Invisible Stalker (Floating Only)
    (27048, 0, 0, 1, 0), -- Breath Caster
    (27180, 0, 0, 1, 0), -- Jintha'kalar Invisible Stalker
    (27200, 0, 0, 1, 0), -- Offering Bunny - Drakil'jin Exterior
    (27201, 0, 0, 1, 0), -- Offering Target Bunny - Drakil'jin Exterior
    (27222, 0, 0, 1, 0), -- Archery Target
    (27223, 0, 0, 1, 0), -- Archery Target
    (27239, 0, 0, 1, 0), -- Rogue Test Dummy
    (27321, 0, 0, 1, 0), -- Kodian Conversation Credit
    (27322, 0, 0, 1, 0), -- Orsonn Conversation Credit
    (27323, 0, 0, 1, 0), -- Outhouse Stalker
    (27326, 0, 0, 1, 0), -- Outhouse Bunny - Grizzly
    (27353, 0, 0, 1, 0), -- Levine Family Termite Bunny
    (27365, 0, 0, 1, 0), -- Stabled Horse
    (27368, 0, 0, 1, 0), -- [DND] Stabled Pet Appearance
    (27369, 0, 0, 1, 0), -- Necromantic Rune Bunny
    (27387, 0, 0, 1, 0), -- [DND] Valiance Keep Footman Spectator
    (27392, 0, 0, 1, 0), -- Avenging Spirit Summoner
    (27396, 0, 0, 1, 0), -- Kill Credit Bunny - Shredder Delivery
    (27402, 0, 0, 1, 0), -- Bone Target Bunny
    (27403, 0, 0, 1, 0), -- Strange Ore Target
    (27413, 0, 0, 1, 0), -- Log Ride Bunny - Alliance
    (27418, 0, 0, 1, 0), -- Rothin's Spell Bunny
    (27420, 0, 0, 1, 0), -- Rothin's Necromantic Rune Bunny
    (27436, 0, 0, 1, 0), -- Upper Wintergarde Mine Shaft
    (27437, 0, 0, 1, 0), -- Lower Wintergarde Mine Shaft
    (27446, 0, 0, 1, 0), -- High Abbot Landgren's Jump Vehicle
    (27448, 0, 0, 1, 0), -- Serinar's Presence
    (27449, 0, 0, 1, 0), -- Neltharion's Flame Fire Bunny
    (27453, 0, 0, 1, 0), -- Blue Sky Kill Credit Bunny - Grizzly Hills
    (27454, 0, 0, 1, 0), -- Zelig Spell Target
    (27466, 0, 0, 1, 0), -- Kill Credit Bunny - Wounded Skirmishers
    (27471, 0, 0, 1, 0), -- Forgotten Rifleman Quest Credit
    (27472, 0, 0, 1, 0), -- Forgotten Peasant Quest Credit
    (27473, 0, 0, 1, 0), -- Forgotten Knight Quest Credit
    (27474, 0, 0, 1, 0), -- Captain Luc D'Merud Quest Credit
    (27529, 0, 0, 1, 0), -- Unu'pe Vision - Smoke Target (DND)
    (27568, 0, 0, 1, 0), -- Venture Co. Stables
    (27572, 0, 0, 1, 0), -- Ruby Controller Bunny
    (27583, 0, 0, 1, 0), -- Novos Summon Target
    (27586, 0, 0, 1, 0), -- QA Test Dummy 80 Normal
    (27589, 0, 0, 1, 0), -- Ruby Strafe Bunny
    (27590, 0, 0, 1, 0), -- QA Test Dummy 80 No Armor
    (27591, 0, 0, 1, 0), -- QA Test Dummy 83 No Armor
    (27592, 0, 0, 1, 0), -- QA Test Dummy 83 Normal
    (27595, 0, 0, 1, 0), -- QA Test Dummy 80 High Magic Resist
    (27596, 0, 0, 1, 0), -- QA Test Dummy 83 High Magic Resist
    (27599, 0, 0, 1, 0), -- QA Test Dummy 80 Fixed Damage
    (27601, 0, 0, 1, 0), -- QA Test Dummy 83 Fixed Damage
    (27609, 0, 0, 1, 0), -- QA Test Dummy 80 Spell Spammer
    (27655, 1, 1, 2, 0), -- Mage-Lord Urom
    (27660, 0, 0, 1, 0), -- Kill Credit Bunny - Venture Bay 01
    (27669, 0, 0, 1, 0), -- Novos Spell Dummy
    (27674, 0, 0, 1, 0), -- Racer Slam Bunny
    (27679, 0, 0, 1, 0), -- Proximity Mine
    (27689, 0, 0, 1, 0), -- Alliance Lumberboat Explosions
    (27710, 0, 0, 1, 0), -- Goblin Rocket Mount Test
    (27723, 0, 0, 1, 0), -- [DND] Aldor Mailbox Malfunction Bunny
    (27798, 0, 0, 1, 0), -- Reincarnated Skytalon
    (27802, 0, 0, 1, 0), -- Orb Target Credit
    (27851, 0, 0, 1, 0), -- Thel'zan Spell Dummy
    (27869, 0, 0, 1, 0), -- Wintergrasp Detection Unit
    (27889, 0, 0, 1, 0), -- Taking Wing Timer Bunny
    (27899, 0, 0, 1, 0), -- Future You
    (27905, 0, 0, 1, 0), -- Wintergrasp Bomber Cockpit
    (27921, 0, 0, 1, 0), -- Drakuru Handshake KC Bunny
    (27929, 0, 0, 1, 0), -- Mummified Carcass KC Bunny
    (27931, 0, 0, 1, 0), -- Despawn Mummy Bunny
    (27959, 0, 0, 1, 0), -- Your Inner Turmoil
    (27988, 0, 0, 1, 0), -- Dalson's Outhouse Bunny
    (27989, 0, 0, 1, 0), -- D.I.S.C.O.
    (27994, 0, 0, 1, 0), -- Lieutenant Icehammer
    (28008, 0, 0, 1, 0), -- Galakrond Spell Dummy
    (28037, 0, 0, 1, 0), -- The Spirit of Gnomeregan
    (28053, 1, 0, 2, 0), -- Apple
    (28060, 1, 0, 2, 0), -- Nyuni
    (28064, 0, 0, 1, 0), -- Drakkari Pedestal 01
    (28128, 0, 0, 1, 0), -- Bristlepine Food Bunny
    (28137, 0, 0, 1, 0), -- Leave No One Behind Bunny
    (28173, 0, 0, 1, 0), -- [ph] exploding barrel
    (28184, 0, 0, 1, 0), -- [DND] under water construction crew
    (28190, 0, 0, 1, 0), -- Venture Bay Kill Credit Bunny - Grizzly Hills
    (28206, 0, 0, 1, 0), -- [DND] L70ETC Drums
    (28230, 0, 0, 1, 0), -- Nozronn's Eye
    (28236, 0, 0, 1, 0), -- Azure Ring Captain
    (28237, 0, 0, 1, 0), -- Dark Matter Target
    (28239, 0, 0, 1, 0), -- Arcane Beam
    (28240, 0, 0, 1, 0), -- Finklestein's Cauldron Bunny
    (28248, 0, 0, 1, 0), -- Alchemist KC Bunny
    (28254, 0, 0, 1, 0), -- Mistwhisper Lightning Target
    (28273, 0, 0, 1, 0), -- Arranged Crystal Formation Bunny
    (28277, 0, 0, 1, 0), -- Harry's Bomber
    (28280, 0, 0, 1, 0), -- QA Test Dummy 83 High Damage
    (28282, 0, 0, 1, 0), -- QA Test Dummy 82 High Damage
    (28292, 0, 0, 1, 0), -- [DND] taxi flavor eagle
    (28293, 0, 0, 1, 0), -- Muddy Mire Maggot KC Bunny
    (28294, 0, 0, 1, 0), -- Withered Batwing KC Bunny
    (28295, 0, 0, 1, 0), -- Amberseed KC Bunny
    (28296, 0, 0, 1, 0), -- Chilled Serpent Mucus KC Bunny
    (28299, 0, 0, 1, 0), -- Frenzyheart Hill Bunny
    (28300, 0, 0, 1, 0), -- Mistwhisper Refuge Bunny
    (28301, 0, 0, 1, 0), -- ZP - Retch! Bunny
    (28304, 0, 0, 1, 0), -- Drakkari Pedestal 02
    (28305, 0, 0, 1, 0), -- Drakkari Pedestal 03
    (28310, 0, 0, 1, 0), -- QA Test Dummy 80 Buff Spammer
    (28311, 0, 0, 1, 0), -- QA Test Dummy 80 Spell Reflector
    (28316, 0, 0, 1, 0), -- Defeated Argent Footman KC Bunny
    (28330, 0, 0, 1, 0), -- Ancient Dirt KC Bunny
    (28333, 0, 0, 1, 0), -- ELM General Purpose Bunny (scale x0.25)
    (28348, 0, 0, 1, 0), -- (Wrathgate Monster) Forsaken Blightspreader (Gas Mask)
    (28352, 0, 0, 1, 0), -- Nethurbian Crater KC Bunny
    (28360, 0, 0, 1, 0), -- Riding Fizzcrank Flyer Taxi
    (28389, 0, 0, 1, 0), -- Primordial Hatchling
    (28441, 0, 0, 1, 0), -- Great Horned Owl Hover Bunny
    (28454, 0, 0, 1, 0), -- Skyreach Pillar Bunny
    (28455, 0, 0, 1, 0), -- Rainspeaker Canopy Bunny
    (28456, 0, 0, 1, 0), -- Sparktouched Haven Bunny
    (28457, 0, 0, 1, 0), -- Spearborn Encampment Bunny
    (28458, 0, 0, 1, 0), -- Kartak's Hold Bunny
    (28459, 0, 0, 1, 0), -- Mosswalker Village Bunny
    (28460, 0, 0, 1, 0), -- Lifeblood Pillar Bunny
    (28461, 0, 0, 1, 0), -- Bristlepine Den Bunny
    (28462, 0, 0, 1, 0), -- Sapphire Hive Bunny
    (28463, 0, 0, 1, 0), -- River's Heart Bunny
    (28473, 0, 0, 1, 0), -- Material You
    (28482, 0, 0, 1, 0), -- Avatar of Freya Conversation Credit
    (28509, 0, 0, 1, 0), -- Building (CoT Stratholme)
    (28520, 0, 0, 1, 0), -- Hair Sample KC Bunny
    (28523, 0, 0, 1, 0), -- Nass Target KC Bunny
    (28567, 0, 0, 1, 0), -- Water Spout
    (28591, 0, 0, 1, 0), -- Ghoul Feeding KC Bunny
    (28595, 0, 0, 1, 0), -- Freya's Horn Credit
    (28616, 1, 0, 2, 0), -- Scarlet Gryphon Rider
    (28617, 0, 0, 1, 0), -- Drakuramas Teleport Bunny 01
    (28627, 0, 0, 1, 0), -- Wood Pile Dummy
    (28631, 0, 0, 1, 0), -- Drakuru KC Bunny 01
    (28643, 0, 0, 1, 0), -- Rain of Darkness Dummy
    (28644, 0, 0, 1, 0), -- Mosswalker Kill Credit
    (28655, 0, 0, 1, 0), -- Sky Darkener Target
    (28657, 0, 0, 1, 0), -- Caged Geist
    (28663, 0, 0, 1, 0), -- Gorebag KC Bunny 01
    (28664, 0, 0, 1, 0), -- Seat Squatter - LAB
    (28670, 1, 0, 2, 0), -- Frostbrood Vanquisher
    (28738, 0, 0, 1, 0), -- Drakuru KC Bunny 00
    (28739, 0, 0, 1, 0), -- Blight Cauldron Bunny 00
    (28740, 0, 0, 1, 0), -- Blight Crystal KC Bunny
    (28741, 0, 0, 1, 0), -- Blight Cauldron KC Bunny 02
    (28751, 0, 0, 1, 0), -- Geist WP Bunny
    (28761, 0, 0, 1, 0), -- Geist Spawn Bunny
    (28762, 0, 0, 1, 0), -- Drakuru KC Bunny 02
    (28765, 0, 0, 1, 0), -- The Lich King
    (28770, 0, 0, 1, 0), -- High Priestess Tua-Tua Hex of Fire Bunny
    (28773, 0, 0, 1, 0), -- High Priest Hawinni Hex of Frost Bunny
    (28775, 0, 0, 1, 0), -- Dark Rider Target
    (28777, 0, 0, 1, 0), -- Catapult KC Bunny
    (28778, 0, 0, 1, 0), -- Scourgewagon Bunny
    (28780, 0, 0, 1, 0), -- Explosive Charges Bunny
    (28786, 0, 0, 1, 0), -- Drakuru KC Bunny 03
    (28839, 0, 0, 1, 0), -- Scarlet Cover Dummy
    (28852, 0, 0, 1, 0), -- Dead Mam'toth Disciple
    (28874, 0, 0, 1, 0), -- Gargoyle Waypoint
    (28879, 0, 0, 1, 0), -- Shalewing
    (28882, 1, 1, 2, 0), -- Enchanted Tiki Warrior
    (28927, 0, 0, 1, 0), -- Enchanted Tiki Dervish
    (28928, 0, 0, 1, 0), -- Drakuru KC Bunny 04
    (28929, 0, 0, 1, 0), -- Drakuru's Upper Chamber Bunny
    (28935, 0, 0, 1, 0), -- Acherus Dummy
    (28950, 0, 0, 1, 0), -- Spell Performance Test Target
    (28953, 0, 0, 1, 0), -- Unkillable Test Dummy 70 Gnome
    (28954, 0, 0, 1, 0), -- Unkillable Test Dummy 70 Tauren
    (28955, 0, 0, 1, 0), -- Unkillable Test Dummy 70 Dwarf
    (28957, 0, 0, 1, 0), -- [Chapter II] Scarlet Crusader Test Dummy Guy
    (29020, 0, 0, 1, 0), -- [DND] Dockhand w/Bag
    (29027, 0, 0, 1, 0), -- Wild Growth Stalker
    (29075, 0, 0, 1, 0), -- QA Test Dummy 73 Raid Debuff (Low Armor)
    (29094, 0, 0, 1, 0), -- Volatile Trap Knockback Bunny
    (29099, 0, 0, 1, 0), -- Drakkari Skullcrusher KC Bunny
    (29100, 0, 0, 1, 0), -- Totally Generic Bunny x8.0 (JSB)
    (29105, 0, 0, 1, 0), -- Eagle Eyes Target
    (29140, 0, 0, 1, 0), -- Camera Shaker - 20-40 seconds
    (29192, 0, 0, 1, 0), -- [Chapter IV] Chapter IV Dummy
    (29215, 0, 0, 1, 0), -- Disciples of the Unholy Bunny
    (29224, 0, 0, 1, 0), -- Presence of Yogg-Saron
    (29238, 1, 1, 2, 0), -- Scourge Haunt
    (29263, 0, 0, 1, 0), -- PattyMacks Hovering Dummy
    (29276, 0, 0, 1, 0), -- Ethereal Summon Target
    (29308, 1, 1, 2, 0), -- Prince Taldaram
    (29344, 0, 0, 1, 0), -- Lord-Commander Arete
    (29397, 0, 0, 1, 0), -- Land Mine Bunny
    (29415, 0, 0, 1, 0), -- Captured Onslaught Gryphon
    (29425, 0, 0, 1, 0), -- Erekem Controller
    (29459, 0, 0, 1, 0), -- Vargul Dummy
    (29504, 0, 0, 1, 0), -- Seething Revenant
    (29588, 0, 0, 1, 0), -- Teleport - Hall -> Heart (EPL)
    (29589, 0, 0, 1, 0), -- Teleport - Heart -> Hall (EPL)
    (29595, 0, 0, 1, 0), -- Frostworg KC Bunny
    (29597, 0, 0, 1, 0), -- Frost Giant KC Bunny
    (29599, 0, 0, 1, 0), -- Brann Snow Target
    (29648, 0, 0, 1, 0), -- Bone Gryphon
    (29655, 0, 0, 1, 0), -- Malygos
    (29737, 0, 0, 1, 0), -- Barrel o' Fun
    (29752, 0, 0, 1, 0), -- Databank Core
    (29754, 0, 0, 1, 0), -- Column Ornament
    (29771, 0, 0, 1, 0), -- ELM General Purpose Bunny (scale x0.01 - Phase I)
    (29772, 0, 0, 1, 0), -- ELM General Purpose Bunny Hide Body (Phase I)
    (29773, 0, 0, 1, 0), -- ELM General Purpose Bunny Large (Phase I)
    (29777, 0, 0, 1, 0), -- Cosmetic Mechanical Gorilla
    (29780, 0, 0, 1, 0), -- Cosmetic Mechanical Chicken
    (29781, 0, 0, 1, 0), -- Cosmetic Mechanical Squirrel
    (29782, 0, 0, 1, 0), -- Cosmetic Mechanical Sheep
    (29783, 0, 0, 1, 0), -- Cosmetic Clockwork Robot
    (29784, 0, 0, 1, 0), -- Cosmetic Clockwork Robot (Blue)
    (29785, 0, 0, 1, 0), -- Cosmetic Clockwork Robot (Red)
    (29802, 0, 0, 1, 0), -- Cosmetic Toy Plane
    (29807, 0, 0, 1, 0), -- [DND] Dalaran Toy Store Plane String Hook
    (29812, 0, 0, 1, 0), -- [DND] Dalaran Toy Store Plane String Bunny
    (29815, 0, 0, 1, 0), -- Chain Swing Bunny
    (29870, 0, 0, 1, 0), -- Persistence Waypoint 00
    (29871, 0, 0, 1, 0), -- Persistence Waypoint 01
    (29872, 1, 0, 2, 0), -- Algar the Chosen
    (29876, 0, 0, 1, 0), -- ELM General Purpose Bunny (Phase I)
    (29877, 0, 0, 1, 0), -- ELM General Purpose Bunny (scale x0.01 - Phase I) Large
    (29881, 0, 0, 1, 0), -- An Unknown Voice
    (29913, 0, 0, 1, 0), -- Dan's Test Dummy (Large AOI)
    (29928, 0, 0, 1, 0), -- Gymer Lock Dummy
    (29998, 0, 0, 1, 0), -- Desecrated Ground V
    (30079, 0, 0, 1, 0), -- ELM General Purpose Bunny (Phase II)
    (30084, 1, 1, 2, 0), -- Power Spark
    (30091, 0, 0, 1, 0), -- Central Conflict Controller Bunny
    (30103, 0, 0, 1, 0), -- Valkyrion Fire Bunny
    (30120, 0, 0, 1, 0), -- Seething Revenant
    (30122, 0, 0, 1, 0), -- Storm Peaks Anvil Bunny
    (30125, 0, 0, 1, 0), -- Vengeful Revenant KC Bunny
    (30126, 0, 0, 1, 0), -- Njormeld KC Bunny
    (30130, 0, 0, 1, 0), -- Veranus Right Foot Bunny
    (30131, 0, 0, 1, 0), -- Veranus Left Foot Bunny
    (30132, 0, 0, 1, 0), -- Veranus Right Wing Bunny
    (30133, 0, 0, 1, 0), -- Veranus Left Wing Bunny
    (30138, 0, 0, 1, 0), -- Frost Giant Ghost KC
    (30139, 0, 0, 1, 0), -- Frost Dwarf Ghost KC
    (30169, 0, 0, 1, 0), -- Smoldering Scrap Bunny
    (30207, 0, 0, 1, 0), -- Forgotten Depths Dummy
    (30209, 0, 0, 1, 0), -- North Lightning Forge
    (30210, 0, 0, 1, 0), -- Hodir's Helm KC Bunny
    (30211, 0, 0, 1, 0), -- Central Lightning Forge
    (30212, 0, 0, 1, 0), -- South Lightning Forge
    (30214, 0, 0, 1, 0), -- Thrall's Big Hit, Lightning Bolt Bunny
    (30235, 0, 0, 1, 0), -- Glory
    (30276, 1, 0, 2, 0), -- Ahn'kahar Web Winder
    (30281, 0, 0, 1, 0), -- Silver Covenant Hippogryph
    (30282, 1, 1, 2, 0), -- Arcane Overload
    (30327, 0, 0, 1, 0), -- Jokkum KC Bunny
    (30332, 1, 0, 2, 0), -- Jotunheim Proto-Drake Rider
    (30334, 0, 0, 1, 0), -- Surge of Power
    (30337, 1, 0, 2, 0), -- Jotunheim Rapid-Fire Harpoon
    (30339, 0, 0, 1, 0), -- Frigid Tomb Controller Bunny
    (30343, 1, 1, 2, 0), -- The Skybreaker
    (30366, 0, 0, 1, 0), -- Lure Jormuttar Bunny
    (30383, 1, 0, 2, 0), -- Brann's Flying Machine
    (30384, 0, 0, 1, 0), -- Flying Machine Controller Bunny
    (30415, 0, 0, 1, 0), -- Wild Wyrm KC Bunny
    (30421, 0, 0, 1, 0), -- Roaming Jormungar KC Bunny
    (30462, 1, 0, 2, 0), -- Thorim
    (30465, 0, 0, 1, 0), -- Dan's Test Void Sentry
    (30476, 0, 0, 1, 0), -- [DND] Icecrown Flight To Airship Bunny (A)
    (30492, 0, 0, 1, 0), -- Loken Controller
    (30500, 0, 0, 1, 0), -- Argent Skytalon
    (30514, 0, 0, 1, 0), -- Thorim Talk KC Bunny
    (30515, 0, 0, 1, 0), -- Witness the Reckoning Credit
    (30559, 0, 0, 1, 0), -- [DND] Icecrown Flight To Airship Bunny (A) Teleport Target
    (30576, 0, 0, 1, 0), -- Vile Like Fire! Kill Credit Bunny
    (30588, 1, 1, 2, 0), -- [DND] Icecrown Flight To Airship Bunny (H)
    (30589, 1, 1, 2, 0), -- [DND] Icecrown Flight To Airship Bunny (H) Teleport Target
    (30598, 0, 0, 1, 0), -- Spike Target
    (30599, 0, 0, 1, 0), -- Vile Like Fire! Fire Bunny
    (30614, 0, 0, 1, 0), -- Spike Target 2
    (30615, 0, 0, 1, 0), -- Dan's Test Dummy (Non Vehicle)
    (30616, 0, 0, 1, 0), -- Flame Tsunami
    (30621, 0, 0, 1, 0), -- Twisted Visage
    (30622, 0, 0, 1, 0), -- Twisted Visage
    (30623, 0, 0, 1, 0), -- Twisted Visage
    (30624, 0, 0, 1, 0), -- Twisted Visage
    (30640, 0, 0, 1, 0), -- [DND] Icecrown Airship (A) - Cannon Target
    (30648, 0, 0, 1, 0), -- Fire Cyclone
    (30649, 1, 1, 2, 0), -- [DND] Icecrown Airship (H) - Cannon Target
    (30650, 0, 0, 1, 0), -- Shadron Portal Visual
    (30655, 0, 0, 1, 0), -- [DND] Icecrown Airship (A) - Cannon Controller 01
    (30669, 0, 0, 1, 0), -- Vanguard Sound Dummy
    (30690, 1, 1, 2, 0), -- [DND] Icecrown Airship (H) - Flak Cannon, Odd
    (30699, 1, 1, 2, 0), -- [DND] Icecrown Airship (H) - Flak Cannon, Even
    (30702, 1, 1, 2, 0), -- Flame Orb
    (30707, 1, 1, 2, 0), -- [DND] Icecrown Airship (H) - Cannon Controller 01
    (30712, 0, 0, 1, 0), -- Bridenbrad Light Bunny
    (30741, 0, 0, 1, 0), -- Shadron Portal
    (30742, 0, 0, 1, 0), -- First Summoning Altar
    (30744, 0, 0, 1, 0), -- Second Summoning Altar
    (30745, 0, 0, 1, 0), -- Third Summoning Altar
    (30844, 0, 0, 1, 0), -- Death Gate (Dummy)
    (30857, 0, 0, 1, 0), -- Defense Dummy Target
    (30874, 0, 0, 1, 0), -- Invulnerability Aura
    (30878, 0, 0, 1, 0), -- Vesperon Controller
    (30883, 0, 0, 1, 0), -- Dalaran Prison Event Controller
    (30888, 0, 0, 1, 0), -- QA Test Dummy 80 Hostile Low Damage
    (30899, 0, 0, 1, 0), -- Abedneum
    (30950, 0, 0, 1, 0), -- Fourth Summoning Altar
    (30990, 0, 0, 1, 0), -- Metal Post Bunny
    (30995, 0, 0, 1, 0), -- Patches Chain Target
    (31005, 0, 0, 1, 0), -- Player Mirror Bunny
    (31006, 0, 0, 1, 0), -- CoT Stratholme - Mal'Ganis KC Bunny
    (31012, 0, 0, 1, 0), -- Iceskin Sentry
    (31047, 0, 0, 1, 0), -- ELM General Purpose Bunny Gigantic
    (31049, 0, 0, 1, 0), -- Geist Return Bunny
    (31077, 0, 0, 1, 0), -- Safirdrang's Chill Target
    (31092, 0, 0, 1, 0), -- Scourge Egg KC Bunny
    (31105, 0, 0, 1, 0), -- Ahn'kahet Brazier KC Bunny
    (31117, 0, 0, 1, 0), -- Safirdrang's Controller Bunny
    (31118, 0, 0, 1, 0), -- Azure Raider
    (31138, 0, 0, 1, 0), -- Tenebron Egg Controller
    (31246, 0, 0, 1, 0), -- [DND] Icecrown Airship Cannon Explosion Bunny
    (31256, 0, 0, 1, 0), -- Bad Fish - Rabbits
    (31264, 0, 0, 1, 0), -- A Mysterious Voice
    (31265, 1, 1, 2, 0), -- Savage Proto-Drake
    (31272, 0, 0, 1, 0), -- Dying Berserker KC Bunny
    (31312, 0, 0, 1, 0), -- Dying Soldier KC Bunny
    (31358, 0, 0, 1, 0), -- (Wrath Gate) Dummy
    (31364, 0, 0, 1, 0), -- Frostbrood Skytalon KC Bunny
    (31481, 0, 0, 1, 0), -- Scourge Fight Kill Credit
    (31517, 0, 0, 1, 0), -- Dalaran Fountain Invis Stalker
    (31569, 0, 0, 1, 0), -- Plague Barrel [Wrath Gate Both] (UC)
    (31570, 0, 0, 1, 0), -- Broken Plague Barrel  [Wrath Gate Both] (UC)
    (31571, 0, 0, 1, 0), -- Broken Plague Barrel 2 [Wrath Gate Both] (UC)
    (31576, 0, 0, 1, 0), -- Invisible Stalker [Wrath Gate Horde CE 01] (UC)
    (31577, 0, 0, 1, 0), -- Invisible Stalker Target [Wrath Gate Horde CE 01] (UC)
    (31641, 0, 0, 1, 0), -- Icecrown - Pit Fall
    (31643, 0, 0, 1, 0), -- Dalaran Well Teleport Bunny
    (31653, 0, 0, 1, 0), -- Invisible Stalker Tesla
    (31683, 0, 0, 1, 0), -- Wrath Gate Dummy
    (31684, 0, 0, 1, 0), -- Wrath Gate Dummy (Undercity)
    (31688, 0, 0, 1, 0), -- Whirlwind
    (31741, 0, 0, 1, 0), -- Cosmetic Rabbit
    (31743, 0, 0, 1, 0), -- Icy Ghoul KC Bunny
    (31767, 0, 0, 1, 0), -- Plague Cauldron KC Bunny
    (31773, 0, 0, 1, 0), -- Plague Cauldron Target
    (31794, 0, 0, 1, 0), -- Alliance Ground Force Bunny
    (31845, 0, 0, 1, 0), -- Horde Ground Force Bunny
    (31848, 1, 1, 2, 0), -- Zidormi
    (31880, 0, 0, 1, 0), -- Summoned Plague Cauldron Bunny
    (31887, 0, 0, 1, 0), -- Ebon Blade Marker
    (31888, 0, 0, 1, 0), -- Horde Transport Controller Bunny
    (31915, 0, 0, 1, 0), -- Horde Transport Dropoff Bunny
    (32167, 0, 0, 1, 0), -- Risen Skeleton KC Bunny
    (32168, 0, 0, 1, 0), -- Vicious Geist KC Bunny
    (32171, 0, 0, 1, 0), -- Unkillable Test Dummy 80 Warrior
    (32190, 1, 1, 2, 0), -- Skybreaker Airman
    (32193, 0, 0, 1, 0), -- [DND] Icecrown Airship Bomb
    (32195, 0, 0, 1, 0), -- South Gate KC Bunny
    (32196, 0, 0, 1, 0), -- Central Gate KC Bunny
    (32197, 0, 0, 1, 0), -- North Gate KC Bunny
    (32199, 0, 0, 1, 0), -- Northwest Gate KC Bunny
    (32200, 0, 0, 1, 0), -- Cave In Dummy
    (32202, 0, 0, 1, 0), -- Desolation KC Bunny
    (32224, 0, 0, 1, 0), -- Alliance Transport Controller Bunny
    (32229, 0, 0, 1, 0), -- Drag Drop KC Bunny
    (32242, 0, 0, 1, 0), -- Blue Sample KC Bunny
    (32244, 0, 0, 1, 0), -- Green Sample KC Bunny
    (32245, 0, 0, 1, 0), -- Dark Sample KC Bunny
    (32256, 1, 1, 2, 0), -- Shield Visual Loc Bunny
    (32264, 0, 0, 1, 0), -- Aldur'thar Channel Bunny
    (32277, 0, 0, 1, 0), -- A distant voice
    (32282, 0, 0, 1, 0), -- Wintergrasp Ghost Rune
    (32314, 0, 0, 1, 0), -- Dark Messenger KC Bunny
    (32318, 0, 0, 1, 0), -- Summoning Stone Bunny
    (32319, 0, 0, 1, 0), -- Enslaved Minion Bunny
    (32328, 0, 0, 1, 0), -- [DND] Dalaran Sewer Arena - Controller - Death
    (32331, 0, 0, 1, 0), -- Past You
    (32339, 0, 0, 1, 0), -- [DND] Dalaran Sewer Arena - Controller
    (32366, 0, 0, 1, 0), -- WGA Dummy
    (32427, 0, 0, 1, 0), -- Plague Cauldron Target 01
    (32431, 0, 0, 1, 0), -- Summoned Plague Cauldron Bunny 01
    (32442, 0, 0, 1, 0), -- Plague Cauldron Target 02
    (32445, 0, 0, 1, 0), -- Summoned Plague Cauldron Bunny 02
    (32452, 0, 0, 1, 0), -- Valley of Lost Hope Vehicle
    (32481, 0, 0, 1, 0), -- Aotona
    (32504, 0, 0, 1, 0), -- The Lich King's Presence
    (32556, 0, 0, 1, 0), -- QA Test Dummy 80 Undead
    (32557, 0, 0, 1, 0), -- QA Test Dummy 80 Beast
    (32558, 0, 0, 1, 0), -- QA Test Dummy 80 Dragonkin
    (32559, 0, 0, 1, 0), -- QA Test Dummy 80 Demon
    (32560, 0, 0, 1, 0), -- QA Test Dummy 80 Giant
    (32561, 0, 0, 1, 0), -- QA Test Dummy 80 Elemental
    (32603, 0, 0, 1, 0), -- Hootie
    (32606, 0, 0, 1, 0), -- [DND] Cosmetic Book
    (32608, 0, 0, 1, 0), -- Hodir's Spear Event Bunny
    (32647, 0, 0, 1, 0), -- Warsong Hold Practice Dummy
    (32648, 0, 0, 1, 0), -- Tirion's Gambit Event Credit
    (32662, 0, 0, 1, 0), -- Invisible Stalker (Floating, Uninteractible, Large, Sessile, Custom Phase 1)
    (32694, 0, 0, 1, 0), -- Vesperon Controller Clear Debuff
    (32742, 0, 0, 1, 0), -- Your Corpse
    (32768, 0, 0, 1, 0), -- Invisible Stalker (Floating, Uninteractible, Large, Sessile, Custom Phase 2)
    (32788, 0, 0, 1, 0), -- Moonglade Return Portal
    (32790, 0, 0, 1, 0), -- Moonglade Portal
    (32794, 0, 0, 1, 0), -- Indalamar's 83 Test Dummy
    (32819, 0, 0, 1, 0), -- Plump Turkey Bunny
    (32828, 0, 0, 1, 0), -- Chair Holder
    (32847, 0, 0, 1, 0), -- Unkillable Test Dummy 80 Warrior (Bonus Armor)
    (32853, 0, 0, 1, 0), -- QA Test Dummy 83 Raid Debuff (High Armor)
    (32854, 0, 0, 1, 0), -- Unkillable Test Dummy 83 Warrior (Bonus Armor)
    (32866, 0, 0, 1, 0), -- Overload Visual
    (33045, 0, 0, 1, 0), -- ELM General Purpose Bunny Large (scale x5)
    (33050, 0, 0, 1, 0), -- Unstable Sun Beam
    (33054, 0, 0, 1, 0), -- Thorim Trap Bunny
    (33087, 0, 0, 1, 0), -- Signal Fire Invisman
    (33114, 0, 0, 1, 0), -- Flame Leviathan Seat
    (33138, 0, 0, 1, 0), -- Lightning Orb
    (33143, 0, 0, 1, 0), -- Overload Control Device
    (33146, 0, 0, 1, 0), -- Demolisher Engineering Console (Old)
    (33170, 0, 0, 1, 0), -- Sun Beam
    (33212, 0, 0, 1, 0), -- Hodir's Fury
    (33213, 0, 0, 1, 0), -- Hodir
    (33221, 0, 0, 1, 0), -- Scorch
    (33233, 0, 0, 1, 0), -- Razorscale Controller
    (33241, 0, 0, 1, 0), -- Freya
    (33242, 0, 0, 1, 0), -- Thorim
    (33244, 0, 0, 1, 0), -- Mimiron
    (33245, 0, 0, 1, 0), -- Razorscale Spawner
    (33282, 0, 0, 1, 0), -- Razorscale Harpoon Fire State
    (33339, 0, 0, 1, 0), -- [DND] Tournament - Ranged Target Dummy - Bunny
    (33340, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Target Dummy - Charge Bunny
    (33341, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Target Dummy - Block Bunny
    (33365, 0, 0, 1, 0), -- Thorim's Hammer
    (33367, 0, 0, 1, 0), -- Freya's Ward
    (33370, 0, 0, 1, 0), -- Mimiron's Inferno
    (33489, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Kill Credit - 01 - Weak Guy
    (33490, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Kill Credit - 02 -Speedy
    (33491, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Kill Credit - 03 - Block Guy
    (33492, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Kill Credit - 04 - Strong Guy
    (33493, 0, 0, 1, 0), -- [DND] Tournament - Mounted Melee - Kill Credit - 05 - Ultimate
    (33500, 0, 0, 1, 0), -- Vezax Bunny
    (33661, 0, 0, 1, 0), -- Armsweep Stalker Kologarn
    (33725, 0, 0, 1, 0), -- Thorim Trap Bunny
    (33742, 0, 0, 1, 0), -- Kologarn Pit Kill Bunny
    (33750, 0, 0, 1, 0), -- Desecrated Ground I
    (33751, 0, 0, 1, 0), -- Desecrated Ground II
    (33752, 0, 0, 1, 0), -- Desecrated Ground III
    (33753, 0, 0, 1, 0), -- Desecrated Ground IV
    (33809, 0, 0, 1, 0), -- Rubble Stalker Kologarn
    (33953, 0, 0, 1, 0), -- Small Stone Summoner
    (33958, 0, 0, 1, 0), -- Exploding Goblin Chisel
    (33990, 0, 0, 1, 0), -- Laughing Skull
    (33991, 0, 0, 1, 0), -- Sanity Well
    (34098, 0, 0, 1, 0), -- Auriaya Seeping Essence Stalker
    (34100, 0, 0, 1, 0), -- Algalon Void Zone Visual Stalker
    (34120, 1, 1, 2, 0), -- Brann's Flying Machine
    (34129, 0, 0, 1, 0), -- Nature Bomb
    (34146, 0, 0, 1, 0), -- Snow Mound (4)
    (34150, 0, 0, 1, 0), -- Snow Mound (6)
    (34151, 0, 0, 1, 0), -- Snow Mound (8)
    (34160, 0, 0, 1, 0), -- Watch Wind Rider
    (34161, 1, 1, 2, 0), -- Mechanostriker 54-A
    (34181, 0, 0, 1, 0), -- Focused Laser
    (34188, 0, 0, 1, 0), -- Razorscale Devouring Flame Stalker
    (34194, 0, 0, 1, 0), -- Superheated Winds
    (34203, 1, 1, 2, 0), -- Displacement Device
    (34211, 0, 0, 1, 0), -- Burst Target
    (34213, 0, 0, 1, 0), -- Flaming Rune
    (34223, 0, 0, 1, 0), -- Sapper Explosion
    (34230, 0, 0, 1, 0), -- Emalon Controller
    (34295, 1, 0, 2, 0), -- Lord Magmathar
    (34306, 1, 0, 2, 0), -- Darkshore Wisp
    (34322, 1, 0, 2, 0), -- Whirling Vortex
    (34400, 0, 0, 1, 0), -- Thessera
    (34548, 0, 0, 1, 0), -- Invisible Spell Target - Tahu
    (34562, 0, 0, 1, 0), -- [DND] Stink Bomb Target
    (34660, 0, 0, 1, 0), -- Anub'arak
    (34704, 0, 0, 1, 0), -- Val'kyr Twins Bullet Stalker Dark
    (34720, 0, 0, 1, 0), -- Val'kyr Twins Bullet Stalker Light
    (34743, 0, 0, 1, 0), -- Val'kyr Twins Bullet Controller
    (34755, 0, 0, 1, 0), -- Healing Marker
    (34781, 0, 0, 1, 0), -- Champions Controller
    (34784, 0, 0, 1, 0), -- Legion Flame
    (34832, 1, 0, 2, 0), -- Warsong War Rider
    (34854, 0, 0, 1, 0), -- Fire Bomb
    (34862, 0, 0, 1, 0), -- Nerubian Burrow
    (34886, 1, 0, 2, 0), -- Kalimdor Eagle
    (34897, 1, 0, 2, 0), -- Black Drake
    (34982, 1, 0, 2, 0), -- Emerald Spirit
    (35009, 0, 0, 1, 0), -- North Sea Kraken Bunny
    (35014, 0, 0, 1, 0), -- Beasts Controller
    (35015, 0, 0, 1, 0), -- Burning Breath Koralon Stalker
    (35016, 0, 0, 1, 0), -- [ph] Argent Raid Spectator - Generic Bunny
    (35018, 0, 0, 1, 0), -- Stalker Koralon
    (35089, 0, 0, 1, 0), -- Black Knight Spell Proxy
    (35106, 0, 0, 1, 0), -- Black Knight Caster
    (35176, 0, 0, 1, 0), -- Slime Pool
    (35339, 0, 0, 1, 0), -- Boat Fire
    (35376, 0, 0, 1, 0), -- Jump Target
    (35377, 0, 0, 1, 0), -- Door Fire
    (35383, 1, 1, 2, 0), -- Bloodfang Lurker (roof)
    (35385, 0, 0, 1, 0), -- Bloodfang Lurker Jump-to
    (35393, 0, 0, 1, 0), -- Raging Vortex
    (35491, 1, 1, 2, 0), -- Black Knight's Skeletal Gryphon
    (35492, 1, 1, 2, 0), -- Zephyr Guard
    (35587, 0, 0, 1, 0), -- Argent Peacekeeper
    (35604, 0, 0, 1, 0), -- Arelas Brightstar
    (35651, 0, 0, 1, 0), -- Purple Ground Rune Argent Raid
    (35753, 0, 0, 1, 0), -- Krennan Aranas
    (35779, 1, 0, 2, 0), -- Korrah's Mount
    (35820, 0, 0, 1, 0), -- Beasts Taplist
    (35821, 0, 0, 1, 0), -- Champions Taplist
    (35876, 0, 0, 1, 0), -- Crusader's White Warhorse
    (36093, 0, 0, 1, 0), -- Vault Stalker
    (36099, 0, 0, 1, 0), -- Anub'arak Tap List
    (36143, 0, 0, 1, 0), -- Gyrochoppa
    (36155, 0, 0, 1, 0), -- Anzim Controller Bunny
    (36173, 0, 0, 1, 0), -- Innocuous Scarab
    (36177, 0, 0, 1, 0), -- Invisible Stalker (Floating, Uninteractible, Infinite, Sessile, Quest Phase 4)
    (36212, 0, 0, 1, 0), -- [DND] Crazed Apothecary Generator
    (36477, 1, 1, 2, 0), -- Krick
    (36505, 0, 0, 1, 0), -- Sling Rocket
    (36536, 0, 0, 1, 0), -- Well of Souls
    (36643, 0, 0, 1, 0), -- [DND] Valentine Boss Manager
    (36649, 1, 0, 2, 0), -- Malicion
    (36676, 1, 0, 2, 0), -- Azuregos
    (36689, 1, 0, 2, 0), -- Kalecgos
    (36719, 0, 0, 1, 0), -- Pterrordax Scavenger
    (36737, 0, 0, 1, 0), -- Invisible Stalker
    (36793, 1, 0, 2, 0), -- Valormok Wind Rider
    (36944, 0, 0, 1, 0), -- Wants Shirts
    (36945, 0, 0, 1, 0), -- Wants Pants
    (36946, 0, 0, 1, 0), -- Wants Unmentionables
    (37020, 0, 0, 1, 0), -- Loaned Gyrocopter
    (37094, 0, 0, 1, 0), -- Crucible of Souls
    (37139, 1, 0, 2, 0), -- Wings of Steel
    (37143, 1, 0, 2, 0), -- Heart of Arkkoroc Aura Bunny
    (37147, 1, 0, 2, 0), -- Military Gyrocopter
    (37203, 0, 0, 1, 0), -- Fourth And Goal Target
    (37219, 1, 1, 2, 0), -- Barrens Fire Cyclone
    (37231, 0, 0, 1, 0), -- Rope Beam Stalker
    (37232, 1, 1, 2, 0), -- Nerub'ar Broodling
    (37501, 1, 1, 2, 0), -- Nerub'ar Champion
    (37502, 1, 1, 2, 0), -- Nerub'ar Webweaver
    (37503, 0, 0, 1, 0), -- Sindragosa's Ward
    (37682, 0, 0, 1, 0), -- 447 Fireworks Bunny
    (37745, 0, 0, 1, 0), -- Quel'Delar
    (37755, 1, 1, 2, 0), -- Sindragosa
    (37801, 0, 0, 1, 0), -- Shadow's Edge Bunny
    (37804, 0, 0, 1, 0), -- Kaja'Cola Balloon
    (37814, 0, 0, 1, 0), -- Shadow's Edge Axe Bunny
    (37849, 0, 0, 1, 0), -- Sartharion Image
    (37850, 0, 0, 1, 0), -- Anub'Rekhan Image
    (37851, 0, 0, 1, 0), -- Noth the Plaguebringer Image
    (37853, 0, 0, 1, 0), -- Instructor Razuvious Image
    (37854, 0, 0, 1, 0), -- Patchwerk Image
    (37855, 0, 0, 1, 0), -- Malygos Image
    (37856, 0, 0, 1, 0), -- Flame Leviathan Image
    (37858, 0, 0, 1, 0), -- Razorscale Image
    (37859, 0, 0, 1, 0), -- Ignis the Furnace Master Image
    (37861, 0, 0, 1, 0), -- XT-002 Deconstructor Image
    (37862, 0, 0, 1, 0), -- Lord Jaraxxus Image
    (37864, 0, 0, 1, 0), -- Lord Marrowgar Image
    (37872, 0, 0, 1, 0), -- Capturing The Unknown - Bunny 1
    (37895, 0, 0, 1, 0), -- Capturing The Unknown - Bunny 2
    (37896, 0, 0, 1, 0), -- Capturing The Unknown - Bunny 3
    (37897, 0, 0, 1, 0), -- Capturing The Unknown - Bunny 4
    (37906, 0, 0, 1, 0), -- Imprisoned Soul
    (37918, 0, 0, 1, 0), -- Column of Frost
    (37974, 1, 0, 2, 0), -- Desolation Wind Rider
    (37978, 1, 0, 2, 0), -- Triumph War Gryphon
    (38068, 0, 0, 1, 0), -- Mana Void
    (38121, 0, 0, 1, 0), -- Soul Feast Kill Credit Bunny
    (38199, 0, 0, 1, 0), -- Frostblade
    (38204, 0, 0, 1, 0), -- Big Love Rocket
    (38289, 0, 0, 1, 0), -- Unholy Infusion KC Bunny
    (38310, 0, 0, 1, 0), -- Invisible Stalker (Float, Uninteractible, LargeAOI) (3.00)
    (38353, 0, 0, 1, 0), -- Blood Queen Orb
    (38448, 1, 1, 2, 0), -- Faceless of the Deep
    (38452, 0, 0, 1, 0), -- Sea Witch Channel Bunny
    (38503, 0, 0, 1, 0), -- Blood Infusion Quest Credit Bunny
    (38527, 0, 0, 1, 0), -- Shadowmourne Bunny
    (38528, 0, 0, 1, 0), -- Shadowmourne Axe Bunny
    (38540, 1, 0, 2, 0), -- Captured Riding Bat
    (38546, 0, 0, 1, 0), -- Frost Infusion Quest Credit
    (38547, 0, 0, 1, 0), -- Sindragosa Quest Credit
    (38548, 0, 0, 1, 0), -- Vile Gas Stalker
    (38587, 0, 0, 1, 0), -- Professor Putricide Proxy Bunny
    (38588, 0, 0, 1, 0), -- Blood Queen Proxy Bunny
    (38710, 0, 0, 1, 0), -- Frostmourne Soul Transform Visual
    (38757, 0, 0, 1, 0), -- Defile
    (38778, 0, 0, 1, 0), -- Bloodbathed Frostbrood Vanquisher
    (38907, 0, 0, 1, 0), -- Queue Controller
    (38918, 0, 0, 1, 0), -- Flying Bomber
    (38929, 0, 0, 1, 0), -- Flying Bomber
    (38983, 0, 0, 1, 0), -- Shadow of Agamand (NPC Version)
    (39023, 0, 0, 1, 0), -- [DND] TB Event Bunny
    (39039, 0, 0, 1, 0), -- Gnomeregan Stealth Fighter
    (39046, 0, 0, 1, 0), -- Crimson Deathcharger
    (39057, 0, 0, 1, 0), -- [DND] Fire Strat Auto
    (39074, 0, 0, 1, 0), -- Pride of Kezan
    (39103, 1, 0, 2, 0), -- Twilight Seeker
    (39135, 0, 0, 1, 0), -- Prologue Portal Bunny
    (39137, 0, 0, 1, 0), -- Shadow Trap
    (39169, 0, 0, 1, 0), -- Lost Isles Mail Bird
    (39259, 0, 0, 1, 0), -- Gnomeregan Flying Machine
    (39320, 0, 0, 1, 0), -- Durotar Watershed Telescope 01 (Raggaran)
    (39345, 0, 0, 1, 0), -- Durotar Watershed Telescope 02 (Tekla)
    (39346, 0, 0, 1, 0), -- Durotar Watershed Telescope 03 (Misha)
    (39347, 0, 0, 1, 0), -- Durotar Watershed Telescope 04 (Zen'Taji)
    (39355, 0, 0, 1, 0), -- [DND] Salute Quest Credit Bunny
    (39356, 0, 0, 1, 0), -- [DND] Roar Quest Credit Bunny
    (39361, 0, 0, 1, 0), -- [DND] Dance Quest Credit Bunny
    (39362, 0, 0, 1, 0), -- [DND] Cheer Quest Credit Bunny
    (39396, 0, 0, 1, 0), -- 'Thunderflash'
    (39466, 0, 0, 1, 0), -- Motivated Citizen
    (39581, 0, 0, 1, 0), -- Poster Marker - Orgrimmar
    (39624, 0, 0, 1, 0), -- Motivated Citizen
    (39670, 1, 0, 2, 0), -- Raz the Crazed
    (39672, 0, 0, 1, 0), -- Poster Marker - Stormwind
    (39683, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - Eject
    (39691, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - Move 1
    (39692, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - Move 2
    (39695, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - Move 3
    (39703, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - Attack
    (39710, 0, 0, 1, 0), -- Aviana's Guardian
    (39724, 1, 0, 2, 0), -- Horrorguard
    (39735, 1, 1, 2, 0), -- Gnomeregan Multi-Bomber
    (39743, 0, 0, 1, 0), -- [DND] GT Bomber Bunny
    (39744, 1, 1, 2, 0), -- [DND] GT Bomber Bunny 2
    (39794, 0, 0, 1, 0), -- Zarithrian Spawn Stalker
    (39809, 0, 0, 1, 0), -- Globe of Azeroth
    (39829, 0, 0, 1, 0), -- Burning Exile
    (39830, 0, 0, 1, 0), -- Glacial Exile
    (39831, 0, 0, 1, 0), -- Thundering Windfury
    (39833, 0, 0, 1, 0), -- Twilight Buzzard
    (39841, 1, 1, 2, 0), -- [DND] Boom Bunny
    (39853, 0, 0, 1, 0), -- Taerar
    (39903, 0, 0, 1, 0), -- Irradiator 3000
    (40001, 0, 0, 1, 0), -- Combustion
    (40029, 0, 0, 1, 0), -- Meteor Strike
    (40039, 0, 0, 1, 0), -- Durak's Shield (stage 4)
    (40041, 0, 0, 1, 0), -- Meteor Strike
    (40042, 0, 0, 1, 0), -- Meteor Strike
    (40043, 0, 0, 1, 0), -- Meteor Strike
    (40044, 0, 0, 1, 0), -- Meteor Strike
    (40055, 0, 0, 1, 0), -- Meteor Strike
    (40079, 0, 0, 1, 0), -- Feralas Wisp
    (40091, 0, 0, 1, 0), -- Orb Rotation Focus
    (40135, 0, 0, 1, 0), -- Consumption
    (40151, 0, 0, 1, 0), -- Combat Stalker
    (40199, 0, 0, 1, 0), -- Tiki Warrior
    (40218, 0, 0, 1, 0), -- Spy Frog Credit
    (40260, 0, 0, 1, 0), -- Troll Volunteer
    (40263, 0, 0, 1, 0), -- Tiki Warrior
    (40264, 0, 0, 1, 0), -- Troll Volunteer
    (40301, 0, 0, 1, 0), -- Tiger Matriarch Credit
    (40320, 0, 0, 1, 0), -- Valiona
    (40387, 0, 0, 1, 0), -- Omen Event Credit
    (40428, 0, 0, 1, 0), -- [DND] Quest Credit Bunny - ET Battle
    (40460, 1, 0, 2, 0), -- Activated Flameward
    (40479, 0, 0, 1, 0), -- Camera Vehicle
    (40506, 0, 0, 1, 0), -- Explosion Bunny
    (40573, 1, 0, 2, 0), -- Twilight Stormwaker
    (40617, 0, 0, 1, 0), -- [DND] Bunny
    (40655, 1, 1, 2, 0), -- Ozumat
    (40663, 1, 1, 2, 0), -- River Boat
    (40687, 1, 0, 2, 0), -- Young Twilight Drake
    (40700, 0, 1, 1, 0), -- Southsea Rowboat
    (40702, 0, 1, 1, 0), -- Southsea Boarder
    (40705, 0, 1, 1, 0), -- Southsea Boarder
    (40707, 0, 1, 1, 0), -- Southsea Rowboat
    (40719, 0, 0, 1, 0), -- Aviana's Guardian
    (40780, 1, 0, 2, 0), -- Emerald Drake
    (40784, 1, 1, 2, 0), -- Dark Fissure
    (40816, 1, 0, 2, 0), -- Aronus
    (40942, 0, 0, 1, 0), -- Warsong Wing Commander
    (41019, 0, 0, 1, 0), -- Rope Ladder
    (41027, 1, 0, 2, 0), -- Wormwing Screecher
    (41028, 1, 0, 2, 0), -- Wormwing Swifttalon
    (41096, 1, 1, 2, 0), -- Naz'jar Spiritmender
    (41112, 1, 0, 2, 0), -- Marion Wormwing
    (41114, 1, 0, 2, 0), -- Thisalee Crow
    (41226, 1, 0, 2, 0), -- Sethria's Hatchling
    (41261, 1, 0, 2, 0), -- Sethria
    (41270, 1, 1, 2, 0), -- Onyxia
    (41287, 0, 0, 1, 0), -- Druid of the Talon
    (41308, 1, 0, 2, 0), -- Aviana
    (41372, 1, 0, 2, 0), -- Frostmane Retreat North
    (41373, 1, 0, 2, 0), -- Frostmane Retreat South
    (41376, 1, 1, 2, 0), -- Nefarian
    (41382, 1, 0, 2, 0), -- Covert Ops Flying Machine
    (41418, 0, 0, 1, 0), -- Krom'gar Hot Air Balloon
    (41475, 1, 1, 2, 0), -- Oil Pump
    (41768, 0, 0, 1, 0), -- Icy Tomb
    (41839, 0, 0, 1, 0), -- [DND] Controller
    (41918, 1, 1, 2, 0), -- Animated Bone Warrior
    (41948, 1, 1, 2, 0), -- Chromatic Prototype
    (41987, 0, 0, 1, 0), -- Krom'gar Hot Air Balloon
    (42015, 1, 0, 2, 0), -- Gnomish Bomber
    (42016, 0, 0, 1, 0), -- Gnomish Flying Machine
    (42389, 1, 0, 2, 0), -- Tortolla's Chain Bunny
    (42469, 0, 0, 1, 0), -- Kor the Immovable
    (42516, 1, 0, 2, 0), -- Twilight Swarmer
    (42522, 0, 0, 1, 0), -- Stone Drake
    (42523, 1, 0, 2, 0), -- Stone Bat
    (42595, 1, 1, 2, 0), -- Shadowblaze Flashpoint
    (42596, 1, 1, 2, 0), -- Shadowblaze
    (42657, 1, 0, 2, 0), -- Hyjal Eagle
    (42659, 1, 0, 2, 0), -- Hyjal Screecher
    (42663, 1, 0, 2, 0), -- Hyjal Owl
    (42824, 1, 0, 2, 0), -- Twilight Pyremaw
    (42837, 1, 0, 2, 0), -- Gurubashi Bat Rider
    (42887, 0, 0, 1, 0), -- Stormbeak
    (42962, 0, 0, 1, 0), -- Stormbeak
    (43241, 0, 0, 1, 0), -- Wings of Hir'eek
    (43443, 0, 1, 1, 0), -- Keeshan's Riverboat
    (43450, 0, 1, 1, 0), -- Keeshan's Riverboat
    (43534, 1, 0, 2, 0), -- Surface to Other Surface Transport
    (43561, 0, 1, 1, 0), -- Bloodsail Rowboat
    (43641, 0, 0, 1, 0), -- Aeosera
    (43656, 1, 1, 2, 0), -- Dominion Stalker
    (43683, 1, 0, 2, 0), -- Goblin Barrage Balloon
    (43717, 0, 1, 1, 0), -- Brashtide Crewman
    (43735, 1, 0, 2, 0), -- Elementium Monstrosity
    (43737, 0, 0, 1, 0), -- Rumbling Betrayer
    (43787, 1, 0, 2, 0), -- Blackrock Drake Rider
    (43790, 0, 1, 1, 0), -- Brashtide Attack Boat
    (43971, 1, 0, 2, 0), -- Stonescale Drake
    (44077, 0, 0, 1, 0), -- Stone Drake
    (44148, 0, 0, 1, 0), -- Stonescale Matriarch
    (44184, 1, 0, 2, 0), -- Loch Buzzard
    (44189, 0, 0, 1, 0), -- Twilight Pyremaw
    (44261, 1, 1, 2, 0), -- Sharptalon Eagle
    (44481, 1, 0, 2, 0), -- Diseased Hawk
    (44483, 1, 1, 2, 0), -- Kirtonos the Herald
    (44566, 0, 0, 1, 0), -- Ozumat
    (44581, 0, 0, 1, 0), -- Ozumat Vehicle
    (44628, 1, 0, 2, 0), -- Golden Eagle
    (44656, 0, 0, 1, 0), -- Ozumat Add Spawner
    (45005, 1, 1, 2, 0), -- Wyvern
    (45030, 0, 0, 1, 0), -- Ozumat Vehicle, Big
    (45191, 0, 0, 1, 0), -- Boulder Platform
    (45239, 1, 0, 2, 0), -- Lesser Val'kyr
    (45447, 1, 0, 2, 0), -- Arikara
    (45455, 1, 1, 2, 0), -- Slipstream
    (45463, 1, 0, 2, 0), -- The Rattle of Bones
    (45466, 1, 0, 2, 0), -- The Writ of History
    (45468, 1, 0, 2, 0), -- The Drums of War
    (45621, 1, 1, 2, 0), -- Elemental Guard
    (45672, 1, 1, 2, 0), -- Naz'jar Soldier
    (45710, 0, 0, 1, 0), -- Fall Catcher
    (45716, 1, 0, 2, 0), -- Orsis Survivor Vehicle
    (45764, 0, 0, 1, 0), -- Archmage Target
    (45993, 1, 1, 2, 0), -- Theralion
    (46024, 1, 0, 2, 0), -- Orsis Colossus Vehicle
    (46087, 1, 0, 2, 0), -- Orsis Colossus Vehicle
    (46185, 0, 0, 1, 0), -- Sanitron 500
    (46304, 1, 0, 2, 0), -- Unstable Twilight
    (46337, 1, 0, 2, 0), -- Torth
    (46663, 1, 0, 2, 0), -- Stormbeak
    (46753, 1, 1, 2, 0), -- Al'Akir
    (46861, 1, 0, 2, 0), -- Nyxondra
    (46974, 1, 0, 2, 0), -- Failed Recruit
    (47066, 1, 1, 2, 0), -- Slipstream
    (47097, 1, 0, 2, 0), -- Cloud
    (47103, 1, 0, 2, 0), -- Cowardly Deathwing
    (47175, 1, 1, 2, 0), -- Stormling
    (47221, 0, 0, 1, 0), -- Schnottz Supply Chopper
    (47228, 1, 0, 2, 0), -- General Purpose Bunny JMF
    (47342, 0, 0, 1, 0), -- Twister
    (47372, 1, 0, 2, 0), -- Gloomwing
    (47467, 0, 0, 1, 0), -- Brotherhood Flying Machine
    (47482, 1, 0, 2, 0), -- Jora "Nobbly" Wildwing
    (47483, 0, 0, 1, 0), -- Highperch Prideling
    (47503, 1, 0, 2, 0), -- Heartrazor
    (47504, 1, 0, 2, 0), -- Heartrazor
    (47507, 1, 0, 2, 0), -- Heartrazor
    (47508, 1, 0, 2, 0), -- Heartrazor
    (47509, 1, 0, 2, 0), -- Richtofen's Wind Rider
    (47510, 1, 0, 2, 0), -- Twilight Skymaster Richtofen
    (47511, 1, 0, 2, 0), -- Highperch Prideling
    (47669, 1, 0, 2, 0), -- Torth
    (47739, 1, 1, 2, 0), -- "Captain" Cookie
    (47777, 1, 1, 2, 0), -- Animus
    (47806, 0, 0, 1, 0), -- Relentless Storm Initial Vehicle
    (47807, 1, 1, 2, 0), -- Relentless Storm
    (47872, 1, 0, 2, 0), -- Human Seedling
    (48137, 1, 0, 2, 0), -- Monstrous Macaw
    (48138, 1, 0, 2, 0), -- Brilliant Clayscraper
    (48155, 1, 0, 2, 0), -- Saltspray Gull
    (48165, 0, 0, 1, 0), -- Fall Catcher
    (48190, 0, 0, 1, 0), -- Lightning Clouds
    (48196, 0, 0, 1, 0), -- Lightning Clouds Extra Visuals
    (48197, 1, 0, 2, 0), -- Dragonmaw Black Drake
    (48214, 0, 0, 1, 0), -- Schnottz Fighter
    (48382, 1, 0, 2, 0), -- Gloomwing
    (48428, 1, 0, 2, 0), -- Myzerian
    (48436, 0, 0, 1, 0), -- Twilight Drake
    (48725, 1, 0, 2, 0), -- Horrorguard
    (49044, 0, 0, 1, 0), -- Agatha
    (49128, 0, 0, 1, 0), -- Daschla
    (49251, 1, 0, 2, 0), -- Wild Gryphon
    (49526, 1, 1, 2, 0), -- Corla Quest Bang
    (49820, 0, 0, 1, 0), -- Deathwing
    (49844, 1, 0, 2, 0), -- Silky Moth
    (49928, 1, 1, 2, 0), -- Crimson Moth
    (50014, 1, 0, 2, 0), -- Twilight Rift
    (50057, 1, 0, 2, 0), -- Blazewing
    (50062, 1, 0, 2, 0), -- Aeonaxx
    (50260, 0, 0, 1, 0), -- Gilnean Crow
    (50372, 0, 0, 1, 0), -- Aradne
    (50401, 1, 0, 2, 0), -- Titan Mechanism
    (51157, 1, 1, 2, 0), -- Golden Orb
    (51190, 0, 0, 1, 0), -- Vision of the Naaru
    (51384, 1, 1, 2, 0), -- Forsaken Bat
    (51608, 0, 0, 1, 0), -- Barrier Cosmetic Stalker (DND)
    (52160, 1, 0, 2, 0), -- Wave of Agony
    (52201, 1, 0, 2, 0), -- Silver Bullet X-831
    (52373, 1, 1, 2, 0), -- Florawing Needler
    (52375, 1, 1, 2, 0), -- Florawing Needler
    (52376, 1, 1, 2, 0), -- Florawing Needler
    (52524, 0, 0, 1, 0), -- Cinderweb Spinner
    (52581, 0, 0, 1, 0), -- Cinderweb Drone
    (52594, 1, 0, 2, 0), -- Goldwing Hawk
    (52595, 1, 0, 2, 0), -- Alpine Songbird
    (52596, 1, 0, 2, 0), -- Forest Owl
    (52597, 0, 0, 1, 0), -- Wings of Aviana
    (52638, 1, 0, 2, 0), -- Amani Kidnapper
    (52688, 0, 0, 1, 0), -- Hyjal Bear Cub
    (52848, 1, 0, 2, 0), -- Hyjal Assault Trooper
    (53082, 1, 1, 2, 0), -- Spiderweb Filament
    (53158, 1, 1, 2, 0), -- Volcano Fire Bunny
    (53267, 1, 0, 2, 0), -- Andrazor
    (53371, 1, 0, 2, 0), -- Hallegosa
    (53392, 1, 0, 2, 0), -- Kalecgos
    (53394, 1, 0, 2, 0), -- Blue Dragon
    (53408, 1, 0, 2, 0), -- Blue Drake
    (53422, 1, 0, 2, 0), -- Dragonwrath, Tarecgosa's Rest
    (53472, 1, 0, 2, 0), -- Thyrinar
    (53541, 1, 1, 2, 0), -- Incindiary Cloud
    (53554, 1, 1, 2, 0), -- Blazing Power
    (53698, 1, 1, 2, 0), -- Fiery Tornado
    (53879, 1, 1, 2, 0), -- Deathwing
    (53889, 1, 1, 2, 0), -- Corrupted Blood
    (53890, 1, 1, 2, 0), -- Hideous Amalgamation
    (54120, 1, 0, 2, 0), -- Balloon Bunny
    (54314, 1, 0, 2, 0), -- Alysra
    (54385, 0, 0, 1, 0), -- Jump
    (54401, 1, 0, 2, 0), -- Naresir Stormfury
    (54402, 1, 0, 2, 0), -- Lurah Wrathvine
    (54476, 1, 1, 2, 0), -- Nozdormu
    (54543, 1, 0, 2, 0), -- Time-Twisted Drake
    (54574, 1, 1, 2, 0), -- Moonlance
    (54580, 1, 1, 2, 0), -- Moonlance
    (54581, 1, 1, 2, 0), -- Moonlance
    (54582, 1, 1, 2, 0), -- Moonlance
    (54647, 0, 0, 1, 0), -- Wayward Landing Fire Bunny
    (54787, 0, 0, 1, 0), -- Huo
    (54864, 1, 1, 2, 0), -- Hammer of Divinity
    (54871, 0, 0, 1, 0), -- Fire Cave Bunny
    (54880, 0, 0, 1, 0), -- Camera Bunny
    (54886, 0, 0, 1, 0), -- Bunny: Final Stand Controller
    (54889, 0, 0, 1, 0), -- Bunny: Sapphire Fire
    (54937, 0, 0, 1, 0), -- Totally Generic Bunny (Art of War Phase)
    (54958, 0, 0, 1, 0), -- Huo
    (54994, 0, 0, 1, 0), -- Ship Vehicle Bunny
    (54997, 0, 0, 1, 0), -- Attack Plane Vehicle Bunny 01
    (55000, 0, 0, 1, 0), -- Attack Plane Vehicle Bunny 02
    (55058, 0, 0, 1, 0), -- Camera Bunny
    (55076, 0, 0, 1, 0), -- Camera Bunny 02
    (55090, 0, 0, 1, 0), -- Subtitle Bunny TEMP
    (55177, 0, 0, 1, 0), -- Bunny: Sapphire Explosion
    (55213, 0, 0, 1, 0), -- Shu
    (55294, 1, 1, 2, 0), -- Ultraxion
    (55298, 0, 0, 1, 0), -- Bunny: Investigating the Ship
    (55340, 0, 0, 1, 0), -- Bungie Beam Bunny 01
    (55376, 0, 0, 1, 0), -- Alchemy Bunny
    (55377, 1, 1, 2, 0), -- Purifying Light
    (55415, 0, 0, 1, 0), -- Life Warden
    (55544, 1, 0, 2, 0), -- Maw of Shu'ma
    (55549, 0, 0, 1, 0), -- Life Warden
    (55620, 0, 0, 1, 0), -- Bunny: Seaplane Fire
    (55649, 0, 0, 1, 0), -- Shang Xi's Hot Air Balloon
    (55650, 0, 0, 1, 0), -- Shang Xi's Hot Air Balloon
    (55682, 0, 0, 1, 0), -- Camera Bunny
    (55685, 0, 0, 1, 0), -- Uplifting Draft
    (55708, 0, 0, 1, 0), -- Generic Bunny
    (55728, 0, 0, 1, 0), -- Ice Wall Exit Stalker
    (55736, 0, 0, 1, 0), -- Camera Target Bunny
    (55769, 0, 0, 1, 0), -- Explosion Bunny 2
    (55782, 0, 0, 1, 0), -- The Sapphire Fire Bunny
    (55786, 0, 0, 1, 0), -- Zhao-Ren
    (55840, 0, 0, 1, 0), -- Shadow Bunny
    (55841, 0, 0, 1, 0), -- Shadow Bunny
    (55913, 0, 0, 1, 0), -- Champion of Time
    (55914, 0, 0, 1, 0), -- Champion of the Emerald Dream
    (55918, 0, 0, 1, 0), -- Shang Xi's Hot Air Balloon
    (55971, 1, 1, 2, 0), -- Deathwing
    (55998, 0, 0, 1, 0), -- Dust Bunny
    (56004, 0, 0, 1, 0), -- Jade Forest Arrival Bunny
    (56014, 0, 0, 1, 0), -- Tan Chao Bunny
    (56016, 0, 0, 1, 0), -- Meditation Bunny
    (56023, 0, 0, 1, 0), -- Beam Target Bunny
    (56024, 0, 0, 1, 0), -- Generic Bunny 5.0
    (56071, 0, 0, 1, 0), -- Bunny: Airborne Flack
    (56088, 0, 0, 1, 0), -- Bunny: Seaplane Fire
    (56089, 0, 0, 1, 0), -- Bunny: Seaplane Fire
    (56090, 0, 0, 1, 0), -- Bunny: Seaplane Fire
    (56091, 0, 0, 1, 0), -- Bunny: Seaplane Fire
    (56093, 0, 0, 1, 0), -- Bunny: Horde Cannon
    (56098, 0, 0, 1, 0), -- Meditation Bunny
    (56099, 1, 1, 2, 0), -- Alexstrasza
    (56100, 1, 1, 2, 0), -- Ysera
    (56101, 1, 1, 2, 0), -- Kalecgos
    (56102, 1, 1, 2, 0), -- Nozdormu
    (56103, 1, 1, 2, 0), -- Thrall
    (56109, 0, 0, 1, 0), -- Beam Target Bunny
    (56158, 0, 0, 1, 0), -- Quest Bang Bunny
    (56167, 1, 1, 2, 0), -- Arm Tentacle
    (56168, 1, 1, 2, 0), -- Wing Tentacle
    (56173, 0, 0, 1, 0), -- Deathwing
    (56249, 0, 0, 1, 0), -- Twilight Assaulter
    (56250, 0, 0, 1, 0), -- Twilight Assaulter
    (56251, 0, 0, 1, 0), -- Twilight Assaulter
    (56252, 0, 0, 1, 0), -- Twilight Assaulter
    (56270, 0, 0, 1, 0), -- Beam Target Bunny
    (56412, 0, 0, 1, 0), -- Camera Bunny
    (56479, 0, 0, 1, 0), -- Legacy of Liu Lang
    (56484, 0, 0, 1, 0), -- Serpent's Spine Marksman
    (56551, 0, 0, 1, 0), -- Outhouse Line Bunny 00
    (56553, 0, 0, 1, 0), -- Outhouse Line Bunny 01
    (56554, 0, 0, 1, 0), -- Outhouse Line Bunny 02
    (56555, 0, 0, 1, 0), -- Outhouse Line Bunny 03
    (56556, 0, 0, 1, 0), -- Outhouse Line Bunny 04
    (56557, 0, 0, 1, 0), -- Outhouse Line Bunny 05
    (56587, 1, 0, 2, 0), -- Twilight Assault Drake
    (56589, 0, 0, 1, 0), -- Striker Ga'dok
    (56630, 1, 1, 2, 0), -- Alexstrasza the Life-Binder
    (56664, 1, 1, 2, 0), -- Kalecgos
    (56665, 1, 1, 2, 0), -- Ysera the Awakened
    (56666, 1, 1, 2, 0), -- Nozdormu the Timeless One
    (56667, 1, 1, 2, 0), -- Thrall
    (56668, 1, 1, 2, 0), -- The Dragon Soul
    (56676, 0, 0, 1, 0), -- Shen-zin Su
    (56706, 0, 0, 1, 0), -- Krik'thik Bombardier
    (56739, 0, 0, 1, 0), -- Hozen Hanging Bunny
    (56754, 0, 0, 1, 0), -- Azure Serpent
    (56781, 1, 0, 2, 0), -- Goriona
    (56799, 0, 0, 1, 0), -- Krik'thik Bombadier
    (56846, 1, 1, 2, 0), -- Arm Tentacle
    (56855, 1, 0, 2, 0), -- Twilight Assault Drake
    (56865, 0, 0, 1, 0), -- Aqua Dancer
    (56867, 0, 0, 1, 0), -- Fiery Trickster
    (56879, 0, 0, 1, 0), -- Krik'thik Glider
    (56893, 0, 0, 1, 0), -- Jade Fire
    (56895, 0, 0, 1, 0), -- Weak Spot
    (56911, 0, 0, 1, 0), -- Mantid Munitions
    (56912, 0, 0, 1, 0), -- Krik'thik Engulfer
    (56914, 0, 0, 1, 0), -- Flamebringer
    (56918, 0, 0, 1, 0), -- Mantid Munitions
    (56922, 1, 0, 2, 0), -- Twilight Infiltrator
    (56929, 0, 0, 1, 0), -- Krik'thik Protectorate
    (57190, 1, 0, 2, 0), -- Engine Stalker
    (57244, 0, 0, 1, 0), -- Camera Bunny
    (57263, 0, 0, 1, 0), -- Camera Target Bunny
    (57271, 0, 0, 1, 0), -- Camera Bunny
    (57279, 0, 0, 1, 0), -- Camera Target Bunny
    (57282, 0, 0, 1, 0), -- Rope Climber
    (57328, 1, 0, 2, 0), -- Travel to Wyrmrest Temple
    (57377, 1, 0, 2, 0), -- Travel to the Eye of Eternity
    (57378, 1, 0, 2, 0), -- Travel to the deck of The Skyfire
    (57379, 1, 0, 2, 0), -- Travel to Wyrmrest Summit
    (57443, 1, 0, 2, 0), -- Travel to The Maelstrom
    (57464, 0, 0, 1, 0), -- Hozen Hanging Bunny
    (57636, 0, 0, 1, 0), -- Stack of Reeds
    (57667, 0, 0, 1, 0), -- Stack of Planks
    (57668, 0, 0, 1, 0), -- Stack of Blocks
    (57690, 0, 0, 1, 0), -- Tiger Pillar Stand
    (57691, 0, 0, 1, 0), -- Tiger Pillar
    (57750, 1, 0, 2, 0), -- Jaomin Ro
    (57769, 0, 0, 1, 0), -- Shen-zin Su
    (57779, 0, 0, 1, 0), -- Huo
    (57795, 0, 0, 1, 0), -- Twilight Assaulter
    (57811, 0, 0, 1, 0), -- Bell Bunny
    (57814, 0, 0, 1, 0), -- Bell Bunny Light
    (57882, 1, 0, 2, 0), -- Travel to Wyrmrest Base
    (57927, 1, 0, 2, 0), -- War Serpent
    (58317, 0, 0, 1, 0), -- Camera Bunny
    (58423, 0, 0, 1, 0), -- Cloud Ring
    (58528, 0, 0, 1, 0), -- Golden Cloud Serpent
    (58550, 0, 0, 1, 0), -- Eastern Fire Summon Bunny
    (58561, 0, 0, 1, 0), -- Northern Fire Summon Bunny
    (58571, 0, 0, 1, 0), -- Southern Fire Summon Bunny
    (58574, 0, 0, 1, 0), -- Camera Bunny
    (58584, 0, 0, 1, 0), -- Camera Target Bunny
    (58595, 0, 0, 1, 0), -- Camera Bunny
    (58604, 0, 0, 1, 0), -- Spider Wall Bunny
    (58629, 0, 0, 1, 0), -- Camera Target Bunny
    (58640, 0, 0, 1, 0), -- Frigid Grasp
    (58663, 0, 0, 1, 0), -- Camera Target Bunny
    (58728, 0, 0, 1, 0), -- Western Fire Summon Bunny
    (58812, 0, 0, 1, 0), -- Hateful Essence
    (58869, 0, 0, 1, 0), -- Blanche's Lightning Rod
    (59018, 0, 0, 1, 0), -- Tracking Carrot
    (59198, 0, 0, 1, 0), -- Dragon Breath Target
    (59205, 0, 0, 1, 0), -- Mantid Munitions
    (59206, 0, 0, 1, 0), -- Mantid Munitions
    (59226, 0, 0, 1, 0), -- Event Bunny
    (59227, 0, 0, 1, 0), -- Wander's Colossal Book of Shadow Puppets
    (59415, 0, 0, 1, 0), -- Meditation Bunny
    (59446, 0, 0, 1, 0), -- Spirit Particle Bunny
    (59512, 1, 1, 2, 0), -- Wall of Suds
    (59591, 0, 0, 1, 0), -- The Master's Flame
    (59635, 0, 0, 1, 0), -- Viletongue Warrior Cliff-Scaling Vehicle
    (59650, 0, 0, 1, 0), -- Viletongue Skirmisher Cliff-Scaling Vehicle
    (59677, 0, 0, 1, 0), -- General Purpose Bunny JMF (Look 2, Flying)
    (59683, 0, 0, 1, 0), -- Exploding Shot Stalker
    (59692, 0, 0, 1, 0), -- All Purpose Bunny (JLR)
    (59707, 0, 0, 1, 0), -- The Anarchist Arcanist
    (59711, 0, 0, 1, 0), -- Arcane Bomb Chase
    (59723, 0, 0, 1, 0), -- Great Wall Explosion Caster Stalker
    (59734, 0, 0, 1, 0), -- Dave's Industrial Light and Magic Bunny (Large)(Sessile)(Large AOI)
    (59778, 0, 0, 1, 0), -- Krik'thik Striker
    (59794, 0, 0, 1, 0), -- Krik'thik Disruptor
    (59804, 0, 0, 1, 0), -- Gripping Hatred
    (59834, 0, 0, 1, 0), -- Boss 3 Encounter Add Generator
    (59885, 0, 0, 1, 0), -- Krik'thik Glider
    (59999, 0, 0, 1, 0), -- Bunny: Mogu Marauders
    (60014, 0, 0, 1, 0), -- Bunny: Explosive Target
    (60089, 0, 0, 1, 0), -- Stone Guard Controller
    (60114, 0, 0, 1, 0), -- Generic Bunny 4.0
    (60274, 0, 0, 1, 0), -- Bunny: Final Power
    (60276, 0, 0, 1, 0), -- Hozen Clinger
    (60291, 0, 0, 1, 0), -- Fire Bunny
    (60366, 0, 0, 1, 0), -- Bunny: Battle Axe of the Thunder King
    (60384, 0, 0, 1, 0), -- Zandalari Pterror Wing
    (60385, 0, 0, 1, 0), -- Zandalari War Wyvern
    (60410, 0, 0, 1, 0), -- Elegon
    (60421, 0, 0, 1, 0), -- Kolramas Digsite
    (60438, 0, 0, 1, 0), -- Wildfire Spark
    (60488, 0, 0, 1, 0), -- Water Spout Bunny
    (60512, 0, 0, 1, 0), -- Spirit Totem
    (60513, 0, 0, 1, 0), -- Spirit Totem
    (60645, 0, 0, 1, 0), -- World's Least Healthy Bunny
    (60691, 0, 0, 1, 0), -- The Final Taste Bunny
    (60793, 0, 0, 1, 0), -- Celestial Protector
    (60906, 0, 0, 1, 0), -- Fissure
    (60913, 0, 0, 1, 0), -- Energy Charge
    (60920, 0, 0, 1, 0), -- Dafeng
    (61140, 0, 0, 1, 0), -- Gara'jal the Spiritbinder
    (61463, 0, 0, 1, 0), -- Slagmaw
    (61484, 0, 0, 1, 0), -- Sik'thik Amber-Sapper
    (61499, 0, 0, 1, 0), -- Ring of Fire
    (61506, 0, 0, 1, 0), -- Loremaster Staff Bunny Event Version
    (61548, 0, 0, 1, 0), -- Loremaster Staff Bunny Quest Version
    (61601, 0, 0, 1, 0), -- Lava
    (61699, 0, 0, 1, 0), -- Sik'thik Amberwing
    (61860, 0, 0, 1, 0), -- Shado-Pan Sword Bunny
    (61865, 0, 0, 1, 0), -- Shado-Pan Sword Bunny Vehicle
    (61873, 1, 1, 2, 0), -- Liu of the Thousand Blows Summon
    (61917, 1, 1, 2, 0), -- Shado-Master Zhiyao Summon
    (61983, 1, 1, 2, 0), -- Shiya Boldblade Summon
    (62004, 0, 0, 1, 0), -- Ghost Essence
    (62091, 0, 0, 1, 0), -- Sik'thik Flyer
    (62164, 1, 0, 2, 0), -- Garalon
    (62205, 0, 0, 1, 0), -- Wing Leader Ner'onok
    (62261, 0, 0, 1, 0), -- Decoy
    (62353, 0, 0, 1, 0), -- Resonating Pulse Bunny - N
    (62442, 0, 0, 1, 0), -- Tsulong
    (62471, 0, 0, 1, 0), -- Ookie's Cleaver Bunny
    (62472, 0, 0, 1, 0), -- Ookie's Cleaver Bunny Vehicle
    (62476, 0, 0, 1, 0), -- Trained Jungle Lory
    (62478, 0, 0, 1, 0), -- Trained Jibberwing
    (62500, 0, 0, 1, 0), -- Zip Line
    (62540, 0, 0, 1, 0), -- Kaz'tik the Manipulator
    (62542, 0, 0, 1, 0), -- Kovok
    (62543, 1, 0, 2, 0), -- Blade Lord Ta'yak
    (62689, 0, 0, 1, 0), -- Sonic Ring
    (62694, 0, 0, 1, 0), -- Sonic Ring
    (62696, 0, 0, 1, 0), -- Sonic Ring
    (62716, 0, 0, 1, 0), -- Sonic Ring
    (62717, 0, 0, 1, 0), -- Sonic Ring
    (62718, 0, 0, 1, 0), -- Sonic Ring
    (62719, 0, 0, 1, 0), -- Sonic Ring
    (62726, 0, 0, 1, 0), -- Sonic Ring
    (62727, 0, 0, 1, 0), -- Sonic Ring
    (62742, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62743, 0, 0, 1, 0), -- Sonic Ring
    (62744, 0, 0, 1, 0), -- Sonic Ring
    (62746, 0, 0, 1, 0), -- Sonic Ring
    (62808, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62827, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62841, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62908, 0, 0, 1, 0), -- Heart of Fear - Armsmaster Ta'yak Tempest Stalker (LTD)
    (62911, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62912, 0, 0, 1, 0), -- JZ TEST BUNNY
    (62953, 1, 1, 2, 0), -- Sea Gull
    (62980, 1, 0, 2, 0), -- Imperial Vizier Zor'lok
    (63121, 0, 0, 1, 0), -- Mogu Ritual Bunny
    (63137, 0, 0, 1, 0), -- Tree Trimming Effects Bunny
    (63138, 0, 0, 1, 0), -- Vehicle Bunny
    (63152, 0, 0, 1, 0), -- Painting Effects Bunny
    (63235, 0, 0, 1, 0), -- Cairn of Bone Bunny 01
    (63236, 0, 0, 1, 0), -- Cairn of Bone Bunny 02
    (63237, 0, 0, 1, 0), -- Cairn of Bone Bunny 03
    (63305, 0, 0, 1, 0), -- Cho Escort Bunny
    (63337, 0, 0, 1, 0), -- The Light of Day
    (63519, 0, 0, 1, 0), -- Water Spirit
    (63520, 0, 0, 1, 0), -- Li Te
    (63567, 0, 0, 1, 0), -- Heart of Fear - Armsmaster Ta'yak - Storm Unleashed Player Vehicle Stalker (LTD)
    (63590, 0, 0, 1, 0), -- [PH]Obviously Temp Placeholder Cutscene Bunny
    (63823, 0, 0, 1, 0), -- Waterspout
    (63826, 0, 0, 1, 0), -- Tart's Boat
    (63835, 0, 0, 1, 0), -- Sonic Pulse
    (63836, 0, 0, 1, 0), -- Sonic Pulse
    (63837, 0, 0, 1, 0), -- Sonic Pulse
    (63942, 0, 0, 1, 0), -- Sha of Fear
    (63943, 0, 0, 1, 0), -- Mistfall Village Fire Bunny
    (63992, 0, 0, 1, 0), -- Great Wall Explosion Target Stalker 1
    (64208, 0, 0, 1, 0), -- Induction Cutscene Controller Bunny
    (64209, 0, 0, 1, 0), -- Yaungol Boat
    (64267, 1, 1, 2, 0), -- Tornado
    (64373, 0, 0, 1, 0), -- Heart of Fear - Trash Version Tempest Stalker (LTD)
    (64383, 0, 0, 1, 0), -- Bubbling Resin
    (64432, 0, 0, 1, 0), -- Sinan the Dreamer
    (64503, 0, 0, 1, 0), -- Mishi
    (64529, 0, 0, 1, 0), -- Mogu Runes (Horizontal Visual)
    (64554, 0, 0, 1, 0), -- Zhao-Ren
    (64600, 0, 0, 1, 0), -- Mogu Runes (Vertical Visual)
    (64640, 0, 0, 1, 0), -- Xuen Event Bunny 00
    (64709, 0, 0, 1, 0), -- Theramore Embers Bunny
    (64710, 0, 0, 1, 0), -- Rope
    (64740, 0, 0, 1, 0), -- Rope Seat
    (64766, 0, 0, 1, 0), -- Xuen Event Bunny 01
    (64768, 0, 0, 1, 0), -- Xuen Event Bunny 02
    (64771, 0, 0, 1, 0), -- Xuen Event Bunny 03
    (64812, 0, 0, 1, 0), -- Main FX Bunny [DND]
    (64820, 0, 0, 1, 0), -- Rock FX Bunny [DND]
    (64823, 0, 0, 1, 0), -- Main Spell FX Bunny [DND]
    (64824, 0, 0, 1, 0), -- Smaller Spell FX Bunny [DND]
    (65227, 0, 0, 1, 0), -- Mogu Runes (Pitch Forward 120) DNT
    (65228, 0, 0, 1, 0), -- Mogu Runes (Pitch Forward 180) DNT
    (65262, 0, 0, 1, 0), -- Door Bunny
    (65293, 0, 0, 1, 0), -- Infinite Energy
    (65297, 0, 0, 1, 0), -- Invisible Stalker
    (65311, 0, 0, 1, 0), -- Sha Crash Bunny
    (65359, 0, 0, 1, 0), -- Gap Jump Bunny
    (65400, 0, 0, 1, 0), -- Krik'thik Glider
    (65401, 1, 1, 2, 0), -- Krik'thik Glider
    (65457, 0, 0, 1, 0), -- Resonating Pulse Bunny - NW
    (65458, 0, 0, 1, 0), -- Resonating Pulse Bunny - NE
    (65459, 0, 0, 1, 0), -- Resonating Pulse Bunny - S
    (65460, 0, 0, 1, 0), -- Resonating Pulse Bunny - SW
    (65461, 0, 0, 1, 0), -- Resonating Pulse Bunny - SE
    (65462, 0, 0, 1, 0), -- Resonating Pulse Bunny - W
    (65463, 0, 0, 1, 0), -- Resonating Pulse Bunny - E
    (65476, 0, 0, 1, 0), -- Balloon Air Spirit Bunny
    (65477, 0, 0, 1, 0), -- Balloon Fire Spirit Bunny
    (65493, 0, 0, 1, 0), -- Shu
    (65498, 1, 0, 2, 0), -- Zar'thik Battle-Mender
    (65499, 1, 0, 2, 0), -- Sra'thik Amber-Trapper
    (65500, 1, 0, 2, 0), -- Kor'thik Elite Blademaster
    (65501, 0, 0, 1, 0), -- Wind Lord Mel'jarak
    (65522, 0, 0, 1, 0), -- Bubble Shield
    (65559, 0, 0, 1, 0), -- Vision of Zhao-Ren
    (65560, 0, 0, 1, 0), -- Vision of Dafeng
    (65583, 0, 0, 1, 0), -- Shock Bunny
    (65625, 0, 0, 1, 0), -- Party Bunny
    (65644, 0, 0, 1, 0), -- [DND] Mana Bomb Bunny
    (65755, 0, 0, 1, 0), -- Honey Bunny
    (65789, 0, 0, 1, 0), -- Corpse Pile Bunny
    (65888, 0, 0, 1, 0), -- Mogu Cannon Bunny
    (65903, 0, 0, 1, 0), -- Mini Mana Bomb
    (66179, 0, 0, 1, 0), -- Wasp Bunny
    (66240, 0, 0, 1, 0), -- Antonidas' Self Help Guide to Standing in Fire
    (66403, 0, 0, 1, 0), -- Gyrocopter Facing Bunny
    (66606, 0, 0, 1, 0), -- General Purpose Bunny JMF (Look 2 - Flying, Huge AOI, lvl 93)
    (67061, 0, 0, 1, 0), -- Parachute Gear Bunny
    (67102, 0, 0, 1, 0), -- Lighting Bunny
    (67103, 0, 0, 1, 0), -- Lighting Bunny
    (67104, 0, 0, 1, 0), -- Lighting Bunny
    (67105, 0, 0, 1, 0), -- Lighting Bunny
    (67106, 0, 0, 1, 0), -- Lighting Bunny
    (67107, 0, 0, 1, 0), -- Lighting Bunny
    (67108, 0, 0, 1, 0), -- Lighting Bunny
    (67109, 0, 0, 1, 0), -- Lighting Bunny
    (67110, 0, 0, 1, 0), -- Lighting Bunny
    (67111, 0, 0, 1, 0), -- Lighting Bunny
    (67112, 0, 0, 1, 0), -- Lighting Bunny
    (67113, 0, 0, 1, 0), -- Lighting Bunny
    (67114, 0, 0, 1, 0), -- Lighting Bunny
    (67115, 0, 0, 1, 0), -- Lighting Bunny
    (67116, 0, 0, 1, 0), -- Lighting Bunny
    (67117, 0, 0, 1, 0), -- Lighting Bunny
    (67118, 0, 0, 1, 0), -- Lighting Bunny
    (67119, 0, 0, 1, 0), -- Lighting Bunny
    (67120, 0, 0, 1, 0), -- Lighting Bunny
    (67121, 0, 0, 1, 0), -- Lighting Bunny
    (67122, 0, 0, 1, 0), -- Lighting Bunny
    (67123, 0, 0, 1, 0), -- Lighting Bunny
    (67124, 0, 0, 1, 0), -- Lighting Bunny
    (67156, 0, 0, 1, 0), -- Grain Gears Bunny
    (67203, 0, 0, 1, 0), -- Face Target Bunny
    (67234, 0, 0, 1, 0), -- Healing Test Bunny
    (67272, 0, 0, 1, 0), -- Scenario Controller
    (67275, 0, 0, 1, 0), -- Kor'kron Gunship
    (67327, 0, 0, 1, 0), -- Zip Line
    (67331, 0, 0, 1, 0), -- Net
    (67341, 0, 0, 1, 0), -- Cannon Exploder
    (67422, 0, 0, 1, 0), -- Battle-Mine
    (67445, 0, 0, 1, 0), -- BG Bunny
    (67634, 0, 0, 1, 0), -- Well Supplied Buff Bunny
    (67640, 0, 0, 1, 0), -- Spark Bunny
    (67666, 0, 0, 1, 0), -- Well Fed Buff Bunny
    (67675, 1, 0, 2, 0), -- Sunreaver Mana Wyrm
    (67677, 0, 0, 1, 0), -- Garrosh/Lor'themar Event Controller Bunny
    (67733, 0, 0, 1, 0), -- Inspired Buff Bunny
    (67741, 0, 0, 1, 0), -- Valve Bunny
    (67771, 0, 0, 1, 0), -- Amberglow Firefly
    (67808, 0, 0, 1, 0), -- JINYU Manual Labor Bunny
    (67829, 0, 0, 1, 0), -- Eyebeam Target
    (67842, 0, 0, 1, 0), -- Rise Of An Empire Event Controller Bunny
    (67899, 0, 0, 1, 0), -- Quicksilver Bunny
    (67928, 0, 0, 1, 0), -- Stack Em High - Completion Bunny
    (67936, 0, 0, 1, 0), -- GNOME Manual Labor Bunny
    (67938, 0, 0, 1, 0), -- Well Lubricated Buff Bunny
    (67961, 0, 0, 1, 0), -- GNOME Gadget Bunny
    (67975, 0, 0, 1, 0), -- Inspired Buff Bunny
    (68036, 1, 1, 2, 0), -- Durumu the Forgotten
    (68054, 0, 0, 1, 0), -- Black Temple Top Credit
    (68065, 1, 1, 2, 0), -- Megaera
    (68101, 0, 0, 1, 0), -- DWARF Manual Labor Bunny
    (68103, 0, 0, 1, 0), -- Inspired Buff Bunny
    (68105, 0, 0, 1, 0), -- Shield Channel Point
    (68116, 0, 0, 1, 0), -- Loaded for Bear Buff Bunny
    (68151, 0, 0, 1, 0), -- Essence of Order
    (68167, 0, 0, 1, 0), -- Burn 'Em Out - Completion Bunny
    (68168, 0, 0, 1, 0), -- The Tiniest Victim - Completion Bunny
    (68171, 0, 0, 1, 0), -- Necessary Breaks - Completion Bunny
    (68194, 0, 0, 1, 0), -- Young Egg of Ji-Kun
    (68202, 0, 0, 1, 0), -- Ji-Kun Fledgling's Egg
    (68227, 0, 0, 1, 0), -- Heart Of The Alliance Event Controller Bunny A
    (68229, 0, 0, 1, 0), -- Heart Of The Alliance Event Controller Bunny B
    (68248, 0, 0, 1, 0), -- Corpse Spider
    (68262, 0, 0, 1, 0), -- Corpse Spider
    (68295, 0, 0, 1, 0), -- A Gathering Storm Event Controller Bunny
    (68303, 0, 0, 1, 0), -- PANDAREN Manual Labor Bunny
    (68309, 0, 0, 1, 0), -- General Purpose Bunny JMF (Shard of Archstone)
    (68324, 0, 0, 1, 0), -- Hair of the Dog Buff Bunny
    (68330, 0, 0, 1, 0), -- Cauldron Bunny
    (68359, 0, 0, 1, 0), -- Pandaren ASLEEP Bunny
    (68360, 0, 0, 1, 0), -- Horde - The Kun-Lai Expedition Event Bunny
    (68374, 0, 0, 1, 0), -- Alliance - The Kun-Lai Expedition Event Bunny
    (68412, 0, 0, 1, 0), -- Iron Fisted Buff Bunny
    (68415, 0, 0, 1, 0), -- Crypt Bunny
    (68459, 0, 0, 1, 0), -- Sewer Boulder
    (68497, 0, 0, 1, 0), -- Vampiric Cave Bat
    (68500, 0, 0, 1, 0), -- Heavy Metal Buff Bunny
    (68518, 0, 0, 1, 0), -- GNOME Trap Bunny
    (68541, 0, 0, 1, 0), -- "To Catch A Spy" - Controller Bunny
    (68588, 0, 0, 1, 0), -- Sunreaver Agent
    (68638, 0, 0, 1, 0), -- Red Dragonhawk
    (68683, 0, 0, 1, 0), -- NIGHT ELF Manual Labor Bunny
    (68702, 0, 0, 1, 0), -- Night Elf Buff Bunny
    (68728, 0, 0, 1, 0), -- Sunreaver Dragonhawk
    (68776, 0, 0, 1, 0), -- Inspired Buff Bunny
    (68791, 0, 0, 1, 0), -- Fuel Shortage - Bunny
    (68813, 0, 0, 1, 0), -- Rusty Valve Bunny
    (68817, 0, 0, 1, 0), -- Finale Controller Bunny
    (68818, 0, 0, 1, 0), -- Divine Bell Bunny
    (68824, 0, 0, 1, 0), -- Fuel Shortage - Bunny - Big Fire
    (68849, 0, 0, 1, 0), -- Skyfire Gyrocopter
    (68918, 0, 0, 1, 0), -- Divine Bell Bunny
    (68937, 0, 0, 1, 0), -- Finale Controller Bunny
    (68938, 0, 0, 1, 0), -- Divine Bell Bunny
    (69018, 0, 0, 1, 0), -- Totally Generic Bunny (JSB)
    (69019, 0, 0, 1, 0), -- General Purpose Bunny (JLR)
    (69028, 0, 0, 1, 0), -- Generic Client-Side Bunny
    (69081, 0, 0, 1, 0), -- Area Trigger Caster Stalker
    (69099, 0, 0, 1, 0), -- Nalak
    (69128, 1, 0, 2, 0), -- Hatchling Skyscreamer
    (69156, 0, 0, 1, 0), -- Zandalari Skyscreamer
    (69162, 1, 1, 2, 0), -- Juvenile Skyscreamer
    (69186, 0, 0, 1, 0), -- Kirin Tor Perimeter Ward
    (69217, 0, 0, 1, 0), -- Manfred
    (69263, 0, 0, 1, 0), -- Tormented Skyscreamer
    (69284, 0, 0, 1, 0), -- Mogu Corpse Bunny
    (69287, 1, 1, 2, 0), -- Disabled Sunreaver Construct
    (69288, 1, 1, 2, 0), -- Buried Sunreaver Construct
    (69289, 1, 1, 2, 0), -- Malfunctioning Sunreaver Construct
    (69290, 1, 1, 2, 0), -- Distressed Sunreaver Construct
    (69292, 0, 0, 1, 0), -- Sunreaver Perimeter Ward
    (69342, 1, 0, 2, 0), -- Risen Ancestor
    (69347, 1, 1, 2, 0), -- Incomplete Drakkari Colossus
    (69349, 1, 0, 2, 0), -- Dark-Eye Raven
    (69351, 0, 0, 1, 0), -- Greater Cave Bat
    (69352, 0, 0, 1, 0), -- Vampiric Cave Bat
    (69355, 0, 0, 1, 0), -- Scout Alaine
    (69356, 0, 0, 1, 0), -- Scout Merior
    (69357, 0, 0, 1, 0), -- Scout Elearis
    (69361, 0, 0, 1, 0), -- Manfred
    (69365, 0, 0, 1, 0), -- Star
    (69369, 0, 0, 1, 0), -- Lightning Ritual Bunny
    (69373, 0, 0, 1, 0), -- Dance Bunny
    (69395, 0, 0, 1, 0), -- Drawn Water
    (69411, 0, 0, 1, 0), -- Zandalari Skyscreamer
    (69428, 1, 0, 2, 0), -- Wild Pterrorwing Hatchling
    (69430, 0, 0, 1, 0), -- Darkeye Raven
    (69451, 0, 0, 1, 0), -- Spell Focus Stalker
    (69458, 0, 0, 1, 0), -- Thunderwing
    (69462, 0, 0, 1, 0), -- Ball Lightning
    (69464, 0, 0, 1, 0), -- Zandalari Pterrorwing
    (69467, 0, 0, 1, 0), -- Statue
    (69477, 0, 0, 1, 0), -- Star
    (69486, 0, 0, 1, 0), -- Sunreaver Bloodhawk
    (69487, 0, 0, 1, 0), -- Sunreaver Bloodhawk
    (69489, 0, 0, 1, 0), -- Sunreaver Bloodhawk
    (69508, 0, 0, 1, 0), -- Zeb'tula Generic Bunny
    (69509, 0, 0, 1, 0), -- Thunderwing
    (69511, 0, 0, 1, 0), -- Zandalari Pterrorwing
    (69562, 0, 0, 1, 0), -- Nalak
    (69571, 0, 0, 1, 0), -- Zeb'tula Barrier Bunny
    (69574, 1, 1, 2, 0), -- Warrior's Sarcophagus
    (69604, 1, 0, 2, 0), -- Tactical Mana Bomb Holder
    (69623, 0, 0, 1, 0), -- Scenario 5.2 - Tear Down This Wall - Wall Destroyer Bunny - JSB
    (69628, 0, 0, 1, 0), -- Mature Egg of Ji-Kun
    (69645, 0, 0, 1, 0), -- Overwhelming Power
    (69647, 0, 0, 1, 0), -- Lightning Strike Bunny
    (69655, 0, 0, 1, 0), -- Activated Forge
    (69660, 0, 0, 1, 0), -- Activated Forge
    (69661, 0, 0, 1, 0), -- Activated Forge
    (69662, 0, 0, 1, 0), -- Activated Forge
    (69688, 1, 1, 2, 0), -- Buried Silver Covenant Construct
    (69693, 1, 1, 2, 0), -- Disabled Silver Covenant Construct
    (69695, 1, 1, 2, 0), -- Distressed Silver Covenant Construct
    (69697, 1, 1, 2, 0), -- Malfunctioning Silver Covenant Construct
    (69751, 0, 0, 1, 0), -- Agent Reginald
    (69752, 0, 0, 1, 0), -- Agent Grisel
    (69754, 0, 0, 1, 0), -- Agent Crowley
    (69756, 0, 0, 1, 0), -- Anima Orb
    (69759, 0, 0, 1, 0), -- Defense Crystal
    (69770, 1, 1, 2, 0), -- Lightning Ritual Stone
    (69771, 0, 0, 1, 0), -- Faded Image of Xuen
    (69772, 1, 0, 2, 0), -- Zandalari Skyscreamer
    (69774, 0, 0, 1, 0), -- Faded Image of Chi-Ji
    (69777, 0, 0, 1, 0), -- Faded Image of Niuzao
    (69779, 0, 0, 1, 0), -- Faded Image of Yu'lon
    (69816, 0, 0, 1, 0), -- Golden Egg
    (69825, 0, 0, 1, 0), -- Thunder Trap
    (69839, 0, 0, 1, 0), -- Fall Catcher
    (69844, 0, 0, 1, 0), -- Alliance Exalted Event - Controller Bunny
    (69869, 0, 0, 1, 0), -- Essence of Anima
    (69870, 0, 0, 1, 0), -- Essence of Vita
    (69895, 0, 0, 1, 0), -- Kirin Tor Sky Ward
    (69900, 0, 0, 1, 0), -- Stone Ritual Bunny
    (69907, 1, 1, 2, 0), -- Kroshik
    (69957, 0, 0, 1, 0), -- Corrupted Anima
    (69958, 0, 0, 1, 0), -- Corrupted Vita
    (69984, 0, 0, 1, 0), -- Stormbreath Bunny
    (70056, 0, 0, 1, 0), -- Gara'jal the Spiritbinder
    (70097, 0, 0, 1, 0), -- Lightning Channel Target Bunny
    (70102, 0, 0, 1, 0), -- Alliance Exalted Event - Controller Bunny - Floating Up
    (70115, 0, 0, 1, 0), -- Alliance Exalted Event - Controller Bunny - Final Staff
    (70196, 1, 1, 2, 0), -- Lightning Ritual Stone
    (70197, 1, 1, 2, 0), -- Lightning Ritual Stone
    (70198, 1, 1, 2, 0), -- Primal Ritual Stone
    (70199, 1, 1, 2, 0), -- Primal Ritual Stone
    (70200, 1, 1, 2, 0), -- Primal Ritual Stone
    (70201, 1, 1, 2, 0), -- Spirit Ritual Stone
    (70203, 1, 1, 2, 0), -- Spirit Ritual Stone
    (70204, 1, 1, 2, 0), -- Spirit Ritual Stone
    (70212, 1, 1, 2, 0), -- Flaming Head
    (70215, 1, 0, 2, 0), -- Hatchling Skyscreamer
    (70231, 0, 0, 1, 0), -- Silver Covenant Hippogryph
    (70232, 0, 0, 1, 0), -- Muckbat
    (70233, 0, 0, 1, 0), -- Silver Covenant Hippogryph
    (70234, 0, 0, 1, 0), -- Silver Covenant Hippogryph
    (70235, 1, 1, 2, 0), -- Frozen Head
    (70246, 0, 0, 1, 0), -- Spirit Flayer
    (70247, 1, 1, 2, 0), -- Venomous Head
    (70252, 1, 1, 2, 0), -- Arcane Head
    (70283, 0, 0, 1, 0), -- Thunder Forge
    (70329, 0, 0, 1, 0), -- Fire Tile Trap Bunny
    (70330, 0, 0, 1, 0), -- Lightning Tile Trap Bunny
    (70331, 0, 0, 1, 0), -- Cloud Tile Trap Bunny
    (70332, 0, 0, 1, 0), -- Arrow Tile Trap Bunny
    (70341, 0, 0, 1, 0), -- Tormented Spirit
    (70342, 0, 0, 1, 0), -- Ninja Rope
    (70344, 0, 0, 1, 0), -- Ninja Rope
    (70409, 0, 0, 1, 0), -- Lightning Pillar Master Bunny
    (70439, 0, 1, 1, 0), -- Torrent of Ice
    (70441, 0, 0, 1, 0), -- Lost Soul
    (70496, 0, 0, 1, 0), -- Board Game Event Bunny
    (70523, 0, 0, 1, 0), -- Eternal Spirit of Tharon'ja
    (70555, 1, 1, 2, 0), -- Felled Leviathan
    (70614, 1, 1, 2, 0), -- Primal Ritual Stone
    (70627, 0, 0, 1, 0), -- Juggler Bunny
    (70640, 0, 0, 1, 0), -- Ji-Kun Area Trigger Dummy [DNT]
    (70738, 0, 0, 1, 0), -- Shadow Bunny
    (70758, 0, 0, 1, 0), -- Electrified Pool Bunny
    (70759, 0, 0, 1, 0), -- Electrified Pool Bunny
    (70760, 0, 0, 1, 0), -- Electrified Pool Bunny
    (70761, 0, 0, 1, 0), -- Electrified Pool Bunny
    (70779, 0, 0, 1, 0), -- Zip Line
    (71045, 0, 0, 1, 0), -- Region Checker Bunny
    (71160, 0, 0, 1, 0), -- Iyyokuk the Lucid
    (71161, 0, 0, 1, 0), -- Kil'ruk the Wind-Reaver
    (71269, 0, 0, 1, 0), -- VO Bunny
    (71315, 0, 0, 1, 0), -- Beachhead Event Controller Bunny
    (71324, 0, 0, 1, 0), -- Zen'tabra Event Controller Bunny
    (71372, 0, 0, 1, 0), -- Caravan Placeholder Bunny
    (71398, 0, 0, 1, 0), -- Zar'thik Swarmer
    (71434, 0, 0, 1, 0), -- Image of Xuen
    (71435, 0, 0, 1, 0), -- Image of Yu'lon
    (71439, 0, 0, 1, 0), -- Image of Niuzao
    (71441, 0, 0, 1, 0), -- Image of Chi-ji
    (71532, 0, 0, 1, 0), -- Sawblade
    (71591, 1, 0, 2, 0), -- Automated Shredder
    (71592, 0, 0, 1, 0), -- The Klaxxi Paragons
    (71606, 0, 0, 1, 0), -- Deactivated Missile Turret
    (71611, 0, 0, 1, 0), -- Sha Pool
    (71628, 0, 0, 1, 0), -- Mantid Amber
    (71683, 0, 0, 1, 0), -- Golden Lotus
    (71684, 0, 0, 1, 0), -- Golden Lotus
    (71686, 0, 0, 1, 0), -- Golden Lotus
    (71694, 0, 0, 1, 0), -- Deactivated Electromagnet
    (71696, 0, 0, 1, 0), -- Activated Electromagnet
    (71711, 0, 0, 1, 0), -- Golden Lotus
    (71740, 0, 0, 1, 0), -- Laser Target Bunny
    (71751, 0, 0, 1, 0), -- Deactivated Laser Turret
    (71789, 0, 0, 1, 0), -- Falling Ash
    (71790, 0, 0, 1, 0), -- Disassembled Crawler Mines
    (71795, 0, 0, 1, 0), -- Activated Crawler Mine Vehicle
    (71820, 0, 0, 1, 0), -- Xuen
    (71910, 0, 0, 1, 0), -- Laser Array Bunny
    (71912, 0, 0, 1, 0), -- Laser Array Target Vehicle
    (71971, 0, 0, 1, 0), -- Firestorm
    (71978, 0, 0, 1, 0), -- Beacon of Hope
    (71985, 0, 0, 1, 0), -- Ko'kron Iron Star
    (72015, 0, 0, 1, 0), -- Activated Laser Turret Base
    (72027, 0, 0, 1, 0), -- Activated Missile Turret Base
    (72059, 0, 0, 1, 0), -- Ancient Flame
    (72215, 0, 0, 1, 0), -- Heart of Y'Shaarj
    (72228, 0, 0, 1, 0), -- Heart of Y'Shaarj
    (72249, 0, 0, 1, 0), -- Galakras
    (72345, 0, 0, 1, 0), -- Steam Vent Bunny
    (72388, 0, 0, 1, 0), -- Laser Array Bunny (Always On)
    (72555, 0, 0, 1, 0), -- Empowered Laser Target Bunny
    (72792, 0, 0, 1, 0), -- Sha Invisible Stalker
    (72887, 0, 0, 1, 0), -- VO Bunny
    (72904, 0, 0, 1, 0), -- Deactivated Deathdealer Turret
    (72905, 0, 0, 1, 0), -- Activated Deathdealer Turret
    (72961, 0, 0, 1, 0), -- Noodle Soup
    (72962, 0, 0, 1, 0), -- Dragon's Nest Noodle Soup
    (72963, 0, 0, 1, 0), -- Pandaren Treasures Noodle Soup
    (72972, 1, 1, 2, 0), -- Lift Hook
    (72986, 0, 0, 1, 0), -- Shanna Sparkfizz
    (73012, 0, 0, 1, 0), -- Klaxxi Skirmisher
    (73084, 0, 0, 1, 0), -- VO Bunny
    (73149, 0, 0, 1, 0), -- Quest - Legendary 5.4 - Tavern Flour Bunny - JSB
    (73188, 0, 0, 1, 0), -- Captive Cave Bat
    (73192, 0, 0, 1, 0), -- Invisible Stalker
    (73222, 1, 1, 2, 0), -- Ooze Controller (Stalker)
    (73223, 0, 0, 1, 0), -- Pterrordax
    (73275, 0, 0, 1, 0), -- Bottle Bunny
    (73281, 1, 1, 2, 0), -- Dread Ship Vazuvius
    (73436, 0, 0, 1, 0), -- VO Bunny
    (73488, 0, 0, 1, 0), -- Invisible Stalker
    (73522, 0, 0, 1, 0), -- Captive Cave Bat
    (73547, 0, 0, 1, 0), -- Dread Captain Genest
    (73557, 1, 1, 2, 0), -- Eerie Fog
    (73743, 1, 1, 2, 0), -- Crashin' Thrashin' Flyer
    (73920, 0, 0, 1, 0), -- Rope
    (73968, 0, 0, 1, 0), -- Target Practice Aim Bunny
    (190011, 1, 1, 2, 0), -- Transmogrification
    (190012, 0, 0, 1, 0), -- MMaps Waypoint
    (190013, 1, 1, 2, 0); --  Isengard Solo Queue Npc
