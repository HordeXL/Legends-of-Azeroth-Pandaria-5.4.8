// Execute production click visibility and target AI. Casting/conditions are
// engine doubles; actual client boarding and arrow interception need playtesting.
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <vector>
using uint32 = uint32_t;
enum { UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK = 1,
       SPELL_ARCHERY_VEHICLE = 114877, SPELL_HEROIC_DEFENSE = 113436,
       SPELL_PLAYER_VEHICLE_AURA = 113399, TALK_INTRO = 1 };
struct Player;
struct Unit
{
    uint32 defenseCaster = 0;
    bool HasAura(uint32, uint32 caster) const { return defenseCaster == caster; }
    Unit* ToUnit() { return this; }
    virtual void CastSpell(Unit*, uint32, bool) { assert(false); }
    virtual void ForceValuesUpdateAtIndex(uint32) { assert(false); }
};
struct Vehicle { uint32 GetCreatureEntry() const { return 59163; } };
struct Creature : Unit
{
    bool clickable = false;
    Vehicle vehicle;
    std::vector<Player*> nearbyClients;
    uint32 proximityCasts = 0;
    uint32 GetGUID() const { return 42; }
    uint32 GetHealth() const { return 100; }
    uint32 GetEntry() const { return 59163; }
    Vehicle const* GetVehicleKit() const { return &vehicle; }
    bool HasFlag(uint32, uint32) const { return clickable; }
    void SetFlag(uint32, uint32) { clickable = true; }
    void RemoveFlag(uint32, uint32) { clickable = false; }
    void CastSpell(Unit*, uint32, bool) override;
    void ForceValuesUpdateAtIndex(uint32) override;
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
struct Player : Unit
{
    bool inRange = false, vehicleAura = true, clientCanClick = false;
    bool CanSeeSpellClickOn(Creature const*) const;
};
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
    bool IsObjectMeetingSpellClickConditions(uint32, uint32, Player* player, Creature const*)
    {
        return allowed && player->vehicleAura && !player->defenseCaster;
    }
} conditionMgr;
auto* sConditionMgr = &conditionMgr;
#include "archery_target.inc"
#include "spellclick_visibility.inc"
struct AuraEffect { };
struct ProximityAura
{
    Creature* owner;
    bool preventDefault = false;
    explicit ProximityAura(Creature* c) : owner(c) { }
    Unit* GetOwner() { return owner; }
    void PreventDefaultAction() { preventDefault = true; }
#include "archery_proximity.inc"
};
void Creature::CastSpell(Unit* target, uint32 spell, bool triggered)
{
    assert(target == this && spell == SPELL_PLAYER_VEHICLE_AURA && triggered);
    ++proximityCasts;
    for (Player* player : nearbyClients)
        if (player->inRange)
            player->vehicleAura = true;
}
void Creature::ForceValuesUpdateAtIndex(uint32 field)
{
    assert(field == UNIT_FIELD_NPC_FLAGS);
    // Unit::BuildValuesUpdate conditionally removes SPELLCLICK per recipient.
    // Reuse its production visibility predicate; cache the last client value.
    for (Player* player : nearbyClients)
        player->clientCanClick = player->CanSeeSpellClickOn(this);
}
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

    player.defenseCaster = 0;
    player.vehicleAura = false;
    Player distant, carrying;
    distant.vehicleAura = false;
    carrying.defenseCaster = 99;
    carrying.inRange = true;
    target.nearbyClients = { &player, &distant, &carrying };
    ProximityAura proximity(&target);

    // Initial create outside the proximity radius: client cannot click.
    target.ForceValuesUpdateAtIndex(UNIT_FIELD_NPC_FLAGS);
    assert(!player.clientCanClick && !distant.clientCanClick && !carrying.clientCanClick);
    player.inRange = true;
    proximity.OnPeriodic(nullptr);
    // Old code grants the server aura but leaves clientCanClick false forever.
    assert(player.vehicleAura && player.clientCanClick);
    assert(!distant.clientCanClick && !carrying.clientCanClick);
    assert(proximity.preventDefault && target.proximityCasts == 1);

    player.inRange = false;
    player.vehicleAura = false; // Simulate natural expiry after leaving range.
    proximity.OnPeriodic(nullptr);
    assert(!player.clientCanClick);
    player.inRange = true;
    proximity.OnPeriodic(nullptr);
    assert(player.clientCanClick);
    player.defenseCaster = 99; // This player picks up a different shield.
    proximity.OnPeriodic(nullptr);
    assert(!player.clientCanClick);
    player.defenseCaster = 0;
    target.RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);
    proximity.OnPeriodic(nullptr);
    assert(!player.clientCanClick); // Refresh must never re-enable a consumed NPC.
    std::cout << "PASS archery proximity: approach, expiry, re-entry, per-player conditions, consumed target, one cast per tick\n";
}
