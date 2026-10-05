#include <cassert>
#include <cmath>
#include <iostream>
#include <map>
#include <set>
using uint32 = unsigned;
struct Position
{
    float x = 0, y = 0, z = 0, o = 0;
    void Relocate(float a, float b, float c, float d) { x=a; y=b; z=c; o=d; }
    float GetPositionX() const { return x; }
    float GetPositionY() const { return y; }
    float GetPositionZ() const { return z; }
    float GetOrientation() const { return o; }
};
struct Map
{
    bool dungeon = true, raid = false, scenario = false, pvp = false;
    uint32 id = 531, difficulty = 0;
    bool IsDungeon() const { return dungeon; }
    bool IsRaid() const { return raid; }
    bool IsScenario() const { return scenario; }
    bool IsBattlegroundOrArena() const { return pvp; }
    uint32 GetId() const { return id; }
    uint32 GetDifficulty() const { return difficulty; }
};
struct Group { uint32 GetGUID() const { return 1; } };
struct Player
{
    Map* map;
    Group* group = nullptr;
    int team = 0;
    bool teleportAccepted = true, alive = false, bones = false, sickness = true;
    float health = 0;
    unsigned teleports = 0;
    Position destination{};
    Map* GetMap() { return map; }
    Group* GetGroup() { return group; }
    int GetTeamId() { return team; }
    bool TeleportTo(uint32 id, float x, float y, float z, float o)
    {
        assert(id == map->id);
        ++teleports;
        destination.Relocate(x,y,z,o);
        return teleportAccepted;
    }
    void ResurrectPlayer(float hp, bool sick) { alive=true; health=hp; sickness=sick; }
    void SpawnCorpseBones() { bones=true; }
};
namespace lfg
{
struct LFGDungeonData
{
    uint32 map = 531, difficulty = 0;
    int faction = -1;
    float x = 100, y = 200, z = 30, o = 1;
};
}
struct LFGMgr
{
    uint32 selected = 0;
    std::map<uint32, lfg::LFGDungeonData> entries;
    std::set<uint32> ids;
    uint32 GetDungeon(uint32) { return selected; }
    lfg::LFGDungeonData const* GetLFGDungeon(uint32 id)
    { auto it = entries.find(id); return it == entries.end() ? nullptr : &it->second; }
    std::set<uint32> const& GetDungeonsByRandom(uint32) { return ids; }
} lfgMgr;
auto sLFGMgr = &lfgMgr;
struct AreaTriggerStruct
{
    float target_X=10, target_Y=20, target_Z=3, target_Orientation=2;
};
struct ObjectMgr
{
    AreaTriggerStruct trigger;
    bool available = true;
    AreaTriggerStruct const* GetMapEntranceTrigger(uint32) { return available ? &trigger : nullptr; }
} objectMgr;
auto sObjectMgr = &objectMgr;
struct MapManager
{
    static bool IsValidMapCoord(uint32, float x, float y, float z, float o)
    { return std::isfinite(x) && std::isfinite(y) && std::isfinite(z) && std::isfinite(o); }
    static bool IsValidMapCoord(uint32 id, Position const& p)
    { return IsValidMapCoord(id,p.x,p.y,p.z,p.o); }
};
#include "release-under-test.inc"
int main()
{
    Map map;
    auto succeeds = [&](float expectedX)
    {
        Player player{&map};
        assert(ResurrectAtInstanceEntrance(&player));
        assert(player.alive && player.health == 1 && !player.sickness && player.bones);
        assert(player.teleports == 1 && player.destination.x == expectedX);
    };
    auto rejected = [&]()
    {
        Player player{&map};
        assert(!ResurrectAtInstanceEntrance(&player));
        assert(!player.alive && !player.bones && player.teleports == 0);
    };
    succeeds(10); // Dungeon.
    map.dungeon=false; map.raid=true;
    succeeds(10);
    map.raid=false; map.scenario=true;
    succeeds(10);
    map.scenario=false;
    rejected(); // Open world.
    map.dungeon=true; map.pvp=true;
    rejected(); // BG/arena even if also flagged as a dungeon.
    map.pvp=false;
    Player failed{&map}; failed.teleportAccepted=false;
    assert(!ResurrectAtInstanceEntrance(&failed) && !failed.alive && !failed.bones);
    objectMgr.available=false;
    rejected(); // Missing entrance: retain normal release.
    lfgMgr.entries[1] = {}; lfgMgr.ids.insert(1);
    succeeds(100); // Scenario entrance fallback without a group/portal.
    lfgMgr.entries[1].map=999;
    rejected();
    lfgMgr.entries[1].map=531; lfgMgr.entries[1].difficulty=1;
    rejected();
    lfgMgr.entries[1].difficulty=0; lfgMgr.entries[1].faction=0;
    rejected(); // Opposite faction.
    lfgMgr.entries[1].faction=1;
    succeeds(100);
    lfgMgr.entries[1].x=lfgMgr.entries[1].y=lfgMgr.entries[1].z=0;
    rejected(); // Unconfigured LFG destination.
    lfgMgr.entries[1]={}; lfgMgr.entries[1].x=NAN;
    rejected();
    lfgMgr.entries[1]={}; objectMgr.available=true;
    Group group; Player wing{&map}; wing.group=&group; lfgMgr.selected=1;
    assert(ResurrectAtInstanceEntrance(&wing) && wing.destination.x == 100);
    lfgMgr.entries[1].map=999;
    Player staleGroup{&map}; staleGroup.group=&group;
    assert(ResurrectAtInstanceEntrance(&staleGroup) && staleGroup.destination.x == 10);
    Player noMap{nullptr};
    assert(!ResurrectAtInstanceEntrance(&noMap));
    std::cout << "17 instance-release cases passed\n";
}
