/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "TargetValue.h"

#include "LastMovementValue.h"
#include "ObjectGuid.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"
#include "RtiTargetValue.h"
#include "ScriptedCreature.h"
#include "ThreatManager.h"
#include <algorithm>
#include <cctype>

Unit* FindTargetValue::Calculate()
{
    if (qualifier.empty())
        return nullptr;

    auto lowerName = [](std::string name)
    {
        std::transform(name.begin(), name.end(), name.begin(),
            [](unsigned char character) { return std::tolower(character); });
        return name;
    };

    std::string const wantedName = lowerName(qualifier);
    auto* targets = botAI->GetAiObjectContext()->GetValue<GuidVector>(
        "possible targets no los");
    if (!targets)
        return nullptr;

    for (ObjectGuid const guid : targets->Get())
    {
        Unit* unit = botAI->GetUnit(guid);
        if (unit && unit->IsAlive() && lowerName(unit->GetName()) == wantedName)
            return unit;
    }

    return nullptr;
}

Unit* FindTargetStrategy::GetResult()
{
    return result;
}

Unit* TargetValue::FindTarget(FindTargetStrategy* strategy)
{
    GuidVector attackers = botAI->GetAiObjectContext()->GetValue<GuidVector>("attackers")->Get();
    for (ObjectGuid const guid : attackers)
    {
        Unit* unit = botAI->GetUnit(guid);
        if (!unit)
            continue;

        ThreatManager& ThreatMgr = unit->GetThreatManager();
        strategy->CheckAttacker(unit, &ThreatMgr);
    }

    return strategy->GetResult();
}

void FindTargetStrategy::GetPlayerCount(Unit* creature, uint32* tankCount, uint32* dpsCount)
{
    Player* bot = botAI->GetBot();
    if (tankCountCache.find(creature) != tankCountCache.end())
    {
        *tankCount = tankCountCache[creature];
        *dpsCount = dpsCountCache[creature];
        return;
    }

    *tankCount = 0;
    *dpsCount = 0;

    Unit::AttackerSet attackers(creature->getAttackers());
    for (Unit* attacker : attackers)
    {
        if (!attacker || !attacker->IsAlive() || attacker == bot)
            continue;

        Player* player = attacker->ToPlayer();
        if (!player)
            continue;

        if (PlayerBotSpec::IsTank(player))
            ++(*tankCount);
        else
            ++(*dpsCount);
    }

    tankCountCache[creature] = *tankCount;
    dpsCountCache[creature] = *dpsCount;
}

bool FindTargetStrategy::IsHighPriority(Unit* attacker)
{
    Group* group = botAI->GetBot()->GetGroup(GroupSlot::Instance);
    if (!group)
        group = botAI->GetBot()->GetGroup();
    if (group)
    {
        ObjectGuid skullGuid = group->GetTargetIcon(7);
        ObjectGuid crossGuid = group->GetTargetIcon(6);
        if ((skullGuid && attacker->GetGUID() == skullGuid) ||
            (crossGuid && attacker->GetGUID() == crossGuid))
            return true;
    }
    GuidVector prioritizedTargets = botAI->GetAiObjectContext()->GetValue<GuidVector>("prioritized targets")->Get();
    for (ObjectGuid targetGuid : prioritizedTargets)
    {
        if (targetGuid && attacker->GetGUID() == targetGuid)
        {
            return true;
        }
    }
    return false;
}

bool FindNonCcTargetStrategy::IsCcTarget(Unit* attacker)
{
    Group* group = botAI->GetBot()->GetGroup(GroupSlot::Instance);
    if (!group)
        group = botAI->GetBot()->GetGroup();
    if (group)
    {
        Group::MemberSlotList const& groupSlot = group->GetMemberSlots();
        for (Group::member_citerator itr = groupSlot.begin(); itr != groupSlot.end(); itr++)
        {
            Player* member = ObjectAccessor::FindPlayer(itr->guid);
            if (!member || !member->IsAlive())
                continue;

            if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(member))
            {
                if (botAI->GetAiObjectContext()->GetValue<Unit*>("rti cc target")->Get() == attacker)
                    return true;

                std::string const rti = botAI->GetAiObjectContext()->GetValue<std::string>("rti cc")->Get();
                int32 index = RtiTargetValue::GetRtiIndex(rti);
                if (index != -1)
                {
                    if (ObjectGuid guid = group->GetTargetIcon(index))
                        if (attacker->GetGUID() == guid)
                            return true;
                }
            }
        }

        if (ObjectGuid guid = group->GetTargetIcon(4))
            if (attacker->GetGUID() == guid)
                return true;
    }

    return false;
}
