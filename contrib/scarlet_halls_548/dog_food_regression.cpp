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
       UNIT_STATE_CASTING, EFFECT_MOTION_TYPE, POINT_MOTION_TYPE };
uint32 urand(uint32 min, uint32) { return min; }
struct Creature;
struct WorldObject { virtual ~WorldObject() = default; virtual Creature* ToCreature() { return nullptr; } };
struct Unit : WorldObject { };
struct Position
{
    float x = 0, y = 0, z = 0, orientation = 0;
    float GetOrientation() const { return orientation; }
};
struct Motion
{
    enum Kind { Patrol, Idle, Chase, Jump, Point } kind = Patrol;
    Unit* target = nullptr;
    Position destination;
    uint32 pointId = 0;
    void Clear() { target = nullptr; }
    void MoveIdle() { kind = Idle; }
    void MoveChase(Unit* unit) { kind = Chase; target = unit; }
    void MovePoint(uint32 id, Position const& position) { kind = Point; pointId = id; destination = position; }
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
    uint32 sleepVisualCasts = 0;
    bool sleepVisual = false;
    bool sleepZzz = false;
    bool alive = true, combat = false, threat = false;
    Unit* victim = nullptr;
    ::AI* ai = nullptr;
    Motion motion;
    Map map;
    Position position;
    Creature(uint32 e, uint32 g) : entry(e), guid(g) { }
    Creature* ToCreature() override { return this; }
    uint32 GetEntry() const { return entry; }
    ObjectGuid GetGUID() const { return guid; }
    bool IsAlive() const { return alive; }
    Unit* GetVictim() const { return victim; }
    ::AI* AI() { return ai; }
    Motion* GetMotionMaster() { return &motion; }
    Map* GetMap() { return &map; }
    Position const& GetPosition() const { return position; }
    void SetFacingTo(float orientation) { position.orientation = orientation; }
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
    void CastSpell(Unit*, uint32 spell, bool)
    {
        ++casts;
        if (spell == 113114) { sleepVisual = true; ++sleepVisualCasts; }
        else if (spell == 55474) sleepZzz = true;
        else motion.kind = Motion::Jump;
    }
    void RemoveAurasDueToSpell(uint32 spell)
    {
        if (spell == 113114) sleepVisual = false;
        if (spell == 55474) sleepZzz = false;
    }
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
    dog.position = {10, 20, 30, 1.5f};
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
    dog.position = {50, 60, 30, 0}; // The food target is away from the dog's patrol.
    watchman.alive = false;
    ai.UpdateAI(100);
    assert(ai.fed && !dog.combat && !dog.threat && dog.victim == nullptr && dog.faction == 35);
    assert(dog.motion.kind == Motion::Point && dog.stand == UNIT_STAND_STATE_STAND);
    assert(!dog.sleepVisual && !dog.sleepZzz); // No sleeping visuals while still walking back.
    assert(dog.motion.destination.x == 10 && dog.motion.destination.y == 20 && dog.motion.destination.z == 30);
    assert(dog.flags & UNIT_FLAG_PACIFIED);
    ai.SetGUID(otherWatchman.guid, GUID_DOG_FOOD_TARGET);
    ai.UpdateAI(100);
    assert(dog.victim == nullptr && dog.motion.kind == Motion::Point && ai.returningAfterFeeding);
    ai.MovementInform(EFFECT_MOTION_TYPE, dog.motion.pointId); // Late leap callback must not put it to sleep.
    ai.MovementInform(POINT_MOTION_TYPE, dog.motion.pointId + 1);
    assert(dog.stand == UNIT_STAND_STATE_STAND);
    assert(!dog.sleepVisual && !dog.sleepZzz);
    dog.position = dog.motion.destination;
    ai.MovementInform(POINT_MOTION_TYPE, dog.motion.pointId);
    assert(dog.stand == UNIT_STAND_STATE_SLEEP && !ai.returningAfterFeeding);
    assert(dog.position.orientation == 1.5f && dog.faction == 35);
    assert(dog.sleepVisual && dog.sleepZzz && dog.sleepVisualCasts == 1);
    ai.MovementInform(POINT_MOTION_TYPE, dog.motion.pointId);
    ai.UpdateAI(100);
    assert(dog.sleepVisualCasts == 1); // Arrival repeats cannot recast the cosmetic.
    std::cout << "PASS bucket hit -> selected watchman attack -> friendly return to patrol position -> sleep on arrival\n";

    ai.Reset();
    assert(!ai.fed && !ai.foodTargetGUID && dog.faction == 16 && !(dog.flags & UNIT_FLAG_PACIFIED));
    assert(!dog.sleepVisual && !dog.sleepZzz && dog.stand == UNIT_STAND_STATE_STAND);
    ai.SetGUID(dog.guid, GUID_DOG_FOOD_TARGET);
    ai.SetGUID(watchman.guid, GUID_DOG_FOOD_TARGET); // Dead target.
    ai.SetGUID(999, GUID_DOG_FOOD_TARGET);
    assert(!ai.foodTargetGUID);
    ai.SetGUID(otherWatchman.guid, GUID_DOG_FOOD_TARGET);
    objects.erase(otherWatchman.guid);
    ai.UpdateAI(100);
    assert(ai.fed && !dog.combat && dog.motion.kind == Motion::Point);
    ai.Reset(); // A late arrival from a previous feeding must not sleep a reset hound.
    ai.MovementInform(POINT_MOTION_TYPE, dog.motion.pointId);
    assert(!ai.returningAfterFeeding && dog.stand == UNIT_STAND_STATE_STAND && dog.faction == 16);
    EatenPredicate filter;
    assert(filter(nullptr) && filter(&dog) && filter(&previousVictim) && !filter(&watchman));
    FoodSpell{nullptr}.HandleHitEffect(0);
    FoodSpell{&dog}.HandleHitEffect(0);
    std::cout << "PASS reset, missing/dead/wrong targets, duplicate hits and target filtering\n";
}
