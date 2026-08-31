/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "PlayerbotTextMgr.h"

#include <algorithm>
#include <bitset>
#include <cctype>
#include <functional>
#include <set>
#include <sstream>

#include "Containers.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "ItemPrototype.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "QuestDef.h"
#include "ReputationMgr.h"
#include "SharedDefines.h"
#include "Unit.h"
// Group.h pulls in ConditionMgr.h which expects Creature to be declared
// already, so it has to come after Player.h.
#include "Group.h"

#define ARRAY_SIZE_CONST(arr) (sizeof(arr) / sizeof((arr)[0]))

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

// Same as ReplaceAll but only replaces whole placeholder tokens. Without this
// "%s" would also cut into "%spell" and leave a mangled word behind.
void ReplaceToken(std::string& str, std::string const& from, std::string const& to)
{
    if (from.empty())
        return;

    size_t pos = 0;
    while ((pos = str.find(from, pos)) != std::string::npos)
    {
        size_t end = pos + from.length();
        if (end < str.size() && (isalnum(static_cast<unsigned char>(str[end])) || str[end] == '_'))
        {
            // A longer token such as "%spell" starts with "%s" - keep looking.
            pos = end;
            continue;
        }

        str.replace(pos, from.length(), to);
        pos += to.length();
    }
}

// Entry of "Thunderfury, Blessed Blade of the Windseeker".
uint32 const THUNDERFURY_ITEM_ID = 19019;

// Fallback standing names used when the localized Trinity string is missing.
char const* const reputationRankNames[MAX_REPUTATION_RANK] = {
    "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"
};

// Maps a profession skill id onto the material it gathers.
// Named TradeCategoryEntry because SharedDefines.h already declares a
// SkillCategory enum.
struct TradeCategoryEntry
{
    uint32 skill;
    char const* category;
};

TradeCategoryEntry const skillCategories[] = {
    { SKILL_MINING, "ore" },
    { SKILL_HERBALISM, "herbs" },
    { SKILL_SKINNING, "leather" },
    { SKILL_TAILORING, "cloth" },
    { SKILL_ENCHANTING, "enchanting mats" },
    { SKILL_ENGINEERING, "engineering parts" },
    { SKILL_FISHING, "fish" },
    { SKILL_COOKING, "cooking ingredients" },
    { SKILL_ALCHEMY, "reagents" },
    { SKILL_BLACKSMITHING, "bars" },
    { SKILL_LEATHERWORKING, "leather" }
};

char const* const fallbackCategories[] = { "ore", "herbs", "leather", "cloth", "mats" };

// Joins a list of chat links: "a", "a and b", "a, b and c".
std::string JoinLinks(std::vector<std::string> const& links)
{
    if (links.empty())
        return "";
    if (links.size() == 1)
        return links[0];

    std::ostringstream out;
    for (size_t i = 0; i < links.size(); ++i)
    {
        if (i)
            out << (i + 1 == links.size() ? " and " : ", ");
        out << links[i];
    }

    return out.str();
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

std::string PlayerbotTextMgr::Format(std::string text, PlayerbotTextContext const& ctx) const
{
    Player* bot = ctx.bot;
    LocaleConstant locale = ctx.locale;

    // ---- values derived from the bot itself ---------------------------------
    if (bot)
    {
        if (AreaTableEntry const* zone = sAreaTableStore.LookupEntry(bot->GetZoneId()))
            ReplaceToken(text, "%zone_name", zone->area_name[0] ? zone->area_name[0] : "");

        if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(bot->GetAreaId()))
            ReplaceToken(text, "%area_name", area->area_name[0] ? area->area_name[0] : "");

        if (ChrRacesEntry const* race = sChrRacesStore.LookupEntry(bot->GetRace()))
            ReplaceToken(text, "%my_race", race->name[0] ? race->name[0] : "");

        if (ChrClassesEntry const* cls = sChrClassesStore.LookupEntry(bot->GetClass()))
            ReplaceToken(text, "%my_class", cls->name[0] ? cls->name[0] : "");

        ReplaceToken(text, "%my_level", std::to_string(bot->GetLevel()));

        // %instance_name - the bot's current map/instance name (dungeon suggestions)
        if (text.find("%instance_name") != std::string::npos)
        {
            std::string instName;
            if (MapEntry const* mapEntry = sMapStore.LookupEntry(bot->GetMapId()))
                instName = mapEntry->name[0] ? mapEntry->name[0] : "";
            ReplaceToken(text, "%instance_name", instName.empty() ? "instance" : instName);
        }

        if (text.find("%my_role") != std::string::npos)
            ReplaceToken(text, "%my_role", ResolveRole(bot));
    }

    // ---- who the bot is aiming at -------------------------------------------
    // Feeds <target>, %target, %victim_name, %player and %unit. The explicitly
    // passed target wins (e.g. the creature that was just killed), otherwise
    // whatever the bot is currently fighting is used.
    std::string targetName = ResolveVictimName(bot, ctx.target);

    if (!targetName.empty())
    {
        ReplaceToken(text, "<target>", targetName);
        ReplaceToken(text, "%target", targetName);
        ReplaceToken(text, "%victim_name", targetName);
        ReplaceToken(text, "%player", targetName);
        ReplaceToken(text, "%unit", targetName);
    }

    // ---- who the bot is talking to ------------------------------------------
    if (text.find("%s") != std::string::npos && !ctx.speaker.empty())
        ReplaceToken(text, "%s", ctx.speaker);

    if (text.find("%other_name") != std::string::npos)
    {
        std::string other = ResolveOtherName(bot, ctx.speaker);
        if (!other.empty())
            ReplaceToken(text, "%other_name", other);
    }

    // ---- reputation ---------------------------------------------------------
    // %faction and %rep_level belong together: resolve them from the same
    // faction so "Need %rep_level with %faction" stays consistent.
    if (text.find("%faction") != std::string::npos || text.find("%rep_level") != std::string::npos)
    {
        if (FactionEntry const* faction = ResolveFactionEntry(bot))
        {
            ReplaceToken(text, "%faction", faction->name[0] ? faction->name[0] : "");
            ReplaceToken(text, "%rep_level", ResolveFactionRank(bot, faction, locale));
        }
    }

    // ---- gathering / trade category -----------------------------------------
    if (text.find("%category") != std::string::npos)
        ReplaceToken(text, "%category", ResolveTradeCategory(bot));

    // ---- items --------------------------------------------------------------
    // Order matters: the longer tokens must go first, otherwise replacing
    // "%item" would chew up "%item_link" and "%item_formatted_link".
    if (text.find("%item_formatted_links") != std::string::npos)
        ReplaceToken(text, "%item_formatted_links", BuildItemLinks(bot, ctx.item, urand(1, 3), locale));

    if (text.find("%item_formatted_link") != std::string::npos)
        ReplaceToken(text, "%item_formatted_link", BuildItemLinks(bot, ctx.item, 1, locale));

    if (text.find("%formatted_item_links") != std::string::npos)
        ReplaceToken(text, "%formatted_item_links", BuildItemLinks(bot, ctx.item, urand(1, 3), locale));

    if (text.find("%random_inventory_item_link") != std::string::npos)
    {
        std::vector<uint32> bag = GetInventoryItemIds(bot);
        if (!bag.empty())
            ReplaceToken(text, "%random_inventory_item_link",
                BuildItemLink(bag[urand(0, uint32(bag.size() - 1))], bot ? bot->GetLevel() : 1, locale));
    }

    if (text.find("%item_link") != std::string::npos || text.find("%item") != std::string::npos)
    {
        // %item_link prefers the explicitly supplied item, otherwise a random
        // item from the bot's bags is used.
        uint32 itemId = ctx.item ? ctx.item->ItemId : 0;
        if (!itemId)
        {
            std::vector<uint32> bag = GetInventoryItemIds(bot);
            if (!bag.empty())
                itemId = bag[urand(0, uint32(bag.size() - 1))];
        }

        if (ItemTemplate const* proto = itemId ? sObjectMgr->GetItemTemplate(itemId) : nullptr)
        {
            ReplaceToken(text, "%item_link", BuildItemLink(proto->ItemId, bot ? bot->GetLevel() : 1, locale));
            ReplaceToken(text, "%item", proto->Name1.empty() ? "item" : proto->Name1);
        }
    }

    // ---- quests -------------------------------------------------------------
    if (text.find("%quest_link") != std::string::npos || text.find("%quest") != std::string::npos ||
        text.find("%random_taken_quest_or_item_link") != std::string::npos)
    {
        if (text.find("%quest_links") != std::string::npos)
            ReplaceToken(text, "%quest_links", BuildQuestLinks(bot, ctx.questId, urand(1, 3), locale));

        if (text.find("%quest_link") != std::string::npos)
            ReplaceToken(text, "%quest_link", BuildQuestLinks(bot, ctx.questId, 1, locale));

        if (text.find("%quest") != std::string::npos)
        {
            uint32 questId = ResolveQuestId(bot, ctx.questId);
            if (Quest const* quest = questId ? sObjectMgr->GetQuestTemplate(questId) : nullptr)
                ReplaceToken(text, "%quest", quest->GetLogTitle());
        }

        // Half of the time flex with an item instead of a quest.
        if (text.find("%random_taken_quest_or_item_link") != std::string::npos)
        {
            std::string link;
            if (urand(0, 1))
            {
                std::vector<uint32> bag = GetInventoryItemIds(bot);
                if (!bag.empty())
                    link = BuildItemLink(bag[urand(0, uint32(bag.size() - 1))], bot ? bot->GetLevel() : 1, locale);
            }

            if (link.empty())
                link = BuildQuestLinks(bot, ctx.questId, 1, locale);

            if (!link.empty())
                ReplaceToken(text, "%random_taken_quest_or_item_link", link);
        }
    }

    // ---- price --------------------------------------------------------------
    if (text.find("%cost_gold") != std::string::npos)
        ReplaceToken(text, "%cost_gold", FormatMoney(ResolvePrice(bot, ctx.item, ctx.gold)));

    // ---- misc ---------------------------------------------------------------
    if (text.find("%thunderfury_link") != std::string::npos)
    {
        std::string link = BuildItemLink(THUNDERFURY_ITEM_ID, bot ? bot->GetLevel() : 80, locale) + " ";
        ReplaceToken(text, "%thunderfury_link", link);
    }

    if (text.find("%amount") != std::string::npos)
        ReplaceToken(text, "%amount", std::to_string(ctx.amount ? ctx.amount : 1));

    if (text.find("%rndK") != std::string::npos)
        ReplaceToken(text, "%rndK", std::to_string(urand(100, 9000)));

    if (text.find("%prefix") != std::string::npos)
        ReplaceToken(text, "%prefix", urand(0, 1) ? "WTS" : "WTB");

    // Never let a raw token such as "%category" reach the chat box.
    if (sPlayerbotAIConfig->hideUnformattedText && HasUnresolvedPlaceholder(text))
        return "";

    return text;
}

std::string PlayerbotTextMgr::Format(std::string text, Player* bot, Unit* target, ItemTemplate const* item) const
{
    PlayerbotTextContext ctx;
    ctx.bot = bot;
    ctx.target = target;
    ctx.item = item;

    return Format(std::move(text), ctx);
}

std::string PlayerbotTextMgr::BuildItemLink(uint32 itemId, uint32 ownerLevel, LocaleConstant locale) const
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto)
        return "";

    std::string name = proto->Name1.empty() ? std::string("item") : proto->Name1;

    // Localized item names live in the `item_template_locale` table; the base
    // template only carries the English (DB) name.
    if (locale != LOCALE_enUS)
    {
        if (ItemLocale const* il = sObjectMgr->GetItemLocale(itemId))
        {
            if (il->Name.size() > size_t(locale - 1) && !il->Name[locale - 1].empty())
                name = il->Name[locale - 1];
        }
    }

    uint32 quality = proto->Quality < MAX_ITEM_QUALITY ? proto->Quality : ITEM_QUALITY_NORMAL;
    uint32 level = ownerLevel ? ownerLevel : proto->ItemLevel;

    char buf[512];
    snprintf(buf, sizeof(buf), "|c%08x|Hitem:%u:0:0:0:0:0:0:0:0:%u|h[%s]|h|r",
        ItemQualityColors[quality], itemId, level, name.c_str());

    return std::string(buf);
}

std::string PlayerbotTextMgr::BuildQuestLink(uint32 questId, LocaleConstant locale) const
{
    Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
    if (!quest)
        return "";

    std::string title = quest->GetLogTitle();
    if (title.empty())
        return "";

    // Localized quest titles live in `quest_template_locale`.
    if (locale != LOCALE_enUS)
    {
        if (QuestTemplateLocale const* ql = sObjectMgr->GetQuestLocale(questId))
        {
            if (ql->LogTitle.size() > size_t(locale - 1) && !ql->LogTitle[locale - 1].empty())
                title = ql->LogTitle[locale - 1];
        }
    }

    char buf[512];
    snprintf(buf, sizeof(buf), "|cff808080|Hquest:%u:%u|h[%s]|h|r",
        questId, uint32(std::max<int32>(quest->GetQuestLevel(), 0)), title.c_str());

    return std::string(buf);
}

std::string PlayerbotTextMgr::FormatMoney(uint32 copper) const
{
    uint32 gold = copper / 10000;
    uint32 silver = (copper / 100) % 100;
    uint32 cop = copper % 100;

    std::ostringstream out;
    if (gold)
        out << gold << "g";
    if (silver)
    {
        if (gold)
            out << " ";
        out << silver << "s";
    }
    if (cop)
    {
        if (gold || silver)
            out << " ";
        out << cop << "c";
    }

    std::string result = out.str();
    return result.empty() ? "0c" : result;
}

std::string PlayerbotTextMgr::TruncateChatText(std::string text, size_t maxLen)
{
    if (text.size() <= maxLen)
        return text;

    // Never cut in the middle of a chat link: fall back to the end of the last
    // complete link that still fits into the window.
    size_t end = text.rfind("|r", maxLen);
    if (end != std::string::npos && end + 2 <= maxLen)
    {
        size_t start = text.rfind("|c", end);
        if (start != std::string::npos && start < end)
            return text.substr(0, end + 2);
    }

    return text.substr(0, maxLen);
}

std::vector<uint32> PlayerbotTextMgr::GetInventoryItemIds(Player* bot) const
{
    std::vector<uint32> ids;
    if (!bot)
        return ids;

    // INVENTORY_SLOT_BAG_0 covers the equipped items (0-18), the bag slots
    // (19-22) and the 16 main backpack slots (23-38).
    for (uint8 slot = 0; slot < INVENTORY_SLOT_ITEM_END; ++slot)
    {
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            ids.push_back(item->GetEntry());
    }

    return ids;
}

std::vector<uint32> PlayerbotTextMgr::GetJournalQuestIds(Player* bot) const
{
    std::vector<uint32> ids;
    if (!bot)
        return ids;

    for (uint8 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        uint32 questId = bot->GetQuestSlotQuestId(slot);
        if (questId && sObjectMgr->GetQuestTemplate(questId))
            ids.push_back(questId);
    }

    return ids;
}

std::string PlayerbotTextMgr::ResolveRole(Player* bot) const
{
    if (!bot)
        return "";

    if (PlayerBotSpec::IsTank(bot, true))
        return "tank";
    if (PlayerBotSpec::IsHeal(bot, true))
        return "healer";

    return "dps";
}

std::string PlayerbotTextMgr::ResolveTradeCategory(Player* bot) const
{
    std::vector<char const*> pool;

    if (bot)
    {
        for (TradeCategoryEntry const& entry : skillCategories)
        {
            if (bot->HasSkill(entry.skill))
                pool.push_back(entry.category);
        }
    }

    if (pool.empty())
        return fallbackCategories[urand(0, ARRAY_SIZE_CONST(fallbackCategories) - 1)];

    return pool[urand(0, uint32(pool.size() - 1))];
}

FactionEntry const* PlayerbotTextMgr::ResolveFactionEntry(Player* bot) const
{
    if (!bot)
        return nullptr;

    FactionStateList const& states = bot->GetReputationMgr().GetStateList();
    std::vector<FactionEntry const*> pool;

    for (auto const& pair : states)
    {
        FactionState const& state = pair.second;

        // Only factions the player can actually see and grind.
        if (!(state.Flags & FACTION_FLAG_VISIBLE) || (state.Flags & FACTION_FLAG_HIDDEN))
            continue;
        if (state.Standing <= 0)
            continue;

        FactionEntry const* entry = sFactionStore.LookupEntry(state.ID);
        if (!entry || !entry->name[0] || entry->reputationListID < 0)
            continue;

        pool.push_back(entry);
    }

    if (pool.empty())
        return nullptr;

    return pool[urand(0, uint32(pool.size() - 1))];
}

std::string PlayerbotTextMgr::ResolveFactionRank(Player* bot, FactionEntry const* faction, LocaleConstant locale) const
{
    if (!faction || !bot)
        return "";

    ReputationRank rank = bot->GetReputationMgr().GetRank(faction);
    if (rank < MIN_REPUTATION_RANK || rank >= MAX_REPUTATION_RANK)
        return "";

    char const* localized = sObjectMgr->GetTrinityString(ReputationRankStrIndex(rank), locale);
    if (localized && *localized)
        return localized;

    return reputationRankNames[rank];
}

std::string PlayerbotTextMgr::ResolveVictimName(Player* bot, Unit* target) const
{
    // An explicit target wins: the caller knows what the line is about (for
    // example the creature that was just killed). Only when nobody was passed
    // do we fall back to whatever the bot is currently fighting.
    if (target)
        return target->GetName();
    if (bot && bot->GetVictim())
        return bot->GetVictim()->GetName();

    return "";
}

uint32 PlayerbotTextMgr::ResolveQuestId(Player* bot, uint32 questId) const
{
    if (questId && sObjectMgr->GetQuestTemplate(questId))
        return questId;

    // Fall back to a random quest the bot currently has in its journal.
    std::vector<uint32> journal = GetJournalQuestIds(bot);
    if (journal.empty())
        return 0;

    return journal[urand(0, uint32(journal.size() - 1))];
}

std::string PlayerbotTextMgr::ResolveOtherName(Player* bot, std::string const& speaker) const
{
    if (!speaker.empty())
        return speaker;

    if (!bot)
        return "";

    // Fall back to a random group member that is not the bot itself.
    if (Group* group = bot->GetGroup())
    {
        std::vector<std::string> names;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (member && member != bot)
                names.push_back(member->GetName());
        }

        if (!names.empty())
            return names[urand(0, uint32(names.size() - 1))];
    }

    return "";
}

std::string PlayerbotTextMgr::BuildItemLinks(Player* bot, ItemTemplate const* item, uint32 count, LocaleConstant locale) const
{
    uint32 ownerLevel = bot ? bot->GetLevel() : 1;

    std::vector<std::string> links;
    if (item)
        links.push_back(BuildItemLink(item->ItemId, ownerLevel, locale));

    std::vector<uint32> bag = GetInventoryItemIds(bot);
    while (links.size() < count && !bag.empty())
    {
        uint32 itemId = bag[urand(0, uint32(bag.size() - 1))];
        std::string link = BuildItemLink(itemId, ownerLevel, locale);
        if (link.empty())
            break;

        // Avoid repeating the very same link.
        if (std::find(links.begin(), links.end(), link) != links.end())
            break;

        links.push_back(link);
    }

    if (links.empty())
        links.push_back("[item]");

    return JoinLinks(links);
}

std::string PlayerbotTextMgr::BuildQuestLinks(Player* bot, uint32 questId, uint32 count, LocaleConstant locale) const
{
    std::vector<std::string> links;

    if (questId)
    {
        std::string link = BuildQuestLink(questId, locale);
        if (!link.empty())
            links.push_back(link);
    }

    std::vector<uint32> journal = GetJournalQuestIds(bot);
    while (links.size() < count && !journal.empty())
    {
        uint32 pick = journal[urand(0, uint32(journal.size() - 1))];
        std::string link = BuildQuestLink(pick, locale);
        if (link.empty())
            break;

        if (std::find(links.begin(), links.end(), link) != links.end())
            break;

        links.push_back(link);
    }

    if (links.empty())
        links.push_back("[quest]");

    return JoinLinks(links);
}

uint32 PlayerbotTextMgr::ResolvePrice(Player* bot, ItemTemplate const* item, uint32 gold) const
{
    if (gold)
        return gold;

    if (item && item->SellPrice)
        return std::max<uint32>(item->SellPrice * urand(1, 5), 100);

    if (bot)
        return std::max<uint32>(bot->GetLevel(), 1u) * urand(100, 1000);

    return urand(1000, 50000);
}

bool PlayerbotTextMgr::HasUnresolvedPlaceholder(std::string const& text) const
{
    // Anything that still looks like "%token" after all substitutions is a
    // placeholder we either do not implement or could not resolve for this bot
    // right now (no target, empty bags, no reputation, ...). Both cases would
    // leak raw text into the chat box, so the line is dropped instead.
    size_t pos = 0;
    while ((pos = text.find('%', pos)) != std::string::npos)
    {
        size_t start = ++pos;
        while (pos < text.size() && (isalnum(static_cast<unsigned char>(text[pos])) || text[pos] == '_'))
            ++pos;

        if (pos > start)
            return true;
    }

    // The only angle bracket placeholder the texts use.
    if (text.find("<target>") != std::string::npos)
        return true;

    return false;
}
