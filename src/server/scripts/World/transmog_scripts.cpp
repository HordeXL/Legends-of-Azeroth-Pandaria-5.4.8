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

/*
5.0
Transmogrification 3.3.5a - Gossip menu
By Rochet2
ScriptName for NPC:
Creature_Transmogrify
TODO:
Make DB saving even better (Deleting)? What about coding?
Fix the cost formula
-- Too much data handling, use default costs
Are the qualities right?
Blizzard might have changed the quality requirements.
(TC handles it with stat checks)
Cant transmogrify rediculus items // Foereaper: would be fun to stab people with a fish
-- Cant think of any good way to handle this easily, could rip flagged items from cata DB
*/

#pragma execution_character_set("UTF-8")
#include "CustomTransmogrification.h"

#define sT  sTransmogrification
#define GTS session->GetTrinityString // dropped translation support, no one using?

class npc_transmogrifier : public CreatureScript
{
public:
    npc_transmogrifier() : CreatureScript("npc_transmogrifier") { }

    bool OnGossipHello(Player* player, Creature* creature)
    {
        sT->UpdatePreview(player, 0);
        sT->CollectInventory(player);
        WorldSession* session = player->GetSession();
        //if (player->GetQuestStatus(40328) == QUEST_STATUS_REWARDED || player->GetQuestStatus(40329) == QUEST_STATUS_REWARDED)
        {
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe6\x8c\x89\x20\x43\x20\xe9\x94\xae\xe9\xa2\x84\xe8\xa7\x88\xe3\x80\x82\xe7\x82\xb9\xe5\x87\xbb\xe2\x80\x9c\xe6\x8e\xa5\xe5\x8f\x97\xe2\x80\x9d\xe4\xbf\x9d\xe5\xad\x98\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9\xe3\x80\x82", EQUIPMENT_SLOT_END + 1, 0);
            if (sT->GetEnableTransmogInfo())
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\xb9\xbb\xe5\x8c\x96\xe6\x98\xaf\xe6\x80\x8e\xe4\xb9\x88\xe7\x8e\xa9\xe7\x9a\x84\xef\xbc\x9f", EQUIPMENT_SLOT_END + 9, 0);

            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            {
                if (const char* slotName = sT->GetSlotName(slot, session))
                {
                    Item* newItem = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
                    uint32 entry = newItem ? sT->GetFakeEntry(newItem->GetGUID()) : 0;
                    std::string label = slotName;
                    if (!newItem)
                        label += "\xef\xbc\x88\xe7\xa9\xba\xef\xbc\x89";
                    else if (sT->GetPreviewEntry(player, slot))
                        label += "\xef\xbc\x88\xe9\xa2\x84\xe8\xa7\x88\xe4\xb8\xad\xef\xbc\x89";
                    else if (entry)
                        label += "\xef\xbc\x88\xe5\xb7\xb2\xe5\xb9\xbb\xe5\x8c\x96\xef\xbc\x89";
                    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, label, EQUIPMENT_SLOT_END, slot);
                }
            }

        #ifdef PRESETS
            if (sT->GetEnableSets())
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\xb7\xb2\xe4\xbf\x9d\xe5\xad\x98\xe7\x9a\x84\xe5\xa5\x97\xe8\xa3\x85", EQUIPMENT_SLOT_END + 4, 0);
        #endif
            if (sT->HasPreview(player))
            {
                player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe6\x8e\xa5\xe5\x8f\x97\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9", EQUIPMENT_SLOT_END + 11, 0,
                    "\xe5\x85\x8d\xe8\xb4\xb9\xe5\xba\x94\xe7\x94\xa8\xe5\x85\xa8\xe9\x83\xa8\xe9\xa2\x84\xe8\xa7\x88\xe5\xa4\x96\xe8\xa7\x82\xef\xbc\x9f\xe6\x9b\xb4\xe6\x94\xb9\xe5\x90\x8e\xe7\x9a\x84\xe7\x89\xa9\xe5\x93\x81\xe5\xb0\x86\xe5\x8f\x98\xe4\xb8\xba\xe6\x8b\xbe\xe5\x8f\x96\xe7\xbb\x91\xe5\xae\x9a\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe9\x80\x80\xe6\x8d\xa2\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe4\xba\xa4\xe6\x98\x93\xe3\x80\x82", 0, false);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\x8f\x96\xe6\xb6\x88\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9", EQUIPMENT_SLOT_END + 12, 0);
            }
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\x88\xb7\xe6\x96\xb0", EQUIPMENT_SLOT_END + 1, 0);
            player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe6\x81\xa2\xe5\xa4\x8d\xe5\x85\xa8\xe9\x83\xa8\xe5\x8e\x9f\xe5\xa7\x8b\xe5\xa4\x96\xe8\xa7\x82", EQUIPMENT_SLOT_END + 2, 0,
                "\xe9\xa2\x84\xe8\xa7\x88\xe5\x85\xa8\xe9\x83\xa8\xe5\xb7\xb2\xe8\xa3\x85\xe5\xa4\x87\xe7\x89\xa9\xe5\x93\x81\xe7\x9a\x84\xe5\x8e\x9f\xe5\xa7\x8b\xe5\xa4\x96\xe8\xa7\x82\xef\xbc\x9f\xe9\x80\x89\xe6\x8b\xa9\xe2\x80\x9c\xe6\x8e\xa5\xe5\x8f\x97\xe2\x80\x9d\xe4\xbf\x9d\xe5\xad\x98\xe3\x80\x82", 0, false);
        }
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action)
    {
        player->PlayerTalkClass->ClearMenus();
        WorldSession* session = player->GetSession();
        if (sender >= 100 && sender < 100 + EQUIPMENT_SLOT_END)
        {
            ShowTransmogItems(player, creature, sender - 100, action);
            return true;
        }
        switch (sender)
        {
            case EQUIPMENT_SLOT_END + 11:
            {
                TransmogTrinityStrings result = sT->AcceptPreview(player, creature);
                if (result != LANG_ERR_TRANSMOG_OK)
                    session->SendNotification("\xe9\xa2\x84\xe8\xa7\x88\xe6\x97\xa0\xe6\xb3\x95\xe5\xba\x94\xe7\x94\xa8\xef\xbc\x8c\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\xe8\xa3\x85\xe5\xa4\x87\xe5\x90\x8e\xe9\x87\x8d\xe8\xaf\x95\xe3\x80\x82");
                OnGossipHello(player, creature);
                break;
            }
            case EQUIPMENT_SLOT_END + 12:
                sT->CancelPreview(player);
                OnGossipHello(player, creature);
                break;
            case EQUIPMENT_SLOT_END: // Show items you can use
                ShowTransmogItems(player, creature, action);
                break;
            case EQUIPMENT_SLOT_END + 1: // Main menu
                OnGossipHello(player, creature);
                break;
            case EQUIPMENT_SLOT_END + 2: // Preview restoring all slots
            {
                for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
                    if (sT->GetSlotName(slot, session))
                        if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                            sT->PreviewAppearance(player, creature, item->GetEntry(), slot);
                OnGossipHello(player, creature);
                break;
            }
            case EQUIPMENT_SLOT_END + 3: // Preview restoring one slot
            {
                if (action < EQUIPMENT_SLOT_END)
                    if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, action))
                        sT->PreviewAppearance(player, creature, item->GetEntry(), action);
                ShowTransmogItems(player, creature, action);
                break;
            }
    #ifdef PRESETS
            case EQUIPMENT_SLOT_END + 4: // Presets menu
            {
                if (!sT->GetEnableSets())
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                if (sT->GetEnableSetInfo())
                    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\xa5\x97\xe8\xa3\x85\xe6\x98\xaf\xe6\x80\x8e\xe4\xb9\x88\xe7\x8e\xa9\xe7\x9a\x84\xef\xbc\x9f", EQUIPMENT_SLOT_END + 10, 0);
                for (Transmogrification::presetIdMap::const_iterator it = sT->presetByName[player->GetGUID()].begin(); it != sT->presetByName[player->GetGUID()].end(); ++it)
                    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "" + it->second, EQUIPMENT_SLOT_END + 6, it->first);

                if (sT->presetByName[player->GetGUID()].size() < sT->GetMaxSets())
                    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe4\xbf\x9d\xe5\xad\x98\xe5\xa5\x97\xe8\xa3\x85", EQUIPMENT_SLOT_END + 8, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 1, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            } break;
            case EQUIPMENT_SLOT_END + 5: // Use preset
            {
                sT->CancelPreview(player);
                if (!sT->GetEnableSets())
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                // action = presetID
                for (Transmogrification::slotMap::const_iterator it = sT->presetById[player->GetGUID()][action].begin(); it != sT->presetById[player->GetGUID()][action].end(); ++it)
                {
                    if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, it->first))
                        sT->PresetTransmog(player, item, it->second, it->first);
                }
                OnGossipSelect(player, creature, EQUIPMENT_SLOT_END + 6, action);
            } break;
            case EQUIPMENT_SLOT_END + 6: // view preset
            {
                if (!sT->GetEnableSets())
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                // action = presetID
                for (Transmogrification::slotMap::const_iterator it = sT->presetById[player->GetGUID()][action].begin(); it != sT->presetById[player->GetGUID()][action].end(); ++it)
                    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, sT->GetItemLink(it->second, session), sender, action);

                player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe5\xba\x94\xe7\x94\xa8\xe5\xa5\x97\xe8\xa3\x85", EQUIPMENT_SLOT_END + 5, action, "\xe5\x85\x8d\xe8\xb4\xb9\xe5\xba\x94\xe7\x94\xa8\xe8\xaf\xa5\xe5\xa5\x97\xe8\xa3\x85\xef\xbc\x9f\xe6\x9b\xb4\xe6\x94\xb9\xe5\x90\x8e\xe7\x9a\x84\xe7\x89\xa9\xe5\x93\x81\xe5\xb0\x86\xe5\x8f\x98\xe4\xb8\xba\xe6\x8b\xbe\xe5\x8f\x96\xe7\xbb\x91\xe5\xae\x9a\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe9\x80\x80\xe6\x8d\xa2\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe4\xba\xa4\xe6\x98\x93\xe3\x80\x82\x5c\x6e\x5c\x6e" + sT->presetByName[player->GetGUID()][action], 0, false);
                player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe5\x88\xa0\xe9\x99\xa4\xe5\xa5\x97\xe8\xa3\x85", EQUIPMENT_SLOT_END + 7, action, "\xe5\x88\xa0\xe9\x99\xa4\xe5\xb7\xb2\xe4\xbf\x9d\xe5\xad\x98\xe7\x9a\x84\xe5\xa5\x97\xe8\xa3\x85\xef\xbc\x9a" + sT->presetByName[player->GetGUID()][action] + "?", 0, false);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 4, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            } break;
            case EQUIPMENT_SLOT_END + 7: // Delete preset
            {
                if (!sT->GetEnableSets())
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                // action = presetID
                CharacterDatabase.PExecute("DELETE FROM `custom_transmogrification_sets` WHERE Owner = %u AND PresetID = %u", player->GetGUID().GetCounter(), action);
                sT->presetById[player->GetGUID()][action].clear();
                sT->presetById[player->GetGUID()].erase(action);
                sT->presetByName[player->GetGUID()].erase(action);

                OnGossipSelect(player, creature, EQUIPMENT_SLOT_END + 4, 0);
            } break;
            case EQUIPMENT_SLOT_END + 8: // Save preset
            {
                if (sT->HasPreview(player))
                {
                    session->SendNotification("\xe4\xbf\x9d\xe5\xad\x98\xe5\xa5\x97\xe8\xa3\x85\xe5\x89\x8d\xe8\xaf\xb7\xe5\x85\x88\xe6\x8e\xa5\xe5\x8f\x97\xe9\xa2\x84\xe8\xa7\x88\xe3\x80\x82");
                    OnGossipHello(player, creature);
                    return true;
                }
                if (!sT->GetEnableSets() || sT->presetByName[player->GetGUID()].size() >= sT->GetMaxSets())
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                uint32 cost = 0;
                bool canSave = false;
                for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
                {
                    if (!sT->GetSlotName(slot, session))
                        continue;
                    if (Item* newItem = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    {
                        uint32 entry = sT->GetFakeEntry(newItem->GetGUID());
                        if (!entry)
                            continue;
                        const ItemTemplate* temp = sObjectMgr->GetItemTemplate(entry);
                        if (!temp)
                            continue;
                        if (!sT->SuitableForTransmogrification(player, temp, true))
                            continue;
                        cost += sT->GetSpecialPrice(temp);
                        canSave = true;
                        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, sT->GetItemLink(entry, session), EQUIPMENT_SLOT_END + 8, 0);
                    }
                }
                if (canSave)
                    player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe4\xbf\x9d\xe5\xad\x98\xe5\xa5\x97\xe8\xa3\x85", 0, 0, "\xe8\xbe\x93\xe5\x85\xa5\xe5\xa5\x97\xe8\xa3\x85\xe5\x90\x8d\xe7\xa7\xb0", cost*sT->GetSetCostModifier() + sT->GetSetCopperCost(), true);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\x88\xb7\xe6\x96\xb0", sender, action);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 4, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            } break;
            case EQUIPMENT_SLOT_END + 10: // Set info
            {
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\xb0\x86\xe5\xbd\x93\xe5\x89\x8d\xe5\xb7\xb2\xe5\xb9\xbb\xe5\x8c\x96\xe7\x9a\x84\xe5\xa4\x96\xe8\xa7\x82\xe4\xbf\x9d\xe5\xad\x98\xe4\xb8\xba\xe4\xb8\x80\xe4\xb8\xaa\xe5\x91\xbd\xe5\x90\x8d\xe5\xa5\x97\xe8\xa3\x85\xe3\x80\x82", EQUIPMENT_SLOT_END + 10, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe9\x80\x89\xe6\x8b\xa9\xe4\xb8\x80\xe4\xb8\xaa\xe5\xb7\xb2\xe4\xbf\x9d\xe5\xad\x98\xe7\x9a\x84\xe5\xa5\x97\xe8\xa3\x85\xef\xbc\x8c\xe5\x85\x8d\xe8\xb4\xb9\xe5\xba\x94\xe7\x94\xa8\xe5\x85\xb6\xe4\xb8\xad\xe5\x85\xbc\xe5\xae\xb9\xe7\x9a\x84\xe5\xa4\x96\xe8\xa7\x82\xe3\x80\x82", EQUIPMENT_SLOT_END + 10, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 4, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            } break;
    #endif
            case EQUIPMENT_SLOT_END + 9: // Transmog info
            {
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\xb7\xb2\xe6\x94\xb6\xe8\x97\x8f\xe7\x9a\x84\xe5\xa4\x96\xe8\xa7\x82\xe6\xb0\xb8\xe4\xb9\x85\xe6\x9c\x89\xe6\x95\x88\xef\xbc\x8c\xe4\xb8\x94\xe5\x90\x8c\xe8\xb4\xa6\xe5\x8f\xb7\xe4\xb8\x8b\xe6\x89\x80\xe6\x9c\x89\xe8\xa7\x92\xe8\x89\xb2\xe5\x85\xb1\xe4\xba\xab\xe3\x80\x82", EQUIPMENT_SLOT_END + 9, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe4\xbd\xa0\xe5\x8f\xaf\xe4\xbb\xa5\xe5\x8d\x96\xe6\x8e\x89\xe5\xa4\x96\xe8\xa7\x82\xe6\x9d\xa5\xe6\xba\x90\xe7\x89\xa9\xe5\x93\x81\xef\xbc\x8c\xe5\xa4\x96\xe8\xa7\x82\xe4\xbb\x8d\xe4\xbc\x9a\xe4\xbf\x9d\xe7\x95\x99\xe3\x80\x82\xe5\xb9\xbb\xe5\x8c\x96\xe5\xae\x8c\xe5\x85\xa8\xe5\x85\x8d\xe8\xb4\xb9\xe3\x80\x82", EQUIPMENT_SLOT_END + 9, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe6\x8c\x89\x20\x43\x20\xe9\x94\xae\xef\xbc\x8c\xe7\x84\xb6\xe5\x90\x8e\xe4\xb8\xba\xe4\xbb\xbb\xe6\x84\x8f\xe9\x83\xa8\xe4\xbd\x8d\xe9\x80\x89\xe6\x8b\xa9\xe5\xa4\x96\xe8\xa7\x82\xe3\x80\x82\xe2\x80\x9c\xe6\x8e\xa5\xe5\x8f\x97\xe2\x80\x9d\xe4\xbf\x9d\xe5\xad\x98\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9\xef\xbc\x9b\xe2\x80\x9c\xe5\x8f\x96\xe6\xb6\x88\xe2\x80\x9d\xe6\x81\xa2\xe5\xa4\x8d\xe4\xb9\x8b\xe5\x89\x8d\xe7\x9a\x84\xe6\xa0\xb7\xe5\xad\x90\xe3\x80\x82", EQUIPMENT_SLOT_END + 9, 0);
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 1, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            } break;
            default: // Transmogrify
            {
                if (sender >= EQUIPMENT_SLOT_END)
                    return true;
                if (!sender && !action)
                {
                    OnGossipHello(player, creature);
                    return true;
                }
                // sender = slot, action = display
                TransmogTrinityStrings res = sT->PreviewAppearance(player, creature, action, sender);
                if (res != LANG_ERR_TRANSMOG_OK)
                    /*session->SendAreaTriggerMessage("%s",GTS(LANG_ERR_TRANSMOG_OK));
                else*/
                    session->SendNotification(res);
                // Keep all slot previews while browsing other appearances.
                ShowTransmogItems(player, creature, sender, 0, action);
            } break;
        }
        return true;
    }

#ifdef PRESETS
    bool OnGossipSelectCode(Player* player, Creature* creature, uint32 sender, uint32 action, const char* code)
    {
        player->PlayerTalkClass->ClearMenus();
        if (sender || action)
            return true; // should never happen
        if (sT->HasPreview(player) || !sT->GetEnableSets())
        {
            OnGossipHello(player, creature);
            return true;
        }
        std::string name(code);
        if (name.find('"') != std::string::npos || name.find('\\') != std::string::npos)
            player->GetSession()->SendNotification(LANG_PRESET_ERR_INVALID_NAME);
        else
        {
            for (uint8 presetID = 0; presetID < sT->GetMaxSets(); ++presetID) // should never reach over max
            {
                if (sT->presetByName[player->GetGUID()].find(presetID) != sT->presetByName[player->GetGUID()].end())
                    continue; // Just remember never to use presetByName[pGUID][presetID] when finding etc!

                int64 cost = 0;
                std::map<uint8, uint32> items;
                for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
                {
                    if (!sT->GetSlotName(slot, player->GetSession()))
                        continue;
                    if (Item* newItem = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    {
                        uint32 entry = sT->GetFakeEntry(newItem->GetGUID());
                        if (!entry)
                            continue;
                        const ItemTemplate* temp = sObjectMgr->GetItemTemplate(entry);
                        if (!temp)
                            continue;
                        if (!sT->SuitableForTransmogrification(player, temp))
                            continue;
                        cost += sT->GetSpecialPrice(temp);
                        items[slot] = entry;
                    }
                }
                if (items.empty())
                    break; // no transmogrified items were found to be saved
                cost *= sT->GetSetCostModifier();
                cost += sT->GetSetCopperCost();
                if (!player->HasEnoughMoney(cost))
                {
                    player->GetSession()->SendNotification(LANG_ERR_TRANSMOG_NOT_ENOUGH_MONEY);
                    break;
                }

                std::ostringstream ss;
                for (std::map<uint8, uint32>::iterator it = items.begin(); it != items.end(); ++it)
                {
                    ss << uint32(it->first) << ' ' << it->second << ' ';
                    sT->presetById[player->GetGUID()][presetID][it->first] = it->second;
                }
                sT->presetByName[player->GetGUID()][presetID] = name; // Make sure code doesnt mess up SQL!
                CharacterDatabase.PExecute("REPLACE INTO `custom_transmogrification_sets` (`Owner`, `PresetID`, `SetName`, `SetData`) VALUES (%u, %u, \"%s\", \"%s\")", player->GetGUID().GetCounter(), uint32(presetID), name.c_str(), ss.str().c_str());
                if (cost)
                    player->ModifyMoney(-cost);
                break;
            }
        }
        OnGossipSelect(player, creature, EQUIPMENT_SLOT_END + 4, 0);
        return true;
    }
#endif

    void ShowTransmogItems(Player* player, Creature* creature, uint8 slot, uint32 page = 0, uint32 selectedEntry = 0)
    {
        if (slot >= EQUIPMENT_SLOT_END) return;
        WorldSession* session = player->GetSession();
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        std::vector<uint32> appearances;
        std::set<uint32> displays;
        if (item)
            for (uint32 entry : sT->GetCollection(player))
            {
                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
                if (sT->CanTransmogrifyItemWithItem(player, item->GetTemplate(), proto, true) &&
                    displays.insert(proto->DisplayInfoID).second)
                    appearances.push_back(entry);
            }
        // Leave room for navigation, restore, Accept and Cancel.
        constexpr uint32 pageSize = 18;
        uint32 lastPage = appearances.empty() ? 0 : (appearances.size() - 1) / pageSize;
        if (selectedEntry)
        {
            auto selected = std::find(appearances.begin(), appearances.end(), selectedEntry);
            if (selected != appearances.end())
            {
                page = uint32(selected - appearances.begin()) / pageSize;
            }
        }
        page = std::min(page, lastPage);
        const char* slotName = sT->GetSlotName(slot, session);
        std::string heading = std::string(slotName ? slotName : "\xe5\xa4\x96\xe8\xa7\x82") +
            "\x20\x2d\x20\xe7\xac\xac\x20" + std::to_string(page + 1) + "/" + std::to_string(lastPage + 1) + "\x20\xe9\xa1\xb5";
        uint32 const pageSender = 100 + slot;
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, heading, pageSender, page);
        uint32 previewEntry = sT->GetPreviewEntry(player, slot);
        uint32 activeEntry = item ? sT->GetFakeEntry(item->GetGUID()) : 0;
        ItemTemplate const* activeAppearance = activeEntry ? sObjectMgr->GetItemTemplate(activeEntry) : item ? item->GetTemplate() : nullptr;
        for (uint32 i = page * pageSize; i < appearances.size() && i < (page + 1) * pageSize; ++i)
        {
            uint32 entry = appearances[i];
            std::string label = sT->GetItemLink(entry, session);
            ItemTemplate const* appearance = sObjectMgr->GetItemTemplate(entry);
            bool active = activeAppearance && appearance && activeAppearance->DisplayInfoID == appearance->DisplayInfoID;
            if (entry == previewEntry)
                label += "\x20\x20\x5b\xe9\xa2\x84\xe8\xa7\x88\x5d";
            else if (active)
                label += "\x20\x20\x5b\xe5\xbd\x93\xe5\x89\x8d\x5d";
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, label, slot, entry);
        }
        if (appearances.empty())
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, item ? "\xe8\xaf\xa5\xe9\x83\xa8\xe4\xbd\x8d\xe5\xb0\x9a\xe6\x9c\xaa\xe6\x94\xb6\xe8\x97\x8f\xe5\x85\xbc\xe5\xae\xb9\xe7\x9a\x84\xe5\xa4\x96\xe8\xa7\x82\xe3\x80\x82"
                : "\xe5\x9c\xa8\xe8\xaf\xa5\xe9\x83\xa8\xe4\xbd\x8d\xe7\xa9\xbf\xe4\xb8\x8a\xe7\x89\xa9\xe5\x93\x81\xe6\x89\x8d\xe8\x83\xbd\xe9\x80\x89\xe6\x8b\xa9\xe5\xa4\x96\xe8\xa7\x82\xe3\x80\x82", EQUIPMENT_SLOT_END, slot);
        if (page > 0)
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe4\xb8\x8a\xe4\xb8\x80\xe9\xa1\xb5", pageSender, page - 1);
        if (page < lastPage)
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe4\xb8\x8b\xe4\xb8\x80\xe9\xa1\xb5", pageSender, page + 1);
        if (sT->HasPreview(player))
        {
            player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe6\x8e\xa5\xe5\x8f\x97\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9", EQUIPMENT_SLOT_END + 11, 0,
                "\xe5\x85\x8d\xe8\xb4\xb9\xe5\xba\x94\xe7\x94\xa8\xe5\x85\xa8\xe9\x83\xa8\xe9\xa2\x84\xe8\xa7\x88\xe5\xa4\x96\xe8\xa7\x82\xef\xbc\x9f\xe6\x9b\xb4\xe6\x94\xb9\xe5\x90\x8e\xe7\x9a\x84\xe7\x89\xa9\xe5\x93\x81\xe5\xb0\x86\xe5\x8f\x98\xe4\xb8\xba\xe6\x8b\xbe\xe5\x8f\x96\xe7\xbb\x91\xe5\xae\x9a\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe9\x80\x80\xe6\x8d\xa2\xe3\x80\x81\xe4\xb8\x8d\xe5\x8f\xaf\xe4\xba\xa4\xe6\x98\x93\xe3\x80\x82", 0, false);
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe5\x8f\x96\xe6\xb6\x88\xe5\x85\xa8\xe9\x83\xa8\xe6\x9b\xb4\xe6\x94\xb9", EQUIPMENT_SLOT_END + 12, 0);
        }
        if (activeEntry || previewEntry)
            player->ADD_GOSSIP_ITEM_EXTENDED(GOSSIP_ICON_CHAT, "\xe6\x81\xa2\xe5\xa4\x8d\xe5\x8e\x9f\xe5\xa7\x8b\xe5\xa4\x96\xe8\xa7\x82", EQUIPMENT_SLOT_END + 3, slot,
                "\xe9\xa2\x84\xe8\xa7\x88\xe8\xaf\xa5\xe7\x89\xa9\xe5\x93\x81\xe7\x9a\x84\xe5\x8e\x9f\xe5\xa7\x8b\xe5\xa4\x96\xe8\xa7\x82\xef\xbc\x9f\xe9\x80\x89\xe6\x8b\xa9\xe2\x80\x9c\xe6\x8e\xa5\xe5\x8f\x97\xe2\x80\x9d\xe4\xbf\x9d\xe5\xad\x98\xe3\x80\x82", 0, false);
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "\xe8\xbf\x94\xe5\x9b\x9e", EQUIPMENT_SLOT_END + 1, 0);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
    }

};

class PS_Transmogrification : public PlayerScript
{
public:
    PS_Transmogrification() : PlayerScript("Player_Transmogrify") { }

    void OnAfterSetVisibleItemSlot(Player* player, uint8 slot, Item *item) {
        if (!item)
            return;

        if (uint32 entry = sT->GetFakeEntry(item->GetGUID()))
            player->SetUInt32Value(PLAYER_FIELD_VISIBLE_ITEMS + (slot * 2), entry);
    }

    void OnAfterMoveItemFromInventory(Player* /*player*/, Item* it, uint8 /*bag*/, uint8 /*slot*/, bool /*update*/) {
        sT->DeleteFakeFromDB(it->GetGUID());
    }
    
    void OnLogin(Player* player)
    {
        sT->CollectInventory(player);
        ObjectGuid playerGUID = player->GetGUID();
        sT->entryMap.erase(playerGUID);
        QueryResult result = CharacterDatabase.PQuery("SELECT GUID, FakeEntry FROM custom_transmogrification WHERE Owner = %u", player->GetGUID().GetCounter());
        if (result)
        {
            do
            {
                ObjectGuid itemGUID = ObjectGuid(HighGuid::Item, (*result)[0].GetUInt32());
                ObjectGuid fakeEntry = ObjectGuid(uint64((*result)[1].GetUInt32()));
                if (sObjectMgr->GetItemTemplate(fakeEntry))
                {
                    sT->dataMap[itemGUID] = playerGUID;
                    sT->entryMap[playerGUID][itemGUID] = fakeEntry;
                }
                else
                {
                    //sLog->outError(LOG_FILTER_SQL, "Item entry (Entry: %u, itemGUID: %u, playerGUID: %u) does not exist, ignoring.", fakeEntry, GUID_LOPART(itemGUID), player->GetGUIDLow());
                    // CharacterDatabase.PExecute("DELETE FROM custom_transmogrification WHERE FakeEntry = %u", fakeEntry);
                }
            } while (result->NextRow());

            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            {
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    player->SetVisibleItemSlot(slot, item);
            }
        }

#ifdef PRESETS
        if (sT->GetEnableSets())
            sT->LoadPlayerSets(playerGUID);
#endif
    }

    void OnUpdate(Player* player, uint32 diff) override
    {
        sT->UpdatePreview(player, diff);
    }

    void OnMapChanged(Player* player) override
    {
        sT->CancelPreview(player);
    }

    void OnLogout(Player* player)
    {
        sT->CancelPreview(player);
        ObjectGuid pGUID = player->GetGUID();
        for (Transmogrification::transmogData::const_iterator it = sT->entryMap[pGUID].begin(); it != sT->entryMap[pGUID].end(); ++it)
            sT->dataMap.erase(it->first);
        sT->entryMap.erase(pGUID);

#ifdef PRESETS
        if (sT->GetEnableSets())
            sT->UnloadPlayerSets(pGUID);
#endif
    }
};

class WS_Transmogrification : public WorldScript
{
public:
    WS_Transmogrification() : WorldScript("WS_Transmogrification") { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            sT->LoadConfig(reload);
    }

    void OnStartup() override
    {
        sT->LoadConfig(false);
        //sLog->outInfo(LOG_FILTER_SERVER_LOADING, "Deleting non-existing transmogrification entries...");
        CharacterDatabase.Execute("DELETE FROM custom_transmogrification WHERE NOT EXISTS (SELECT 1 FROM item_instance WHERE item_instance.guid = custom_transmogrification.GUID)");

#ifdef PRESETS
        // Clean even if disabled
        // Dont delete even if player has more presets than should
        CharacterDatabase.Execute("DELETE FROM `custom_transmogrification_sets` WHERE NOT EXISTS(SELECT 1 FROM characters WHERE characters.guid = custom_transmogrification_sets.Owner)");
#endif
    }

    void OnBeforeConfigLoad(bool reload) override
    {
        /*if (!reload) {
            std::string conf_path = _CONF_DIR;
            std::string cfg_file = conf_path + "/transmog.conf";
            std::string cfg_def_file = cfg_file +".dist";

            sConfigMgr->LoadMore(cfg_def_file.c_str());

            sConfigMgr->LoadMore(cfg_file.c_str());
        }*/
    }
};

class global_transmog_script : public GlobalScript {
    public:
        global_transmog_script() : GlobalScript("global_transmog_script") { }
        
        void OnItemDelFromDB(CharacterDatabaseTransaction trans, ObjectGuid itemGuid) {
            sT->DeleteFakeFromDB(itemGuid, trans);
        }
        
        void OnMirrorImageDisplayItem(const Item *item, uint32 &display) {
            if (uint32 entry = sTransmogrification->GetFakeEntry(item->GetGUID()))
                display=uint32(sObjectMgr->GetItemTemplate(entry)->DisplayInfoID);
        }
};

void AddSC_transmog() 
{
    new global_transmog_script();
    new npc_transmogrifier();
    new PS_Transmogrification();
    new WS_Transmogrification();
}
