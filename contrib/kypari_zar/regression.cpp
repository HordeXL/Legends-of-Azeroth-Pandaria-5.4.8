#include <cassert>
#include <cstdint>
#include <cmath>
#include <iostream>
#include <list>
#include <set>
#include <string>
#include <vector>
using uint32 = uint32_t;
using uint8 = uint8_t;
struct ObjectGuid {
    unsigned value = 0;
    ObjectGuid(unsigned v = 0) : value(v) { }
    bool IsEmpty() const { return !value; }
    bool operator==(ObjectGuid r) const { return value == r.value; }
    bool operator<(ObjectGuid r) const { return value < r.value; }
};
enum { QUEST_STATUS_INCOMPLETE = 1, REACT_PASSIVE, UNIT_FIELD_FLAGS,
    UNIT_FLAG_DISABLE_MOVE, UNIT_FLAG_IMMUNE_TO_NPC = 512, UNIT_FLAG_IMMUNE_TO_PC = 256,
    UNIT_FIELD_NPC_FLAGS, LANG_UNIVERSAL, TEMPSUMMON_TIMED_OR_DEAD_DESPAWN,
    TEMPSUMMON_MANUAL_DESPAWN, UNIT_STATE_EVADE };
struct Position { };
struct Player;
struct Creature;
struct TempSummon;
struct ScriptedAI;
using CreatureAI = ScriptedAI;
std::vector<TempSummon*> world;
std::vector<Player*> players;
bool spawnFails = false;
unsigned nextGuid = 100;
struct Unit {
    ObjectGuid guid;
    bool alive = true;
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    ObjectGuid GetGUID() const { return guid; }
    unsigned GetFaction() const { return 1; }
    bool IsAlive() const { return alive; }
    TempSummon* SummonCreature(uint32, Position, int, uint32, uint32, ObjectGuid);
};
struct Player : Unit {
    int status = QUEST_STATUS_INCOMPLETE;
    unsigned towerCredit = 0, defenseCredit = 0;
    bool near = true;
    Player() { guid = ++nextGuid; players.push_back(this); }
    Player* ToPlayer() override { return this; }
    int GetQuestStatus(uint32 q) { assert(q == 31022); return status; }
    void KilledMonsterCredit(uint32 id) { if (id == 63286) ++towerCredit; else { assert(id == 63287); ++defenseCredit; } }
};
struct Creature : Unit {
    ScriptedAI* ai = nullptr;
    ObjectGuid owner;
    bool despawned = false;
    Unit* victim = nullptr;
    uint32 entry = 0;
    ScriptedAI* AI() { return ai; }
    virtual TempSummon* ToTempSummon() { return nullptr; }
    unsigned faction=0;
    bool evading=false;
    void SetFaction(unsigned value) {faction=value;}
    void DeleteThreatList() {}
    void CombatStop(bool) {}
    void ClearUnitState(int) {evading=false;}
    void SetReactState(int) { }
    void SetFlag(int, int) { }
    void RemoveFlag(int, int) { }
    void SetUInt32Value(int, int) { }
    void Say(std::string const&, int, Player*) { }
    void DespawnOrUnsummon(uint32 = 0) { despawned = true; }
    bool IsWithinDistInMap(Player* player, float) { return player->near; }
    Position GetFirstCollisionPosition(float, float) { return {}; }
};
struct TempSummon : Creature {
    ObjectGuid summoner;
    TempSummon* ToTempSummon() override { return this; }
    ObjectGuid GetSummonerGUID() { return summoner; }
};
struct ScriptedAI {
    Creature* me;
    explicit ScriptedAI(Creature* c) : me(c) { }
    virtual ~ScriptedAI() = default;
    virtual void IsSummonedBy(Unit*) { }
    virtual void JustSummoned(Creature*) { }
    virtual void AttackStart(Unit* victim) { me->victim = victim; }
};
struct SummonList {
    std::set<Creature*> members;
    explicit SummonList(Creature*) { }
    void Summon(Creature* c) { members.insert(c); }
    void Despawn(Creature* c) { members.erase(c); }
    void DespawnAll() { for (auto c : members) c->DespawnOrUnsummon(); members.clear(); }
};
struct CreatureScript { explicit CreatureScript(char const*) { } };
struct GameObjectScript { explicit GameObjectScript(char const*) { } };
struct GameObject { Position GetFirstCollisionPosition(float, float) { return {}; } };
namespace ObjectAccessor {
Creature* GetCreature(Creature&, ObjectGuid guid) {
    for (auto c : world) if (!c->despawned && c->guid == guid) return c;
    return nullptr;
}
Player* GetPlayer(Creature&, ObjectGuid guid) {
    for (auto p : players) if (p->GetGUID() == guid) return p;
    return nullptr;
}
}
void GetCreatureListWithEntryInGrid(std::list<Creature*>& result, GameObject*, uint32 entry, float) {
    for (auto c : world) if (!c->despawned && c->entry == entry) result.push_back(c);
}
// PRODUCTION_SCRIPT
TempSummon* Unit::SummonCreature(uint32 entry, Position, int, uint32, uint32, ObjectGuid owner) {
    if (spawnFails) return nullptr;
    auto c = new TempSummon;
    c->entry = entry; c->guid = ++nextGuid; c->summoner = guid; c->owner = owner;
    c->ai = entry == KypariZar::Korven ? npc_korven_kypari_zar().GetAI(c) : new ScriptedAI(c);
    world.push_back(c);
    c->ai->IsSummonedBy(this);
    if (auto parent = dynamic_cast<Creature*>(this)) parent->AI()->JustSummoned(c);
    return c;
}
using AI = npc_korven_kypari_zar::npc_korven_kypari_zarAI;
void resetWorld() {
    for (auto c : world) { delete c->ai; delete c; }
    world.clear(); players.clear(); spawnFails = false;
}
AI* start(Player& p) {
    GameObject go;
    assert(go_kypari_zar_sonar_tower().OnGossipHello(&p, &go));
    assert(!world.empty());
    return dynamic_cast<AI*>(world.back()->AI());
}
void killWave(AI* ai) {
    auto ids = ai->attackers;
    for (auto id : ids) for (auto c : world) if (c->guid == id) {
        assert(c->victim == ai->me && c->owner == ai->playerGUID);
        c->alive = false;
        ai->SummonedCreatureDies(c, nullptr);
        ai->SummonedCreatureDespawn(c);
        c->despawned = true;
    }
}
int main() {
    {
        Player p; GameObject go;
        p.status = 0; go_kypari_zar_sonar_tower().OnGossipHello(&p, &go); assert(world.empty());
        p.status = QUEST_STATUS_INCOMPLETE; p.alive = false;
        go_kypari_zar_sonar_tower().OnGossipHello(&p, &go); assert(world.empty());
        p.alive = true; spawnFails = true;
        go_kypari_zar_sonar_tower().OnGossipHello(&p, &go); assert(world.empty() && !p.towerCredit);
    }
    resetWorld();
    {
        Player p; auto ai = start(p); assert(p.towerCredit == 1 && !p.defenseCredit);
        assert(ai->me->faction==p.GetFaction());
        GameObject go;
        for (int i = 0; i < 10; ++i) go_kypari_zar_sonar_tower().OnGossipHello(&p, &go);
        assert(world.size() == 1 && p.towerCredit == 1);
        Player other; auto otherAI = start(other); assert(otherAI != ai && world.size() == 2);
        for (unsigned wave = 1; wave <= 3; ++wave) {
            ai->UpdateAI(5000); assert(ai->wave == wave && ai->attackers.size() == wave + 2);
            ai->UpdateAI(1000); assert(!p.defenseCredit);
            killWave(ai); assert(ai->attackers.empty() && !p.defenseCredit);
            ai->me->evading=true;ai->EnterEvadeMode();
            assert(!ai->me->evading && ai->wave==wave && !ai->finished);
        }
        ai->UpdateAI(5000); assert(p.defenseCredit == 1 && !other.defenseCredit && ai->finished);
        ai->UpdateAI(5000); assert(p.defenseCredit == 1);
    }
    resetWorld();
    // Real-world callback gaps: confirm death from the corpse or despawn event.
    for (bool corpseRemoved : {false, true}) {
        Player p; auto ai = start(p);
        for (unsigned wave = 1; wave <= 3; ++wave) {
            ai->UpdateAI(5000); assert(ai->wave == wave);
            auto ids = ai->attackers;
            for (auto id : ids) for (auto c : world) if (c->guid == id) {
                c->alive = false;
                if (corpseRemoved) { ai->SummonedCreatureDespawn(c); c->despawned = true; }
            }
            if (!corpseRemoved) ai->UpdateAI(1);
            assert(ai->attackers.empty() && !ai->finished);
            ai->UpdateAI(4999); assert(ai->wave == wave);
            // Complete the pause without starting another wave in this helper.
            ai->timer = 1;
        }
        ai->UpdateAI(1); assert(ai->finished && p.defenseCredit == 1);
        resetWorld();
    }
    // A living attacker still blocks progression, even when its neighbours died.
    {
        Player p; auto ai = start(p);ai->UpdateAI(5000);
        world.back()->alive = false;ai->UpdateAI(1000);
        assert(ai->wave == 1 && ai->attackers.size() == 2 && !ai->finished);
        world.back()->alive = true;
        resetWorld();
    }
    for (int failure = 0; failure < 8; ++failure) {
        Player p; auto ai = start(p); ai->UpdateAI(5000); assert(!ai->attackers.empty());
        switch (failure) {
            case 0: p.alive = false; ai->UpdateAI(1); break;
            case 1: p.near = false; ai->UpdateAI(1); break;
            case 2: p.status = 0; ai->UpdateAI(1); break;
            case 3: players.clear(); ai->UpdateAI(1); players.push_back(&p); break;
            case 4: ai->JustDied(nullptr); break;
            case 5: ai->UpdateAI(180000); break;
            case 6: world.back()->despawned = true; ai->SummonedCreatureDespawn(world.back()); break;
            case 7: killWave(ai); spawnFails = true; ai->UpdateAI(5000); spawnFails = false; break;
        }
        assert(ai->finished && !p.defenseCredit && ai->attackers.empty());
        for (auto c : world) assert(c->despawned || !c->alive);
        p.alive = true; p.near = true; p.status = QUEST_STATUS_INCOMPLETE;
        auto retry = start(p); assert(retry != ai && !retry->finished);
        resetWorld();
    }
    std::cout << "Kypari Zar: click gates, duplicate clicks, separate owners, three combat waves, credit, cleanup and eight retry paths passed\n";
}
