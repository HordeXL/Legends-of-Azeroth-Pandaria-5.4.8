/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_PLAYERBOTTEXTMGR_H
#define _PLAYERBOT_PLAYERBOTTEXTMGR_H

#include "Common.h"
#include "DBCEnums.h"

#include <string>
#include <unordered_map>
#include <vector>

class Player;
class Unit;
struct FactionEntry;
struct ItemTemplate;

// Extra data needed to resolve placeholders that cannot be derived from the
// bot itself. Everything left at its default is resolved automatically by
// PlayerbotTextMgr::Format() (inventory, quest log, reputation, talents, ...).
struct PlayerbotTextContext
{
    Player* bot = nullptr;                 // the bot that is speaking
    Unit* target = nullptr;                // <target>, %target, %victim_name fallback
    ItemTemplate const* item = nullptr;    // %item_link, %item_formatted_link, %item, ...
    std::string speaker;                   // %s / %other_name - who the bot is answering
    uint32 questId = 0;                    // %quest_link / %quest (0 = pick a random journal quest)
    uint32 gold = 0;                       // %cost_gold in copper (0 = derive from item/level)
    uint32 amount = 0;                     // %amount
    LocaleConstant locale = LOCALE_enUS;   // locale used for DBC / DB strings
};

// Manager for the random bot speech system. Loads the speech tables from the
// Playerbots database and provides random texts by category, locale aware,
// with placeholder substitution.
//
// Tables consumed:
//   ai_playerbot_texts            - rich multi-locale texts (say/yell, reply_type)
//   playerbots_speech             - classic taunt/aoe/loot lines with <target>
//   playerbots_speech_probability - per-category speech probability (taunt/aoe/loot)
//   ai_playerbot_texts_chance     - per-category chance for ai_playerbot_texts
class PlayerbotTextMgr
{
public:
    static PlayerbotTextMgr* instance();

    // Loads all speech tables into memory. Called once at startup.
    void Load();

    // True when the given category has at least one entry in ai_playerbot_texts.
    bool HasText(std::string const name) const;

    // Per-category probability (from playerbots_speech_probability /
    // ai_playerbot_texts_chance). Returns 0 when unknown.
    uint32 GetSpeechProbability(std::string const name) const;

    // Random text from ai_playerbot_texts for a category. When locale is a
    // non-English locale the matching localized column is preferred. sayTypeOut
    // receives the say_type of the chosen entry (0 = say, 1 = yell).
    // Returns an empty string when the category is unknown.
    std::string GetText(std::string const name, LocaleConstant locale = LOCALE_enUS, uint32* sayTypeOut = nullptr);

    // Random text from playerbots_speech for a category (classic taunt/aoe/loot
    // lines). Replaces the <target> placeholder with the given target name.
    std::string GetSpeech(std::string const name, std::string const target = "");

    // Substitutes every supported placeholder in a raw text. Placeholders that
    // need external data are resolved from the bot state when the context does
    // not provide them (inventory, quest log, reputation, talents, ...).
    //
    // Supported placeholders:
    //   <target>            -> target unit name
    //   %target             -> target unit name
    //   %zone_name          -> current zone name
    //   %area_name          -> current area name
    //   %my_race            -> bot race name
    //   %my_class           -> bot class name
    //   %my_level           -> bot level
    //   %my_role            -> tank / healer / dps
    //   %instance_name      -> current map (instance) name
    //   %item_link          -> real item chat link
    //   %item               -> item name (no link)
    //   %item_formatted_link / %item_formatted_links -> one or more item links
    //   %formatted_item_links -> one or more item links
    //   %random_inventory_item_link -> link of a random item from the bags
    //   %random_taken_quest_or_item_link -> random quest or item link
    //   %quest_link / %quest_links -> one or more quest links
    //   %quest              -> quest title (no link)
    //   %faction            -> a faction the bot has reputation with
    //   %rep_level          -> standing with that faction (Friendly, Revered, ...)
    //   %category           -> gathering/trade category (ore, herbs, ...)
    //   %cost_gold          -> price, formatted as "12g 34s 56c"
    //   %victim_name        -> name of the unit the bot is fighting
    //   %s / %other_name    -> name of the player the bot is talking to
    //   %thunderfury_link   -> Thunderfury chat link (spam)
    //   %amount             -> numeric amount from the context
    //   %rndK               -> random number
    //   %prefix             -> trade prefix (WTB / WTS / LFG)
    //
    // Returns an empty string when a placeholder could not be resolved and
    // AiPlayerbot.HideUnformattedText is enabled - this keeps raw tokens such
    // as "%category" from ever reaching the chat box.
    std::string Format(std::string text, PlayerbotTextContext const& ctx) const;

    // Backward compatible wrapper around the context based overload.
    std::string Format(std::string text, Player* bot, Unit* target = nullptr, ItemTemplate const* item = nullptr) const;

    // Builds a real client side item chat link, e.g.
    // |cffa335ee|Hitem:19019:0:0:0:0:0:0:0:0:90|h[Thunderfury]|h|r
    std::string BuildItemLink(uint32 itemId, uint32 ownerLevel, LocaleConstant locale) const;

    // Builds a real client side quest chat link, e.g.
    // |cff808080|Hquest:2278:47|h[The Platinum Discs]|h|r
    std::string BuildQuestLink(uint32 questId, LocaleConstant locale) const;

    // Formats an amount of copper as "12g 34s 56c".
    std::string FormatMoney(uint32 copper) const;

    // Chat messages are limited to 255 bytes by the client. Cuts the text down
    // without leaving a half written chat link behind.
    static std::string TruncateChatText(std::string text, size_t maxLen = 255);

private:
    PlayerbotTextMgr() = default;
    ~PlayerbotTextMgr() = default;

    struct TextEntry
    {
        std::string text;
        uint32 sayType = 0;
        bool replyType = false;
        std::string loc[8];  // text_loc1..8 (non-English DBC locales)
    };

    // Context resolution helpers (all of them tolerate a null bot).
    std::vector<uint32> GetInventoryItemIds(Player* bot) const;
    std::vector<uint32> GetJournalQuestIds(Player* bot) const;
    std::string ResolveRole(Player* bot) const;
    std::string ResolveTradeCategory(Player* bot) const;
    FactionEntry const* ResolveFactionEntry(Player* bot) const;
    std::string ResolveFactionRank(Player* bot, FactionEntry const* faction, LocaleConstant locale) const;
    uint32 ResolveQuestId(Player* bot, uint32 questId) const;
    std::string ResolveVictimName(Player* bot, Unit* target) const;
    std::string ResolveOtherName(Player* bot, std::string const& speaker) const;
    std::string BuildItemLinks(Player* bot, ItemTemplate const* item, uint32 count, LocaleConstant locale) const;
    std::string BuildQuestLinks(Player* bot, uint32 questId, uint32 count, LocaleConstant locale) const;
    uint32 ResolvePrice(Player* bot, ItemTemplate const* item, uint32 gold) const;

    // True when the text still contains a placeholder token we do not implement.
    bool HasUnresolvedPlaceholder(std::string const& text) const;

    std::unordered_map<std::string, std::vector<TextEntry>> _texts;
    std::unordered_map<std::string, std::vector<std::string>> _speech;
    std::unordered_map<std::string, uint32> _chances;
    bool _loaded = false;
};

#define sPlayerbotTextMgr PlayerbotTextMgr::instance()

#endif
