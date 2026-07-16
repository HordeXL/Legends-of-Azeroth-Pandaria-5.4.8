# SkyFire 548 Migration Checklist

Avots: `C:\wamp64\www\SkyFire_548`
Merkis: `C:\wamp64\www\Legends-of-Azeroth-Pandaria-5.4.8`

Sis fails ir darba saraksts atlasitajiem SkyFire 548 labojumiem. Atzime `- [x]`, kad punkts ir parbaudits, parnests vai apzinati noraidits. Pie katra punkta pieraksti isu piezimi, commit hash vai SQL failu, ja tas jau ir izdarits.

## Noteikumi

- Neparnest visu SkyFire `src` mapi.
- Neparnest visu SkyFire world dumpu.
- SQL failus parnest tikai pec tabulu un kolonnu salidzinasanas ar musu shemu.
- `DROP TABLE` tipa migracijas nepalaist pret esosu world DB bez atseviska backup un manualas parbaudes.
- `skyfire_string` musu projekta jaadapte uz `trinity_string`.
- `playercreateinfo_spell_cast` musu projekta jaadapte uz `playercreateinfo_cast_spell`.

## Build Prasibas

- [x] Parbaudit, vai vajag parnemt SkyFire CMake prasibu izmainas.
  - Avots: `SkyFire_548/CMakeLists.txt`
  - SkyFire: CMake `3.27.7` Linux, `4.1.2` Windows, C++23, Boost `1.91.0`, OpenSSL minimums `4.0.0`.
  - Musu projekts: CMake `3.16`, C++20.
  - Piezimes: neparnest saja migracijas posma. Musu projekts veiksmigi buvejas ar esosho `Build` konfiguraciju un C++20; SkyFire toolchain prasibas ir projekta/platformas modernizacija, ne konkreto runtime/SQL fixu dependencies. Atsevisks toolchain upgrade japlano tikai pec vajadzibas, ne saja SkyFire selected fixes porta.

- [x] Izlemt, vai README prasibas jaatjauno pa posmiem vai tikai pec build migracijas.
  - Risks: dokumentacija var prasit toolchain, kuru projekts vel reali neizmanto.
  - Piezimes: README prasibas tagad nemainit. Dokumentaciju atjaunot tikai tad, ja reali tiek parnestas build/toolchain prasibas un parbaudits pilns build uz jaunajiem minimumiem; citadi README prasitu versijas, kuras projekts vel nav pienemis.

## Core Patch Kandidati

- [x] Parbaudit un parnest `mmaps_generator` output mapes autoizveidi.
  - Avots commit: `8fd50ef0dd Create mmap output directory automatically`
  - Fails: `src/tools/mmaps_generator/PathGenerator.cpp`
  - Risks: zems.
  - Piezimes: musu `PathGenerator.cpp` jau izveido `mmaps` mapi ar `boost::filesystem::create_directory("mmaps")`, tapec SkyFire patch nav japarnes atseviski.

- [x] Parbaudit, vai character list refresh pec character delete jau ir musu projekta.
  - Avots commit: `b942f5b982 Fix client character list not updating after character deletion`
  - Musu fails: `src/server/game/Handlers/CharacterHandler.cpp`
  - Statuss no sakotneja audita: izskatas jau ieviests pie character delete handlera.
  - Piezimes: nebija ieviests; parnests ekvivalents labojums. Pec `SMSG_CHAR_DELETE` success musu kods tagad izsauc `HandleCharEnumOpcode` ar tukshu `EnumCharacters` packetu, lai klientam aiziet svaigs `SMSG_CHAR_ENUM`.

- [x] Auditet Deeprun Tram / legacy transport compatibility.
  - Avots commit: `58b309aae4 Add isolated Deeprun Tram transport compatibility`
  - Saistits commit: `3e7d6869b9 Preserve Deeprun station objects while riding`
  - Faili: `LegacyTransportSupport.*`, `TransportMgr`, `Transport`, `Map`, `ObjectMgr`, `GridNotifiers`
  - Risks: augsts, jo transportu sistemas atskiras.
  - Piezimes: SkyFire patch galvenokart mape vecos DB entry `176080-176085` uz klienta Subway entry `218203-218208` un pievieno izolētu legacy local transport slani. Musu `world` DB jau satur `gameobject` spawnus ar klienta entry `218203-218208` map 369, nevis vecos `176080-176085`; `gameobject_template` sim entry ir `GAMEOBJECT_TYPE_TRANSPORT`, `ObjectMgr` tos registre ka local transports, un `Transport::CreateLocal` jau satur Subway rotaciju special case `218203-218208`. Pedejos startup/shutdown logos nav `missing TransportAnimation`, `will not be created`, `Deeprun` vai Subway transport kludu. SkyFire legacy mapping slani paslaik neparnest; atgriezties pie si tikai, ja reala speles testa Deeprun Tram neredz/vai pazud station objekti brauciena laika.

- [x] Auditet cinematic/login/logout crash fixus.
  - Avoti:
    - `33e826eaa9 Fix client stack overflow on login/logout...`
    - `dbe92a5a06 Fix client crash during intro cinematic...`
    - `4407a5ac2f Fix client UI stack overflow...`
    - `89ec14ad24 Ignore client movement packets during player cinematic...`
  - Faili: `Player.cpp`, `WorldSession.cpp`, `QuestHandler.cpp`, `MovementHandler.cpp`
  - Risks: videjs/augsts, jo musu cinematic implementacija atskiras.
  - Piezimes: tie ir C++ runtime fixi, ne SQL. Musu `SMSG_TRIGGER_CINEMATIC` jau izmanto 4 baitu `WorldPackets::Misc::TriggerCinematic`, tapec SkyFire packet revert dala jau atbilst. Parnests logout complete fixes (`SMSG_LOGOUT_COMPLETE` bez lieka GUID payload), pievienots `Player::IsInCinematic()`, un guardi questgiver status query/movement packetiem cinematic/logout laika.

- [x] Auditet `Fix quest details divider guid`.
  - Avots commit: `df45d5df43 Fix quest details divider guid`
  - Fails: `src/server/game/Entities/Creature/GossipDef.cpp`
  - Risks: videjs.
  - Piezimes: musu `SendQuestGiverQuestDetails` jau izmanto `guid = _session->GetPlayer()->GetDivider()` un `guid2 = npcGUID`; mask/byte seciba atbilst SkyFire labotajai versijai, kur divider GUID un quest giver GUID vairs nav samainiti. Papildu C++ izmainas nav vajadzigas.

## SQL Kandidati, Kurus Var Parnest Pec Parbaudes

- [x] `2024_09_08_world_00.sql`
  - Avots: `SkyFire_548/sql/updates/world/2024_09_08_world_00.sql`
  - Saturs: Stolen Malt Sack flags/loot.
  - Risks: zems.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`; `gameobject_template.flags` adaptets uz `gameobject_template_addon.flags`.

- [x] `2025_02_02_world_00.sql`
  - Avots: `SkyFire_548/sql/updates/world/2025_02_02_world_00.sql`
  - Saturs: questender fix quest `12636`.
  - Risks: zems.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`.

- [x] `2026_06_22_world_01.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_06_22_world_01.sql`
  - Saturs: kill credit un graveyard cleanup.
  - Risks: zems/videjs.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`.

- [x] `2026_06_22_world_02.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_06_22_world_02.sql`
  - Saturs: Timeless Isle lootid links.
  - Risks: videjs, japarbauda esosie `lootid`.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`.

- [x] `2026_06_22_world_03.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_06_22_world_03.sql`
  - Saturs: SoO/MoP creature loot rows.
  - Risks: videjs, var parrakstit esosu loot balansu.
  - Piezimes: auditets un apzinati nav importets. Fails veic `DELETE` uz 17 `creature_loot_template` entry un pec tam ievieto 1047 loot rindas; musu `world` DB tiem pasiem entry jau ir 266 rindas, tai skaita difficulty specifiski `lootmode` un reference loot (`mincountOrRef` negativas vertibas). Pilnu batch nelaist ka migration fix, jo tas parrakstitu esosu SoO loot strukturu/balansu. Ja velak reala speles testa atrod konkretu SoO loot problemu, taisit per-entry diff/merge ar backup, nevis importet so failu pilna apjoma.

- [x] `2026_06_27_world_02.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_06_27_world_02.sql`
  - Saturs: Bellygrub duplicate spawn cleanup.
  - Risks: zems.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`.

- [x] `2026_07_05_world_00.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_07_05_world_00.sql`
  - Saturs: Jitter's Bugs quest loot/phasing fix.
  - Risks: zems/videjs.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`; `spell_area` rinda `spell=49416, quest_start=26717` musu DB neeksisteja, tapec si update dala bija no-op.

- [x] `2026_07_05_world_01.sql`
  - Avots: `SkyFire_548/sql/updates/world/2026_07_05_world_01.sql`
  - Saturs: Extinguishing Hope quest `26391`.
  - Risks: zems/videjs.
  - Piezimes: sagatavots un palaists `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`; `modelid1/modelid2` adaptets uz `creature_template_model`; `SourceGroup = 0` izlaists, jo gan musu, gan SkyFire `ConditionMgr` to ignoretu; SkyFire commit `025994932d` sim fixam nepievieno C++ izmainas.

## SQL Kandidati, Kas Jaadapte

- [x] Adaptet `2026_01_23_world_00.sql`.
  - Avots izmanto: `skyfire_string`
  - Musu DB izmanto: `trinity_string`
  - Risks: zems pec tabulas nosaukuma un kolonnu pielagosanas.
  - Piezimes: adaptets faila `sql/updates/world/2026_07_08_02_skyfire_account_gm_strings_commands.sql` un palaists pret `world` DB. `skyfire_string` pielagots uz `trinity_string`; SkyFire `command.permission` RBAC ID netika importeti tiesi, jo musu tabula izmanto `command.security` ar `AccountTypes` 0-4. Iestatits `account set gmlevel` security `2` un `gm list` security `0`; DB parbaude OK.

- [x] Adaptet `2026_06_27_world_00.sql`.
  - Avots izmanto: `playercreateinfo_spell_cast`
  - Musu DB izmanto: `playercreateinfo_cast_spell`
  - Risks: videjs, japarbauda kolonnu nosaukumi un esosie dati.
  - Piezimes: adaptets atseviska faila `sql/updates/world/2026_07_08_00_skyfire_hunter_start_pet_spells.sql`; palaists pret `world` DB, parbaudits 14 rindu imports; worldserver startup OK, ieladeti 76 player create cast spells bez `playercreateinfo_cast_spell` kludam; notestets ar jaunu hunter character izveidi, visiem pareizi pieliekas starta pets.

- [x] Adaptet vai izlaist `2026_06_27_world_01.sql`.
  - Avots izmanto: `playercreateinfo_spell`
  - Musu baze si tabula nav tada pasa forma.
  - Risks: videjs.
  - Piezimes: parbaudits; SkyFire fails tikai dzes `Spell IN (13358, 24949, 87816)` no `playercreateinfo_spell`. Musu `world` DB nav `playercreateinfo_spell` tabulas, bet ir `playercreateinfo_cast_spell` un `playercreateinfo_spell_custom`; konkretie spell ID neeksiste ne viena no sim tabulam. Atsevisks SQL nav vajadzigs, fix mums ir no-op.

- [x] Auditet `2026_06_27_world_03.sql`.
  - Saturs: `areatrigger_tavern_rest_area` jauna tabula un dati.
  - Risks: augsts, jo vajag atbilstosu core loaderi.
  - Piezimes: SQL viens pats nav pietiekams. Musu core nelasa `areatrigger_tavern_rest_area`; `ObjectMgr::LoadTavernAreaTriggers()` lasa tikai `areatrigger_tavern`, un `MiscHandler::HandleAreaTriggerOpcode()` tavern gadijuma tikai izsauc `SetRestFlag`/`RemoveRestFlag`. SkyFire sim fixam ir C++ atbalsts commitos `5d9d675931`, `89aee0459e`, `6cc43c6f1a`, bet musu rest sistema atskiras no SkyFire `InnEnter/REST_TYPE_IN_TAVERN` modela, tapec ports nav tikai SQL un nav tiesi cherry-pickojams. Japlano atsevisks C++ adapters vai janoignore lidz ir konkrets Goldshire/rest bug reproduceris.

## SQL, Ko Nepalaist Tiesi

- [x] Noraidit vai manuali parrakstit `2026_07_04_world_01.sql`.
  - Iemesls: `DROP TABLE IF EXISTS gossip_menu`.
  - Risks: augsts, var izdzesst esosu MoP/custom gossip saturu.
  - Piezimes: tiesi nepalaist. Ja no si faila vajadzes konkretas rindas, tas japarparaksta manuala, salidzinosha update faila bez `DROP TABLE` un bez pilna gossip satura parrakstisanas.

- [x] Noraidit vai manuali parrakstit `2026_07_04_world_02.sql`.
  - Iemesls: `DROP TABLE IF EXISTS gossip_menu_option`.
  - Risks: augsts, var izdzesst esosu MoP/custom gossip saturu.
  - Piezimes: tiesi nepalaist. Ja no si faila vajadzes konkretas rindas, tas japarparaksta manuala, salidzinosha update faila bez `DROP TABLE` un bez pilna gossip option satura parrakstisanas.

- [x] Parbaudit, vai `2026_07_04_world_00.sql` mums vispar ir vajadzigs.
  - Faila komentars: `Quest POI port from LOA`.
  - Sakotnejais secinajums: tas drizak ir no musu datiem uz SkyFire, nevis otradi.
  - Piezimes: neimportet no SkyFire uz musu DB. Faila merkis pec komentara ir LOA Quest POI ports uz SkyFire, tapec tas nav migracijas kandidats atpakal uz LOA.

## Ja Velak Tomer Parnest Lielos/Atliktos Failus

Sis nav daramo darbu saraksts tagadejai migracijai. Tas ir drosibas plans gadijumam, ja velak nolemj parnest lielos SQL vai DB batchus, kuri saja posma tika noraiditi vai atlikti.

- `2026_06_22_world_03.sql` / SoO creature loot:
  - Ko dotu, ja parnestu: varetu papildinat Siege of Orgrimmar/MoP boss un creature loot ar SkyFire/Wowhead balstitiem item dropiem, ja speles testa redzams, ka kadiem bossiem trukst loot vai drop table ir parak tuksa.
  - Nelaist originalo failu pilna apjoma, jo tas sakas ar `DELETE FROM creature_loot_template WHERE entry IN (...)`.
  - Pirms darba izveidot backup tikai skartajiem entry: `creature_loot_template` rindas entry `71454,71515,71543,71770,71771,71772,71773,72131,72354,72421,72655,72658,72791,72929,73342,73349,73452`.
  - Sadali darbu pa vienam boss/entry, nevis vienu 1047 rindu batch.
  - Salidzini esosho loot ar SkyFire loot pec `entry`, `item`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`.
  - Saglaba musu difficulty specifiskos `lootmode` un reference loot (`mincountOrRef` negativas vertibas), ja vien reala testa nav pieradits, ka tiesi tas ir nepareizi.
  - Ja vajag pievienot trukstosos itemus, veidot manualu `INSERT IGNORE`/`UPDATE` failu bez lielas sakuma dzesanas.
  - Pec katra entry testa: worldserver startup, `DBErrors.log`, boss kill/loot in-game parbaude attiecigaja difficulty.

- `2026_07_04_world_01.sql` / `gossip_menu` un `2026_07_04_world_02.sql` / `gossip_menu_option`:
  - Ko dotu, ja parnestu: varetu salabot vai papildinat NPC dialogus, gossip opcijas, quest/teleport/vendor/trainer saites un citus menu ierakstus, ja konkretam NPC spele trukst pareizs dialogs vai opcija.
  - Nelaist originalos failus, jo tie satur `DROP TABLE` un pilnu tabulu parrakstisanu.
  - Vispirms eksportet musu esoshas `gossip_menu` un `gossip_menu_option` tabulas backupam.
  - Importet SkyFire failus tikai atseviska pagaidu datubaze vai temp tabulas, nevis tiesi `world`.
  - Izveidot diff: rindas, kas SkyFire ir jaunas, rindas, kas atskiras, un rindas, kuras musu DB ir custom/MoP specifiskas.
  - Parnest tikai konkretas rindas ar manualu `INSERT ... ON DUPLICATE KEY UPDATE` vai atseviskiem `UPDATE`, noradot iemeslu katrai grupai.
  - Pec porta parbaudit NPC gossip in-game tiem NPC/menus, kurus diff maina; tikai DB startup bez kludam nav pietiekams tests.

- `2026_07_04_world_00.sql` / Quest POI port from LOA:
  - Ko dotu, ja parnestu pareiza virziena: varetu salabot quest objektivu punktus kartes/minimap POI datos, ja klienta quest tracker rada nepareizu vietu vai vispar nerada quest zonu.
  - Nepienemt ka tas ir SkyFire -> LOA fixes fails; pec komentara tas ir LOA dati, kas porteti uz SkyFire.
  - Ja velak vajag Quest POI salidzinasanu, taisit abas puses diffu pa `quest_poi` un `quest_poi_points`, nevis importet failu atpakal.
  - Parnest tikai tas rindas, kuras musu DB reali trukst vai atskiras no sagaidama klienta quest map behavior.

- `2026_06_27_world_03.sql` / tavern rest area:
  - Ko dotu, ja parnestu ar C++ atbalstu: varetu precizak noteikt inn/tavern rest zonas, lai speletajs pareizi sanem rested state un logout/rest behavior konkrētās vietās.
  - SQL viens pats nav pietiekams, jo musu core nelasa `areatrigger_tavern_rest_area`.
  - Pirms SQL porta izveidot C++ dizainu: vai nu adaptet musu esosho `areatrigger_tavern` loaderi, vai ieviest jaunu loaderi ar skaidru integraciju `ObjectMgr` un `MiscHandler`.
  - Salidzinat SkyFire commitus `5d9d675931`, `89aee0459e`, `6cc43c6f1a` pret musu rest sistemu; cherry-pick netaisit akli, jo modeli atskiras.
  - Tests pec porta: Goldshire/inn rest enter/leave, logout rest state, hearthstone inn behavior, un DB startup bez missing table/loader kludam.

- SkyFire full world dump:
  - Ko dotu, ja izmantotu ka references avotu: tas var kalpot ka salidzinasanas baze trukstosiem spawn, quest, loot, gossip, SmartAI vai template datiem, bet tikai konkrētu bugu labosanai.
  - Neimportet pari musu `world` DB.
  - Ja vajag izmantot ka references avotu, importet tikai atseviska salidzinasanas datubaze, piemeram `skyfire_world_ref`.
  - Salidzinat pa tabulam un pa konkretu bug/reproduceri, nevis "sync all".
  - Katram parnesumam veidot mazu, reversible SQL update failu ar komentaru, no kuras SkyFire tabulas/rindam dati nemti.
  - Pec katra maza batch palaist worldserver un parbaudit `DBErrors.log`; lielus batchus nedrikst kraut bez starptesta.

## World DB Kopejais Secinajums

- [x] Apstiprinat, ka SkyFire full world dump netiks importets pari musu DB.
  - SkyFire SFDB dump: aptuveni 119 MB, 172 tabulas.
  - Musu world dump: aptuveni 481 MB, 230 tabulas.
  - Risks: loti augsts, ja importe pilnu dumpu.
  - Piezimes: apstiprinats. Pilnu SkyFire world dumpu neimportet pari musu DB; turpinam tikai ar atlasitiem, shemai pielagotiem SQL update failiem un atseviskiem C++ portiem.

- [x] Pirms jebkura SQL porta izveidot atsevisku musu SQL update failu.
  - Ieteiktais nosaukums: `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql`
  - Piezimes: fails izveidots ar atlasitajiem drosajiem fixiem un palaists pret `world` DB.

- [x] Pec katra SQL porta parbaudit `DBErrors.log` un worldserver startup.
  - Piezimes: `sql/updates/world/2026_07_06_00_skyfire_selected_fixes.sql` notestets; batch atzits par kartiba.
