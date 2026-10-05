// Execute production click visibility and target AI. Casting/conditions are
// engine doubles; actual client boarding and arrow interception need playtesting.
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
using uint32 = uint32_t;
enum { UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK = 1,
       SPELL_ARCHERY_VEHICLE = 114877, SPELL_HEROIC_DEFENSE = 113436, TALK_INTRO = 1 };
struct Unit
{
    uint32 defenseCaster = 0;
    bool HasAura(uint32, uint32 caster) const { return defenseCaster == caster; }
};
struct Vehicle { uint32 GetCreatureEntry() const { return 59163; } };
struct Creature : Unit
{
    bool clickable = false;
    Vehicle vehicle;
    uint32 GetGUID() const { return 42; }
    uint32 GetHealth() const { return 100; }
    uint32 GetEntry() const { return 59163; }
    Vehicle const* GetVehicleKit() const { return &vehicle; }
    bool HasFlag(uint32, uint32) const { return clickable; }
    void SetFlag(uint32, uint32) { clickable = true; }
    void RemoveFlag(uint32, uint32) { clickable = false; }
};
struct ScriptedAI
{
    Creature* me;
    uint32 announcements = 0, casts = 0;
    explicit ScriptedAI(Creature* c) : me(c) { }
    virtual ~ScriptedAI() = default;
    virtual void Reset() { }
    virtual void OnSpellClick(Unit*, bool&) { }
    virtual void DamageTaken(Unit*, uint32&) { }
    virtual void UpdateAI(uint32) { }
    void DoCast(Unit*, uint32, bool = false) { ++casts; }
    void Talk(uint32) { ++announcements; }
};
struct Player : Unit { bool CanSeeSpellClickOn(Creature const*) const; };
struct SpellClickInfo
{
    uint32 spellId = SPELL_HEROIC_DEFENSE;
    bool IsFitToRequirements(Player const*, Creature const*) const { return true; }
};
using SpellClickInfoContainer = std::multimap<uint32, SpellClickInfo>;
using SpellClickInfoMapBounds = std::pair<SpellClickInfoContainer::const_iterator, SpellClickInfoContainer::const_iterator>;
struct ObjectMgr
{
    SpellClickInfoContainer clicks;
    SpellClickInfoMapBounds GetSpellClickInfoMapBounds(uint32 entry) const { return clicks.equal_range(entry); }
} objectMgr;
auto* sObjectMgr = &objectMgr;
struct ConditionMgr
{
    bool allowed = true;
    bool IsObjectMeetingSpellClickConditions(uint32, uint32, Player*, Creature const*) { return allowed; }
} conditionMgr;
auto* sConditionMgr = &conditionMgr;
#include "archery_target.inc"
#include "spellclick_visibility.inc"
int main()
{
    Creature target;
    Player player;
    npc_reinforced_archery_targetAI ai(&target);
    ai.Reset();
    assert(target.clickable);
    assert(!player.CanSeeSpellClickOn(&target)); // Original DB omission hides the flag.
    objectMgr.clicks.emplace(59163, SpellClickInfo{});
    assert(player.CanSeeSpellClickOn(&target));
    conditionMgr.allowed = false;
    assert(!player.CanSeeSpellClickOn(&target));
    conditionMgr.allowed = true;
    bool result = true; // HandleSpellClick can report true even when the cast fails.
    ai.OnSpellClick(&player, result);
    assert(target.clickable && !ai.hasRider && ai.announcements == 0);
    player.defenseCaster = 99; // Another target's aura must not consume this target.
    ai.OnSpellClick(&player, result);
    assert(target.clickable && !ai.hasRider);
    player.defenseCaster = target.GetGUID();
    ai.OnSpellClick(&player, result);
    assert(ai.hasRider && !target.clickable && ai.announcements == 1);
    assert(ai.casts == 1); // Only Reset's periodic aura: no second boarding cast.
    assert(!player.CanSeeSpellClickOn(&target));
    ai.OnSpellClick(&player, result);
    assert(ai.announcements == 1 && ai.casts == 1);
    ai.Reset();
    assert(target.clickable && !ai.hasRider);
    std::cout << "PASS archery target: click visibility, failed/foreign casts, single pickup, reset\n";
}
