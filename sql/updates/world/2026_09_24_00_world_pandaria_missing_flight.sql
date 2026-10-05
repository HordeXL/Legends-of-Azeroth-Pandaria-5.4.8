-- Restore missing flight movement for creatures spawned in Pandaria (map 870).
-- Source: world_548_20240722.sql, creature_template.InhabitType.
-- Convert the original bitmask using the same rules as 2024_07_24_00_world.sql:
-- Ground = bit 1, Swim = bit 2, Flight = 1 (air only) or 2 (ground + air),
-- Rooted = bit 8. Preserve all existing movement records and script settings.
-- Reload creature templates and respawn affected creatures, or restart worldserver.
INSERT IGNORE INTO `creature_template_movement`
    (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`)
VALUES
    (24288, 0, 0, 1, 0), -- ELM General Purpose Bunny Hide Body
    (28960, 0, 0, 1, 0), -- Totally Generic Bunny (JSB)
    (35114, 0, 0, 1, 0), -- ELM General Purpose Bunny (All Phases)
    (41200, 1, 1, 2, 0), -- Generic Bunny - PRK
    (54559, 0, 0, 1, 0), -- Glittering Amberfly
    (55289, 0, 0, 1, 0), -- Vacant Destroyer
    (55370, 1, 1, 2, 0), -- General Purpose Bunny ZTO
    (56034, 0, 0, 1, 0), -- Thieving Plainshawk
    (56171, 0, 0, 1, 0), -- Great White Plainshawk
    (56199, 0, 0, 1, 0), -- Lightwing Hunter
    (56201, 0, 0, 1, 0), -- Orchard Wasp
    (56283, 0, 0, 1, 0), -- Tigerfly
    (56396, 0, 0, 1, 0), -- Hungry Bloodtalon
    (56703, 1, 0, 2, 0), -- Ik'thik Colossus
    (56722, 0, 0, 1, 0), -- Ik'thik Warrior
    (56723, 0, 0, 1, 0), -- Ik'thik Wing Commander
    (56779, 0, 0, 1, 0), -- Yu'lon
    (57195, 0, 0, 1, 0), -- Ik'thik Swiftclaw
    (57196, 0, 0, 1, 0), -- Ik'thik Wingblade
    (57215, 0, 0, 1, 0), -- Grainhunter Hawk
    (57216, 0, 0, 1, 0), -- Soaring Hunter
    (57232, 0, 0, 1, 0), -- Dappled Moth
    (57421, 0, 0, 1, 0), -- Mothallus
    (57422, 0, 0, 1, 0), -- Mutated Silkmoth
    (57445, 0, 0, 1, 0), -- War Serpent
    (57673, 0, 0, 1, 0), -- Curious Water Sprite
    (57851, 0, 0, 1, 0), -- Thunderbird
    (57871, 1, 0, 2, 0), -- War Serpent
    (58111, 0, 0, 1, 0), -- Thunderbird
    (58139, 0, 0, 1, 0), -- Observer Owl
    (58213, 0, 0, 1, 0), -- Windward Matriarch
    (58214, 0, 0, 1, 0), -- Windward Matriarch
    (58217, 0, 0, 1, 0), -- Windward Viper
    (58230, 0, 0, 1, 0), -- Sandy Petrel
    (58231, 0, 0, 1, 0), -- Dampnet Osprey
    (58275, 0, 0, 1, 0), -- Nest Bunny
    (58362, 0, 0, 1, 0), -- Orchard Beehive
    (58363, 0, 0, 1, 0), -- Honeykeeper
    (58367, 0, 0, 1, 0), -- Ik'thik Precursor
    (58440, 0, 0, 1, 0), -- Race Pennant
    (58457, 0, 0, 1, 0), -- Silkfeather Hawk
    (58591, 0, 0, 1, 0), -- Ashweb Hanging Web Bunny
    (58910, 0, 0, 1, 0), -- Plainshawk
    (59112, 0, 0, 1, 0), -- Dawnfeather Flyer
    (59136, 0, 0, 1, 0), -- Sunwalker Scout
    (59154, 0, 0, 1, 0), -- Yak Statuette
    (59158, 0, 0, 1, 0), -- Subjugated Serpent
    (59197, 0, 0, 1, 0), -- Canopy Screecher
    (59235, 0, 0, 1, 0), -- Albino Canopy Screecher
    (59243, 0, 0, 1, 0), -- Farm Moth
    (59251, 0, 0, 1, 0), -- Trenchwing Scavenger
    (59351, 0, 0, 1, 0), -- Emerald Fenfly
    (59384, 0, 0, 1, 0), -- Bluff Hawk
    (59404, 0, 0, 1, 0), -- Knifetooth Swarmer
    (59409, 0, 0, 1, 0), -- Hozen Swing
    (59481, 1, 1, 2, 0), -- World Trigger
    (59528, 0, 0, 1, 0), -- Cliff Kite
    (59641, 0, 0, 1, 0), -- Monstrous Plainshawk
    (59672, 0, 0, 1, 0), -- Summit Bonestripper
    (59700, 0, 0, 1, 0), -- Northwind Hawk
    (59757, 0, 0, 1, 0), -- Duskstalker
    (59768, 0, 0, 1, 0), -- Jadeglow Wasp
    (59770, 0, 0, 1, 0), -- Shrine Fly
    (59774, 0, 0, 1, 0), -- Ivory Starling
    (59785, 0, 0, 1, 0), -- Singing Moth
    (59788, 0, 0, 1, 0), -- Spirit Darter
    (59984, 0, 0, 1, 0), -- Trained Jibberwing
    (60027, 0, 0, 1, 0), -- Prisoner Bindings
    (60072, 0, 0, 1, 0), -- Swooping Plainshawk
    (60139, 0, 0, 1, 0), -- Wise Ana Wu
    (60166, 0, 0, 1, 0), -- Cloudrunner Leng
    (60167, 0, 0, 1, 0), -- Skydancer Shun
    (60196, 0, 0, 1, 0), -- Dusky Lory
    (60198, 0, 0, 1, 0), -- Crimson Lory
    (60200, 0, 0, 1, 0), -- Emerald Lory
    (60582, 1, 1, 2, 0), -- Terracotta Champion
    (60736, 0, 0, 1, 0), -- Chain Bunny
    (60862, 0, 0, 1, 0), -- Steam Bunny
    (60866, 0, 0, 1, 0), -- Upland Eagle
    (60931, 0, 0, 1, 0), -- Training Target
    (61374, 0, 0, 1, 0), -- Krik'thik Deep-Scout
    (61843, 0, 0, 1, 0), -- Kun-Lai Corpsepicker
    (62014, 0, 0, 1, 0), -- Krik'thik Acidslinger
    (62090, 0, 0, 1, 0), -- Mantid Bunny
    (62128, 0, 0, 1, 0), -- Kor'thik Fleetwing
    (62203, 0, 0, 1, 0), -- Klaxxi'va Tik
    (62267, 0, 0, 1, 0), -- Wild Cloudrunner
    (62300, 0, 0, 1, 0), -- Kor'thik Swarmer
    (62301, 0, 0, 1, 0), -- Adjunct Kree'zot
    (62309, 0, 0, 1, 0), -- Hei Feng
    (62311, 0, 0, 1, 0), -- Shan'ze Cloudrunner
    (62386, 0, 0, 1, 0), -- Sapfly
    (62448, 0, 0, 1, 0), -- Onyx Stormclaw
    (62563, 1, 1, 2, 0), -- Shek'zeer Bladesworn
    (62567, 0, 0, 1, 0), -- Cloudrunner Hatchling
    (62576, 0, 0, 1, 0), -- Sik'thik Drone
    (62584, 0, 0, 1, 0), -- Shan'ze Cloudrunner
    (62585, 0, 0, 1, 0), -- Shan'ze Cloudrunner
    (62586, 0, 0, 1, 0), -- Shan'ze Cloudrunner
    (62597, 0, 0, 1, 0), -- Wild Cloudrunner
    (62598, 0, 0, 1, 0), -- Wild Cloudrunner
    (62599, 0, 0, 1, 0), -- Wild Cloudrunner
    (62602, 0, 0, 1, 0), -- Kri'thik Screecher
    (62853, 1, 1, 2, 0), -- Paragon 05 Bunny
    (63176, 0, 0, 1, 0), -- Ik'thik Egg-Drone
    (63289, 0, 0, 1, 0), -- Luyu Moth
    (63314, 0, 0, 1, 0), -- Wodin the Troll-Servant
    (63361, 0, 0, 1, 0), -- Mei Li Sparkler
    (63366, 1, 1, 2, 0), -- The Spring Drifter
    (63517, 1, 1, 2, 0), -- The Spring Drifter
    (63562, 0, 0, 1, 0), -- Mogu Statue Mount Bunny
    (63895, 0, 0, 1, 0), -- Shan'ze Cloudrider
    (63920, 0, 0, 1, 0), -- Hei Feng
    (63973, 0, 0, 1, 0), -- Krik'thik Swarmer
    (63980, 0, 0, 1, 0), -- Amber Moth
    (64367, 0, 0, 1, 0), -- Invisible Man
    (64403, 0, 0, 1, 0), -- Alani
    (64411, 0, 0, 1, 0), -- Zandalari Pterrorwing
    (64412, 0, 0, 1, 0), -- Zandalari Terror Rider
    (64535, 0, 0, 1, 0), -- Cloud Serpent
    (64551, 0, 0, 1, 0), -- Duskwing Crow
    (64612, 0, 0, 1, 0), -- Observer Owl
    (64898, 0, 0, 1, 0), -- Speed Boost Rune
    (64995, 0, 0, 1, 0), -- Adjunct Sek'ot
    (65204, 0, 0, 1, 0), -- Effervescent Glowfly
    (65205, 0, 0, 1, 0), -- Gilded Moth
    (65335, 0, 0, 1, 0), -- War Serpent
    (65336, 0, 0, 1, 0), -- War Serpent
    (65394, 0, 0, 1, 0), -- Overgrown Seacarp
    (65486, 1, 1, 2, 0), -- Shek'zeer Wingblade
    (65573, 0, 0, 1, 0), -- Ik'thik Warrior
    (65575, 0, 0, 1, 0), -- Vor'thik Swarmborn
    (65584, 0, 0, 1, 0), -- Ik'thik Slayer
    (65608, 0, 0, 1, 0), -- [DNT] Fireflies
    (65617, 0, 0, 1, 0), -- Zijin Hollowfly
    (65619, 0, 0, 1, 0), -- Kil'ruk the Wind-Reaver
    (65629, 0, 0, 1, 0), -- Upland Raven
    (65753, 1, 0, 2, 0), -- Totally Generic Bunny - GIGANTIC (JSB)
    (65757, 0, 0, 1, 0), -- Azure Flutterwing
    (65759, 0, 0, 1, 0), -- Iridescent Flutterwing
    (65760, 0, 0, 1, 0), -- Sun-Touched Flutterwing
    (65787, 0, 0, 1, 0), -- Zan'thik Resonator
    (65799, 0, 0, 1, 0), -- Fluttering Swallowtail
    (65802, 0, 0, 1, 0), -- Krasari Hissing Wasp
    (65814, 0, 0, 1, 0), -- Krasari Hissing Waspling
    (65843, 0, 0, 1, 0), -- Strongarm Gyrocopter
    (65851, 0, 0, 1, 0), -- Crimson Pandaren Phoenix
    (65984, 0, 0, 1, 0), -- Tiny Mutated Silkmoth
    (66194, 0, 0, 1, 0), -- Waste Scavenger
    (66297, 0, 0, 1, 0), -- Skyfire Gyrocopter
    (66319, 0, 0, 1, 0), -- Fear-Touched Moth
    (66349, 0, 0, 1, 0), -- Gurubashi Bat Rider
    (66368, 0, 0, 1, 0), -- Carrion Vulture
    (66382, 1, 1, 2, 0), -- Gyrocopter Facing Bunny
    (66451, 0, 0, 1, 0), -- Gilded Tern
    (66473, 0, 0, 1, 0), -- Skyfire Gyrocopter
    (66514, 0, 0, 1, 0), -- Fluttering Moth
    (66749, 0, 0, 1, 0), -- Wanderer's Festival Lantern
    (66771, 0, 0, 1, 0), -- Cocky Crow
    (66970, 0, 0, 1, 0), -- Violet Pandaren Phoenix
    (66971, 0, 0, 1, 0), -- Ashen Pandaren Phoenix
    (66972, 0, 0, 1, 0), -- Emerald Pandaren Phoenix
    (67035, 0, 0, 1, 0), -- Ik'thik Slayer
    (67160, 1, 1, 2, 0), -- Klaxxi Vess-Guard
    (67237, 0, 0, 1, 0), -- General Purpose Bunny JMF (Look 2 - Flying, Gigantic AOI)
    (67359, 0, 0, 1, 0), -- Skyfire Gyrocopter X2
    (67369, 0, 0, 1, 0), -- Shieldwall Gryphon Rider
    (67679, 0, 0, 1, 0), -- Eternal Strider
    (67897, 0, 0, 1, 0), -- Gnomish Flying Machine
    (68553, 0, 0, 1, 0), -- SLG Generic MoP (Large AOI)
    (68705, 0, 0, 1, 0), -- Riding Wyvern
    (68837, 0, 0, 1, 0), -- Gnomish Flying Machine
    (70020, 0, 0, 1, 0), -- Pterrorwing Skyscreamer
    (71883, 1, 1, 2, 0), -- Playful Water Spirit
    (72245, 0, 0, 1, 0), -- Zesqua
    (72676, 0, 0, 1, 0), -- Spirit Healer
    (72876, 0, 0, 1, 0), -- Crimsonscale Firestorm
    (72973, 0, 0, 1, 0), -- General Purpose Bunny JMF (Look 2, Huge AOI)
    (72990, 0, 0, 1, 0), -- Whitefeather
    (73023, 1, 1, 2, 0), -- Moori
    (73034, 1, 1, 2, 0), -- Hozen Swing
    (73167, 0, 0, 1, 0), -- Huolon
    (73282, 0, 0, 1, 0), -- Garnia
    (73303, 0, 0, 1, 0), -- Emperor Shaohao
    (73489, 0, 0, 1, 0), -- General Purpose Bunny JMF (Ground, Slow)
    (73531, 0, 0, 1, 0), -- Highwind Albatross
    (73573, 0, 0, 1, 0); -- Ashwing Moth
