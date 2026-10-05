#include <cstdint>
#include <cstdio>
#include <map>
#include <set>
#include <stdexcept>
#include <utility>
using uint32 = uint32_t;
enum { UF_FLAG_PUBLIC=1, UF_FLAG_VIEWER_DEPENDENT=2, UNIT_FIELD_NPC_FLAGS=3, UNIT_NPC_FLAG_SPELLCLICK=4 };
struct Guid {
    int id; bool gameObject;
    bool IsGameObject() const { return gameObject; }
    bool IsCreatureOrVehicle() const { return !gameObject; }
    bool operator<(Guid const& other) const { return id < other.id; }
};
using ClientGUIDs = std::set<Guid>;
struct WorldPacket {};
struct UpdateData {
    unsigned blocks=0;
    explicit UpdateData(int) {}
    bool HasData() const { return blocks != 0; }
    void BuildPacket(WorldPacket*) {}
};
struct Player;
struct QuestObject {
    int flags=0; unsigned updates=0;
    void SetFieldNotifyFlag(int flag) { flags |= flag; }
    void RemoveFieldNotifyFlag(int flag) { flags &= ~flag; }
    void BuildValuesUpdateBlockForPlayer(UpdateData* data, Player*) { ++updates; ++data->blocks; }
};
struct GameObject : QuestObject {};
struct Vehicle { uint32 GetCreatureEntry() const { return 65379; } };
struct Creature : QuestObject {
    bool HasFlag(int,int) const { return true; }
    Vehicle* GetVehicleKit() const { return nullptr; }
    uint32 GetEntry() const { return 65379; }
};
using SpellClickInfoMapBounds = std::pair<int,int>;
struct ObjectMgr { SpellClickInfoMapBounds GetSpellClickInfoMapBounds(uint32) { return {0,1}; } };
ObjectMgr objectMgr; ObjectMgr* sObjectMgr=&objectMgr;
struct Map {
    std::map<int,GameObject> objects;
    std::map<int,Creature> creatures;
    GameObject* GetGameObject(Guid guid) { return &objects.at(guid.id); }
};
struct Session { unsigned packets=0; void SendPacket(WorldPacket*) { ++packets; } };
struct Player {
    bool inWorld=true; ClientGUIDs m_clientGUIDs; Map map; Session session;
    bool IsInWorld() const { return inWorld; }
    int GetMapId() const { return 1001; }
    Map* GetMap() { if(!inWorld)throw std::runtime_error("Old map accessed during transfer"); return &map; }
    Session* GetSession() { return &session; }
    void UpdateForQuestWorldObjects();
};
struct ObjectAccessor {
    static Creature* GetCreatureOrPetOrVehicle(Player& player, Guid guid) { return &player.GetMap()->creatures.at(guid.id); }
};
#include "quest_visibility.inc"

int main()
{
    Player player;
    for(int i=0;i<8;++i) {
        player.m_clientGUIDs.insert({i,i<3});
        if(i<3)player.map.objects.emplace(i,GameObject{});
        else player.map.creatures.emplace(i,Creature{});
    }
    // OnRemoveMember teleports first; Group::RemoveMember subsequently requests
    // a quest refresh while the eight old GUIDs are still cached.
    player.inWorld=false;
    try { player.UpdateForQuestWorldObjects(); }
    catch(std::exception const& e) { std::fprintf(stderr,"FAIL %s\n",e.what()); return 1; }
    if(player.session.packets) return 2;
    // The same refresh must still work for a player remaining on the map.
    player.inWorld=true;
    player.UpdateForQuestWorldObjects();
    if(player.session.packets!=1) return 3;
    for(auto const& pair:player.map.objects) if(pair.second.updates!=1 || pair.second.flags) return 4;
    for(auto const& pair:player.map.creatures) if(pair.second.updates!=1 || pair.second.flags) return 5;
    player.m_clientGUIDs.clear();
    player.UpdateForQuestWorldObjects();
    if(player.session.packets!=1) return 6;
    std::puts("PASS transfer suppresses stale quest objects; live refresh includes all eight objects; empty visibility sends nothing");
}
