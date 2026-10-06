// Run the production spawn/reset/arrival hooks and DoZoneInCombat against
// small engine doubles. In particular, do not call Reset before InitializeAI:
// the first pull must behave like subsequent pulls, even with no target nearby.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <vector>
using uint32 = std::uint32_t;
enum { REACT_PASSIVE, REACT_AGGRESSIVE, POWER_MANA, UNIT_FIELD_FLAGS,
       BOSS_WHITEMANE, NOT_STARTED, POINT_MOTION_TYPE, ACTION_DURAND, TYPEID_UNIT };
constexpr uint32 UNIT_FLAG_NON_ATTACKABLE = 2, UNIT_FLAG_NOT_SELECTABLE = 0x02000000;
constexpr float VISIBLE_RANGE = 100.0f;
static unsigned errors = 0;
#define TC_LOG_ERROR(...) (++errors)
#define CHECK(condition) do { if (!(condition)) { std::cerr << "Failed: " #condition << '\n'; std::exit(1); } } while (false)
struct Creature;
struct CreatureAI;
struct Unit;
struct ThreatManager
{
    std::vector<Unit*> targets;
    bool isThreatListEmpty() const { return targets.empty(); }
    Unit* getHostilTarget() { return targets.empty() ? nullptr : targets.front(); }
};
struct Unit
{
    bool alive = true, combat = false;
    ThreatManager threat;
    virtual ~Unit() = default;
    bool IsAlive() const { return alive; }
    bool isDead() const { return !alive; }
    virtual void SetInCombatWith(Unit*) { combat = true; }
    bool CanHaveThreatList() const { return true; }
    ThreatManager& GetThreatManager() { return threat; }
    Unit* getAttackerForHelper() { return nullptr; }
    static Unit* GetCreature(Unit&, uint32) { return nullptr; }
    CreatureAI* GetAI() { return nullptr; }
};
struct Player : Unit
{
    bool gm = false;
    float distance = 80.0f;
    bool IsGameMaster() const { return gm; }
};
struct Map
{
    struct Reference { Player* player; Player* GetSource() const { return player; } };
    struct PlayerList : std::vector<Reference> { bool isEmpty() const { return empty(); } } players;
    bool IsDungeon() const { return true; }
    PlayerList const& GetPlayers() const { return players; }
};
struct InstanceScript
{
    unsigned resets = 0;
    void SetData(uint32, uint32) { ++resets; }
    uint32 GetGuidData(uint32) { return 0; }
};
struct Creature : Unit
{
    Map map;
    CreatureAI* ai = nullptr;
    Unit* victim = nullptr;
    int reaction = REACT_AGGRESSIVE;
    uint32 flags = 64, mana = 0, maxMana = 0;
    bool heroic = false, regeneration = false;
    unsigned engagements = 0;
    Map* GetMap() { return &map; }
    CreatureAI* AI() { return ai; }
    bool HasReactState(int state) const { return reaction == state; }
    void SetReactState(int state) { reaction = state; }
    Unit* GetVictim() { return victim; }
    bool IsSummon() const { return false; }
    Creature* ToTempSummon() { return this; }
    Unit* GetSummoner() { return nullptr; }
    Creature* ToCreature() { return this; }
    uint32 GetTypeId() { return TYPEID_UNIT; }
    uint32 GetEntry() { return 3977; }
    bool IsFriendlyTo(Unit*) { return false; }
    bool IsHostileTo(Unit*) { return true; }
    void AddThreat(Unit* target, float) { threat.targets.push_back(target); }
    Player* FindNearestPlayer(float range)
    {
        Player* result = nullptr;
        for (auto const& ref : map.players)
            if (ref.player->alive && !ref.player->gm && ref.player->distance <= range)
                range = (result = ref.player)->distance;
        return result;
    }
    Unit* SelectNearestTarget(float range) { return FindNearestPlayer(range); }
    void SetInCombatWith(Unit*) override;
    bool Attack(Unit* target, bool)
    {
        if (!target || !target->IsAlive()) return false;
        victim = target;
        SetInCombatWith(target);
        AddThreat(target, 0);
        return true;
    }
    void SetMaxPower(uint32, uint32 value) { maxMana = value; }
    uint32 GetMaxPower(uint32) const { return maxMana; }
    void SetPower(uint32, uint32 value) { mana = value; }
    void setRegeneratingHealth(bool value) { regeneration = value; }
    void SetFlag(uint32, uint32 value) { flags |= value; }
    void RemoveFlag(uint32, uint32 value) { flags &= ~value; }
};
struct CreatureAI
{
    Creature* me;
    explicit CreatureAI(Creature* creature) : me(creature) { me->ai = this; }
    virtual ~CreatureAI() = default;
    virtual void Reset() { }
    #include "base_initialize.inc"
    virtual void AttackStart(Unit*) { }
    virtual void MovementInform(uint32, uint32) { }
    virtual void DoAction(int) { }
    void DoZoneInCombat(Creature* creature = nullptr, float maxRangeToNearestTarget = 50.0f);
};
#include "zone_combat.inc"
void Creature::SetInCombatWith(Unit*)
{
    if (combat) return;
    combat = true;
    ++engagements;
    // BossAI::_JustEngagedWith calls DoZoneInCombat again after the core
    // sets combat, before the outer call has added its first threat entry.
    ai->DoZoneInCombat();
}
struct BossAI : CreatureAI
{
    InstanceScript instanceStorage;
    InstanceScript* instance = &instanceStorage;
    struct Events { unsigned resets = 0; void Reset() { ++resets; } } events;
    bool combatMovement = true;
    explicit BossAI(Creature* creature) : CreatureAI(creature) { }
    bool IsHeroic() const { return me->heroic; }
    void SetCombatMovement(bool value) { combatMovement = value; }
    void _Reset() { }
    void DoStartNoMovement(Unit*) { }
    void EnterEvadeMode() { Reset(); }
};
struct WhitemaneAI : BossAI
{
    bool _switch = true, InRessurection = true;
    explicit WhitemaneAI(Creature* creature) : BossAI(creature) { }
    #include "whitemane_hooks.inc"
};
int main()
{
    for (bool heroic : { false, true })
    {
        Creature boss;
        boss.heroic = heroic;
        Player tank, other, dead, gm;
        dead.alive = false;
        gm.gm = true;
        boss.map.players.assign({{&tank}, {&other}, {&dead}, {&gm}});
        WhitemaneAI ai(&boss);
        ai.InitializeAI(); // Fresh grid load, no prior evade/Reset.
        CHECK(boss.reaction == REACT_PASSIVE);
        CHECK((boss.flags & (UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE)) == (UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE));
        CHECK(boss.mana == (heroic ? 120000u : 6415u));
        CHECK(!ai.combatMovement && !ai._switch && !ai.InRessurection);
        CHECK(boss.SelectNearestTarget(50.0f) == nullptr);
        // Durand activates her while she is still running from her room.
        boss.RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE);
        ai.DoZoneInCombat(&boss);
        CHECK(errors == 0 && boss.combat && tank.combat && other.combat);
        CHECK(!dead.combat && !gm.combat);
        CHECK(!boss.threat.isThreatListEmpty() && !boss.victim);
        CHECK(boss.engagements == 1);
        ai.MovementInform(POINT_MOTION_TYPE, 0);
        CHECK(boss.reaction == REACT_AGGRESSIVE && boss.victim);
        CHECK(!(boss.flags & UNIT_FLAG_NON_ATTACKABLE));
        ai.DoZoneInCombat();
        CHECK(errors == 0);
        ai.Reset(); // Subsequent attempt keeps the same pre-fight state.
        CHECK(boss.reaction == REACT_PASSIVE && boss.regeneration);
    }
    Creature corpse;
    corpse.alive = false;
    WhitemaneAI corpseAI(&corpse);
    corpseAI.InitializeAI();
    CHECK(corpseAI.instanceStorage.resets == 0); // Do not reset a saved dead boss.
    std::cout << "Whitemane first-pull, Normal/Heroic, zone combat, arrival, reset and corpse checks passed.\n";
}
