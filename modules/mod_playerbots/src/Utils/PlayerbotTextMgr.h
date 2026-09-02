/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_PLAYERBOTTEXTMGR_H
#define _PLAYERBOT_PLAYERBOTTEXTMGR_H

#include "Common.h"
#include "DBCEnums.h"

#include <atomic>
#include <ctime>
#include <string>
#include <unordered_map>
#include <vector>

class Player;
class Unit;
struct ItemTemplate;
class Quest;

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

    // Random text from the whole ai_playerbot_texts table, ignoring the name
    // (category) field entirely. Locale and sayTypeOut behave like GetText.
    // Returns an empty string when the table contains no entries.
    std::string GetRandomText(LocaleConstant locale = LOCALE_enUS, uint32* sayTypeOut = nullptr);

    // Atomically reserves a single global ambient-speech slot. No matter how
    // many bots are online, only one caller wins a slot per intervalSec seconds
    // (measured from the previous win), so the World channel never floods with
    // simultaneous bot chatter. Returns true when this caller may speak now.
    bool TryReserveAmbientSpeech(uint32 intervalSec);

    // Random text from playerbots_speech for a category (classic taunt/aoe/loot
    // lines). Replaces the <target> placeholder with the given target name.
    std::string GetSpeech(std::string const name, std::string const target = "");

    // Substitutes the supported placeholders in a raw text:
    //   <target>    -> target unit name
    //   %item_link  -> item chat link (or "[item]" fallback)
    //   %quest_link -> quest chat link (or "[quest]" fallback)
    //   %zone_name  -> current zone name
    //   %area_name  -> current area name
    //   %my_race    -> bot race name
    //   %my_class   -> bot class name
    //   %my_level   -> bot level
    std::string Format(std::string text, Player* bot, Unit* target = nullptr, ItemTemplate const* item = nullptr, Quest const* quest = nullptr) const;

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

    std::unordered_map<std::string, std::vector<TextEntry>> _texts;
    std::unordered_map<std::string, std::vector<std::string>> _speech;
    std::unordered_map<std::string, uint32> _chances;
    // Unix time of the last granted global ambient-speech slot (0 = none yet).
    std::atomic<time_t> _lastAmbientSpeech{ 0 };
    bool _loaded = false;
};

#define sPlayerbotTextMgr PlayerbotTextMgr::instance()

#endif
