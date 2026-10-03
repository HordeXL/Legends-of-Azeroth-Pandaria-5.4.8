// Executes the production Starving Hound AI and Dog Food hit callback.
#include <cassert>
#include <cstdint>
#include <iostream>
#include <list>
#include <map>
using uint32 = uint32_t;
using int32 = int32_t;
using SpellEffIndex = int;
struct ObjectGuid
{
    uint32 value;
    ObjectGuid(uint32 v = 0) : value(v) { }
    operator uint32() const { return value; }
    static ObjectGuid const Empty;
};
ObjectGuid const ObjectGuid::Empty;
enum { NPC_STARVING_HOUND = 58876, NPC_VIGILANT_WATCHMAN = 58898,
       WORLDSTATE_HUMANE_SOCIETY = 12645 };
enum { UNIT_FIELD_FLAGS, UNIT_FLAG_PACIFIED = 1, REACT_PASSIVE, REACT_AGGRESSIVE,
       UNIT_STAND_STATE_STAND, UNIT_STAND_STATE_SLEEP, EMOTE_STATE_NONE,
       UNIT_STATE_CASTING, EFFECT_MOTION_TYPE };
uint32 urand(uint32 min, uint32) { return min; }
struct Creature;
struct WorldObject { virtual ~WorldObject() = default; virtual Creature* ToCreature() { return nullptr; } };
struct Unit : WorldObject { };
struct Motion
{
    enum Kind { Patrol, Idle, Chase, Jump } kind = Patrol;
    Unit* target = nullptr;
    void Clear() { target = nullptr; }
    void MoveIdle() { kind = Idle; }
    void MoveChase(Unit* unit) { kind = Chase; target = unit; }
};
struct Map { void SetWorldState(uint32, uint32) { } };
struct AI
{
    virtual ~AI() = default;
    virtual void Reset() { }
    virtual void SetGUID(ObjectGuid, int32) { }
    virtual void MovementInform(uint32, uint32) { }
    virtual void JustEngagedWith(Unit*) { }
    virtual void JustDied(Unit*) { }
    virtual void UpdateAI(uint32) { }
};
struct Creature : Unit
{
    uint32 entry, guid, faction = 16, react = REACT_AGGRESSIVE, flags = 0, stand = UNIT_STAND_STATE_STAND;
    uint32 melee = 0, casts = 0;
    bool alive = true, combat = false, threat = false;
    Unit* victim = nullptr;
    ::AI* ai = nullptr;
    Motion motion;
    Map map;
    Creature(uint32 e, uint32 g) : entry(e), guid(g) { }
    Creature* ToCreature() override { return this; }
    uint32 GetEntry() const { return entry; }
    ObjectGuid GetGUID() const { return guid; }
    bool IsAlive() const { return alive; }
    Unit* GetVictim() const { return victim; }
    ::AI* AI() { return ai; }
    Motion* GetMotionMaster() { return &motion; }
    Map* GetMap() { return &map; }
    void RestoreFaction() { faction = 16; }
    void SetFaction(uint32 value) { faction = value; }
    void SetReactState(uint32 value) { react = value; }
    void SetFlag(uint32, uint32 value) { flags |= value; }
    void RemoveFlag(uint32, uint32 value) { flags &= ~value; }
    void SetStandState(uint32 value) { stand = value; }
    void HandleEmoteStateCommand(uint32) { }
    void CombatStop(bool) { combat = false; victim = nullptr; }
    void DeleteThreatList() { threat = false; }
    bool HasUnitState(uint32) const { return false; }
    void CastSpell(Unit*, uint32, bool) { ++casts; motion.kind = Motion::Jump; }
    void StopMoving() { }
    void AddAura(uint32, Creature*) { }
};
std::map<uint32, Creature*> objects;
namespace ObjectAccessor
{
    Creature* GetCreature(Creature&, ObjectGuid guid)
    {
        auto i = objects.find(guid);
        return i == objects.end() ? nullptr : i->second;
    }
}
struct EventMap
{
    void Reset() { }
    void ScheduleEvent(uint32, uint32) { }
    void Update(uint32) { }
    uint32 ExecuteEvent() { return 0; }
};
struct ScriptedAI : AI
{
    Creature* me;
    explicit ScriptedAI(Creature* c) : me(c) { c->ai = this; }
    void AttackStart(Unit* target) { me->victim = target; me->combat = true; me->threat = true; me->motion.MoveChase(target); }
    bool UpdateVictim() { return me->victim != nullptr; }
    void DoMeleeAttackIfReady() { if (me->victim) ++me->melee; }
};
std::list<Creature*> nearbyHounds;
void GetCreatureListWithEntryInGrid(std::list<Creature*>& result, Creature*, uint32, float) { result = nearbyHounds; }
#include "starving_hound.inc"
struct FoodSpell
{
    Creature* target;
    Creature* GetHitCreature() { return target; }
    #include "dog_food_hit.inc"
};
int main()
{
    Creature watchman(NPC_VIGILANT_WATCHMAN, 1), otherWatchman(NPC_VIGILANT_WATCHMAN, 2);
    Creature dog(NPC_STARVING_HOUND, 3), deadDog(NPC_STARVING_HOUND, 4);
    objects = {{1, &watchman}, {2, &otherWatchman}, {3, &dog}, {4, &deadDog}};
    npc_starving_houndAI ai(&dog), deadAI(&deadDog);
    ai.Reset();
    deadAI.Reset();
    deadDog.alive = false;
    nearbyHounds = {&dog, &deadDog};
    Unit previousVictim;
    ai.AttackStart(&previousVictim);
    dog.motion.kind = Motion::Patrol;
    FoodSpell{&watchman}.HandleHitEffect(0);
    assert(watchman.motion.kind == Motion::Idle && (watchman.flags & UNIT_FLAG_PACIFIED));
    assert(dog.victim == &watchman && dog.motion.kind == Motion::Jump);
    assert(dog.faction == FACTION_FEEDING_HOUND && dog.react == REACT_PASSIVE && deadDog.casts == 0);
    ai.MovementInform(EFFECT_MOTION_TYPE, 0);
    assert(dog.motion.kind == Motion::Chase && dog.motion.target == &watchman);
    ai.UpdateAI(100);
    assert(dog.melee == 1); // No Dog Food aura is needed.
    ai.SetGUID(otherWatchman.guid, GUID_DOG_FOOD_TARGET);
    assert(dog.victim == &watchman && dog.casts == 1);
    dog.victim = &previousVictim;
    ai.UpdateAI(100);
    assert(dog.victim == &watchman); // Previous player/pet aggro cannot steal the food target.
    watchman.alive = false;
    ai.UpdateAI(100);
    assert(ai.fed && !dog.combat && !dog.threat && dog.victim == nullptr && dog.faction == 35);
    assert(dog.motion.kind == Motion::Idle && dog.stand == UNIT_STAND_STATE_SLEEP);
    assert(dog.flags & UNIT_FLAG_PACIFIED);
    ai.SetGUID(otherWatchman.guid, GUID_DOG_FOOD_TARGET);
    ai.UpdateAI(100);
    assert(dog.victim == nullptr && dog.motion.kind == Motion::Idle);
    std::cout << "PASS bucket hit -> selected watchman attack -> friendly sleeping hound\n";

    ai.Reset();
    assert(!ai.fed && !ai.foodTargetGUID && dog.faction == 16 && !(dog.flags & UNIT_FLAG_PACIFIED));
    ai.SetGUID(dog.guid, GUID_DOG_FOOD_TARGET);
    ai.SetGUID(watchman.guid, GUID_DOG_FOOD_TARGET); // Dead target.
    ai.SetGUID(999, GUID_DOG_FOOD_TARGET);
    assert(!ai.foodTargetGUID);
    ai.SetGUID(otherWatchman.guid, GUID_DOG_FOOD_TARGET);
    objects.erase(otherWatchman.guid);
    ai.UpdateAI(100);
    assert(ai.fed && !dog.combat && dog.motion.kind == Motion::Idle);
    EatenPredicate filter;
    assert(filter(nullptr) && filter(&dog) && filter(&previousVictim) && !filter(&watchman));
    FoodSpell{nullptr}.HandleHitEffect(0);
    FoodSpell{&dog}.HandleHitEffect(0);
    std::cout << "PASS reset, missing/dead/wrong targets, duplicate hits and target filtering\n";
}
