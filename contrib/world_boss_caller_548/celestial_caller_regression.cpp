#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <list>
#include <string>
#include <vector>

using uint32 = std::uint32_t;
using uint8 = std::uint8_t;
constexpr uint32 UNIT_FIELD_FLAGS = 0;
constexpr uint32 UNIT_FLAG_NON_ATTACKABLE = 2;
constexpr uint32 UNIT_FLAG_IMMUNE_TO_PC = 256;
constexpr uint32 UNIT_FLAG_NON_ATTACKABLE_2 = 65536;
constexpr uint32 UNIT_FLAG_NOT_SELECTABLE = 33554432;
constexpr uint32 GOSSIP_ACTION_INFO_DEF = 1000;
constexpr uint32 GOSSIP_SENDER_MAIN = 1;
constexpr uint32 GOSSIP_ICON_CHAT = 0;
constexpr uint32 DEFAULT_GOSSIP_MESSAGE = 68;

struct ObjectGuid
{
    uint32 Counter;
    uint32 GetCounter() const { return Counter; }
};

struct WorldObject
{
    uint32 Phase = 1;
    bool InSamePhase(WorldObject const* other) const { return (Phase & other->Phase) != 0; }
};

struct Creature : WorldObject
{
    Creature(uint32 entry, ObjectGuid guid) : Entry(entry), Guid(guid) { }
    uint32 Entry;
    ObjectGuid Guid;
    uint32 Faction = 35;
    uint32 Flags = UNIT_FLAG_NON_ATTACKABLE;
    bool Alive = true;
    bool InWorld = true;
    bool Combat = false;
    bool Evade = false;
    float Distance = 0.0f;
    std::vector<Creature*> Nearby;

    uint32 GetEntry() const { return Entry; }
    ObjectGuid GetGUID() const { return Guid; }
    uint32 GetDBTableGUIDLow() const { return Guid.Counter; }
    uint32 GetFaction() const { return Faction; }
    bool IsAlive() const { return Alive; }
    bool IsInWorld() const { return InWorld; }
    bool IsInCombat() const { return Combat; }
    bool IsInEvadeMode() const { return Evade; }
    bool HasFlag(uint32, uint32 mask) const { return (Flags & mask) != 0; }
    void GetCreatureListWithEntryInGrid(std::list<Creature*>& result, uint32 entry, float radius)
    {
        for (auto* boss : Nearby)
            if (boss->Entry == entry && boss->Distance <= radius)
                result.push_back(boss);
    }
    Creature* FindNearestCreature(uint32 entry, float radius, bool alive)
    {
        Creature* nearest = nullptr;
        for (auto* boss : Nearby)
            if (boss->Entry == entry && boss->Alive == alive && boss->Distance <= radius &&
                InSamePhase(boss) && (!nearest || boss->Distance < nearest->Distance))
                nearest = boss;
        return nearest;
    }
};

#include "celestial_caller_production.inc"

struct MenuItem { std::string Text; uint32 Sender; uint32 Action; };
struct Player : WorldObject
{
    std::vector<MenuItem> Items;
    bool Closed = false;
    void* GetSession() { return nullptr; }
};
struct ChatHandler
{
    explicit ChatHandler(void*) { }
    template<class... Args> void PSendSysMessage(char const*, Args...) { }
};
enum class WorldBossStagedState { Idle, Grouped };
WorldBossStagedState WorldBossStageState = WorldBossStagedState::Idle;
WorldBossCallerConfig Config;
bool ValidConfig = true;
bool LoadWorldBossCallerConfig(Creature*, WorldBossCallerConfig& config)
{
    config = Config;
    return ValidConfig;
}
char const* GetSupportedWorldBossName(uint32 entry)
{
    switch (entry)
    {
        case 71952: return "Chi-Ji";
        case 71953: return "Xuen";
        case 71954: return "Niuzao";
        case 71955: return "Yu'lon";
        case 62346: return "Galleon";
        default: return nullptr;
    }
}
void ClearGossipMenuFor(Player* player) { player->Items.clear(); }
void CloseGossipMenuFor(Player* player) { player->Closed = true; }
void AddGossipItemFor(Player* player, uint32, std::string text, uint32 sender, uint32 action)
{
    player->Items.push_back({text, sender, action});
}
void SendGossipMenuFor(Player*, uint32, ObjectGuid) { }

#include "celestial_caller_menu.inc"

unsigned Checks = 0;
void Check(bool passed, char const* message)
{
    ++Checks;
    if (!passed) { std::cerr << "FAIL: " << message << '\n'; std::exit(1); }
}
bool HasAction(Player const& player, uint32 action)
{
    return std::any_of(player.Items.begin(), player.Items.end(),
        [action](MenuItem const& item) { return item.Action == action; });
}

int main()
{
    Creature caller{990912, {4000118}};
    Creature bosses[] = {{71952, {101}}, {71953, {102}}, {71954, {103}}, {71955, {104}}};
    for (auto& boss : bosses) caller.Nearby.push_back(&boss);
    Config.SearchRadius = 250.0f;
    Config.RaidSizeMask = 3;
    Player player;
    Check(!FindConfiguredWorldBoss(&caller, Config), "all four corner bosses are inactive");
    Check(!FindConfiguredWorldBoss(nullptr, Config), "missing caller");
    Check(!IsActiveCelestialWorldBoss(nullptr), "missing candidate");

    for (auto& boss : bosses)
    {
        boss.Faction = 31;
        Check(!FindConfiguredWorldBoss(&caller, Config), "intro is not yet attackable");
        boss.Flags = 0;
        Check(FindConfiguredWorldBoss(&caller, Config) == &boss, "each active Celestial resolves");
        ShowWorldBossCallerMenu(&player, &caller);
        Check(HasAction(player, WORLD_BOSS_CALLER_STAGE_10), "Call 10 offered");
        Check(HasAction(player, WORLD_BOSS_CALLER_STAGE_25), "Call 25 offered");
        for (auto const& item : player.Items)
        {
            if (item.Action == WORLD_BOSS_CALLER_STAGE_10 || item.Action == WORLD_BOSS_CALLER_STAGE_25 ||
                item.Action == WORLD_BOSS_CALLER_PREVIEW_10 || item.Action == WORLD_BOSS_CALLER_PREVIEW_25)
            {
                Check(item.Text.find(GetSupportedWorldBossName(boss.Entry)) != std::string::npos,
                    "menu names actual active boss");
                Check(WorldBossCallerSelectionMatches(&boss, item.Sender), "menu retains displayed spawn");
                Check(!WorldBossCallerSelectionMatches(nullptr, item.Sender), "missing boss rejects stale menu");
                Creature replacement = boss;
                ++replacement.Guid.Counter;
                Check(!WorldBossCallerSelectionMatches(&replacement, item.Sender), "replacement rejects stale menu");
            }
        }
        for (uint32 flag : {UNIT_FLAG_NON_ATTACKABLE, UNIT_FLAG_NON_ATTACKABLE_2,
            UNIT_FLAG_IMMUNE_TO_PC, UNIT_FLAG_NOT_SELECTABLE})
        {
            boss.Flags = flag;
            Check(!FindConfiguredWorldBoss(&caller, Config), "protected boss excluded");
        }
        boss.Flags = 0;
        boss.Evade = true;
        Check(!FindConfiguredWorldBoss(&caller, Config), "evading boss excluded from new Call");
        Check(!IsStagedCelestialUnavailable(&boss, boss.Entry), "evade preserves existing session");
        boss.Evade = false;
        boss.Alive = false;
        Check(!FindConfiguredWorldBoss(&caller, Config), "dead boss excluded");
        boss.Alive = true;
        boss.InWorld = false;
        Check(!FindConfiguredWorldBoss(&caller, Config), "unloaded boss excluded");
        boss.InWorld = true;
        boss.Phase = 2;
        Check(!FindConfiguredWorldBoss(&caller, Config), "different phase excluded");
        boss.Phase = 1;
        boss.Distance = 251.0f;
        Check(!FindConfiguredWorldBoss(&caller, Config), "outside radius excluded");
        boss.Distance = 0.0f;
        boss.Faction = 35;
        Check(!FindConfiguredWorldBoss(&caller, Config), "friendly victory excluded even without flags");
        Check(IsStagedCelestialUnavailable(&boss, boss.Entry), "rotation cancels pending assembly");
        Check(IsStagedCelestialUnavailable(nullptr, boss.Entry), "missing selected spawn cancels assembly");
        uint32 timer = 0;
        Check(!UpdateWorldBossDefeatTimer(&boss, false, timer) && timer == 0,
            "initial friendly state is not victory");
        Check(!UpdateWorldBossDefeatTimer(&boss, true, timer) && timer == 1000,
            "nonlethal victory starts timer");
        for (unsigned i = 0; i < 8; ++i)
            Check(!UpdateWorldBossDefeatTimer(nullptr, true, timer), "despawn retains observed victory delay");
        Check(UpdateWorldBossDefeatTimer(nullptr, true, timer), "victory cleans up at ten seconds");
        boss.Flags = UNIT_FLAG_NON_ATTACKABLE;
    }

    ShowWorldBossCallerMenu(&player, &caller);
    Check(!HasAction(player, WORLD_BOSS_CALLER_STAGE_10) && !HasAction(player, WORLD_BOSS_CALLER_PREVIEW_25),
        "inactive court has no Call or Preview");
    Check(HasAction(player, WORLD_BOSS_CALLER_STATUS) && HasAction(player, WORLD_BOSS_CALLER_REBUFF) &&
        HasAction(player, WORLD_BOSS_CALLER_DISMISS), "management remains available between bosses");
    bosses[0].Faction = bosses[1].Faction = 31;
    bosses[0].Flags = bosses[1].Flags = 0;
    Check(!FindConfiguredWorldBoss(&caller, Config), "two active bosses are ambiguous");
    ShowWorldBossCallerMenu(&player, &caller);
    Check(!HasAction(player, WORLD_BOSS_CALLER_STAGE_10), "ambiguous court blocks Call");
    caller.Phase = 0xFFFFFFFF;
    bosses[0].Phase = 2;
    Check(FindConfiguredWorldBoss(&caller, Config, &player) == &bosses[1],
        "all-phase caller selects only the player's phase");
    bosses[1].Phase = 2;
    ShowWorldBossCallerMenu(&player, &caller);
    Check(!HasAction(player, WORLD_BOSS_CALLER_STAGE_10), "menu excludes bosses invisible to the player");
    caller.Phase = bosses[0].Phase = bosses[1].Phase = 1;
    Config.BossEntry = bosses[0].Entry;
    Check(FindConfiguredWorldBoss(&caller, Config) == &bosses[0], "legacy caller stays boss-specific");
    bosses[0].Faction = 35;
    Check(!FindConfiguredWorldBoss(&caller, Config), "legacy caller rejects inactive corner");
    Config.BossEntry = 0;
    Creature duplicate = bosses[1];
    duplicate.Guid.Counter = 999;
    caller.Nearby.push_back(&duplicate);
    Check(!FindConfiguredWorldBoss(&caller, Config), "duplicate same-entry active spawns are ambiguous");
    caller.Nearby.pop_back();
    Config.RaidSizeMask = 1;
    ShowWorldBossCallerMenu(&player, &caller);
    Check(HasAction(player, WORLD_BOSS_CALLER_STAGE_10) && !HasAction(player, WORLD_BOSS_CALLER_STAGE_25),
        "raid mask respected");

    uint32 timer = 0;
    Check(!UpdateWorldBossDefeatTimer(nullptr, true, timer) && timer == 0, "missing boss never proves victory");
    bosses[1].Combat = true;
    Check(!UpdateWorldBossDefeatTimer(&bosses[1], true, timer) && timer == 0, "combat is not victory");
    bosses[1].Combat = false;
    bosses[1].Evade = true;
    Check(!UpdateWorldBossDefeatTimer(&bosses[1], true, timer) && timer == 0, "wipe is not victory");
    bosses[1].Evade = false;
    Check(!UpdateWorldBossDefeatTimer(&bosses[1], true, timer) && timer == 0, "reset stays available for another pull");

    Creature galleon{62346, {105}};
    caller.Nearby.push_back(&galleon);
    Config.BossEntry = 62346;
    Check(FindConfiguredWorldBoss(&caller, Config) == &galleon, "ordinary caller preserves live lookup");
    Check(!IsStagedCelestialUnavailable(nullptr, galleon.Entry), "ordinary staging unchanged");
    Check(!UpdateWorldBossDefeatTimer(&galleon, true, timer) && timer == 0,
        "friendly faction alone is not victory for other bosses");
    galleon.Alive = false;
    Check(!UpdateWorldBossDefeatTimer(&galleon, true, timer) && timer == 1000, "normal death starts cleanup");
    Check(!FindConfiguredWorldBoss(&caller, Config), "ordinary corpse is not a Call target");
    ValidConfig = false;
    ShowWorldBossCallerMenu(&player, &caller);
    Check(player.Closed && player.Items.empty(), "invalid configuration closes menu");
    std::cout << "Celestial caller regression: " << Checks << " checks passed\n";
}
