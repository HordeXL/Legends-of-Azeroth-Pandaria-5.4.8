// Execute the production AI with small engine doubles. Spellclick delivery
// models the core's order: DB conditions, queued spell, then OnSpellClick.
#include <cassert>
#include <cstdint>
#include <iostream>
using uint32 = std::uint32_t;
enum { UNIT_FIELD_FLAGS, UNIT_FIELD_NPC_FLAGS };
enum { UNIT_FLAG_NON_ATTACKABLE = 2, UNIT_FLAG_DISABLE_MOVE = 4, UNIT_NPC_FLAG_SPELLCLICK = 8 };
enum { REACT_PASSIVE, REACT_AGGRESSIVE };
struct Unit { virtual ~Unit() = default; };
struct InstanceScript { };
struct EventMap { void Update(uint32) { } };
struct Creature : Unit
{
    uint32 flags[2] = {};
    int reaction = REACT_AGGRESSIVE;
    bool visual = true; // creature_template_addon applies Fuel Barrel
    bool despawned = false;
    uint32 despawnDelay = 0;
    unsigned visualCasts = 0, explosions = 0, queuedExplosions = 0, melee = 0;
    InstanceScript* GetInstanceScript() { return nullptr; }
    uint32 GetHealth() { return 100; }
    void SetReactState(int value) { reaction = value; }
    void SetFlag(int field, uint32 value) { flags[field] |= value; }
    void RemoveFlag(int field, uint32 value) { flags[field] &= ~value; }
    bool HasFlag(int field, uint32 value) { return (flags[field] & value) == value; }
    bool HasAura(uint32 spell) { assert(spell == 114875); return visual; }
    void RemoveAurasDueToSpell(uint32 spell) { assert(spell == 114875); visual = false; }
    void CastSpell(Unit*, uint32 spell, bool)
    {
        if (spell == 114875) { visual = true; ++visualCasts; }
        else { assert(spell == 114952); ++queuedExplosions; }
    }
    void DespawnOrUnsummon(uint32 delay = 0) { despawnDelay = delay; despawned = !delay; }
    void ResolveSpells() { assert(!despawned); explosions += queuedExplosions; queuedExplosions = 0; }
};
struct ScriptedAI
{
    Creature* me;
    explicit ScriptedAI(Creature* creature) : me(creature) { }
    virtual ~ScriptedAI() = default;
    virtual void Reset() { }
    virtual void IsSummonedBy(Unit*) { }
    virtual void AttackStart(Unit*) { ++me->melee; }
    virtual void OnSpellClick(Unit*, bool&) { }
    virtual void DamageTaken(Unit*, uint32&) { }
    virtual void UpdateAI(uint32) { }
    bool UpdateVictim() { return true; }
    void DoMeleeAttackIfReady() { ++me->melee; }
};
#include "fuel_tank.inc"

static bool Click(Creature& barrel, npc_scm_fuel_tankAI& ai, Unit& player)
{
    // SourceType 18, target 1, aura 114875; DB spell 114952, flags 0.
    bool result = barrel.HasAura(SPELL_FUEL_BARREL);
    if (result)
        barrel.CastSpell(&barrel, SPELL_BARREL_EXPLOSION, false);
    ai.OnSpellClick(&player, result);
    return result;
}

int main()
{
    Creature barrel;
    Unit enemy, player;
    npc_scm_fuel_tankAI ai(&barrel);
    ai.Reset();
    assert(barrel.reaction == REACT_PASSIVE);
    assert(barrel.HasFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_DISABLE_MOVE));
    assert(barrel.HasFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK));
    assert(barrel.visual && barrel.visualCasts == 0);
    for (unsigned tick = 0; tick < 300; ++tick)
    {
        ai.AttackStart(&enemy);
        ai.UpdateAI(200);
    }
    assert(barrel.melee == 0 && barrel.visual && barrel.visualCasts == 0);
    for (uint32 amount : { 1u, 99u, 100u, 1000u })
    {
        ai.DamageTaken(&enemy, amount);
        assert(amount == 0);
    }
    bool rejected = false;
    ai.OnSpellClick(&player, rejected);
    assert(barrel.visual && barrel.despawnDelay == 0 && !barrel.despawned);
    assert(Click(barrel, ai, player));
    assert(!barrel.visual && !barrel.HasFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK));
    assert(!barrel.despawned && barrel.despawnDelay > 0);
    assert(!Click(barrel, ai, player)); // queued double click, including another player
    barrel.ResolveSpells();
    assert(barrel.explosions == 1);

    Creature withoutAddon;
    withoutAddon.visual = false;
    npc_scm_fuel_tankAI other(&withoutAddon);
    other.Reset();
    other.Reset();
    assert(withoutAddon.visual && withoutAddon.visualCasts == 1);
    std::cout << "PASS: stationary noncombat prop, stable aura, damage immunity, rejected click, single explosion before despawn, reset fallback\n";
}
