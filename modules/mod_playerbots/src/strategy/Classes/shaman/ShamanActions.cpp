/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "ShamanActions.h"

#include <algorithm>
#include <initializer_list>

#include "Group.h"
#include "Playerbots.h"
#include "SpellHistory.h"
#include "Totem.h"
#include "Timer.h"

namespace
{
constexpr float CoordinatedTotemRadius = 80.0f;

Group* GetTotemCoordinationGroup(Player* bot)
{
    if (!bot)
        return nullptr;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    return group ? group : bot->GetGroup();
}

std::vector<uint32> ResolveTotemSpells(PlayerbotAI* botAI,
    std::initializer_list<char const*> names)
{
    std::vector<uint32> spells;
    for (char const* name : names)
    {
        uint32 spellId = botAI->GetAiObjectContext()->GetValue<uint32>(
            "spell id", name)->Get();
        if (spellId)
            spells.push_back(spellId);
    }
    return spells;
}

bool HasActiveCoordinatedTotem(Player* bot,
    std::vector<uint32> const& spellIds)
{
    Group* group = GetTotemCoordinationGroup(bot);
    if (!group || !bot->GetMap())
        return false;

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || member->GetMap() != bot->GetMap())
            continue;

        for (uint8 slot : {SUMMON_SLOT_TOTEM_FIRE, SUMMON_SLOT_TOTEM_EARTH,
                           SUMMON_SLOT_TOTEM_WATER, SUMMON_SLOT_TOTEM_AIR,
                           SUMMON_SLOT_TOTEM_EXTRA})
        {
            if (!member->m_SummonSlot[slot])
                continue;

            Creature* totem = member->GetMap()->GetCreature(
                member->m_SummonSlot[slot]);
            if (!totem || !totem->IsAlive() ||
                bot->GetDistance(totem) > CoordinatedTotemRadius)
                continue;

            uint32 createdBySpell = totem->GetUInt32Value(
                UNIT_FIELD_CREATED_BY_SPELL);
            if (std::find(spellIds.begin(), spellIds.end(), createdBySpell) !=
                spellIds.end())
                return true;
        }
    }
    return false;
}

bool IsCoordinatedTotemCaster(Player* bot, uint32 spellId)
{
    Group* group = GetTotemCoordinationGroup(bot);
    if (!group)
        return true;

    Player* selected = nullptr;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        PlayerbotAI* memberAI = member ? GET_PLAYERBOT_AI(member) : nullptr;
        if (!member || !memberAI || memberAI->IsRealPlayer() ||
            member->GetClass() != CLASS_SHAMAN || !member->IsAlive() ||
            member->GetMap() != bot->GetMap() ||
            bot->GetDistance(member) > CoordinatedTotemRadius ||
            !member->HasSpell(spellId) ||
            !member->GetSpellHistory()->IsReady(spellId))
            continue;

        if (!selected || member->GetGUID() < selected->GetGUID())
            selected = member;
    }
    return !selected || selected == bot;
}

bool IsCoordinatedTotemUseful(Player* bot, PlayerbotAI* botAI,
    char const* ownSpell, std::initializer_list<char const*> sharedActiveSpells)
{
    uint32 ownSpellId = botAI->GetAiObjectContext()->GetValue<uint32>(
        "spell id", ownSpell)->Get();
    if (!ownSpellId)
        return false;

    std::vector<uint32> activeSpellIds = ResolveTotemSpells(
        botAI, sharedActiveSpells);
    return !HasActiveCoordinatedTotem(bot, activeSpellIds) &&
        IsCoordinatedTotemCaster(bot, ownSpellId);
}

std::string GetAssignedAirTotem(Player* bot)
{
    Group* group = GetTotemCoordinationGroup(bot);
    if (!group)
        return {};

    std::vector<Player*> shamans;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        PlayerbotAI* memberAI = member ? GET_PLAYERBOT_AI(member) : nullptr;
        if (!member || !memberAI || memberAI->IsRealPlayer() ||
            member->GetClass() != CLASS_SHAMAN || !member->IsAlive() ||
            member->GetMap() != bot->GetMap() ||
            bot->GetDistance(member) > CoordinatedTotemRadius)
            continue;
        shamans.push_back(member);
    }
    std::sort(shamans.begin(), shamans.end(), [](Player* left, Player* right)
    {
        return left->GetGUID() < right->GetGUID();
    });

    auto position = std::find(shamans.begin(), shamans.end(), bot);
    if (position == shamans.end())
        return {};

    if (shamans.size() == 1)
        return bot->GetSpecialization() == SPEC_SHAMAN_ENHANCEMENT ?
            "windfury totem" : "wrath of air totem";

    // Give the first caster/healer Wrath and the first Enhancement shaman
    // Windfury. Remaining shamans add Grace before any effect is duplicated.
    std::vector<std::string> assignment(shamans.size());
    auto enhancement = std::find_if(shamans.begin(), shamans.end(),
        [](Player* member)
        {
            return member->GetSpecialization() == SPEC_SHAMAN_ENHANCEMENT;
        });
    auto caster = std::find_if(shamans.begin(), shamans.end(),
        [](Player* member)
        {
            return member->GetSpecialization() != SPEC_SHAMAN_ENHANCEMENT;
        });
    if (caster != shamans.end())
        assignment[std::distance(shamans.begin(), caster)] =
            "wrath of air totem";
    if (enhancement != shamans.end())
        assignment[std::distance(shamans.begin(), enhancement)] =
            "windfury totem";

    static char const* effects[] =
    {
        "wrath of air totem", "windfury totem", "grace of air totem"
    };
    for (std::string& selected : assignment)
    {
        if (!selected.empty())
            continue;
        for (char const* effect : effects)
            if (std::find(assignment.begin(), assignment.end(), effect) ==
                assignment.end())
            {
                selected = effect;
                break;
            }
        if (selected.empty())
            selected = effects[uint32(&selected - assignment.data()) % 3];
    }

    return assignment[std::distance(shamans.begin(), position)];
}

bool IsCoordinatedSustainedTotemUseful(Player* bot, PlayerbotAI* botAI,
    std::string const& action)
{
    if (!botAI->IsGroupPveActivity())
        return true;

    bool const airTotem = action == "wrath of air totem" ||
        action == "windfury totem" || action == "grace of air totem";
    if (airTotem)
    {
        if (GetAssignedAirTotem(bot) != action)
            return false;

        std::vector<uint32> activeSpellIds = ResolveTotemSpells(
            botAI, {action.c_str()});
        return !activeSpellIds.empty() &&
            !HasActiveCoordinatedTotem(bot, activeSpellIds);
    }
    if (action != "strength of earth totem" &&
             action != "stoneskin totem" &&
             action != "mana spring totem" &&
             action != "flametongue totem" &&
             action != "totem of wrath")
        return true;

    return IsCoordinatedTotemUseful(bot, botAI, action.c_str(),
        {action.c_str()});
}
}

bool CastTotemAction::isUseful()
{
    if (!IsCoordinatedSustainedTotemUseful(bot, botAI, name))
        return false;

    if (needLifeTime > 0.1f && AI_VALUE(uint8, "attacker count") < 3)
    {
        Unit* target = AI_VALUE(Unit*, "current target");
        if (!target)
        {
            return false;
        }
        float dps = AI_VALUE(float, "estimated group dps");
        if (target->GetHealth() / dps < needLifeTime)
        {
            return false;
        }
    }
    return CastBuffSpellAction::isUseful() && !AI_VALUE2(bool, "has totem", name) && !botAI->HasAura(buff, bot);
}

bool CastManaSpringTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "healing stream totem");
}

bool CastManaTideTotemAction::isUseful()
{
    if (!CastTotemAction::isUseful() ||
        !IsCoordinatedTotemUseful(bot, botAI, "mana tide totem",
            {"mana tide totem"}))
        return false;

    if (!announcementStartedAt)
        return true;

    uint32 elapsed = getMSTimeDiff(announcementStartedAt, getMSTime());
    if (elapsed > 10000)
    {
        // The need disappeared, the cast was blocked, or the encounter state
        // changed. Start a fresh warning instead of casting from stale state.
        announcementStartedAt = 0;
        return true;
    }

    return elapsed >= 5000;
}

bool CastManaTideTotemAction::Execute(Event event)
{
    uint32 now = getMSTime();
    if (!announcementStartedAt)
    {
        botAI->Say("Mana Tide Totem in 5 seconds!");
        announcementStartedAt = now;
        return true;
    }

    if (getMSTimeDiff(announcementStartedAt, now) < 5000)
        return false;

    bool cast = CastBuffSpellAction::Execute(event);
    if (cast)
        announcementStartedAt = 0;

    return cast;
}

bool CastHealingTideTotemAction::isUseful()
{
    return CastTotemAction::isUseful() &&
        IsCoordinatedTotemUseful(bot, botAI, "healing tide totem",
            {"healing tide totem", "spirit link totem"});
}

bool CastSpiritLinkTotemAction::isUseful()
{
    return CastTotemAction::isUseful() &&
        IsCoordinatedTotemUseful(bot, botAI, "spirit link totem",
            {"healing tide totem", "spirit link totem"});
}

bool CastFlametongueTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "magma totem") &&
           !botAI->HasAura("totem of wrath", bot);
}

bool CastSearingTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "flametongue totem");
}

bool CastMagmaTotemAction::isUseful() {
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !bot->IsWithinMeleeRange(target))
        return false;

    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", name); 
}

bool CastFireNovaAction::isUseful() {
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;
    Creature* fireTotem = bot->GetMap()->GetCreature(bot->m_SummonSlot[1]);
    if (!fireTotem)
        return false;
    
    if (target->GetDistance(fireTotem) > 8.0f)
        return false;
    
    return CastMeleeSpellAction::isUseful(); 
}

bool CastCleansingTotemAction::isUseful()
{
    return CastTotemAction::isUseful() && !AI_VALUE2(bool, "has totem", "mana tide totem");
}
