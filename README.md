# Legends of Azeroth Pandaria 5.4.8

World of Warcraft Mists of Pandaria emulator core for client build `5.4.8.18414`.

This project is based on SkyFire/TrinityCore-style server architecture and builds the usual `authserver`, `worldserver`, database tools, and map extraction tools.

The repository is an actively developed MoP test server rather than an untouched
upstream core. It contains source-backed core/database repairs, custom playerbot
automation, solo test systems and administrator tooling. Features marked
**experimental** below have passed build and clean-start checks, but still require
more in-game encounter testing before they should be treated as production-ready.

## Project Features and Current Status

Status recorded for the current local project configuration on 2026-09-01:

| Component | Included | Current local status | Notes |
| --- | --- | --- | --- |
| MoP 5.4.8 core | Yes | Enabled | Client build `18414`; `authserver`, `worldserver`, scripts and extraction tools. |
| Playerbots | Yes | Enabled | `AiPlayerbot.Enabled = 1`; automatic random-bot login remains disabled. |
| Solo Arena bot fill | Yes | Enabled, experimental | Arena Battlemaster choices for 2v2, 3v3 and 5v5; role/faction-aware bot selection, temporary PvP loadouts, preparation buffs, rewards, exit/health recovery and cleanup. |
| Battleground bot fill and objectives | Yes | Enabled, experimental | Fills a real player's queue, builds both factions, applies temporary PvP loadouts and includes CTF, node, orb, cart, vehicle, resurrection, escort, mount and basic path/LoS handling. |
| LFG/LFR bot fill | Yes | Enabled, experimental | Stages missing tank/healer/damage roles for a real player, including the native 25-player Raid Finder 2/6/17 composition, and uses the normal 5.4.8 proposal flow. Filler dungeon locks are refreshed after equipment preparation; temporary LFR fillers inherit the real requester's progression access while retaining level, faction, season and item-level checks. Each filler gets one pre-combat class-buff attempt; there is no Arena-style waiting/retry stage once combat begins. Requester leave/logout pauses managed bot AI, removes the fillers from the instance group, returns them outside and logs them out. Dungeon-specific mechanics still require gameplay coverage. |
| World-boss raid bots | Yes | Available, experimental | Neutral Boss Bot Caller NPCs support 10/25-player preview/call, PvE role selection and gear, legendary cloaks, raid marks, summon, buffs/rebuff, wipe recovery, status and dismiss/cleanup. Encounter-specific AI is still being tuned. |
| Combat Assistant 5.4.8 | Yes | Server side enabled | One physical click/key press casts the server-recommended ability. All playable classes/specs are supported; the client addon must also be installed. |
| VIP hybrid/test vendors | Yes | SQL package included | VIP1-3 test equipment plus optional gems, enchants, riding, mounts and profession helpers. VIP1/T14, VIP2/T15 and VIP3/T16 include class/spec-labelled five-piece PvE sets with genuine 2/4-piece bonuses; all three ranks' real weapons accept one Sha-Touched legendary gem. |
| AuctionHouseBot | Yes | **Disabled** | Seller and buyer are both disabled in the active `worldserver.conf`; normal player auctions are unaffected. |
| Warden client checks | Yes | **Disabled** | The Warden subsystem and check data are present, but `Warden.Enabled = 0` in the active configuration. |

### Major Custom Systems

- **Playerbot Arena automation:** a real player can use an Arena Battlemaster's
  custom solo 2v2/3v3/5v5 choices. The server selects the required teammate and
  opponents, loads only the managed bots, creates the teams, queues the match and
  restores managed bot state afterward. The connected real player's equipment is
  never replaced by the temporary bot loadout.
- **Playerbot Battleground automation:** specific and random BG queues can be
  populated only in response to a real player's queue. Objective routing exists
  for the playable local 5.4.8 BG templates, including Warsong Gulch, Twin Peaks,
  Arathi Basin, Battle for Gilneas, Eye of the Storm, Temple of Kotmogu, Deepwind
  Gorge, Silvershard Mines, Alterac Valley, Isle of Conquest and Strand of the
  Ancients. Score and rewards still go through normal battleground handlers.
- **Playerbot LFG automation:** missing dungeon roles are selected by faction,
  level, specialization and eligibility. Bot entry, proposal acceptance and group
  ownership use the core's normal LFG paths. Each filler gets one class-buff attempt
  after entering the dungeon and before combat; unlike Arena preparation, it is not
  retried after the requester or bot enters combat. Unsupported action target values
  are rejected safely and logged once with the bot, class, specialization, action and
  target-value names instead of crashing the map worker. The real requester remains
  every filler's pinned master for the complete run; fillers assist the requester's
  target and enemies already attacking the party, but cannot autonomously chain-pull
  unrelated packs merely because the requester is in combat. When the
  real requester leaves or logs out, only the automation-owned fillers are
  quiesced, removed from the abandoned instance group, returned outside and
  logged out; they are not left behind under a bot leader.
- **Pandaria world-boss raid staging:** visible neutral Boss Bot Callers are placed
  at supported outdoor bosses. They can assemble 10- or 25-player PvE raids around
  the requester, revive bots, apply role-appropriate builds/equipment, mark the
  main tank and primary healer, rebuff after deaths and safely dismiss the staged
  raid when the boss dies or the player cancels it. Headless playerbots are
  excluded from personal/bonus world-boss rewards regardless of whether they were
  called through this NPC or summoned normally; loot, money bags, currencies,
  legendary quest drops and loot lockouts remain reserved for real players.
- **Combat Assistant addon:** the tracked addon in
  [`contrib/combat_assistant_548`](contrib/combat_assistant_548) displays one
  recommended spell button and can bind it to key `2`. The server evaluates the
  active class/spec, talents, resources, cooldowns, crowd control, interrupts,
  dispels, emergency healing, defensives and supported ally protection. It never
  auto-casts and does not bypass GCD, range, facing, immunity or line of sight.
- **VIP PvE test equipment:** the package in
  [`vip_hybrid_solo_set_sql`](vip_hybrid_solo_set_sql) provides free test vendors
  and class/spec-aware VIP1 T14, VIP2 T15 and VIP3 T16 equipment for solo and
  encounter testing. The
  package keeps its generated SQL and source generator together so it can be
  reproduced on another database.

### Core, Quest and Database Work

The project also contains many bounded, source-backed fixes rather than blanket
deletions made only to silence logs. Notable completed work includes:

- Pandaren Alliance/Horde faction choice now refreshes the 5.4.8 client without a
  relog; it was verified with the 32-bit client for Alliance and the 64-bit client
  for Horde.
- The Death Knight `Eye of Acherus` quest vehicle can complete its scripted flight
  and then be flown/controlled by the player.
- Wandering Isle quest chains, dialogue, credits, transports, balloon flight,
  phasing and duplicate-spawn problems have received targeted repairs.
- Wandering Isle quest `29792`, `Bidden to Greatness`, is verified end to end.
  One closed Mandori and Pei-Wu world gate is visible before the quest. Accepting
  the quest hides those base spawns and creates exactly one personal gate at each
  scene; both gates open automatically, cannot be clicked manually, award the
  required credits and allow the quest to complete normally. The underlying
  SmartAI no-parameter event fallthrough that caused duplicate summons was fixed
  in the core.
- Missing `creature_text` diagnostics include the requested text group, full source
  GUID, map, position and owner identity so an invalid `Talk()` caller can be traced.
- Spell scripts, conditions, SmartAI, creature text, LFG destinations, item random
  suffix data, vendors, pools and gameobject/creature spawns have been audited
  against compatible local SkyFire/Trinity database sources with backups before
  destructive changes.
- Reforge restore/update handling and Void Storage slot/persistence safety include
  compatible fixes selectively ported from a reviewed SkyFire 5.4.8 update range.
- The 2026-08-24 fresh-start audit completed with an empty `DBErrors.log` and no
  startup error/warning/invalid/missing/crash diagnostics in `Server.log`.
- The extraction helper also copies client `cameras` data used by cinematic camera
  paths in addition to `dbc`, `maps`, `vmaps` and `mmaps`.

Detailed implementation history, exact backups, deferred work and verification
results are recorded in
[`doc/startup-log-fix-plan-2026-07-09.md`](doc/startup-log-fix-plan-2026-07-09.md).
SkyFire migration/source comparison notes are in
[`doc/SKYFIRE_548_MIGRATION_CHECKLIST.md`](doc/SKYFIRE_548_MIGRATION_CHECKLIST.md).

### Known Limits

- Playerbots and the Arena/BG/LFG/world-boss automation are development/test
  features. Individual class AI and encounter mechanics still need wider in-game
  verification.
- Generic world-boss tank swapping is not guessed without verified encounter data.
  Galleon has separate add-tank handling; other boss-specific positioning and
  handoff logic remains encounter-dependent.
- Some old database warnings remain deliberately unchanged where no exact compatible
  source exists. Data is not removed merely to make a warning disappear.

## Requirements

### Windows

- Windows 10/11 x64
- Visual Studio 2022 Community with `Desktop development with C++`
- Windows SDK 10.0.22621 or newer
- CMake 3.27 or newer
- Boost 1.85 x64 for MSVC 14.3/14.4
- Wampserver 3.4.2 with MySQL 5.7.44 (verified project database runtime)
- OpenSSL 1.1.1 or OpenSSL 3.x

Tested local Windows layout:

```txt
Wampserver: 3.4.2 64-bit
Apache:     2.4.67
PHP:        7.4.33
MySQL:      5.7.44 (active project DBMS)
MariaDB:    11.4.9 (installed with Wampserver, not the active project DBMS)
Boost:      C:/local/boost_1_85_0
OpenSSL:    C:/Program Files/OpenSSL-Win64
```

### Linux

- GCC 13+ or Clang 12+
- CMake 3.27+
- Boost 1.81+
- MySQL 5.7-compatible server; other database engines/major versions are not part
  of the currently verified project runtime
- OpenSSL 1.1.1 or 3.x

## Configure and Build on Windows

The repository includes a CMake preset for a Wampserver-style Windows setup:

```powershell
cmake --preset windows-wamp-vs2022
cmake --build --preset windows-wamp-vs2022-relwithdebinfo
```

Or open the generated solution:

```txt
Build/Legends-of-Azeroth-Pandaria-5.4.8.sln
```

Recommended Visual Studio build configuration:

```txt
RelWithDebInfo x64
```

The built executables will be in:

```txt
Build/bin/RelWithDebInfo
```

Important executables:

```txt
authserver.exe
worldserver.exe
mapextractor.exe
vmap4extractor.exe
vmap4assembler.exe
mmaps_generator.exe
```

## OpenSSL 3 Legacy Provider

For OpenSSL 3, the server needs the OpenSSL legacy provider because MoP authentication still uses RC4 through `AuthCrypt`.

If you use OpenSSL 3, copy this file:

```txt
C:/Program Files/OpenSSL-Win64/bin/legacy.dll
```

next to the server executables:

```txt
Build/bin/RelWithDebInfo/legacy.dll
```

Without this file, `worldserver.exe` can crash when a client connects to the realm. The crash stack usually points to:

```txt
Trinity::Crypto::ARC4::ARC4
AuthCrypt::AuthCrypt
WorldSocket::WorldSocket
```

Also keep these DLLs next to the executables:

```txt
libcrypto-3-x64.dll
libssl-3-x64.dll
libmysql.dll
```

## Database Setup

Create the base databases:

```sql
CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE characters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE acore_playerbots DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```

Import the base SQL files:

```txt
sql/base/auth.sql
sql/base/characters.sql
sql/base/world_548_20240722.sql
```

Then import relevant updates from:

```txt
sql/updates
modules/mod_playerbots/data/sql
```

Playerbots uses its own database. The runtime config should point to it:

```ini
PlayerbotsDatabaseInfo = "127.0.0.1;3306;user;password;acore_playerbots"
PlayerbotsDatabase.WorkerThreads = 1
PlayerbotsDatabase.SynchThreads = 1
```

The verified local runtime uses `acore_playerbots`. A database named
`mop_playerbots` may exist on a development machine as an older/imported comparison
database, but it is not used unless `PlayerbotsDatabaseInfo` is explicitly changed
to point to it.

## Configuration Files

Copy or keep the generated config files next to the executables:

```txt
authserver.conf
worldserver.conf
playerbots.conf
```

Useful local settings:

```ini
DataDir = "."
RealmID = 1
WorldServerPort = 8085
BindIP = "0.0.0.0"
Console.Enable = 0
Warden.Enabled = 0
```

`Console.Enable = 0` is useful when running `worldserver.exe` in the background. If you launch it manually in a visible terminal and want console commands, set it to `1`.

### AuctionHouseBot and Warden

Both systems are compiled into the project, but both are intentionally disabled in
the current active local configuration:

```ini
AuctionHouseBot.Seller.Enabled = 0
AuctionHouseBot.Buyer.Enabled = 0
AuctionHouseBot.Buyer.Alliance.Enabled = 0
AuctionHouseBot.Buyer.Horde.Enabled = 0
AuctionHouseBot.Buyer.Neutral.Enabled = 0

Warden.Enabled = 0
```

AuctionHouseBot can seed auctions and buy player auctions when configured, but no
AuctionHouseBot seller/buyer activity is currently requested. This does not disable
the normal Auction House used by players.

Warden is the core's client integrity/check subsystem. Its check definitions may
still be loaded during WorldServer startup even while `Warden.Enabled = 0`; that
startup message alone does not mean checks or enforcement are active. Review its
failure action, hold-off, response delay and ban settings before enabling it on a
public realm. The distributed `worldserver.conf.dist` currently has a different
Warden default, so preserve `Warden.Enabled = 0` in the active `worldserver.conf`
when copying or regenerating configuration files if Warden should remain disabled.

For a local server, set the realm address in the `auth.realmlist` table:

```sql
UPDATE auth.realmlist
SET address = '127.0.0.1',
    localAddress = '127.0.0.1',
    localSubnetMask = '255.255.255.0',
    port = 8085,
    gamebuild = 18414
WHERE id = 1;
```

## Extracting Client Data

The server needs client data extracted from a clean World of Warcraft `5.4.8.18414` client:

```txt
dbc
maps
vmaps
mmaps
cameras
```

Build the project with `TOOLS=ON`, then copy or use:

```txt
extract_548_18414_maps_vmaps_mmaps.bat
```

Put the `.bat` file in the root of the WoW client folder and run it there. Before running, edit these paths inside the file if your project is not in the default local path:

```bat
set "TOOLS_DIR=C:\wamp64\www\Legends-of-Azeroth-Pandaria-5.4.8\Build\bin\RelWithDebInfo"
set "SERVER_DIR=C:\wamp64\www\Legends-of-Azeroth-Pandaria-5.4.8\Build\bin\RelWithDebInfo"
```

For build `5.4.8.18414`, the extractor uses:

```bat
set "TARGET_BUILD=18273"
```

This is expected for this extractor and client data layout.

## Running the Server

Start MySQL first, then run:

```txt
Build/bin/RelWithDebInfo/authserver.exe
Build/bin/RelWithDebInfo/worldserver.exe
```

Ports:

```txt
authserver:  3724
worldserver: 8085
```

Create an account from the `worldserver` console:

```txt
account create Admin password
account set gmlevel Admin 3 -1
account set addon Admin 4
```

For a local client, set `WTF/Config.wtf`:

```txt
SET realmlist "127.0.0.1"
SET portal "127.0.0.1"
```

## Playerbots

Playerbots are included and enabled in the current local test setup, but remain
experimental. They may still expose class-, map- or encounter-specific gameplay
issues depending on database state and configuration.

Required file:

```txt
Build/bin/RelWithDebInfo/playerbots.conf
```

Basic enable/disable options:

```ini
AiPlayerbot.Enabled = 1
AiPlayerbot.RandomBotAutologin = 0
```

Automatic random-bot login is not required by the custom queue systems. Arena, BG,
LFG and world-boss staging load only the exact bots selected for the real player's
request and clean them up afterward.

Every random-bot login equips four `Royal Satchel` bags (28 slots each) before
specialization, Caller or loadout preparation begins. A pre-existing bag that
contains any item is never removed; an empty smaller bag may be upgraded. Gear
initialization repeats this capacity check before replacing equipment.

Hunter random bots also recover older pets that were accidentally persisted in
invalid slot `255`; the pet is moved into a valid active slot instead of making
the bot repeat `Call Pet 1` indefinitely. Raid preparation casts Arcane
Brilliance on the party rather than only checking the mage's own persistent
aura. Shaman raid cooldown totems are coordinated across nearby headless bots:
only one Mana Tide is active at once, and Spirit Link/Healing Tide are staggered
instead of being spent together. Personal damage totems and stackable healing
totems remain independent.

World-boss composition maximizes class diversity inside each role before
filling duplicate-class slots. A 25-player Alliance pool therefore uses one
Paladin, Priest, Shaman, Monk and Druid healer when all five are free, and takes
one representative of every available DPS class before adding further damage
bots. Low starting item level no longer excludes a valid class; selected bots
receive their specialization's five-piece item-level 566 T16 set and the
appropriate legendary cloak. Remaining slots prioritize missing raid buffs,
then lower PvP-piece count and higher starting item level, with random choice
between exact gear ties.

Random-bot hunter pets use the PvE Ferocity specialization. Every permanent
Playerbot pet—including Hunter, Warlock and Mage pets—uses passive reaction.
Taunt and direct threat-generating pet spells are disabled both during pet
initialization and later autocast maintenance, and a pet attack command is
refused until its target has already entered combat (or the owner is directly
attacking that target), preventing the pet from pulling for the raid.

The active local test configuration currently enables the request-driven queue
features and Combat Assistant:

```ini
AiPlayerbot.AutoQueue.Enabled = 1
AiPlayerbot.AutoQueue.DryRun = 1
AiPlayerbot.AutoQueue.LFG = 1
AiPlayerbot.AutoQueue.LFG.Automatic = 1
AiPlayerbot.AutoQueue.Battleground = 1
AiPlayerbot.AutoQueue.Battleground.Automatic = 1
AiPlayerbot.AutoQueue.Arena = 1
AiPlayerbot.AutoQueue.Arena.Automatic = 1
AiPlayerbot.AutoQueue.Arena.AutomaticBattlemasterSolo = 1
AiPlayerbot.CombatAssistant.Enabled = 1
LFGSolo.Enabled = 0
```

`DryRun = 1` keeps the older generic observer protected. The newer explicitly
enabled request-driven Arena/BG/LFG paths have their own gates and are not disabled
by that observer setting. Distributed `.dist` configurations retain safer defaults;
do not assume a newly copied config matches the local test configuration.

The legacy `LFGSolo` shortcut must remain disabled while playerbot LFG filling is
enabled. When `LFGSolo.Enabled = 1`, every dungeon queue is reduced to one damage
slot, the real player receives an immediate solo proposal, and there are no missing
tank/healer/damage slots for the bot automation to fill.

Implementation and test details are documented in
[`contrib/playerbot_auto_queue_548/README.md`](contrib/playerbot_auto_queue_548/README.md).

For debugging, disable them:

```ini
AiPlayerbot.Enabled = 0
AiPlayerbot.RandomBotAutologin = 0
```

The first playerbots startup can take longer because random bot accounts and characters are prepared.

## Troubleshooting

If the client reaches realm selection but disconnects when selecting the realm:

- Check that `worldserver.exe` is still running.
- Check that port `8085` is listening.
- If using OpenSSL 3, make sure `legacy.dll` is next to `worldserver.exe`.
- Check `Build/bin/RelWithDebInfo/Logs/Server.log`.
- Check crash reports in `Build/bin/RelWithDebInfo/Crashes`.

PowerShell checks:

```powershell
Get-Process authserver,worldserver -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 3724,8085 -ErrorAction SilentlyContinue
```

If `authserver.exe` says port `3724` is already in use, another `authserver` instance is already running:

```powershell
taskkill /F /IM authserver.exe
```

## License

GPL-2.0. See [COPYING.md](COPYING.md).

## Authors and Contributors

See [THANKS.md](THANKS.md).

## Build Status

[![windows-build](https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8/actions/workflows/windows-build-release.yml/badge.svg?branch=master)](https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8/actions/workflows/windows-build-release.yml)
[![linux-gcc-build](https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8/actions/workflows/linux_gcc.yml/badge.svg?branch=master)](https://github.com/Legends-of-Azeroth/Legends-of-Azeroth-Pandaria-5.4.8/actions/workflows/linux_gcc.yml)

<a href="https://scan.coverity.com/projects/legends-of-azeroth-mop">
  <img alt="Coverity Scan Build Status" src="https://scan.coverity.com/projects/26941/badge.svg"/>
</a>
