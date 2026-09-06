/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "PlayerbotTextMgr.h"

#include <algorithm>
#include <bitset>
#include <unordered_map>
#include <functional>
#include <sstream>

#include "AiFactory.h"
#include "PlayerbotAI.h"
#include "Bag.h"
#include "Containers.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "ItemPrototype.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "QuestDef.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Unit.h"

namespace
{
void ReplaceAll(std::string& str, std::string const& from, std::string const& to)
{
    if (from.empty())
        return;

    size_t pos = 0;
    while ((pos = str.find(from, pos)) != std::string::npos)
    {
        str.replace(pos, from.length(), to);
        pos += to.length();
    }
}

Item* GetRandomBagItem(Player* bot)
{
    if (!bot || !bot->IsInWorld())
        return nullptr;

    std::vector<Item*> items;
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            items.push_back(item);

    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        if (Bag* bag = bot->GetBagByPos(bagSlot))
            for (uint8 slot = 0; slot < bag->GetBagSize(); ++slot)
                if (Item* item = bot->GetItemByPos(bagSlot, slot))
                    items.push_back(item);

    return items.empty() ? nullptr : items[urand(0, items.size() - 1)];
}

std::vector<Quest const*> GetRandomActiveQuests(Player* bot, uint32 count)
{
    std::vector<Quest const*> pool;
    if (!bot)
        return pool;

    for (auto const& [questId, statusData] : bot->getQuestStatusMap())
        if (statusData.Status == QUEST_STATUS_INCOMPLETE || statusData.Status == QUEST_STATUS_COMPLETE)
            if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
                pool.push_back(quest);

    std::vector<Quest const*> picked;
    for (uint32 i = 0; i < count && !pool.empty(); ++i)
    {
        size_t idx = urand(0, uint32(pool.size() - 1));
        picked.push_back(pool[idx]);
        pool.erase(pool.begin() + idx);
    }
    return picked;
}

uint32 GetRandomKnownSpellId(Player* bot)
{
    if (!bot)
        return 0;

    std::vector<uint32> spellIds;
    for (auto const& [spellId, spell] : bot->GetSpellMap())
        if (spell->active && !spell->disabled)
            if (SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId))
                if (spellInfo->SpellName[0] && spellInfo->SpellName[0][0])
                    spellIds.push_back(spellId);

    return spellIds.empty() ? 0 : spellIds[urand(0, uint32(spellIds.size() - 1))];
}

std::string GetLocalizedItemName(ItemTemplate const* proto, Player* bot)
{
    std::string name = proto->Name1;
    if (!name.empty() && bot)
    {
        LocaleConstant locale = bot->GetSession()->GetSessionDbLocaleIndex();
        if (locale != LOCALE_enUS)
            if (ItemLocale const* localeEntry = sObjectMgr->GetItemLocale(proto->ItemId))
                ObjectMgr::GetLocaleString(localeEntry->Name, locale, name);
    }
    return name;
}

std::string BuildItemLink(ItemTemplate const* proto, Player* bot)
{
    std::string name = GetLocalizedItemName(proto, bot);
    if (name.empty())
        name = "item";

    std::ostringstream link;
    link << "|c" << std::hex << ItemQualityColors[proto->Quality] << std::dec
         << "|Hitem:" << proto->ItemId << ":0:0:0:0:0:0:0:0:0|h[" << name << "]|h|r";
    return link.str();
}

std::string BuildQuestLink(Quest const* quest, Player* bot)
{
    std::string title = quest->GetLogTitle();
    if (!title.empty() && bot)
    {
        LocaleConstant locale = bot->GetSession()->GetSessionDbLocaleIndex();
        if (locale != LOCALE_enUS)
            if (QuestTemplateLocale const* localeEntry = sObjectMgr->GetQuestLocale(quest->GetQuestId()))
                ObjectMgr::GetLocaleString(localeEntry->LogTitle, locale, title);
    }
    if (title.empty())
        title = "quest";

    std::ostringstream link;
    link << "|cff808080|Hquest:" << quest->GetQuestId() << ":"
         << quest->GetQuestLevel() << "|h[" << title << "]|h|r";
    return link.str();
}

std::string BuildSpellLink(uint32 spellId)
{
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo || !spellInfo->SpellName[0] || !spellInfo->SpellName[0][0])
        return "";

    std::ostringstream link;
    link << "|cff71d5ff|Hspell:" << spellId << "|h[" << spellInfo->SpellName[0] << "]|h|r";
    return link.str();
}
}

PlayerbotTextMgr* PlayerbotTextMgr::instance()
{
    static PlayerbotTextMgr instance;
    return &instance;
}

void PlayerbotTextMgr::Load()
{
    _texts.clear();
    _speech.clear();
    _chances.clear();

    uint32 textCount = 0;
    QueryResult results = PlayerbotsDatabase.PQuery(
        "SELECT `name`, `text`, `say_type`, `reply_type`, `text_loc1`, `text_loc2`, `text_loc3`, `text_loc4`, "
        "`text_loc5`, `text_loc6`, `text_loc7`, `text_loc8` FROM `ai_playerbot_texts`");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();

            TextEntry entry;
            entry.text = fields[1].GetString();
            entry.sayType = fields[2].GetUInt32();
            entry.replyType = fields[3].GetUInt32() > 0;
            for (uint8 i = 0; i < 8; ++i)
                entry.loc[i] = fields[4 + i].GetString();

            _texts[fields[0].GetString()].push_back(std::move(entry));
            ++textCount;
        } while (results->NextRow());
    }

    uint32 speechCount = 0;
    results = PlayerbotsDatabase.PQuery("SELECT `name`, `text` FROM `playerbots_speech`");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();
            _speech[fields[0].GetString()].push_back(fields[1].GetString());
            ++speechCount;
        } while (results->NextRow());
    }

    results = PlayerbotsDatabase.PQuery("SELECT `name`, `probability` FROM `playerbots_speech_probability`");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();
            _chances[fields[0].GetString()] = fields[1].GetUInt32();
        } while (results->NextRow());
    }

    results = PlayerbotsDatabase.PQuery("SELECT `name`, `probability` FROM `ai_playerbot_texts_chance`");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();
            _chances[fields[0].GetString()] = fields[1].GetUInt32();
        } while (results->NextRow());
    }

    _loaded = true;
    TC_LOG_INFO("server.loading", ">> Loaded %u playerbot texts, %u speech lines, %u chance entries in %u ms",
        textCount, speechCount, (uint32)_chances.size(), GetMSTimeDiffToNow(0));
}

bool PlayerbotTextMgr::HasText(std::string const name) const
{
    auto it = _texts.find(name);
    return it != _texts.end() && !it->second.empty();
}

uint32 PlayerbotTextMgr::GetSpeechProbability(std::string const name) const
{
    auto it = _chances.find(name);
    if (it == _chances.end())
        return 0;
    return it->second;
}

std::string PlayerbotTextMgr::GetText(std::string const name, LocaleConstant locale, uint32* sayTypeOut)
{
    auto it = _texts.find(name);
    if (it == _texts.end() || it->second.empty())
        return "";

    std::vector<TextEntry> const& entries = it->second;
    TextEntry const& entry = entries[urand(0, uint32(entries.size() - 1))];

    if (sayTypeOut)
        *sayTypeOut = entry.sayType;

    if (locale > LOCALE_enUS && locale <= LOCALE_ruRU)
    {
        std::string const& localized = entry.loc[locale - 1];
        if (!localized.empty())
            return localized;
    }

    return entry.text;
}

std::string PlayerbotTextMgr::GetRandomText(LocaleConstant locale, uint32* sayTypeOut)
{
    // Flatten every category into one pool and pick a uniformly random entry,
    // so the name (category) field does not influence the selection.
    uint32 total = 0;
    for (auto const& [name, entries] : _texts)
        total += uint32(entries.size());

    if (total == 0)
        return "";

    uint32 pick = urand(0, total - 1);
    for (auto const& [name, entries] : _texts)
    {
        if (pick < entries.size())
        {
            TextEntry const& entry = entries[pick];

            if (sayTypeOut)
                *sayTypeOut = entry.sayType;

            if (locale > LOCALE_enUS && locale <= LOCALE_ruRU)
            {
                std::string const& localized = entry.loc[locale - 1];
                if (!localized.empty())
                    return localized;
            }

            return entry.text;
        }
        pick -= uint32(entries.size());
    }

    return "";
}

bool PlayerbotTextMgr::TryReserveAmbientSpeech(uint32 intervalSec)
{
    time_t now = time(nullptr);

    // Fast path: if the previous slot is older than intervalSec the caller may
    // try to claim the slot. CAS prevents two bots from both winning it.
    time_t last = _lastAmbientSpeech.load(std::memory_order_relaxed);
    while (last + intervalSec <= now)
    {
        if (_lastAmbientSpeech.compare_exchange_weak(last, now,
                std::memory_order_relaxed, std::memory_order_relaxed))
        {
            return true;  // this caller won the slot
        }
        // CAS failed -> another thread claimed it; re-read and retry.
        last = _lastAmbientSpeech.load(std::memory_order_relaxed);
    }

    return false;  // within cooldown, another bot spoke recently
}

std::string PlayerbotTextMgr::GetSpeech(std::string const name, std::string const target)
{
    auto it = _speech.find(name);
    if (it == _speech.end() || it->second.empty())
        return "";

    std::string text = it->second[urand(0, uint32(it->second.size() - 1))];

    if (!target.empty())
        ReplaceAll(text, "<target>", target);

    return text;
}

std::string PlayerbotTextMgr::Format(std::string text, Player* bot, Unit* target, ItemTemplate const* item, Quest const* quest) const
{
    if (bot)
    {
        if (AreaTableEntry const* zone = sAreaTableStore.LookupEntry(bot->GetZoneId()))
            ReplaceAll(text, "%zone_name", zone->area_name[0]);

        if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(bot->GetAreaId()))
            ReplaceAll(text, "%area_name", area->area_name[0]);

        if (ChrRacesEntry const* race = sChrRacesStore.LookupEntry(bot->GetRace()))
            ReplaceAll(text, "%my_race", race->name[0]);

        if (ChrClassesEntry const* cls = sChrClassesStore.LookupEntry(bot->GetClass()))
            ReplaceAll(text, "%my_class", cls->name[0]);

        ReplaceAll(text, "%my_level", std::to_string(bot->GetLevel()));

        // %my_role - the bot's current group role (tank / healer / dps)
        if (text.find("%my_role") != std::string::npos)
        {
            std::string role = "dps";
            switch (AiFactory::GetPlayerRoles(bot))
            {
                case BOT_ROLE_TANK:   role = "tank";   break;
                case BOT_ROLE_HEALER: role = "healer"; break;
                case BOT_ROLE_DPS:    role = "dps";    break;
                default:              role = "dps";    break;
            }
            ReplaceAll(text, "%my_role", role);
        }

        // %instance_name - a clickable Dungeon Journal link for a party dungeon
        // (Map.dbc map_type == 1, MAP_INSTANCE). The bot's current map is used
        // when it has a JournalInstance.dbc entry; otherwise a random journal-
        // backed dungeon is picked. Raids, battlegrounds, arenas, scenarios and
        // world maps never match.
        if (text.find("%instance_name") != std::string::npos)
        {
            // Map.dbc map id -> Dungeon Journal instance id (JournalInstance.dbc)
            static std::unordered_map<uint32, uint32> const journalInstanceByMap = []
            {
                std::unordered_map<uint32, uint32> byMap;
                for (uint32 i = 0; i < sJournalInstanceStore.GetNumRows(); ++i)
                    if (JournalInstanceEntry const* entry = sJournalInstanceStore.LookupEntry(i))
                        byMap.emplace(entry->MapID, entry->ID);
                return byMap;
            }();

            std::string instName;
            uint32 journalInstanceId = 0;
            auto useMap = [&](MapEntry const* mapEntry)
            {
                auto itr = journalInstanceByMap.find(mapEntry->MapID);
                if (itr == journalInstanceByMap.end())
                    return;
                journalInstanceId = itr->second;
                instName = mapEntry->name[0];
            };

            if (MapEntry const* mapEntry = sMapStore.LookupEntry(bot->GetMapId()))
                if (mapEntry->IsNonRaidDungeon() && mapEntry->name[0])
                    useMap(mapEntry);

            if (!journalInstanceId)
            {
                std::vector<MapEntry const*> pool;
                for (uint32 i = 0; i < sMapStore.GetNumRows(); ++i)
                {
                    MapEntry const* dungeon = sMapStore.LookupEntry(i);
                    if (!dungeon || !dungeon->IsNonRaidDungeon() || !dungeon->name[0])
                        continue;
                    if (!journalInstanceByMap.count(dungeon->MapID))
                        continue;
                    if (std::find_if(pool.begin(), pool.end(), [dungeon](MapEntry const* other)
                        { return std::string(dungeon->name[0]) == other->name[0]; }) != pool.end())
                        continue;
                    pool.push_back(dungeon);
                }
                if (!pool.empty())
                    useMap(pool[urand(0, pool.size() - 1)]);
            }

            // |Hjournal:0:<instanceID>:<difficulty>|h -- clicking opens the
            // Dungeon Journal at that instance (difficulty 1 = normal).
            if (journalInstanceId)
                ReplaceAll(text, "%instance_name",
                    "|cff66bbff|Hjournal:0:" + std::to_string(journalInstanceId) + ":1|h[" + instName + "]|h|r");
            else
                ReplaceAll(text, "%instance_name", instName.empty() ? "instance" : instName);
        }
    }

    if (target)
        ReplaceAll(text, "<target>", target->GetName());
    else
        ReplaceAll(text, "<target>", "someone");

    // ---- Legacy AiPlayerbot placeholders ----
    // The old text pool uses more tokens than the ones handled above. They are
    // filled from the bot's own state (bags, quest log, spellbook), the
    // optional target/item/quest context, or simple random values, so pool
    // texts containing them become speakable. Prefix-colliding tokens are
    // replaced longest-first (%quest_links before %quest_link, %spells before
    // %spell, %item last). Tokens with no sensible source (%s, %prefix,
    // %gameobject) stay unresolved on purpose: TalkRandom re-rolls rows with
    // leftover placeholders instead of sending raw "%xxx" to chat.
    if (bot && text.find('%') != std::string::npos)
    {
        // Shared contexts, computed at most once per call.
        Quest const* questContext = quest;
        if (!questContext && text.find("%qu") != std::string::npos)
            if (std::vector<Quest const*> picked = GetRandomActiveQuests(bot, 1); !picked.empty())
                questContext = picked[0];

        Item* bagItem = nullptr;
        bool bagItemSearched = false;
        auto getBagItem = [&]() -> Item*
        {
            if (!bagItemSearched)
            {
                bagItem = GetRandomBagItem(bot);
                bagItemSearched = true;
            }
            return bagItem;
        };

        std::string spellLink;
        bool spellSearched = false;
        auto getSpellLink = [&]() -> std::string
        {
            if (!spellSearched)
            {
                if (uint32 spellId = GetRandomKnownSpellId(bot))
                    spellLink = BuildSpellLink(spellId);
                spellSearched = true;
            }
            return spellLink;
        };

        // Quest objectives (need an active quest).
        if (questContext)
        {
            std::string objectiveText;
            uint32 objectiveCount = 0;
            for (QuestObjective const& objective : questContext->GetObjectives())
            {
                if (objectiveText.empty() && !objective.Description.empty())
                    objectiveText = objective.Description;
                if (!objectiveCount && objective.Amount > 0)
                    objectiveCount = uint32(objective.Amount);
            }
            if (objectiveText.empty())
                objectiveText = questContext->GetLogTitle();
            if (!objectiveCount)
                objectiveCount = urand(5, 25);

            if (text.find("%quest_obj_name") != std::string::npos)
                ReplaceAll(text, "%quest_obj_name", objectiveText);
            if (text.find("%quest_obj_required") != std::string::npos)
                ReplaceAll(text, "%quest_obj_required", std::to_string(objectiveCount));
            if (text.find("%quest_obj_available") != std::string::npos)
                ReplaceAll(text, "%quest_obj_available", std::to_string(urand(1, objectiveCount)));
            if (text.find("%quest_obj_missing") != std::string::npos)
                ReplaceAll(text, "%quest_obj_missing", std::to_string(urand(1, objectiveCount)));
            if (text.find("%quest_obj_full_formatted") != std::string::npos)
                ReplaceAll(text, "%quest_obj_full_formatted",
                    objectiveText + " (" + std::to_string(urand(1, objectiveCount)) + "/" + std::to_string(objectiveCount) + ")");
        }

        // Quest links (longest token first).
        if (text.find("%quest_links") != std::string::npos)
        {
            std::vector<Quest const*> picked = GetRandomActiveQuests(bot, 3);
            if (!picked.empty())
            {
                std::string joined = BuildQuestLink(picked[0], bot);
                for (size_t i = 1; i < picked.size(); ++i)
                    joined += " and " + BuildQuestLink(picked[i], bot);
                ReplaceAll(text, "%quest_links", joined);
            }
        }
        if (text.find("%quest_link") != std::string::npos && questContext)
            ReplaceAll(text, "%quest_link", BuildQuestLink(questContext, bot));
        if (text.find("%qu") != std::string::npos && questContext)
            ReplaceAll(text, "%qu", BuildQuestLink(questContext, bot));
        if (text.find("%quest") != std::string::npos && questContext)
            ReplaceAll(text, "%quest", BuildQuestLink(questContext, bot));

        // Item links and names (longest token first, plain %item last).
        if (text.find("%random_inventory_item_link") != std::string::npos)
            if (Item* randomItem = getBagItem())
                ReplaceAll(text, "%random_inventory_item_link", BuildItemLink(randomItem->GetTemplate(), bot));
        if (text.find("%item_formatted_links") != std::string::npos || text.find("%formatted_item_links") != std::string::npos)
        {
            std::string joined;
            for (uint32 i = 0; i < 3; ++i)
            {
                if (Item* randomItem = GetRandomBagItem(bot))
                {
                    if (!joined.empty())
                        joined += ", ";
                    joined += BuildItemLink(randomItem->GetTemplate(), bot);
                }
                if (joined.empty() || urand(0, 1))
                    break;
            }
            if (!joined.empty())
            {
                ReplaceAll(text, "%formatted_item_links", joined);
                ReplaceAll(text, "%item_formatted_links", joined);
            }
        }
        if (text.find("%item_formatted_link") != std::string::npos)
            if (Item* randomItem = getBagItem())
                ReplaceAll(text, "%item_formatted_link", BuildItemLink(randomItem->GetTemplate(), bot));
        if (text.find("%thunderfury_link") != std::string::npos)
            if (ItemTemplate const* thunderfury = sObjectMgr->GetItemTemplate(19019))
                ReplaceAll(text, "%thunderfury_link", BuildItemLink(thunderfury, bot));
        if (text.find("%gem") != std::string::npos)
            if (Item* randomItem = getBagItem())
                if (randomItem->GetTemplate()->Class == ITEM_CLASS_GEM)
                    ReplaceAll(text, "%gem", BuildItemLink(randomItem->GetTemplate(), bot));
        if (text.find("%item_link") != std::string::npos)
        {
            if (item)
                ReplaceAll(text, "%item_link", BuildItemLink(item, bot));
            else if (Item* randomItem = getBagItem())
                ReplaceAll(text, "%item_link", BuildItemLink(randomItem->GetTemplate(), bot));
        }
        if (text.find("%item") != std::string::npos)
        {
            std::string name;
            if (item)
                name = GetLocalizedItemName(item, bot);
            else if (Item* randomItem = getBagItem())
                name = GetLocalizedItemName(randomItem->GetTemplate(), bot);
            if (!name.empty())
                ReplaceAll(text, "%item", name);
        }

        // Spells (longest token first).
        if (text.find("%spells") != std::string::npos)
        {
            std::string first = getSpellLink();
            if (!first.empty())
                ReplaceAll(text, "%spells", first);
        }
        if (text.find("%spell") != std::string::npos)
        {
            std::string link = getSpellLink();
            if (!link.empty())
                ReplaceAll(text, "%spell", link);
        }

        // Simple values.
        auto replaceRand = [&text](char const* token, uint32 minValue, uint32 maxValue)
        {
            if (text.find(token) != std::string::npos)
                ReplaceAll(text, token, std::to_string(urand(minValue, maxValue)));
        };
        if (text.find("%faction") != std::string::npos)
            ReplaceAll(text, "%faction", bot->GetTeamId() == TEAM_ALLIANCE ? "Alliance" : "Horde");
        if (text.find("%category") != std::string::npos)
        {
            static char const* categories[] = { "weapons", "armor", "consumables", "trade goods", "recipes", "gems", "enchanting", "bags" };
            ReplaceAll(text, "%category", categories[urand(0, uint32(sizeof(categories) / sizeof(categories[0])) - 1)]);
        }
        if (text.find("%rep_level") != std::string::npos)
        {
            static char const* repLevels[] = { "friendly", "honored", "revered", "exalted" };
            ReplaceAll(text, "%rep_level", repLevels[urand(0, uint32(sizeof(repLevels) / sizeof(repLevels[0])) - 1)]);
        }
        if (text.find("%cost_gold") != std::string::npos)
            ReplaceAll(text, "%cost_gold", std::to_string(urand(1, 500)) + " gold");
        replaceRand("%rnd", 1, 100);
        replaceRand("%amount", 2, 30);
        if (target)
        {
            if (text.find("%victim_name") != std::string::npos)
                ReplaceAll(text, "%victim_name", target->GetName());
            if (text.find("%other_name") != std::string::npos)
                ReplaceAll(text, "%other_name", target->GetName());
            if (text.find("%unit") != std::string::npos)
                ReplaceAll(text, "%unit", target->GetName());
        }
        if (text.find("%player") != std::string::npos)
            ReplaceAll(text, "%player", bot->GetName());
    }

    return text;
}
