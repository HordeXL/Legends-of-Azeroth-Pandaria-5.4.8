/*
* This file is part of the Pandaria 5.4.8 Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "CustomTransmogrification.h"
#include "Bag.h"
#include "Chat.h"
#pragma execution_character_set("UTF-8")


Transmogrification::Transmogrification()
{

}

Transmogrification::~Transmogrification()
{
    
}

Transmogrification* Transmogrification::instance()
{
    static Transmogrification instance;
    return &instance;
}

namespace
{
bool IsCollectibleAppearance(uint32 entry)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    if (!proto || !proto->DisplayInfoID ||
        (proto->Class != ITEM_CLASS_ARMOR && proto->Class != ITEM_CLASS_WEAPON))
        return false;
    switch (proto->InventoryType)
    {
        case INVTYPE_NON_EQUIP: case INVTYPE_BAG: case INVTYPE_FINGER:
        case INVTYPE_TRINKET: case INVTYPE_AMMO: case INVTYPE_QUIVER: case INVTYPE_RELIC:
            return false;
        default: return true;
    }
}
}

void Transmogrification::LoadCollection(uint32 account)
{
    if (collections.count(account))
        return;
    auto& entries = collections[account];
    if (QueryResult saved = CharacterDatabase.PQuery(
        "SELECT itemEntry FROM account_transmog_appearances WHERE accountId = %u", account))
        do { entries.insert((*saved)[0].GetUInt32()); } while (saved->NextRow());

    // Include offline characters on this account, but not mail, auctions or
    // guild-bank contents that have not been taken into personal inventory.
    QueryResult owned = CharacterDatabase.PQuery(
        "SELECT i.itemEntry FROM character_inventory v JOIN characters c ON c.guid=v.guid "
        "JOIN item_instance i ON i.guid=v.item WHERE c.account=%u "
        "UNION SELECT v.itemEntry FROM character_void_storage v JOIN characters c ON c.guid=v.playerGuid WHERE c.account=%u "
        "UNION SELECT t.FakeEntry FROM custom_transmogrification t JOIN characters c ON c.guid=t.Owner WHERE c.account=%u "
        "UNION SELECT i.transmogrifyId FROM character_inventory v JOIN characters c ON c.guid=v.guid "
        "JOIN item_instance i ON i.guid=v.item WHERE c.account=%u AND i.transmogrifyId<>0",
        account, account, account, account);
    if (!owned)
        return;
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    do
    {
        uint32 entry = (*owned)[0].GetUInt32();
        if (IsCollectibleAppearance(entry) && entries.insert(entry).second)
            trans->PAppend("INSERT IGNORE INTO account_transmog_appearances (accountId,itemEntry) VALUES (%u,%u)", account, entry);
    } while (owned->NextRow());
    CharacterDatabase.CommitTransaction(trans);
}

void Transmogrification::LearnAppearance(Player* player, uint32 entry, bool notify)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() ||
        player->GetSession()->GetRemoteAddress().empty() || !IsCollectibleAppearance(entry))
        return;
    uint32 account = player->GetSession()->GetAccountId();
    bool announce = notify && player->IsInWorld();
    {
        std::lock_guard<std::mutex> lock(collectionMutex);
        LoadCollection(account);
        auto& entries = collections[account];
        if (entries.count(entry))
            return;

        // Different item entries can share an appearance. Save both for
        // compatibility filtering, but only announce a newly collected look.
        if (announce)
            for (uint32 known : entries)
                if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(known))
                    if (proto->DisplayInfoID == sObjectMgr->GetItemTemplate(entry)->DisplayInfoID)
                    {
                        announce = false;
                        break;
                    }
        entries.insert(entry);
        CharacterDatabase.PExecute("INSERT IGNORE INTO account_transmog_appearances (accountId,itemEntry) VALUES (%u,%u)", account, entry);
    }
    if (announce)
    {
        std::string message = GetItemLink(entry, player->GetSession()) + " has been added to your appearance collection.";
        ChatHandler(player->GetSession()).SendSysMessage(message.c_str());
    }
}

std::vector<uint32> Transmogrification::GetCollection(Player* player)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() || player->GetSession()->GetRemoteAddress().empty())
        return {};
    uint32 account = player->GetSession()->GetAccountId();
    std::lock_guard<std::mutex> lock(collectionMutex);
    LoadCollection(account);
    auto const& entries = collections[account];
    return {entries.begin(), entries.end()};
}

bool Transmogrification::HasAppearance(Player* player, uint32 entry)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() || player->GetSession()->GetRemoteAddress().empty())
        return false;
    std::lock_guard<std::mutex> lock(collectionMutex);
    uint32 account = player->GetSession()->GetAccountId();
    LoadCollection(account);
    return collections[account].count(entry) != 0;
}

void Transmogrification::CollectInventory(Player* player)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() || player->GetSession()->GetRemoteAddress().empty()) return;
    auto collect = [&](Item* item)
    {
        if (!item) return;
        LearnAppearance(player, item->GetEntry(), false);
        LearnAppearance(player, item->GetVisibleEntry(), false);
    };
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < BANK_SLOT_BAG_END; ++slot)
        collect(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < BANK_SLOT_BAG_END; ++slot)
        if (slot < INVENTORY_SLOT_BAG_END || slot >= BANK_SLOT_BAG_START)
            if (Bag* bag = player->GetBagByPos(slot))
                for (uint32 i = 0; i < bag->GetBagSize(); ++i)
                    collect(player->GetItemByPos(slot, i));
    for (uint8 slot = 0; slot < VOID_STORAGE_MAX_SLOT; ++slot)
        if (VoidStorageItem* item = player->GetVoidStorageItem(slot))
            LearnAppearance(player, item->ItemEntry, false);
}

TransmogTrinityStrings Transmogrification::TransmogrifyAppearance(Player* player, uint32 entry, uint8 slot)
{
    if (slot >= EQUIPMENT_SLOT_END) return LANG_ERR_TRANSMOG_INVALID_SLOT;
    if (!HasAppearance(player, entry)) return LANG_ERR_TRANSMOG_MISSING_SRC_ITEM;
    Item* target = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!target) return LANG_ERR_TRANSMOG_MISSING_DEST_ITEM;
    if (!CanTransmogrifyItemWithItem(player, target->GetTemplate(), sObjectMgr->GetItemTemplate(entry), true))
        return LANG_ERR_TRANSMOG_INVALID_ITEMS;
    int64 cost = std::max<int64>(0, int64(GetSpecialPrice(target->GetTemplate()) * ScaledCostModifier) + CopperCost);
    if (!player->HasEnoughMoney(cost)) return LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY;
    if (RequireToken && !player->HasItemCount(TokenEntry, TokenAmount))
        return LANG_ERR_TRANSMOG_NOT_ENOUGH_TOKENS;
    if (RequireToken) player->DestroyItemCount(TokenEntry, TokenAmount, true);
    player->ModifyMoney(-cost);
    SetFakeEntry(player, entry, slot, target);
    target->SetBinding(true);
    target->UpdatePlayedTime(player);
    target->SetNotRefundable(player);
    target->ClearSoulboundTradeable(player);
    target->SetState(ITEM_CHANGED, player);
    return LANG_ERR_TRANSMOG_OK;
}

bool Transmogrification::HasPreview(Player* player)
{
    std::lock_guard<std::mutex> lock(previewMutex);
    return previews.count(player->GetGUID()) != 0;
}

uint32 Transmogrification::GetVisibleEntryForSave(Player* player, uint8 slot)
{
    if (GetPreviewEntry(player, slot))
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        return item ? item->GetVisibleEntry() : 0;
    }
    return player->GetUInt32Value(PLAYER_FIELD_VISIBLE_ITEMS + slot * 2);
}

uint32 Transmogrification::GetPreviewEntry(Player* player, uint8 slot)
{
    std::lock_guard<std::mutex> lock(previewMutex);
    auto session = previews.find(player->GetGUID());
    if (session == previews.end())
        return 0;
    auto item = session->second.items.find(slot);
    return item == session->second.items.end() ? 0 : item->second.entry;
}

void Transmogrification::CancelPreview(Player* player)
{
    PreviewSession preview;
    {
        std::lock_guard<std::mutex> lock(previewMutex);
        auto found = previews.find(player->GetGUID());
        if (found == previews.end())
            return;
        preview = found->second;
        previews.erase(found);
    }
    // Restore the currently equipped items, not an old cached appearance:
    // equipment or permanent transmogrification may have changed meanwhile.
    for (auto const& pair : preview.items)
        player->SetVisibleItemSlot(pair.first,
            player->GetItemByPos(INVENTORY_SLOT_BAG_0, pair.first));
}

TransmogTrinityStrings Transmogrification::PreviewAppearance(Player* player,
    Creature* npc, uint32 entry, uint8 slot)
{
    if (slot >= EQUIPMENT_SLOT_END)
        return LANG_ERR_TRANSMOG_INVALID_SLOT;
    if (!player->IsAlive() || player->IsInCombat() ||
        !player->GetNPCIfCanInteractWith(npc->GetGUID(), UNIT_NPC_FLAG_GOSSIP))
        return LANG_ERR_TRANSMOG_INVALID_ITEMS;
    Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item)
        return LANG_ERR_TRANSMOG_MISSING_DEST_ITEM;
    if (entry != item->GetEntry() && !HasAppearance(player, entry))
        return LANG_ERR_TRANSMOG_MISSING_SRC_ITEM;
    if (entry != item->GetEntry() && !CanTransmogrifyItemWithItem(player, item->GetTemplate(),
        sObjectMgr->GetItemTemplate(entry), true))
        return LANG_ERR_TRANSMOG_INVALID_ITEMS;

    UpdatePreview(player, 0);
    {
        std::lock_guard<std::mutex> lock(previewMutex);
        PreviewSession& preview = previews[player->GetGUID()];
        preview.npc = npc->GetGUID();
        preview.remaining = 300000;
        if (entry == item->GetVisibleEntry())
            preview.items.erase(slot);
        else
            preview.items[slot] = {item->GetGUID(), item->GetVisibleEntry(), entry};
        if (preview.items.empty())
            previews.erase(player->GetGUID());
    }
    // Cosmetic update only: no item modifiers, binding, payment or DB writes.
    player->SetUInt32Value(PLAYER_FIELD_VISIBLE_ITEMS + slot * 2, entry);
    return LANG_ERR_TRANSMOG_OK;
}

void Transmogrification::UpdatePreview(Player* player, uint32 diff)
{
    PreviewSession preview;
    {
        std::lock_guard<std::mutex> lock(previewMutex);
        auto found = previews.find(player->GetGUID());
        if (found == previews.end())
            return;
        found->second.remaining -= std::min(diff, found->second.remaining);
        preview = found->second;
    }
    bool invalid = !preview.remaining || !player->IsAlive() || player->IsInCombat() ||
        !player->GetNPCIfCanInteractWith(preview.npc, UNIT_NPC_FLAG_GOSSIP);
    for (auto const& pair : preview.items)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, pair.first);
        if (!item || item->GetGUID() != pair.second.item ||
            item->GetVisibleEntry() != pair.second.originalEntry)
            invalid = true;
    }
    if (invalid)
        CancelPreview(player);
}

TransmogTrinityStrings Transmogrification::AcceptPreview(Player* player, Creature* npc)
{
    UpdatePreview(player, 0);
    PreviewSession preview;
    {
        std::lock_guard<std::mutex> lock(previewMutex);
        auto found = previews.find(player->GetGUID());
        if (found == previews.end() || found->second.npc != npc->GetGUID())
            return LANG_ERR_TRANSMOG_INVALID_ITEMS;
        preview = found->second;
    }
    // Validate the complete outfit before applying any slot. This feature is
    // free; refuse a paid configuration instead of partially charging/applying.
    if (RequireToken)
        return LANG_ERR_TRANSMOG_NOT_ENOUGH_TOKENS;
    for (auto const& pair : preview.items)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, pair.first);
        if (!item || item->GetGUID() != pair.second.item ||
            (pair.second.entry != item->GetEntry() &&
                (!HasAppearance(player, pair.second.entry) ||
                !CanTransmogrifyItemWithItem(player, item->GetTemplate(),
                    sObjectMgr->GetItemTemplate(pair.second.entry), true))))
        {
            CancelPreview(player);
            return LANG_ERR_TRANSMOG_INVALID_ITEMS;
        }
        if (std::max<int64>(0, int64(GetSpecialPrice(item->GetTemplate()) *
            ScaledCostModifier) + CopperCost) != 0)
            return LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY;
    }
    CancelPreview(player);
    for (auto const& pair : preview.items)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, pair.first);
        if (pair.second.entry == item->GetEntry())
            DeleteFakeEntry(player, pair.first, item);
        else
            TransmogrifyAppearance(player, pair.second.entry, pair.first);
    }
    return LANG_ERR_TRANSMOG_OK;
}

#ifdef PRESETS
void Transmogrification::PresetTransmog(Player* player, Item* itemTransmogrified, uint32 fakeEntry, uint8 slot)
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::PresetTransmog");

    if (!EnableSets)
        return;
    if (!player || !itemTransmogrified)
        return;
    if (slot >= EQUIPMENT_SLOT_END)
        return;
    if (!HasAppearance(player, fakeEntry) ||
        !CanTransmogrifyItemWithItem(player, itemTransmogrified->GetTemplate(), sObjectMgr->GetItemTemplate(fakeEntry), true))
        return;

    // [AZTH] Custom
    if (GetFakeEntry(itemTransmogrified->GetGUID()))
        DeleteFakeEntry(player, slot, itemTransmogrified);

    SetFakeEntry(player, fakeEntry, slot, itemTransmogrified); // newEntry


    itemTransmogrified->UpdatePlayedTime(player);

    itemTransmogrified->SetOwnerGUID(player->GetGUID());
    itemTransmogrified->SetNotRefundable(player);
    itemTransmogrified->ClearSoulboundTradeable(player);
}

void Transmogrification::LoadPlayerSets(ObjectGuid pGUID)
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::LoadPlayerSets");

    for (presetData::iterator it = presetById[pGUID].begin(); it != presetById[pGUID].end(); ++it)
        it->second.clear();

    presetById[pGUID].clear();

    presetByName[pGUID].clear();

    QueryResult result = CharacterDatabase.PQuery("SELECT `PresetID`, `SetName`, `SetData` FROM `custom_transmogrification_sets` WHERE Owner = %u", pGUID.GetCounter());
    if (result)
    {
        do
        {
            uint8 PresetID = (*result)[0].GetUInt8();
            std::string SetName = (*result)[1].GetString();
            std::istringstream SetData((*result)[2].GetString());
            while (SetData.good())
            {
                uint32 slot;
                uint32 entry;
                SetData >> slot >> entry;
                if (SetData.fail())
                    break;
                if (slot >= EQUIPMENT_SLOT_END)
                {
                    TC_LOG_DEBUG("Transmogrification.log", "Item entry (FakeEntry: %u, playerGUID: %u, slot: %u, presetId: %u) has invalid slot, ignoring.", entry, pGUID.GetCounter(), slot, uint32(PresetID));
                    continue;
                }
                if (sObjectMgr->GetItemTemplate(entry))
                    presetById[pGUID][PresetID][slot] = entry; // Transmogrification::Preset(presetName, fakeEntry);
                                                               //else
                                                               //TC_LOG_DEBUG(LOG_FILTER_SQL, "Item entry (FakeEntry: %u, playerGUID: %u, slot: %u, presetId: %u) does not exist, ignoring.", entry, GUID_LOPART(pGUID), uint32(slot), uint32(PresetID));
            }

            if (!presetById[pGUID][PresetID].empty())
            {
                presetByName[pGUID][PresetID] = SetName;
                // load all presets anyways
                //if (presetByName[pGUID].size() >= GetMaxSets())
                //    break;
            }
            else // should be deleted on startup, so  this never runs (shouldnt..)
            {
                presetById[pGUID].erase(PresetID);
                CharacterDatabase.PExecute("DELETE FROM `custom_transmogrification_sets` WHERE Owner = %u AND PresetID = %u", pGUID.GetCounter(), PresetID);
            }
        } while (result->NextRow());
    }
}

bool Transmogrification::GetEnableSets() const
{
    return EnableSets;
}
uint8 Transmogrification::GetMaxSets() const
{
    return MaxSets;
}
float Transmogrification::GetSetCostModifier() const
{
    return SetCostModifier;
}
int32 Transmogrification::GetSetCopperCost() const
{
    return SetCopperCost;
}

void Transmogrification::UnloadPlayerSets(ObjectGuid pGUID)
{
    for (presetData::iterator it = presetById[pGUID].begin(); it != presetById[pGUID].end(); ++it)
        it->second.clear();
    presetById[pGUID].clear();

    presetByName[pGUID].clear();
}
#endif

const char* Transmogrification::GetSlotName(uint8 slot, WorldSession* /*session*/) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetSlotName");

    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD: return  "Head";// session->GetTrinityString(LANG_SLOT_NAME_HEAD);
        case EQUIPMENT_SLOT_SHOULDERS: return  "Shoulders";// session->GetTrinityString(LANG_SLOT_NAME_SHOULDERS);
        case EQUIPMENT_SLOT_BODY: return  "Shirt";// session->GetTrinityString(LANG_SLOT_NAME_BODY);
        case EQUIPMENT_SLOT_CHEST: return  "Chest";// session->GetTrinityString(LANG_SLOT_NAME_CHEST);
        case EQUIPMENT_SLOT_WAIST: return  "Waist";// session->GetTrinityString(LANG_SLOT_NAME_WAIST);
        case EQUIPMENT_SLOT_LEGS: return  "Legs";// session->GetTrinityString(LANG_SLOT_NAME_LEGS);
        case EQUIPMENT_SLOT_FEET: return  "Feet";// session->GetTrinityString(LANG_SLOT_NAME_FEET);
        case EQUIPMENT_SLOT_WRISTS: return  "Wrists";// session->GetTrinityString(LANG_SLOT_NAME_WRISTS);
        case EQUIPMENT_SLOT_HANDS: return  "Hands";// session->GetTrinityString(LANG_SLOT_NAME_HANDS);
        case EQUIPMENT_SLOT_BACK: return  "Back";// session->GetTrinityString(LANG_SLOT_NAME_BACK);
        case EQUIPMENT_SLOT_MAINHAND: return  "Main Hand";// session->GetTrinityString(LANG_SLOT_NAME_MAINHAND);
        case EQUIPMENT_SLOT_OFFHAND: return  "Off Hand";// session->GetTrinityString(LANG_SLOT_NAME_OFFHAND);
        case EQUIPMENT_SLOT_RANGED: return  "Ranged";// session->GetTrinityString(LANG_SLOT_NAME_RANGED);
        case EQUIPMENT_SLOT_TABARD: return  "Tabard";// session->GetTrinityString(LANG_SLOT_NAME_TABARD);
        default: return NULL;
    }
}

std::string Transmogrification::GetItemIcon(uint32 entry, uint32 width, uint32 height, int x, int y) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetItemIcon");

    std::ostringstream ss;
    ss << "|TInterface";
    const ItemTemplate* temp = sObjectMgr->GetItemTemplate(entry);
    const ItemDisplayInfoEntry* dispInfo = NULL;
    if (temp)
    {
        dispInfo = sItemDisplayInfoStore.LookupEntry(temp->DisplayInfoID);
        if (dispInfo)
            ss << "/ICONS/" << dispInfo->inventoryIcon[LOCALE_zhCN];
    }
    if (!dispInfo)
        ss << "/InventoryItems/WoWUnknownItem01";
    ss << ":" << width << ":" << height << ":" << x << ":" << y << "|t";
    return ss.str();
}

std::string Transmogrification::GetSlotIcon(uint8 slot, uint32 width, uint32 height, int x, int y) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetSlotIcon");

    std::ostringstream ss;
    ss << "|TInterface/PaperDoll/";
    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD: ss << "UI-PaperDoll-Slot-Head"; break;
        case EQUIPMENT_SLOT_SHOULDERS: ss << "UI-PaperDoll-Slot-Shoulder"; break;
        case EQUIPMENT_SLOT_BODY: ss << "UI-PaperDoll-Slot-Shirt"; break;
        case EQUIPMENT_SLOT_CHEST: ss << "UI-PaperDoll-Slot-Chest"; break;
        case EQUIPMENT_SLOT_WAIST: ss << "UI-PaperDoll-Slot-Waist"; break;
        case EQUIPMENT_SLOT_LEGS: ss << "UI-PaperDoll-Slot-Legs"; break;
        case EQUIPMENT_SLOT_FEET: ss << "UI-PaperDoll-Slot-Feet"; break;
        case EQUIPMENT_SLOT_WRISTS: ss << "UI-PaperDoll-Slot-Wrists"; break;
        case EQUIPMENT_SLOT_HANDS: ss << "UI-PaperDoll-Slot-Hands"; break;
        case EQUIPMENT_SLOT_BACK: ss << "UI-PaperDoll-Slot-Chest"; break;
        case EQUIPMENT_SLOT_MAINHAND: ss << "UI-PaperDoll-Slot-MainHand"; break;
        case EQUIPMENT_SLOT_OFFHAND: ss << "UI-PaperDoll-Slot-SecondaryHand"; break;
        case EQUIPMENT_SLOT_RANGED: ss << "UI-PaperDoll-Slot-Ranged"; break;
        case EQUIPMENT_SLOT_TABARD: ss << "UI-PaperDoll-Slot-Tabard"; break;
        default: ss << "UI-Backpack-EmptySlot";
    }
    ss << ":" << width << ":" << height << ":" << x << ":" << y << "|t";
    return ss.str();
}

std::string Transmogrification::GetItemLink(Item* item, WorldSession* session) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetItemLink");

    LocaleConstant localeConstant = session->GetSessionDbLocaleIndex();
    int loc_idx = session->GetSessionDbLocaleIndex(); // TODO
    const ItemTemplate* temp = item->GetTemplate();
    std::string name = temp->Name1;
    if (localeConstant != LOCALE_enUS)
        if (ItemLocale const* il = sObjectMgr->GetItemLocale(temp->ItemId))
            ObjectMgr::GetLocaleString(il->Name, localeConstant, name);

    if (int32 itemRandPropId = item->GetItemRandomPropertyId())
    {
        char const* suffix = NULL;
        if (itemRandPropId < 0)
        {
            const ItemRandomSuffixEntry* itemRandEntry = sItemRandomSuffixStore.LookupEntry(-item->GetItemRandomPropertyId());
            if (itemRandEntry)
                suffix = itemRandEntry->nameSuffix[loc_idx];
        }
        else
        {
            const ItemRandomPropertiesEntry* itemRandEntry = sItemRandomPropertiesStore.LookupEntry(item->GetItemRandomPropertyId());
            if (itemRandEntry)
                suffix = itemRandEntry->nameSuffix[loc_idx];
        }
        if (suffix)
        {
            std::string test(&suffix[(name != temp->Name1) ? loc_idx : DEFAULT_LOCALE]);
            if (!test.empty())
            {
                name += ' ';
                name += test;
            }
        }
    }

    std::ostringstream oss;
    oss << "|c" << std::hex << ItemQualityColors[temp->Quality] << std::dec <<
        "|Hitem:" << temp->ItemId << ":" <<
        item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT) << ":" <<
        item->GetEnchantmentId(SOCK_ENCHANTMENT_SLOT) << ":" <<
        item->GetEnchantmentId(SOCK_ENCHANTMENT_SLOT_2) << ":" <<
        item->GetEnchantmentId(SOCK_ENCHANTMENT_SLOT_3) << ":" <<
        item->GetEnchantmentId(BONUS_ENCHANTMENT_SLOT) << ":" <<
        item->GetItemRandomPropertyId() << ":" << item->GetItemSuffixFactor() << ":" <<
        (uint32)item->GetOwner()->GetLevel() << "|h[" << name << "]|h|r";

    return oss.str();
}

std::string Transmogrification::GetItemLink(uint32 entry, WorldSession* session) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetItemLink");

    const ItemTemplate* temp = sObjectMgr->GetItemTemplate(entry);
    LocaleConstant localeConstant = session->GetSessionDbLocaleIndex();
    std::string name = temp->Name1;
    if (localeConstant != LOCALE_enUS)
        if (ItemLocale const* il = sObjectMgr->GetItemLocale(entry))
            ObjectMgr::GetLocaleString(il->Name, localeConstant, name);

    std::ostringstream oss;
    oss << "|c" << std::hex << ItemQualityColors[temp->Quality] << std::dec <<
        "|Hitem:" << entry << ":0:0:0:0:0:0:0:0:0|h[" << name << "]|h|r";

    return oss.str();
}

uint32 Transmogrification::GetFakeEntry(ObjectGuid itemGUID) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::GetFakeEntry");

    transmogData::const_iterator itr = dataMap.find(itemGUID);
    if (itr == dataMap.end()) return 0;
    transmogMap::const_iterator itr2 = entryMap.find(itr->second);
    if (itr2 == entryMap.end()) return 0;
    transmogData::const_iterator itr3 = itr2->second.find(itemGUID);
    if (itr3 == itr2->second.end()) return 0;
    return itr3->second.GetCounter();
}

void Transmogrification::UpdateItem(Player* player, Item* item, uint32 /*newItemId*/) const
{
    TC_LOG_DEBUG("Transmogrification.log", "Transmogrification::UpdateItem");

    if (item->IsEquipped())
    {
        player->SetVisibleItemSlot(item->GetSlot(), item);
        if (player->IsInWorld())
            item->SendUpdateToPlayer(player);
    }
}

void Transmogrification::DeleteFakeEntry(Player* player, uint8 /*slot*/, Item* itemTransmogrified, CharacterDatabaseTransaction trans)
{
    //if (!GetFakeEntry(item))
    //    return false;
    DeleteFakeFromDB(itemTransmogrified->GetGUID(), trans);
    itemTransmogrified->RemoveDynamicModifier(ITEM_MODIFIER_INDEX_TRANSMOGRIFICATION, player);
    itemTransmogrified->SetState(ITEM_CHANGED, player);
    UpdateItem(player, itemTransmogrified, 0);
}

void Transmogrification::SetFakeEntry(Player* player, uint32 newEntry, uint8 /*slot*/, Item* itemTransmogrified)
{
    ObjectGuid itemGUID = itemTransmogrified->GetGUID();
    entryMap[player->GetGUID()][itemGUID] = ObjectGuid(uint64(newEntry));
    dataMap[itemGUID] = player->GetGUID();
    itemTransmogrified->SetDynamicModifier(ITEM_MODIFIER_INDEX_TRANSMOGRIFICATION, newEntry, player);
    itemTransmogrified->SetState(ITEM_CHANGED, player);
    CharacterDatabase.PExecute("REPLACE INTO custom_transmogrification (GUID, FakeEntry, Owner) VALUES (%u, %u, %u)", itemGUID.GetCounter(), newEntry, player->GetGUID().GetCounter());
    CharacterDatabase.PExecute("UPDATE item_instance SET transmogrifyId = %u WHERE guid = %u", newEntry, itemGUID.GetCounter());
    UpdateItem(player, itemTransmogrified, newEntry);
}

TransmogTrinityStrings Transmogrification::Transmogrify(Player* player, ObjectGuid itemGUID, uint8 slot, /*uint32 newEntry, */bool no_cost)
{
    int64 cost = 0;
    // slot of the transmogrified item
    if (slot >= EQUIPMENT_SLOT_END)
    {
        // TC_LOG_DEBUG(LOG_FILTER_NETWORKIO, "WORLD: HandleTransmogrifyItems - Player (GUID: %u, name: %s) tried to transmogrify an item (lowguid: %u) with a wrong slot (%u) when transmogrifying items.", player->GetGUIDLow(), player->GetName().c_str(), GUID_LOPART(itemGUID), slot);
        return LANG_ERR_TRANSMOG_INVALID_SLOT;
    }

    Item* itemTransmogrifier = NULL;
    // guid of the transmogrifier item, if it's not 0
    if (itemGUID)
    {
        itemTransmogrifier = player->GetItemByGuid(itemGUID);
        if (!itemTransmogrifier)
        {
            //TC_LOG_DEBUG(LOG_FILTER_NETWORKIO, "WORLD: HandleTransmogrifyItems - Player (GUID: %u, name: %s) tried to transmogrify with an invalid item (lowguid: %u).", player->GetGUIDLow(), player->GetName().c_str(), GUID_LOPART(itemGUID));
            return LANG_ERR_TRANSMOG_MISSING_SRC_ITEM;
        }
    }

    // transmogrified item
    Item* itemTransmogrified = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!itemTransmogrified)
    {
        //TC_LOG_DEBUG(LOG_FILTER_NETWORKIO, "WORLD: HandleTransmogrifyItems - Player (GUID: %u, name: %s) tried to transmogrify an invalid item in a valid slot (slot: %u).", player->GetGUIDLow(), player->GetName().c_str(), slot);
        return LANG_ERR_TRANSMOG_MISSING_DEST_ITEM;
    }

    if (!itemTransmogrifier) // reset look newEntry
    {
        // Custom
        DeleteFakeEntry(player, slot, itemTransmogrified);
    }
    else
    {
        if (!CanTransmogrifyItemWithItem(player, itemTransmogrified->GetTemplate(), itemTransmogrifier->GetTemplate()))
        {
            //TC_LOG_DEBUG(LOG_FILTER_NETWORKIO, "WORLD: HandleTransmogrifyItems - Player (GUID: %u, name: %s) failed CanTransmogrifyItemWithItem (%u with %u).", player->GetGUIDLow(), player->GetName().c_str(), itemTransmogrified->GetEntry(), itemTransmogrifier->GetEntry());
            return LANG_ERR_TRANSMOG_INVALID_ITEMS;
        }

        if (!no_cost)
        {
            if (RequireToken)
            {
                if (player->HasItemCount(TokenEntry, TokenAmount))
                    player->DestroyItemCount(TokenEntry, TokenAmount, true);
                else
                    return LANG_ERR_TRANSMOG_NOT_ENOUGH_TOKENS;
            }

            cost = GetSpecialPrice(itemTransmogrified->GetTemplate());
            cost *= ScaledCostModifier;
            cost += CopperCost;

            if (cost) // 0 cost if reverting look
            {
                if (cost < 0)
                    TC_LOG_DEBUG("Transmogrification.log",  "Transmogrification::Transmogrify - %s (%u) transmogrification invalid cost (non negative, amount %li). Transmogrified %u with %u", player->GetName().c_str(), player->GetGUID().GetCounter(), -cost, itemTransmogrified->GetEntry(), itemTransmogrifier->GetEntry());
                else
                {
                    if (!player->HasEnoughMoney(cost))
                        return LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY;
                    player->ModifyMoney(-cost, false);
                }
            }
        }

        // Custom
        SetFakeEntry(player, itemTransmogrifier->GetEntry(), slot, itemTransmogrified); // newEntry

        itemTransmogrified->UpdatePlayedTime(player);

        itemTransmogrified->SetOwnerGUID(player->GetGUID());
        itemTransmogrified->SetNotRefundable(player);
        itemTransmogrified->ClearSoulboundTradeable(player);

        if (itemTransmogrifier->GetTemplate()->Bonding == BIND_ON_ACQUIRE || itemTransmogrifier->GetTemplate()->Bonding == BIND_ON_USE)
            itemTransmogrifier->SetBinding(true);

        itemTransmogrifier->SetOwnerGUID(player->GetGUID());
        itemTransmogrifier->SetNotRefundable(player);
        itemTransmogrifier->ClearSoulboundTradeable(player);
    }

    return LANG_ERR_TRANSMOG_OK;
}

bool Transmogrification::CanTransmogrifyItemWithItem(Player* player, ItemTemplate const* target, ItemTemplate const* source, bool collected) const
{
    if (!target || !source)
        return false;

    if (source->ItemId == target->ItemId)
        return false;

    if (!SuitableForTransmogrification(player, target, collected) || !SuitableForTransmogrification(player, source, collected))
        return false;

    if (source->InventoryType == INVTYPE_BAG ||
        source->InventoryType == INVTYPE_RELIC ||
        // source->InventoryType == INVTYPE_BODY ||
        source->InventoryType == INVTYPE_FINGER ||
        source->InventoryType == INVTYPE_TRINKET ||
        source->InventoryType == INVTYPE_AMMO ||
        source->InventoryType == INVTYPE_QUIVER)
        return false;

    if (source->Class == ITEM_CLASS_WEAPON && target->InventoryType == INVTYPE_WEAPONOFFHAND)
        return true;

    if (source->Class == ITEM_CLASS_WEAPON && target->InventoryType == INVTYPE_HOLDABLE)
        return true;
    
    if (source->Class == ITEM_CLASS_WEAPON && target->InventoryType == INVTYPE_SHIELD)
        return true;

    // TC doesnt check this? Checked by Inventory type check.
    if (source->Class != target->Class)
        return false;

    if (source->SubClass != target->SubClass && !IsRangedWeapon(target->Class, target->SubClass))
    {
        if (source->Class == ITEM_CLASS_ARMOR && !AllowMixedArmorTypes)
            return false;
        if (source->Class == ITEM_CLASS_WEAPON && !AllowMixedWeaponTypes)
            return false;
    }

    if (source->InventoryType != target->InventoryType)
    {
        if (source->Class == ITEM_CLASS_WEAPON &&
           (IsRangedWeapon(target->Class, target->SubClass) != IsRangedWeapon(source->Class, source->SubClass)))/* ||
            source->InventoryType == INVTYPE_WEAPONMAINHAND ||
            source->InventoryType == INVTYPE_WEAPONOFFHAND))*/
            return false;
        if (source->Class == ITEM_CLASS_ARMOR &&
            !((source->InventoryType == INVTYPE_CHEST && target->InventoryType == INVTYPE_ROBE) ||
            (source->InventoryType == INVTYPE_ROBE && target->InventoryType == INVTYPE_CHEST)))
            return false;
    }

    return true;
}

bool hasTransmogStats(ItemTemplate const* proto)
{
    for (uint8 i = 0; i < MAX_ITEM_PROTO_STATS; ++i)
        if (proto->ItemStat[i].ItemStatValue != 0)
            return true;

    return false;
}

bool Transmogrification::SuitableForTransmogrification(Player* player, ItemTemplate const* proto, bool ignoreQuality) const
{
    // ItemTemplate const* proto = item->GetTemplate();
    if (!player || !proto)
        return false;

    if (proto->Class != ITEM_CLASS_ARMOR &&
        proto->Class != ITEM_CLASS_WEAPON)
        return false;

    // Skip all checks for allowed items
    if (IsAllowed(proto->ItemId))
        return true;

    if (IsNotAllowed(proto->ItemId))
        return false;

    if (!AllowFishingPoles && proto->Class == ITEM_CLASS_WEAPON && proto->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE)
        return false;

    if (!ignoreQuality && !IsAllowedQuality(proto->Quality))
        return false;

    if ((proto->Flags2 & ITEM_FLAGS_EXTRA_HORDE_ONLY) && player->GetTeamId() != TEAM_HORDE)
        return false;

    if ((proto->Flags2 & ITEM_FLAGS_EXTRA_ALLIANCE_ONLY) && player->GetTeamId() != TEAM_ALLIANCE)
        return false;

    if (!IgnoreReqClass && (proto->AllowableClass & player->GetClassMask()) == 0)
        return false;

    if (!IgnoreReqRace && (proto->AllowableRace & player->GetRaceMask()) == 0)
        return false;

    if (!IgnoreReqSkill && proto->RequiredSkill != 0)
    {
        if (player->GetSkillValue(proto->RequiredSkill) == 0)
            return false;
        else if (player->GetSkillValue(proto->RequiredSkill) < proto->RequiredSkillRank)
            return false;
    }

    if (!IgnoreReqSpell && proto->RequiredSpell != 0 && !player->HasSpell(proto->RequiredSpell))
        return false;

    if (!IgnoreReqLevel && player->GetLevel() < proto->RequiredLevel)
        return false;

    // If World Event is not active, prevent using event dependant items
    if (!IgnoreReqEvent && proto->HolidayId && !IsHolidayActive((HolidayIds)proto->HolidayId))
        return false;

    if (!IgnoreReqStats)
    {
        if (!proto->RandomProperty && !proto->RandomSuffix && hasTransmogStats(proto)
                /*[AZTH] Yehonal: we should transmorg also items without stats*/)
        {
            bool found = false;
            for (uint8 i = 0; i < MAX_ITEM_PROTO_STATS; ++i)
            {
                if (proto->ItemStat[i].ItemStatValue != 0)
                {
                    found = true;
                    break;
                }
            }
            if (!found)
                return false;
        }
    }

    return true;
}

uint32 Transmogrification::GetSpecialPrice(ItemTemplate const* proto) const
{
    uint32 cost = proto->SellPrice < 10000 ? 10000 : proto->SellPrice;
    return cost;
}
bool Transmogrification::IsRangedWeapon(uint32 Class, uint32 SubClass) const
{
    return Class == ITEM_CLASS_WEAPON && (
        SubClass == ITEM_SUBCLASS_WEAPON_BOW ||
        SubClass == ITEM_SUBCLASS_WEAPON_GUN ||
        SubClass == ITEM_SUBCLASS_WEAPON_CROSSBOW);
}

bool Transmogrification::IsAllowed(uint32 entry) const
{
    return Allowed.find(entry) != Allowed.end();
}

bool Transmogrification::IsNotAllowed(uint32 entry) const
{
    return NotAllowed.find(entry) != NotAllowed.end();
}

bool Transmogrification::IsAllowedQuality(uint32 quality) const
{
    switch (quality)
    {
        case ITEM_QUALITY_POOR: return AllowPoor;
        case ITEM_QUALITY_NORMAL: return AllowCommon;
        case ITEM_QUALITY_UNCOMMON: return AllowUncommon;
        case ITEM_QUALITY_RARE: return AllowRare;
        case ITEM_QUALITY_EPIC: return AllowEpic;
        case ITEM_QUALITY_LEGENDARY: return AllowLegendary;
        case ITEM_QUALITY_ARTIFACT: return AllowArtifact;
        case ITEM_QUALITY_HEIRLOOM: return AllowHeirloom;
        default: return false;
    }
}

void Transmogrification::LoadConfig(bool reload)
{
#ifdef PRESETS
    EnableSetInfo = sConfigMgr->GetBoolDefault("Transmogrification.EnableSetInfo", true);
    SetNpcText = uint32(sConfigMgr->GetIntDefault("Transmogrification.SetNpcText", 601084));

    EnableSets = sConfigMgr->GetBoolDefault("Transmogrification.EnableSets", true);
    MaxSets = (uint8)sConfigMgr->GetIntDefault("Transmogrification.MaxSets", 10);
    SetCostModifier = sConfigMgr->GetFloatDefault("Transmogrification.SetCostModifier", 3.0f);
    SetCopperCost = sConfigMgr->GetIntDefault("Transmogrification.SetCopperCost", 0);

    if (MaxSets > MAX_OPTIONS)
        MaxSets = MAX_OPTIONS;

    if (reload) // dont store presets for nothing
    {
        SessionMap const& sessions = sWorld->GetAllSessions();
        for (SessionMap::const_iterator it = sessions.begin(); it != sessions.end(); ++it)
        {
            if (Player* player = it->second->GetPlayer())
            {
                // skipping session check
                UnloadPlayerSets(player->GetGUID());
                if (GetEnableSets())
                    LoadPlayerSets(player->GetGUID());
            }
        }
    }
#endif

    EnableTransmogInfo = sConfigMgr->GetBoolDefault("Transmogrification.EnableTransmogInfo", true);
    TransmogNpcText = uint32(sConfigMgr->GetIntDefault("Transmogrification.TransmogNpcText", 601083));

    std::istringstream issAllowed(sConfigMgr->GetStringDefault("Transmogrification.Allowed", ""));
    std::istringstream issNotAllowed(sConfigMgr->GetStringDefault("Transmogrification.NotAllowed", ""));
    while (issAllowed.good())
    {
        uint32 entry;
        issAllowed >> entry;
        if (issAllowed.fail())
            break;
        Allowed.insert(entry);
    }
    while (issNotAllowed.good())
    {
        uint32 entry;
        issNotAllowed >> entry;
        if (issNotAllowed.fail())
            break;
        NotAllowed.insert(entry);
    }

    ScaledCostModifier = sConfigMgr->GetFloatDefault("Transmogrification.ScaledCostModifier", 1.0f);
    CopperCost = sConfigMgr->GetIntDefault("Transmogrification.CopperCost", 0);

    RequireToken = sConfigMgr->GetBoolDefault("Transmogrification.RequireToken", false);
    TokenEntry = uint32(sConfigMgr->GetIntDefault("Transmogrification.TokenEntry", 49426));
    TokenAmount = uint32(sConfigMgr->GetIntDefault("Transmogrification.TokenAmount", 1));

    AllowPoor = sConfigMgr->GetBoolDefault("Transmogrification.AllowPoor", false);
    AllowCommon = sConfigMgr->GetBoolDefault("Transmogrification.AllowCommon", false);
    AllowUncommon = sConfigMgr->GetBoolDefault("Transmogrification.AllowUncommon", true);
    AllowRare = sConfigMgr->GetBoolDefault("Transmogrification.AllowRare", true);
    AllowEpic = sConfigMgr->GetBoolDefault("Transmogrification.AllowEpic", true);
    AllowLegendary = sConfigMgr->GetBoolDefault("Transmogrification.AllowLegendary", false);
    AllowArtifact = sConfigMgr->GetBoolDefault("Transmogrification.AllowArtifact", false);
    AllowHeirloom = sConfigMgr->GetBoolDefault("Transmogrification.AllowHeirloom", true);

    AllowMixedArmorTypes = sConfigMgr->GetBoolDefault("Transmogrification.AllowMixedArmorTypes", false);
    AllowMixedWeaponTypes = sConfigMgr->GetBoolDefault("Transmogrification.AllowMixedWeaponTypes", false);
    AllowFishingPoles = sConfigMgr->GetBoolDefault("Transmogrification.AllowFishingPoles", false);

    IgnoreReqRace = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqRace", false);
    IgnoreReqClass = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqClass", false);
    IgnoreReqSkill = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqSkill", false);
    IgnoreReqSpell = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqSpell", false);
    IgnoreReqLevel = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqLevel", false);
    IgnoreReqEvent = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqEvent", false);
    IgnoreReqStats = sConfigMgr->GetBoolDefault("Transmogrification.IgnoreReqStats", false);

    if (!sObjectMgr->GetItemTemplate(TokenEntry))
    {
        //TC_LOG_DEBUG(LOG_FILTER_SERVER_LOADING, "Transmogrification.TokenEntry (%u) does not exist. Using default.", TokenEntry);
        TokenEntry = 49426;
    }
}

void Transmogrification::DeleteFakeFromDB(ObjectGuid itemGUID, CharacterDatabaseTransaction trans)
{
    if (dataMap.find(itemGUID) != dataMap.end())
    {
        if (entryMap.find(dataMap[itemGUID]) != entryMap.end())
            entryMap[dataMap[itemGUID]].erase(itemGUID);
        dataMap.erase(itemGUID);
    }
    if (trans)
        trans->PAppend("DELETE FROM custom_transmogrification WHERE GUID = %u", itemGUID.GetCounter());
    else
        CharacterDatabase.PExecute("DELETE FROM custom_transmogrification WHERE GUID = %u", itemGUID.GetCounter());
}

bool Transmogrification::GetEnableTransmogInfo() const
{
    return EnableTransmogInfo;
}
uint32 Transmogrification::GetTransmogNpcText() const
{
    return TransmogNpcText;
}
bool Transmogrification::GetEnableSetInfo() const
{
    return EnableSetInfo;
}
uint32 Transmogrification::GetSetNpcText() const
{
    return SetNpcText;
}
float Transmogrification::GetScaledCostModifier() const
{
    return ScaledCostModifier;
}
int32 Transmogrification::GetCopperCost() const
{
    return CopperCost;
}
bool Transmogrification::GetRequireToken() const
{
    return RequireToken;
}
uint32 Transmogrification::GetTokenEntry() const
{
    return TokenEntry;
}
uint32 Transmogrification::GetTokenAmount() const
{
    return TokenAmount;
}
bool Transmogrification::GetAllowMixedArmorTypes() const
{
    return AllowMixedArmorTypes;
};
bool Transmogrification::GetAllowMixedWeaponTypes() const
{
    return AllowMixedWeaponTypes;
};
