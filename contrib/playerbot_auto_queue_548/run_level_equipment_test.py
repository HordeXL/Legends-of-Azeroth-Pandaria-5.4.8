#!/usr/bin/env python3
"""Exercise production pre-fill cleanup after scaling an equipped pool bot."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'modules/mod_playerbots/src/Factory/BotFactory.cpp').read_text()
start = source.index('    // Remove inherited high-level gear')
end = source.index('    for (int32 slot =', start)
cleanup = source[start:end]
harness = r'''
#include "modules/mod_playerbots/src/Factory/ManagedPveEquipmentPolicy.h"
#include <array>
#include <cassert>
#include <string>
#include <vector>
using uint8 = unsigned char;
using uint32 = unsigned;
enum { EQUIPMENT_SLOT_START=0, EQUIPMENT_SLOT_HEAD=0, EQUIPMENT_SLOT_BODY=3,
       EQUIPMENT_SLOT_TRINKET1=12, EQUIPMENT_SLOT_BACK=14,
       EQUIPMENT_SLOT_RANGED=17, EQUIPMENT_SLOT_TABARD=18,
       EQUIPMENT_SLOT_END=19, INVENTORY_SLOT_BAG_0=255 };
#define TC_LOG_INFO(...) ((void)0)
#define TC_LOG_ERROR(...) ((void)0)
struct Template { uint32 RequiredLevel; };
struct Item {
    uint32 entry, ilvl; Template proto;
    Template const* GetTemplate() const { return &proto; }
    uint32 GetEntry() const { return entry; }
};
struct Player {
    std::array<Item*, EQUIPMENT_SLOT_END> equipped{};
    Item* GetItemByPos(uint8, uint8 slot) { return equipped[slot]; }
    uint32 GetItemLevel(Item* item) { return item->ilvl; }
    std::string GetName() { return "Celenia"; }
};
struct Factory {
    Player* bot; uint32 level;
    bool missingOnly=true, genuineItemsOnly=true, pveOnly=true, bagFull=false;
    std::vector<Item*> bag;
    Factory(Player* player, uint32 newLevel) : bot(player), level(newLevel) {}
    bool MoveEquippedItemToBag(uint8 slot) {
        if (bagFull) return false;
        bag.push_back(bot->equipped[slot]); bot->equipped[slot]=nullptr;
        return true;
    }
    void Cleanup() {
FUNCTION
    }
};
int main() {
    Player bot;
    Item cloak{98149,608,{90}}, armor{99093,569,{90}};
    Item normal{23037,85,{60}}, malformed{1,600,{0}}, wrongLevel{2,100,{62}};
    Item cosmetic{3,1,{90}}, ranged{4,600,{90}};
    bot.equipped[14]=&cloak; bot.equipped[0]=&armor;
    bot.equipped[10]=&normal; bot.equipped[12]=&malformed;
    bot.equipped[7]=&wrongLevel; bot.equipped[3]=&cosmetic;
    bot.equipped[17]=&ranged;
    Factory factory(&bot,61); factory.Cleanup();
    assert(factory.bag.size()==5);
    assert(bot.equipped[10]==&normal && bot.equipped[3]==&cosmetic);
    assert(!bot.equipped[0] && !bot.equipped[14] && !bot.equipped[7]);
    assert(!bot.equipped[12] && !bot.equipped[17]);
    factory.Cleanup(); assert(factory.bag.size()==5);
    // Even slots that leveling gear generation skips must be cleaned.
    bot.equipped[12]=&malformed; factory.level=20; factory.Cleanup();
    assert(!bot.equipped[12]);
    // A full bag must not delete equipment; final validation can reject it.
    bot.equipped[14]=&cloak; factory.bagFull=true; factory.Cleanup();
    assert(bot.equipped[14]==&cloak);
    assert(!ManagedPveEquipmentPolicy::IsLevelAppropriate(factory.level,
        cloak.ilvl,cloak.proto.RequiredLevel,true));
    factory.level=90; factory.bagFull=false; factory.Cleanup();
    assert(bot.equipped[14]==&cloak);
}
'''.replace('FUNCTION', cleanup)
with tempfile.TemporaryDirectory(prefix='level-equipment-test-') as directory:
    directory = Path(directory)
    cpp = directory / 'cleanup.cpp'
    cpp.write_text(harness)
    for source_file, name in [
        (cpp, 'cleanup'),
        (root / 'contrib/playerbot_auto_queue_548/level60_equipment_regression.cpp', 'policy'),
    ]:
        binary = directory / name
        subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-pedantic',
                        '-I', str(root), str(source_file), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
print('Level equipment policy and production cleanup checks passed')
