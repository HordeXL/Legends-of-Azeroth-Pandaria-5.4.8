#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <list>
#include <map>
#include <vector>
using uint32 = uint32_t;
using uint8 = uint8_t;
using int32 = int32_t;
#include "policy.inc"
constexpr int LOOT_ITEM_TYPE_ITEM = 0;
constexpr int RATE_DROP_ITEM_REFERENCED_AMOUNT = 0;
#define TC_LOG_ERROR(...) ((void)0)
int32 irand(int32 low, int32 high) { assert(high >= low); return high; }
namespace Trinity { namespace Containers {
template<class T> auto SelectRandomContainerElement(T const& list) { return list.back(); }
}}
struct World { float getRate(int) { return 1; } } world;
World* sWorld = &world;
struct Map
{
    bool raid = false;
    bool IsDungeon() { return true; }
    bool IsRaid() { return raid; }
} map;
struct Player { Map* GetMap() { return &map; } } player;
struct LootStoreItem
{
    uint32 itemid;
    float chance;
    uint32 lootmode = 1;
    int mincountOrRef = 1;
    uint32 maxcount = 1;
    uint8 group = 0;
    int type = 0;
    bool needs_quest = false;
    bool Roll(bool, float multiplier = 1.0f) const
    {
        return chance * multiplier >= 100;
    }
};
using LootStoreItemList = std::list<LootStoreItem*>;
struct Loot
{
    std::vector<LootStoreItem> items;
    uint32 sourceEntry = 0;
    void AddItem(LootStoreItem const& item, Player*) { items.push_back(item); }
};
struct LootGroupInvalidSelector
{
    Loot const& loot;
    uint32 mode;
    LootGroupInvalidSelector(Loot const& l, uint32 m, Player*) : loot(l), mode(m) {}
    bool operator()(LootStoreItem* item) const
    {
        return (item->lootmode && !(item->lootmode & mode)) ||
            std::any_of(loot.items.begin(), loot.items.end(),
                [item](auto const& existing) { return existing.itemid == item->itemid; });
    }
};
struct LootTemplate
{
    struct LootGroup
    {
        LootStoreItemList ExplicitlyChanced, EqualChanced;
        LootStoreItem const* Roll(Loot&, uint32, Player*, bool = false,
            float = 1.0f) const;
        void Process(Loot&, uint32, Player*, LootRollPolicy = LootRollPolicy::Normal) const;
    };
    using LootGroups = std::vector<LootGroup*>;
    LootStoreItemList Entries;
    LootGroups Groups;
    bool ProcessScriptedLoot(Loot&, Player*) const { return false; }
    void Process(Loot&, bool, uint32, uint8, Player*, LootRollPolicy = LootRollPolicy::Normal) const;
};
struct References
{
    std::map<int, LootTemplate*> tables;
    LootTemplate const* GetLootFor(int id) const
    {
        auto it = tables.find(id);
        return it == tables.end() ? nullptr : it->second;
    }
} LootTemplates_Reference;
constexpr int TYPEID_UNIT = 3;
struct Object
{
    int type, mapId;
    bool raid = false, boss = false;
    Map objectMap;
    int GetTypeId() const { return type; }
    Object* ToCreature() { return this; }
    int GetMapId() const { return mapId; }
    Map* GetMap() { objectMap.raid = raid; return &objectMap; }
    bool IsDungeonBoss() const { return boss; }
};
using Creature = Object;
struct LootStore {} LootTemplates_Creature, otherStore;
#include "methods.inc"
int main()
{
    Object aq40{TYPEID_UNIT, 531, false, false, {}},
        aq20{TYPEID_UNIT, 509, false, false, {}};
    Object raidBoss{TYPEID_UNIT, 724, true, true, {}};
    Object raidTrash{TYPEID_UNIT, 724, true, false, {}};
    Object chest{5, 531, false, false, {}};
    assert(SelectPolicy(&aq40, LootTemplates_Creature) == LootRollPolicy::AllDirectItems);
    assert(SelectPolicy(&aq20, LootTemplates_Creature) == LootRollPolicy::Normal);
    assert(SelectPolicy(&raidBoss, LootTemplates_Creature) == LootRollPolicy::BoostedRaidBoss);
    assert(SelectPolicy(&raidTrash, LootTemplates_Creature) == LootRollPolicy::Normal);
    assert(SelectPolicy(&chest, LootTemplates_Creature) == LootRollPolicy::Normal);
    assert(SelectPolicy(nullptr, LootTemplates_Creature) == LootRollPolicy::Normal);
    assert(SelectPolicy(&aq40, otherStore) == LootRollPolicy::Normal);
    LootStoreItem a{1, 5}, b{2, 10}, c{3, 0}, excluded{4, 100, 2};
    LootTemplate::LootGroup weighted{{&a, &b}, {}};
    Loot loot;
    weighted.Process(loot, 1, &player);
    assert(loot.items.empty()); // A normal low-chance group can still miss.
    weighted.Process(loot, 1, &player, LootRollPolicy::GuaranteedGroups);
    assert(loot.items.size() == 1 && loot.items[0].itemid == 2);
    loot.items.clear();
    LootStoreItem rare{99, 0.000001f};
    LootTemplate::LootGroup tiny{{&rare}, {}};
    tiny.Process(loot, 1, &player, LootRollPolicy::GuaranteedGroups);
    assert(loot.items.size() == 1 && loot.items[0].itemid == 99);
    loot.items.clear();
    LootTemplate::LootGroup direct{{&a, &excluded}, {&b, &c}};
    direct.Process(loot, 1, &player, LootRollPolicy::AllDirectItems);
    assert(loot.items.size() == 3); // All items, except the wrong loot mode.
    direct.Process(loot, 1, &player, LootRollPolicy::AllDirectItems);
    assert(loot.items.size() == 3); // Duplicate filtering remains active.
    loot.items.clear();
    LootStoreItem boostedA{30, 50}, boostedB{31, 50};
    LootTemplate boosted{{}, {new LootTemplate::LootGroup{{&boostedA, &boostedB}, {}}}};
    boosted.Process(loot, true, 1, 0, &player, LootRollPolicy::BoostedRaidBoss);
    assert(loot.items.size() == 2); // Raid bosses draw twice without duplicating an item.
    loot.items.clear();
    LootTemplate::LootGroup mixed{{&a}, {&c}};
    mixed.Process(loot, 1, &player, LootRollPolicy::GuaranteedGroups);
    assert(loot.items.size() == 1 && loot.items[0].itemid == 3);
    LootTemplate shared{{}, {&direct}};
    LootStoreItem reference{10, 1, 1, -10};
    LootStoreItem nestedReference{11, 1, 1, -11};
    LootTemplate nested{{&nestedReference}, {}};
    LootTemplates_Reference.tables = {{10, &nested}, {11, &shared}};
    LootStoreItem quest{20, 1}; quest.needs_quest = true;
    LootTemplate root{{&reference, &quest, &excluded}, {}};
    loot.items.clear();
    root.Process(loot, true, 1, 0, &player);
    assert(loot.items.empty());
    root.Process(loot, true, 1, 0, &player, LootRollPolicy::AllDirectItems);
    assert(loot.items.size() == 2); // Nested references pick one, quest stays quest-only.
    assert(loot.items[1].itemid == 20 && loot.items[1].needs_quest);
    loot.items.clear();
    reference.group = 1;
    LootTemplates_Reference.tables[10] = &shared;
    root.Process(loot, true, 1, 0, &player, LootRollPolicy::AllDirectItems);
    assert(loot.items.size() == 2); // Explicit group references work too.
    std::cout << "AQ40 loot regression checks passed\n";
}
