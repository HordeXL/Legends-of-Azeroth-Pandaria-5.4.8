// Tests the production cast boundary, per-bot runtime and scheduler multiplier.
// The full priority selector is exercised by affliction_regression.cpp.
#include "../../modules/mod_playerbots/src/AfflictionAssistantPolicy.h"
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <map>
#include <set>
#include <string>

using uint32 = uint32_t;
struct ObjectGuid { uint32 id = 0; uint32 GetCounter() const { return id; } };
bool operator==(ObjectGuid a, ObjectGuid b) { return a.id == b.id; }
#include "affliction_bot_runtime.inc"

enum { CLASS_WARLOCK = 9, SPEC_WARLOCK_AFFLICTION = 265,
    SPELL_AURA_OVERRIDE_ACTIONBAR_SPELLS, SPELL_AURA_OVERRIDE_ACTIONBAR_SPELLS_2,
    CURRENT_CHANNELED_SPELL, TRIGGERED_NONE = 0, TRIGGERED_IGNORE_CAST_IN_PROGRESS = 1,
    UNIT_STATE_LOST_CONTROL = 2, UNIT_STATE_IN_FLIGHT = 4,
    SPELL_INTERRUPT_FLAG_MOVEMENT = 8, SPELL_AURA_CAST_WHILE_WALKING = 16,
    SPELL_CAST_OK = 0, TARGET_FLAG_DEST_LOCATION = 32 };
struct Player;
struct Spell;
struct SpellInfo {
    uint32 Id = 0, InterruptFlags = SPELL_INTERRUPT_FLAG_MOVEMENT, ExplicitTargetMask = 0;
    uint32 CastTime = 1000;
    float Speed = 30;
    bool Channel = false;
    bool IsChanneled() const { return Channel; }
    uint32 CalcCastTime(uint32, Spell*) const { return CastTime; }
};
struct AuraEffect {
    uint32 Override = 0;
    bool IsAffectingSpell(SpellInfo const*) const { return true; }
    uint32 GetAmount() const { return Override; }
};
struct Unit {
    using AuraEffectList = std::vector<AuraEffect const*>;
    bool Alive = true, InWorld = true, Protected = false, Engaged = true, Controlled = false;
    int Map = 1;
    ObjectGuid Guid{1};
    bool IsAlive() const { return Alive; }
    bool IsInWorld() const { return InWorld; }
    int GetMap() const { return Map; }
    ObjectGuid GetGUID() const { return Guid; }
    bool HasBreakableByDamageCrowdControlAura() const { return Controlled; }
};
struct SpellCastTargets {
    Unit* Target = nullptr;
    void SetUnitTarget(Unit* target) { Target = target; }
    Unit* GetUnitTarget() const { return Target; }
    void SetDst(Unit const&) {}
};
struct Cooldowns {
    bool Blocked = false;
    bool HasGlobalCooldown(SpellInfo const*) const { return Blocked; }
};
struct Player : Unit {
    uint32 Class = CLASS_WARLOCK, Spec = SPEC_WARLOCK_AFFLICTION, UnitState = 0;
    bool Battleground = false, Arena = false, Teleport = false, Moving = false, WalkingCast = false, Flying = false;
    float Health = 100, Distance = 30;
    int Interruptions = 0, CastResult = SPELL_CAST_OK;
    Spell* Channel = nullptr;
    Cooldowns Gcd;
    std::set<uint32> Learned, Auras;
    AuraEffectList Overrides;
    uint32 GetClass() const { return Class; }
    uint32 GetTalentSpecialization() const { return Spec; }
    bool InBattleground() const { return Battleground; }
    bool InArena() const { return Arena; }
    bool HasSpell(uint32 id) const { return Learned.count(id) != 0; }
    bool HasAura(uint32 id) const { return Auras.count(id) != 0; }
    AuraEffectList const& GetAuraEffectsByType(int type) const {
        static AuraEffectList empty;
        return type == SPELL_AURA_OVERRIDE_ACTIONBAR_SPELLS ? Overrides : empty;
    }
    Cooldowns& GetGlobalCooldownMgr() { return Gcd; }
    Spell* GetCurrentSpell(int) { return Channel; }
    void InterruptSpell(int) { ++Interruptions; Channel = nullptr; }
    bool HasUnitState(uint32 flags) const { return (UnitState & flags) != 0; }
    bool IsFlying() const { return Flying; }
    bool IsValidAttackTarget(Unit* target) const { return target != this; }
    bool IsBeingTeleported() const { return Teleport; }
    bool isMoving() const { return Moving; }
    bool HasAuraTypeWithAffectMask(int, SpellInfo const*) const { return WalkingCast; }
    uint32 GetLevel() const { return 90; }
    float GetDistance(Unit*) const { return Distance; }
    float GetHealthPct() const { return Health; }
};
struct SpellManager {
    std::map<uint32, SpellInfo> Infos;
    uint32 GetNextSpellInChain(uint32) const { return 0; }
    uint32 GetFirstSpellInChain(uint32 id) const { return id; }
    SpellInfo const* GetSpellInfo(uint32 id) const {
        auto it = Infos.find(id); return it == Infos.end() ? nullptr : &it->second;
    }
} manager;
SpellManager* sSpellMgr = &manager;
uint32 casts = 0, lastSpell = 0;
int lastFlags = -1;
Unit* lastTarget = nullptr;
struct Spell {
    Player* Caster;
    SpellInfo const* Info;
    int Flags;
    SpellCastTargets m_targets;
    Spell(Player* player, SpellInfo const* info, int flags) : Caster(player), Info(info), Flags(flags) {}
    SpellInfo const* GetSpellInfo() const { return Info; }
    int CheckPetCast(Unit*) const { return Caster->Channel && !Flags ? 1 : Caster->CastResult; }
    bool CanAutoCast(Unit* target) const { return CheckPetCast(target) == SPELL_CAST_OK; }
    void prepare(SpellCastTargets* target) {
        ++casts; lastSpell = Info->Id; lastFlags = Flags; lastTarget = target->Target;
        delete this; // production must not dereference a prepared/instant spell
    }
};
struct PlayerbotAI {
    Player* Bot;
    bool GroupPve = true, Vehicle = false, Allowed = true, Opening = true, Area = true;
    Player* GetBot() const { return Bot; }
    bool IsGroupPveActivity() const { return GroupPve; }
    bool IsInVehicle() const { return Vehicle; }
    bool CanLfgAutoQueueEngage(Unit*) const { return Allowed; }
    bool IsGroupPveOpeningSpellAllowed(SpellInfo const*, Unit*) const { return Opening; }
    bool IsGroupPveAreaSpellSafe(SpellInfo const*, Unit*) const { return Area; }
};
struct GroupPveCombat {
    static bool DamageAllowed(Player*, Unit* target) { return target->Engaged; }
};
bool IsAfflictionProtectedAlly(Player*, Unit* target) { return target->Protected; }
bool IsAfflictionEngaged(Player*, Unit* target) { return target->Engaged; }
std::map<uint32, AfflictionRotationRuntime> CombatAssistantStates;
uint32 nowMs = 10000;
uint32 getMSTime() { return nowMs; }
uint32 getMSTimeDiff(uint32 old, uint32 now) { return now - old; }
struct CombatRecommendation {
    uint32 SpellId = 0; Unit* Target = nullptr; char const* Reason = "WAIT";
    explicit operator bool() const { return SpellId && Target; }
};
CombatRecommendation chosen;
AfflictionRotationRuntime* seenRuntime = nullptr;
PlayerbotAI* seenAI = nullptr;
Unit* seenTarget = nullptr;
uint32 pendingAtSelection = 0;
CombatRecommendation SelectAfflictionRecommendation(Player*, Unit* target,
    AfflictionRotationRuntime& runtime, PlayerbotAI* ai) {
    seenTarget = target; seenAI = ai; seenRuntime = &runtime; pendingAtSelection = runtime.HauntPendingTimer;
    return chosen;
}
class Action {
    std::string name;
public:
    Action(char const* value) : name(value) {}
    std::string getName() const { return name; }
};
class Multiplier {
protected:
    PlayerbotAI* botAI;
public:
    Multiplier(PlayerbotAI* ai, char const*) : botAI(ai) {}
    virtual float GetValue(Action*) { return 1; }
};
#include "affliction_bot_production.inc"

unsigned checks = 0;
void check(bool value, char const* message) {
    ++checks;
    if (!value) { std::cerr << "FAIL: " << message << '\n'; std::exit(1); }
}
int main() {
    using namespace AfflictionAssistant;
    Player player; Unit target; target.Guid.id = 2;
    PlayerbotAI ai{&player}; AfflictionRotationRuntime runtime;
    for (uint32 id : {Haunt, Corruption, SoulSwap, Seed, Soulburn, MaleficGrasp}) {
        player.Learned.insert(id); manager.Infos[id].Id = id;
    }
    for (uint32 id : {SoulburnSwap, SoulburnSeed}) manager.Infos[id].Id = id;
    check(UsesAfflictionBotRotation(&ai), "group PvE Affliction uses shared selector");
    for (bool* flag : {&player.Battleground, &player.Arena}) {
        *flag = true; check(!UsesAfflictionBotRotation(&ai), "PvP keeps existing rotation"); *flag = false;
    }
    ai.GroupPve = false; check(!UsesAfflictionBotRotation(&ai), "solo bot behavior unchanged"); ai.GroupPve = true;
    player.Spec = 267; check(!UsesAfflictionBotRotation(&ai), "Destruction is not replaced"); player.Spec = 265;
    player.Class = 8; check(!UsesAfflictionBotRotation(&ai), "other classes excluded"); player.Class = 9;

    AfflictionRotationMultiplier multiplier(&ai);
    for (char const* name : {"haunt", "agony", "life tap", "soul burn", "rain of fire", "seed of corruption", "dark soul: misery"}) {
        ::Action action(name);
        check(multiplier.GetValue(&action) == 0, "legacy spell cannot bypass shared priorities");
        ai.GroupPve = false; check(multiplier.GetValue(&action) == 1, "mode switch restores legacy action"); ai.GroupPve = true;
    }
    for (char const* name : {"affliction rotation", "boss mechanics", "avoid aoe", "combat formation move", "reach spell", "pet attack"}) {
        ::Action action(name); check(multiplier.GetValue(&action) == 1, "movement/pets/mechanics remain available");
    }

    chosen = {Haunt, &target, "HAUNT"};
    check(RunAfflictionBotRotation(&ai, &target, runtime), "bot executes shared recommendation");
    check(seenAI == &ai && seenRuntime == &runtime && seenTarget == &target, "explicit AI target and local runtime reach selector");
    check(casts == 1 && lastFlags == TRIGGERED_NONE, "actual bot cast is untriggered");
    check(runtime.HauntTarget == target.Guid && runtime.HauntPendingTimer == 2500, "track cast plus missile flight and margin");
    check(CombatAssistantStates.empty(), "bot cast does not mutate player addon map");
    nowMs += 1033; chosen = {};
    RunAfflictionBotRotation(&ai, &target, runtime);
    check(pendingAtSelection == 1467, "logged second-Haunt instant still has an in-flight projectile");
    AfflictionRotationRuntime other;
    RunAfflictionBotRotation(&ai, &target, other);
    check(pendingAtSelection == 0 && runtime.HauntPendingTimer == 1467, "bot runtime instances are independent");
    nowMs += 2000; RunAfflictionBotRotation(&ai, &target, runtime);
    check(pendingAtSelection == 0, "pending timer expires without underflow");
    runtime.LastUpdate = 0xfffffff0u; runtime.HauntPendingTimer = 100; nowMs = 16;
    RunAfflictionBotRotation(&ai, &target, runtime);
    check(pendingAtSelection == 68, "timer tolerates millisecond-clock rollover");

    for (bool* denied : {&target.Protected, &target.Controlled, &player.Teleport}) {
        *denied = true; chosen = {Haunt, &target, "HAUNT"};
        uint32 before = casts; RunAfflictionBotRotation(&ai, &target, runtime);
        check(casts == before, "no new casts against protected/CC target or while teleporting"); *denied = false;
    }
    for (bool* allowed : {&target.Alive, &target.InWorld, &target.Engaged, &ai.Allowed, &ai.Opening, &ai.Area}) {
        *allowed = false; uint32 before = casts;
        RunAfflictionBotRotation(&ai, &target, runtime);
        check(casts == before, "final target/pull/area gate prevents cast"); *allowed = true;
    }
    for (bool* denied : {&player.Gcd.Blocked, &ai.Vehicle, &player.Moving}) {
        *denied = true; uint32 before = casts;
        RunAfflictionBotRotation(&ai, &target, runtime);
        check(casts == before, "GCD/vehicle/movement checks remain active"); *denied = false;
    }

    Spell channel(&player, manager.GetSpellInfo(MaleficGrasp), 0);
    channel.m_targets.SetUnitTarget(&target); player.Channel = &channel;
    chosen = {MaleficGrasp, &target, "CHANNELING"};
    uint32 before = casts;
    check(RunAfflictionBotRotation(&ai, &target, runtime) && casts == before && player.Interruptions == 0,
        "channel continuation does not restart it");
    chosen = {Haunt, &target, "HAUNT"}; player.CastResult = 1;
    check(!RunAfflictionBotRotation(&ai, &target, runtime) && player.Channel == &channel,
        "failed replacement validation preserves current channel");
    player.CastResult = SPELL_CAST_OK;
    check(RunAfflictionBotRotation(&ai, &target, runtime) && player.Interruptions == 1 && lastFlags == TRIGGERED_NONE,
        "validated replacement interrupts once and casts normally");

    chosen = {SoulSwap, &target, "SOULBURN_SWAP"};
    check(!RunAfflictionBotRotation(&ai, &target, runtime), "normal Soul Swap inhale cannot replace instant application");
    player.Auras.insert(Soulburn); AuraEffect swap{SoulburnSwap}; player.Overrides = {&swap};
    check(RunAfflictionBotRotation(&ai, &target, runtime) && lastSpell == SoulburnSwap, "resolve learned Soul Swap via active Soulburn override");
    check(!player.HasSpell(SoulburnSwap), "override need not be separately learned");
    player.Learned.insert(86664); swap.Override = SoulburnSeed; chosen = {Seed, &target, "SOULBURN_SEED"};
    ai.Area = false;
    check(!RunAfflictionBotRotation(&ai, &target, runtime), "resolved Soulburn Seed still passes final area guard");
    ai.Area = true;
    check(RunAfflictionBotRotation(&ai, &target, runtime) && lastSpell == SoulburnSeed, "cast safe Soulburn Seed override");
    player.Overrides.clear(); player.Auras.clear();
    PrepareCheckedSpell(&player, Haunt, &target, true);
    check(CombatAssistantStates[player.Guid.id].HauntPendingTimer == 2500,
        "player button retains its original addon projectile tracking");
    chosen = {Haunt, &target, "HAUNT"};
    nowMs += 100; RunAfflictionBotRotation(&ai, &target, runtime);
    check(CombatAssistantStates[player.Guid.id].HauntPendingTimer == 2500,
        "bot runtime updates do not age or overwrite player addon state");
    std::cout << "Affliction bot integration: " << checks << " checks passed\n";
}
