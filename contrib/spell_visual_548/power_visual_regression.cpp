#include "../../src/server/game/Spells/SpellPowerVisuals.h"
#include <cassert>
#include <iostream>
#include <set>

using uint32 = std::uint32_t;
enum { CLASS_WARLOCK = 9, CLASS_PRIEST = 5, CLASS_PALADIN = 2, SPEC_WARLOCK_AFFLICTION = 265,
    SPEC_WARLOCK_DEMONOLOGY = 266, SPEC_WARLOCK_DESTRUCTION = 267,
    POWER_SOUL_SHARDS = 7, POWER_BURNING_EMBERS = 14, POWER_DEMONIC_FURY = 15,
    POWER_SHADOW_ORBS = 13, BASE_ATTACK = 0, ITEM_SUBCLASS_WEAPON_SWORD = 7,
    ITEM_SUBCLASS_WEAPON_SWORD2 = 8, ITEM_SUBCLASS_WEAPON_AXE = 0, ITEM_SUBCLASS_WEAPON_AXE2 = 1 };

struct ItemTemplate { int SubClass = ITEM_SUBCLASS_WEAPON_SWORD; };
struct Item { ItemTemplate data; ItemTemplate const* GetTemplate() const { return &data; } };

class Player
{
public:
    int playerClass = CLASS_WARLOCK, spec = SPEC_WARLOCK_AFFLICTION;
    int shards = 0, embers = 0, fury = 0, maxOrbs = 3, casts = 0;
    bool alive = true, inWorld = true;
    bool glyph = false, equipped = true;
    Item weapon;
    std::set<uint32> auras;
    int GetClass() const { return playerClass; }
    bool IsInWorld() const { return inWorld; }
    bool IsAlive() const { return alive; }
    int GetSpecialization() const { return spec; }
    bool HasSpell(uint32 id) const { assert(id == 115934); return glyph; }
    Item* GetWeaponForAttack(int) { return equipped ? &weapon : nullptr; }
    bool HasAura(uint32 id) const { return auras.count(id) != 0; }
    int GetPower(int type) const { return type == POWER_SOUL_SHARDS ? shards : type == POWER_BURNING_EMBERS ? embers : fury; }
    int GetMaxPower(int) const { return maxOrbs; }
    void CastSpell(Player* target, uint32 id, bool triggered)
    {
        assert(target == this && triggered); // Cosmetic updates must not interrupt a cast or consume resources.
        assert(id != 117197 && id != 122736);
        auras.insert(id);
        ++casts;
    }
    void RemoveAurasDueToSpell(uint32 id) { auras.erase(id); }
    void ShadowVisuals(int val);
};

// UPDATE_WARLOCK
// UPDATE_PALADIN

void Player::ShadowVisuals(int val)
{
    int power = POWER_SHADOW_ORBS;
    // SHADOW_VISUALS
}

struct AuraInfo { int StackAmount; };
struct TestAura
{
    AuraInfo info;
    int stacks, charges;
    AuraInfo const* GetSpellInfo() const { return &info; }
    int GetStackAmount() const { return stacks; }
    int GetCharges() const { return charges; }
};
int SnapshotCharges(TestAura const* aura) { return /* SNAPSHOT_CHARGES */; }
int IncrementalCharges(TestAura const* aura) { return /* INCREMENTAL_CHARGES */; }

struct AuraEffect {};
using AuraEffectHandleModes = int;
constexpr uint32 SPELL_SHA_MAELSTROM_WEAPON_FULL_STACKS = 60349;
struct StackAura
{
    int stacks = 5;
    int GetStackAmount() const { return stacks; }
    int GetMaxStackAmount() const { return 5; }
};
struct ShamanVisual
{
    Player player;
    StackAura aura;
    Player* GetUnitOwner() { return &player; }
    StackAura* GetAura() { return &aura; }
    // SHAMAN_APPLY
    // SHAMAN_REMOVE
};

int main()
{
    using namespace SpellPowerVisuals;
    Player player;
    int checks = 0;
    auto expect = [&](std::set<uint32> const& expected)
    {
        int shards = player.shards, embers = player.embers, fury = player.fury;
        UpdateWarlock(&player);
        std::set<uint32> actual;
        for (uint32 id : WarlockSpells) if (player.HasAura(id)) actual.insert(id);
        assert(actual == expected);
        assert(player.shards == shards && player.embers == embers && player.fury == fury);
        int casts = player.casts;
        UpdateWarlock(&player);
        assert(player.casts == casts); // Repeated synchronization does not restart animations.
        ++checks;
    };
    expect({});
    player.shards = 100; expect({104756});
    player.shards = 200; expect({104759});
    player.shards = 300; expect({104756,104759});
    player.shards = 400; expect({104759,123171});
    player.auras.insert(56241); expect({123730,123731});
    player.shards = 300; expect({123728,123730});
    player.shards = 200; expect({123730});
    player.shards = 100; expect({123728});
    player.auras.erase(56241); expect({104756});
    player.shards = 99; expect({});
    player.shards = 400; expect({104759,123171});
    player.spec = SPEC_WARLOCK_DESTRUCTION;
    player.embers = 19; expect({});
    player.embers = 20; expect({116855});
    player.embers = 30; expect({116855,116920});
    player.embers = 29; expect({116855});
    player.auras.insert(56241); expect({123730});
    player.embers = 40; expect({123730,123731});
    player.auras.erase(56241); expect({116855,116920});
    player.embers = 0; expect({});
    player.spec = SPEC_WARLOCK_DEMONOLOGY;
    player.fury = 980; expect({122738,131755}); // Large jump must create both layers.
    player.fury = 979; expect({122738});
    player.fury = 500; expect({122738});
    player.fury = 499; expect({});
    player.fury = 1000; expect({122738,131755});
    player.alive = false; expect({});
    player.alive = true; expect({122738,131755});
    player.inWorld = false;
    player.auras.clear();
    UpdateWarlock(&player); assert(player.auras.empty()); ++checks;
    player.inWorld = true; expect({122738,131755});
    player.spec = 0; expect({});
    player.playerClass = CLASS_PRIEST;
    player.spec = SPEC_WARLOCK_AFFLICTION;
    UpdateWarlock(&player); assert(player.auras.empty()); ++checks;
    UpdateWarlock(nullptr); ++checks;

    // The client applies glyph aura 403 to the base orb. Do not leave a
    // separate raven aura stuck after glyph removal, or recast each update.
    player.auras = {57985,127850};
    player.ShadowVisuals(1);
    assert(player.HasAura(77487) && !player.HasAura(127850)); ++checks;
    int casts = player.casts;
    player.ShadowVisuals(2); assert(player.casts == casts); ++checks;
    player.auras.erase(57985);
    player.ShadowVisuals(2); assert(player.HasAura(77487) && player.casts == casts); ++checks;
    player.ShadowVisuals(3); assert(player.HasAura(124495)); ++checks;
    casts = player.casts;
    player.ShadowVisuals(3); assert(player.casts == casts); ++checks;
    player.ShadowVisuals(0);
    assert(!player.HasAura(77487) && !player.HasAura(124495)); ++checks;
    player.maxOrbs = 0;
    player.ShadowVisuals(0); assert(!player.HasAura(124495)); ++checks;

    for (int maxStack : {0,1,2})
    {
        TestAura aura{{maxStack}, 2, 7};
        int expected = maxStack > 1 ? 2 : 7;
        assert(SnapshotCharges(&aura) == expected);
        assert(IncrementalCharges(&aura) == expected);
        ++checks;
    }
    player.playerClass = CLASS_PALADIN;
    player.auras.clear();
    auto expectPaladin = [&](uint32 visual)
    {
        UpdatePaladin(&player);
        assert(player.HasAura(127755) == (visual == 127755));
        assert(player.HasAura(127756) == (visual == 127756));
        int casts = player.casts;
        UpdatePaladin(&player);
        assert(player.casts == casts);
        ++checks;
    };
    expectPaladin(0); // Sword alone is not sufficient: the glyph must be equipped.
    player.glyph = true; expectPaladin(127755);
    player.weapon.data.SubClass = ITEM_SUBCLASS_WEAPON_SWORD2; expectPaladin(127755);
    player.weapon.data.SubClass = ITEM_SUBCLASS_WEAPON_AXE; expectPaladin(127756);
    player.weapon.data.SubClass = ITEM_SUBCLASS_WEAPON_AXE2; expectPaladin(127756);
    player.weapon.data.SubClass = 4; expectPaladin(0); // Maces keep the ordinary judgment.
    player.weapon.data.SubClass = ITEM_SUBCLASS_WEAPON_SWORD; expectPaladin(127755);
    player.equipped = false; expectPaladin(0);
    player.equipped = true; expectPaladin(127755);
    player.glyph = false; expectPaladin(0);
    player.glyph = true; expectPaladin(127755);
    player.alive = false; expectPaladin(0);
    player.alive = true; expectPaladin(127755);
    player.auras.clear(); player.inWorld = false; expectPaladin(0);
    player.inWorld = true; player.playerClass = CLASS_WARLOCK; expectPaladin(0);
    UpdatePaladin(nullptr); ++checks;
    ShamanVisual shaman;
    shaman.HandleApply(nullptr, 0); // Restored at five stacks, without a new proc.
    assert(shaman.player.HasAura(60349)); ++checks;
    int shamanCasts = shaman.player.casts;
    shaman.HandleApply(nullptr, 0);
    assert(shaman.player.casts == shamanCasts); ++checks;
    shaman.aura.stacks = 4;
    shaman.HandleApply(nullptr, 0);
    assert(!shaman.player.HasAura(60349)); ++checks;
    shaman.aura.stacks = 5;
    shaman.HandleApply(nullptr, 0);
    assert(shaman.player.HasAura(60349)); ++checks;
    shaman.HandleRemove(nullptr, 0);
    assert(!shaman.player.HasAura(60349)); ++checks;
    std::cout << checks << " spell visual regression checks passed\n";
}
