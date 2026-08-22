/*
 * This file is part of the Legends of Azeroth Pandaria Project. See THANKS file for Copyright information
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

#include "ScriptPCH.h"
#include "Chat.h"
#include "ScriptedGossip.h"
#include "Item.h"
#include "Player.h"
#include "QuestDef.h"
#include "ObjectMgr.h"
#include "DatabaseEnv.h"

class item_quest_completer : public ItemScript
{
public:
    item_quest_completer() : ItemScript("item_quest_completer") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (player->IsInCombat())
        {
            player->GetSession()->SendNotification("你处于战斗状态!");
            return true;
        }

        // Build list of incomplete quests
        std::map<uint32, QuestStatusData> const& questMap = player->getQuestStatusMap();
        uint32 count = 0;

        player->PlayerTalkClass->ClearMenus();

        for (auto const& itr : questMap)
        {
            if (itr.second.Status != QUEST_STATUS_INCOMPLETE)
                continue;

            Quest const* quest = sObjectMgr->GetQuestTemplate(itr.first);
            if (!quest)
                continue;

            // Use localized quest title
            std::string questTitle = GetLocalizedQuestTitle(player, quest);
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_DOT, questTitle, GOSSIP_SENDER_MAIN, itr.first);
            ++count;
        }

        if (count == 0)
        {
            player->GetSession()->SendNotification("你没有未完成的任务!");
            player->CLOSE_GOSSIP_MENU();
            return true;
        }

        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "Nevermind", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, item->GetGUID());
        return true;
    }

    void OnGossipSelect(Player* player, Item* /*item*/, uint32 /*sender*/, uint32 action) override
    {
        player->PlayerTalkClass->ClearMenus();

        if (action == GOSSIP_ACTION_INFO_DEF + 1)
        {
            player->CLOSE_GOSSIP_MENU();
            return;
        }

        // action is the quest ID
        uint32 questId = action;
        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);

        if (!quest || player->GetQuestStatus(questId) != QUEST_STATUS_INCOMPLETE)
        {
            player->GetSession()->SendNotification("未找到该任务或任务已完成!");
            player->CLOSE_GOSSIP_MENU();
            return;
        }

        // Auto-complete the quest (fill objectives + reward)
        player->CompleteQuest(questId, true, true);

        // Log to database
        LogQuestCompletion(player, quest);

        // Use localized quest title in notification
        std::string questTitle = GetLocalizedQuestTitle(player, quest);
        player->GetSession()->SendNotification("任务「%s」已完成!", questTitle.c_str());
        player->CLOSE_GOSSIP_MENU();
    }

private:
    // Get localized quest title for the player's locale, falls back to default
    std::string GetLocalizedQuestTitle(Player* player, Quest const* quest) const
    {
        std::string title = quest->GetLogTitle();
        LocaleConstant localeConstant = player->GetSession()->GetSessionDbLocaleIndex();
        if (localeConstant != LOCALE_enUS)
        {
            QuestTemplateLocale const* locQuest = sObjectMgr->GetQuestLocale(quest->GetQuestId());
            if (locQuest)
            {
                std::string localizedTitle;
                ObjectMgr::GetLocaleString(locQuest->LogTitle, localeConstant, localizedTitle);
                if (!localizedTitle.empty())
                    title = localizedTitle;
            }
        }
        return title;
    }

    // Get localized quest log description for the player's locale, falls back to default
    std::string GetLocalizedQuestDescription(Player* player, Quest const* quest) const
    {
        std::string description = quest->GetLogDescription();
        LocaleConstant localeConstant = player->GetSession()->GetSessionDbLocaleIndex();
        if (localeConstant != LOCALE_enUS)
        {
            QuestTemplateLocale const* locQuest = sObjectMgr->GetQuestLocale(quest->GetQuestId());
            if (locQuest)
            {
                std::string localizedDescription;
                ObjectMgr::GetLocaleString(locQuest->LogDescription, localeConstant, localizedDescription);
                if (!localizedDescription.empty())
                    description = localizedDescription;
            }
        }
        return description;
    }

    void LogQuestCompletion(Player* player, Quest const* quest) const
    {
        uint32 questId = quest->GetQuestId();

        // Find quest giver NPC from database
        uint32 questGiverNpc = 0;
        QueryResult starterResult = WorldDatabase.PQuery("SELECT id FROM creature_queststarter WHERE quest=%u", questId);
        if (starterResult)
            questGiverNpc = starterResult->Fetch()[0].GetUInt32();

        // Find turn-in NPC from database
        uint32 questTurninNpc = 0;
        QueryResult turninResult = WorldDatabase.PQuery("SELECT id FROM creature_questender WHERE quest=%u", questId);
        if (turninResult)
            questTurninNpc = turninResult->Fetch()[0].GetUInt32();

        // Build objectives text using localized description if available, otherwise use objectives
        std::string objectives;
        for (auto const& obj : quest->Objectives)
        {
            if (!objectives.empty())
                objectives += "; ";
            objectives += obj.Description;
        }

        if (objectives.empty())
            objectives = GetLocalizedQuestDescription(player, quest);

        // Determine faction
        std::string faction = player->GetTeam() == ALLIANCE ? "联盟" : "部落";

        // Use localized quest title for logging
        std::string questName = GetLocalizedQuestTitle(player, quest);
        WorldDatabase.EscapeString(questName);
        std::string objectivesEscaped = objectives;
        WorldDatabase.EscapeString(objectivesEscaped);
        std::string playerName = player->GetName();
        WorldDatabase.EscapeString(playerName);

        // Skip if this quest was already recorded (by any player)
        QueryResult result = WorldDatabase.PQuery("SELECT id FROM 任务完成记录 WHERE quest_id=%u", questId);
        if (result)
            return;

        WorldDatabase.PExecute("INSERT INTO 任务完成记录 (quest_id, quest_name, quest_giver_npc, quest_objectives, quest_turnin_npc, player_name, faction) "
            "VALUES (%u, '%s', %u, '%s', %u, '%s', '%s')",
            questId, questName.c_str(), questGiverNpc, objectivesEscaped.c_str(), questTurninNpc,
            playerName.c_str(), faction.c_str());
    }
};

void AddSC_quest_completer()
{
    new item_quest_completer();
}
