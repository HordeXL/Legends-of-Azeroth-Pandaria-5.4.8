/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "PlayerbotTextMgr.h"

#include <bitset>
#include <functional>
#include <sstream>

#include "Containers.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "ItemPrototype.h"
#include "Log.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
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

std::string PlayerbotTextMgr::Format(std::string text, Player* bot, Unit* target, ItemTemplate const* item) const
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
    }

    if (target)
        ReplaceAll(text, "<target>", target->GetName());

    if (item)
    {
        std::string name = item->Name1.empty() ? "item" : item->Name1;
        ReplaceAll(text, "%item_link", "[" + name + "]");
    }

    return text;
}
