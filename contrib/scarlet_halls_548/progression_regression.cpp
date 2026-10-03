#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <list>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using uint8 = uint8_t;
using uint32 = uint32_t;
struct Position { float x, y, z, orientation; };
struct ObjectGuid
{
    uint32 value = 0;
    ObjectGuid(uint32 v = 0) : value(v) { }
    operator uint32() const { return value; }
    static const ObjectGuid Empty;
};
const ObjectGuid ObjectGuid::Empty;
enum EncounterState { NOT_STARTED, IN_PROGRESS, FAIL, DONE, SPECIAL, TO_BE_DECIDED };
enum { DOOR_TYPE_PASSAGE, DOOR_TYPE_ROOM, BOUNDARY_NONE, REACT_PASSIVE, REACT_AGGRESSIVE,
       UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE = 1, UNIT_FLAG_NON_ATTACKABLE = 2 };
struct DoorData { uint32 entry, boss, type, boundary; };
struct ScenarioBosses { uint32 boss, criteria; };
class Creature;
struct Unit
{
    virtual ~Unit() = default;
    virtual Creature* ToCreature() { return nullptr; }
};
struct Player : Unit { };
struct WorldObject : Unit { };
struct CreatureAI
{
    Creature* owner;
    std::vector<uint32> actions;
    void DoAction(uint32 action);
};
struct Motion
{
    uint32 point = 0;
    void MovePoint(uint32 id, Position const&) { point = id; }
    void MoveChase(Unit*) { }
};
struct Creature : WorldObject
{
    uint32 entry, dbGuid, flags = 0, health = 1000;
    bool visible = true, alive = true, despawned = false;
    bool combat = true, attacking = true, threat = true, walking = true;
    uint32 react = REACT_AGGRESSIVE;
    uint32 faction = 16;
    Motion motion;
    CreatureAI ai{this, {}};
    Creature(uint32 e, uint32 g) : entry(e), dbGuid(g) { }
    Creature* ToCreature() override { return this; }
    uint32 GetEntry() const { return entry; }
    ObjectGuid GetGUID() const { return dbGuid; }
    uint32 GetDBTableGUIDLow() const { return dbGuid; }
    bool isDead() const { return !alive; }
    bool IsAlive() const { return alive; }
    void Respawn() { alive = true; }
    void SetReactState(uint32 state) { react = state; }
    void SetDisplayId(uint32) { }
    void AddAura(uint32, Creature*) { }
    void SetFlag(uint32, uint32 flag) { flags |= flag; }
    bool HasFlag(uint32, uint32 flag) const { return (flags & flag) != 0; }
    void SetVisible(bool value) { visible = value; }
    void DespawnOrUnsummon(uint32 = 0) { despawned = true; }
    bool HealthBelowPctDamaged(int pct, uint32 damage) const { return int64_t(health) - damage < pct * 10; }
    void CastSpell(Unit*, uint32, bool) { }
    void RemoveAllAuras() { }
    void AttackStop() { attacking = false; }
    void CombatStop(bool) { combat = false; }
    void DeleteThreatList() { threat = false; }
    void SetFaction(uint32 value) { faction = value; }
    void SetWalk(bool value) { walking = value; }
    Motion* GetMotionMaster() { return &motion; }
    void RemoveFlag(uint32, uint32 flag) { flags &= ~flag; }
    Unit* SelectNearestTarget(float) { return nullptr; }
    void Attack(Unit*, bool) { attacking = true; }
    uint32 GetHealth() const { return health; }
    void DealDamage(Creature* target, uint32 damage, void*, uint32, uint32, void*, bool)
    {
        if (damage >= target->health) { target->health = 0; target->alive = false; }
        else target->health -= damage;
    }
    CreatureAI* AI() { return &ai; }
};
struct GameObject
{
    uint32 entry, guid;
    uint32 GetEntry() const { return entry; }
    ObjectGuid GetGUID() const { return guid; }
};
struct Map
{
    std::map<uint32, Creature*> creatures;
    bool IsChallengeDungeon() const { return false; }
    void SetWorldState(uint32, uint32) { }
    Creature* GetCreature(ObjectGuid guid) { auto i = creatures.find(guid); return i == creatures.end() ? nullptr : i->second; }
};
using InstanceMap = Map;
struct InstanceScript
{
    Map* instance;
    std::vector<EncounterState> states;
    std::map<uint32, bool> doors;
    explicit InstanceScript(Map* map) : instance(map) { }
    virtual ~InstanceScript() = default;
    virtual void Initialize() { }
    virtual void OnPlayerEnter(Player*) { }
    virtual void OnCreatureCreate(Creature*) { }
    virtual void OnGameObjectCreate(GameObject*) { }
    virtual void OnUnitDeath(Unit*) { }
    virtual void Update(uint32) { }
    virtual void SetData(uint32, uint32) { }
    virtual uint32 GetData(uint32) const { return 0; }
    virtual ObjectGuid GetGuidData(uint32) const { return {}; }
    virtual std::string GetSaveData() { return {}; }
    virtual void Load(char const*) { }
    void SetBossNumber(uint32 n) { states.assign(n, TO_BE_DECIDED); }
    EncounterState GetBossState(uint32 i) const { return i < states.size() ? states[i] : TO_BE_DECIDED; }
    virtual bool SetBossState(uint32 i, EncounterState state)
    {
        if (i >= states.size() || states[i] == state) return false;
        bool loading = states[i] == TO_BE_DECIDED;
        states[i] = state;
        return !loading;
    }
    std::string GetBossSaveData() { std::ostringstream s; for (auto state : states) s << state << ' '; return s.str(); }
    void HandleGameObject(ObjectGuid guid, bool open) { doors[guid] = open; }
    void LoadDoorData(std::vector<DoorData> const&) { }
    void LoadScenarioInfo(std::vector<ScenarioBosses> const&, uint32) { }
    void SendChallengeInfo(Player*, uint32) { }
    void AddDoor(GameObject*, bool) { }
    void SetChallengeDoorGuid(ObjectGuid) { }
    bool IsChallengeModeCompleted() const { return false; }
    void UpdateConditionInfo(Creature*, uint32) { }
    void ScheduleBeginningTimeUpdate(uint32) { }
    void ScheduleChallengeStartup(uint32) { }
    void ScheduleChallengeTimeUpdate(uint32) { }
    void SaveToDB() { }
};
struct InstanceMapScript
{
    InstanceMapScript(char const*, uint32) { }
    virtual InstanceScript* GetInstanceScript(InstanceMap*) const = 0;
};
#define OUT_LOAD_INST_DATA_FAIL ((void)0)
#define OUT_LOAD_INST_DATA(x) ((void)0)
#define OUT_LOAD_INST_DATA_COMPLETE ((void)0)
#include "scarlet_halls.h"
#include "instance_scarlet_halls.cpp"

enum { ACTION_ACTIVATE_DOG = 1, ACTION_FINISH_HIM = 2, ACTION_MOVE_TO = 3, ACTION_EATING = 4,
       UNIT_FLAG_IN_COMBAT = 4, POINT_MOTION_TYPE = 8, DIRECT_DAMAGE, SPELL_SCHOOL_MASK_NORMAL,
       EVENT_RAKE, SPELL_RAKE_HEROIC, SPELL_RAKE_NORMAL, SPELL_BLOODY_RAGE = 116140,
       TALK_DOGFAIL, TALK_SUDENDEATH_01, EVENT_AT_END };
void CreatureAI::DoAction(uint32 action)
{
    actions.push_back(action);
    if (action == ACTION_ACTIVATE_DOG) owner->flags &= ~UNIT_FLAG_NON_ATTACKABLE;
}
std::list<Creature*> hounds;
std::list<Creature*> guards;
Creature* sergeantTarget = nullptr;
void GetCreatureListWithEntryInGrid(std::list<Creature*>& list, WorldObject*, uint32 entry, float)
{
    list = entry == NPC_SCARLET_GUARDIAN ? guards : hounds;
}
Creature* GetClosestCreatureWithEntry(WorldObject*, uint32, float, bool) { return sergeantTarget; }
namespace ObjectAccessor { Unit* GetUnit(Creature&, ObjectGuid) { return nullptr; } }
namespace Trinity { namespace Containers {
    template<class T> typename T::value_type SelectRandomContainerElement(T const& list) { assert(!list.empty()); return list.front(); }
} }
#include "select_hound.inc"
struct DamageAI { virtual void DamageTaken(Unit*, uint32&) = 0; };
struct Braun : DamageAI
{
    Creature* me;
    bool Scenario = false, SudenDeath = false, GetRage = false;
    int Phase = 0;
    struct Events { uint32 scheduled = 0; void Reset() { scheduled = 0; } void ScheduleEvent(uint32 id, uint32) { scheduled = id; } } events;
    explicit Braun(Creature* creature) : me(creature) { }
    void Talk(uint32) { }
    #include "braun_damage.inc"
};
struct HoundAI
{
    virtual void DoAction(int32_t) = 0;
    virtual void MovementInform(uint32, uint32) = 0;
};
using int32 = int32_t;
struct Hound : HoundAI
{
    Creature* me;
    InstanceScript* _instance = nullptr;
    Braun::Events events;
    explicit Hound(Creature* creature) : me(creature) { }
    bool IsHeroic() const { return false; }
    #include "hound_outro.inc"
};
using Instance = instance_scarlet_halls::instance_scarlet_halls_InstanceMapScript;
int main()
{
    Map map;
    Instance fresh(&map);
    fresh.Initialize();
    fresh.Load("S H 0 0 0");
    assert(fresh.states.size() == 3);
    Creature entrance(NPC_HOODED_CRUSADER, 537793), outro(NPC_HOODED_CRUSADER, 538235);
    map.creatures[outro.dbGuid] = &outro;
    fresh.OnCreatureCreate(&entrance);
    fresh.OnCreatureCreate(&outro);
    assert(entrance.visible && !outro.visible);
    fresh.SetBossState(BOSS_FLAMEWEAVER_KOEGLER, IN_PROGRESS);
    assert(!outro.visible);
    fresh.SetBossState(BOSS_FLAMEWEAVER_KOEGLER, DONE);
    assert(outro.visible);

    GameObject gate{GO_COMANDER_LINDON_EXIT, 42};
    fresh.OnGameObjectCreate(&gate);
    assert(!fresh.doors[42]);
    fresh.SetData(DATA_COMANDER_LINDON, DONE);
    assert(fresh.doors[42]);
    fresh.SetBossState(BOSS_HOUNDMASTER_BRAUN, IN_PROGRESS);
    assert(!fresh.doors[42]);
    fresh.SetBossState(BOSS_HOUNDMASTER_BRAUN, NOT_STARTED);
    assert(fresh.doors[42]);
    Instance reloaded(&map);
    reloaded.Initialize();
    reloaded.Load(fresh.GetSaveData().c_str());
    reloaded.OnGameObjectCreate(&gate);
    assert(reloaded.GetData(DATA_COMANDER_LINDON) == DONE && reloaded.doors[42]);
    outro.visible = false;
    reloaded.OnCreatureCreate(&outro);
    assert(outro.visible); // Koegler is already dead before this grid is created.

    Creature guard(NPC_SCARLET_GUARDIAN, 538029), sergeant(NPC_SERGEANT_VERDONE, 538028), hound(NPC_OBEDIEND_HOUND, 538001);
    fresh.OnCreatureCreate(&guard);
    assert(!guard.despawned && guard.react == REACT_PASSIVE);
    reloaded.Load("S H 3 0 0"); // Legacy completed Braun save, with no Lindon token.
    reloaded.OnGameObjectCreate(&gate);
    assert(reloaded.doors[42]);
    reloaded.OnCreatureCreate(&guard);
    reloaded.OnCreatureCreate(&sergeant);
    reloaded.OnCreatureCreate(&hound);
    assert(guard.despawned && sergeant.despawned && hound.despawned);
    reloaded.Load("S H 1 99 0 1");
    assert(reloaded.GetBossState(0) == NOT_STARTED && reloaded.GetBossState(1) == NOT_STARTED);
    assert(reloaded.GetData(DATA_COMANDER_LINDON) == NOT_STARTED);
    reloaded.Load(""); // Malformed input must not use uninitialized header bytes.
    std::cout << "PASS NPC visibility, late grid loads, legacy/new saves and Lindon/Braun gate states\n";

    Creature boss(NPC_HOUNDMASTER_BRAUN, 1), dog1(NPC_OBEDIEND_HOUND, 2), dog2(NPC_OBEDIEND_HOUND, 3), deadDog(NPC_OBEDIEND_HOUND, 4);
    dog1.flags = dog2.flags = deadDog.flags = UNIT_FLAG_NON_ATTACKABLE;
    deadDog.alive = false;
    hounds = {&deadDog, &dog1, &dog2};
    Braun braun(&boss);
    uint32 damage = 250;
    braun.DamageTaken(nullptr, damage);
    assert(braun.Phase == 2 && dog1.ai.actions.size() == 1 && dog2.ai.actions.size() == 1);
    assert(deadDog.ai.actions.empty() && damage == 250 && !braun.Scenario);
    assert(SelectedObedientHound(&boss) == nullptr); // No unused live dogs.
    damage = 450;
    braun.DamageTaken(nullptr, damage);
    assert(braun.Phase == 4 && dog1.ai.actions.size() == 1 && dog2.ai.actions.size() == 1);
    damage = 2000;
    braun.DamageTaken(nullptr, damage);
    assert(damage == 0 && braun.Scenario && braun.events.scheduled == EVENT_AT_END);
    assert(dog1.ai.actions.back() == ACTION_FINISH_HIM && deadDog.ai.actions.empty());
    damage = 2000;
    braun.DamageTaken(nullptr, damage);
    assert(damage == 0); // A second hit cannot cut off the outro.
    braun.SudenDeath = true;
    damage = 1000;
    braun.DamageTaken(nullptr, damage);
    assert(damage == 1000); // Scripted execution can complete.
    hounds.clear();
    assert(SelectedObedientHound(&boss) == nullptr);
    std::cout << "PASS hound thresholds, dead/used/absent hounds and lethal-hit outro protection\n";

    Creature outroDog(NPC_OBEDIEND_HOUND, 10), outroGuard(NPC_SCARLET_GUARDIAN, 11), outroSergeant(NPC_SERGEANT_VERDONE, 12);
    guards = {&outroGuard};
    sergeantTarget = &outroSergeant;
    Hound houndAI(&outroDog);
    houndAI.DoAction(ACTION_MOVE_TO);
    assert(!outroDog.combat && !outroDog.attacking && !outroDog.threat);
    assert(outroDog.react == REACT_PASSIVE && outroDog.faction == 35 && !outroDog.walking);
    assert(outroDog.motion.point == 1 && outroDog.HasFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE));
    houndAI.MovementInform(POINT_MOTION_TYPE, 0);
    assert(outroGuard.alive && outroSergeant.alive);
    houndAI.MovementInform(POINT_MOTION_TYPE, 1);
    assert(!outroGuard.alive && !outroSergeant.alive && outroDog.despawned);
    std::cout << "PASS hound leaves combat, reaches the exit, kills guards and despawns\n";
}
