#include <cassert>
#include <cstdint>
#include <iostream>
#include <list>
#include <map>
#include <vector>
using uint32 = std::uint32_t;
using uint8 = std::uint8_t;
constexpr int LOOT_ITEM_TYPE_ITEM = 0, RATE_DROP_ITEM_REFERENCED_AMOUNT = 0;
struct Player { uint32 map; };
struct Condition { uint32 requiredMap; };
using ConditionContainer = std::vector<Condition>;
struct Conditions
{
    bool IsObjectMeetToConditions(Player* player, ConditionContainer const& conditions)
    {
        for (auto const& condition : conditions)
            if (!player || player->map != condition.requiredMap)
                return false;
        return true;
    }
} conditionMgr;
auto sConditionMgr = &conditionMgr;
struct World { float getRate(int) { return 1.0f; } } world;
auto sWorld = &world;
struct LootStoreItem
{
    uint32 itemid;
    int mincountOrRef = 1;
    uint32 lootmode = 0, maxcount = 1;
    uint8 group = 0;
    int type = LOOT_ITEM_TYPE_ITEM;
    bool rolls = true;
    ConditionContainer conditions;
    bool Roll(bool) const { return rolls; }
};
using LootStoreItemList = std::list<LootStoreItem*>;
struct Loot
{
    std::vector<LootStoreItem> items;
    void AddItem(LootStoreItem const& item, Player*) { items.push_back(item); }
};
struct LootGroup
{
    LootStoreItem* item;
    void Process(Loot& loot, uint32 mode, Player* player)
    {
        if (!item->lootmode || (item->lootmode & mode))
            loot.AddItem(*item, player);
    }
};
struct LootTemplate
{
    using LootGroups = std::vector<LootGroup*>;
    LootStoreItemList Entries;
    LootGroups Groups;
    bool ProcessScriptedLoot(Loot&, Player*) const { return false; }
    void Process(Loot&, bool, uint32, uint8, Player*) const;
};
struct References
{
    std::map<int, LootTemplate*> tables;
    LootTemplate const* GetLootFor(int id) const
    {
        auto found = tables.find(id);
        return found == tables.end() ? nullptr : found->second;
    }
} LootTemplates_Reference;
#include "loot_process.inc"

int main()
{
    Player modern{1004}, legacy{189};
    LootStoreItem oldItem{7721};
    LootGroup oldGroup{&oldItem};
    LootTemplate child{{}, {&oldGroup}};
    LootTemplates_Reference.tables[3787] = &child;
    LootStoreItem reference{3787, -3787};
    reference.conditions = {{189}};
    LootTemplate root{{&reference}, {}};
    for (uint32 mode : {2u, 4u})
    {
        Loot current;
        root.Process(current, true, mode, 0, &modern);
        assert(current.items.empty());
        root.Process(current, true, mode, 0, &legacy);
        assert(current.items.size() == 1 && current.items[0].itemid == 7721);
    }
    Loot missingPlayer;
    root.Process(missingPlayer, true, 4, 0, nullptr);
    assert(missingPlayer.items.empty());
    reference.group = 1;
    Loot grouped;
    root.Process(grouped, true, 4, 0, &modern);
    assert(grouped.items.empty());
    root.Process(grouped, true, 4, 0, &legacy);
    assert(grouped.items.size() == 1);
    reference.group = 0;
    LootStoreItem outer{9000, -9000};
    LootTemplate nested{{&outer}, {}};
    LootTemplates_Reference.tables[9000] = &root;
    Loot nestedResult;
    nested.Process(nestedResult, true, 4, 0, &modern);
    assert(nestedResult.items.empty());
    nested.Process(nestedResult, true, 4, 0, &legacy);
    assert(nestedResult.items.size() == 1);

    // Unconditional Heroic pools keep their mode and two-item multiplier.
    reference.conditions.clear();
    reference.lootmode = 4;
    reference.maxcount = 2;
    Loot normal, heroic;
    root.Process(normal, true, 2, 0, &modern);
    root.Process(heroic, true, 4, 0, &modern);
    assert(normal.items.empty() && heroic.items.size() == 2);
    reference.rolls = false;
    Loot failedRoll;
    root.Process(failedRoll, true, 4, 0, &modern);
    assert(failedRoll.items.empty());

    // Direct item conditions remain attached for per-player loot eligibility.
    oldItem.conditions = {{189}};
    LootTemplate direct{{&oldItem}, {}};
    Loot perPlayer;
    direct.Process(perPlayer, true, 4, 0, &modern);
    assert(perPlayer.items.size() == 1 && !perPlayer.items[0].conditions.empty());
    std::cout << "PASS: reference map conditions, nested/group references, legacy preservation, difficulty/count/chance preservation, per-player direct conditions\n";
}
