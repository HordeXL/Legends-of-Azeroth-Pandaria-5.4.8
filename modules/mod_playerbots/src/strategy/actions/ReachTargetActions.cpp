/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "ReachTargetActions.h"

#include "Event.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "ServerFacade.h"

#include "Log.h"

bool ReachTargetAction::Execute(Event event)
{
    return ReachCombatTo(AI_VALUE(Unit*, GetTargetName()), distance);
}

bool ReachTargetAction::isUseful()
{
    // do not move while casting
    if (bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr)
    {
        return false;
    }
    Unit* target = GetTarget();
    // float dis = distance + CONTACT_DISTANCE;
    return target &&
        !bot->IsWithinCombatRange(target, distance);  // sServerFacade->IsDistanceGreaterThan(AI_VALUE2(float,
    // "distance", GetTargetName()), distance);
}

std::string const ReachTargetAction::GetTargetName() { return "current target"; }

CastReachTargetSpellAction::CastReachTargetSpellAction(PlayerbotAI* botAI, std::string const spell, float distance)
    : CastSpellAction(botAI, spell), distance(distance)
{
}
bool CastReachTargetSpellAction::isUseful()
{
    // Charge-style movement is useful in PvP, but in a dungeon/raid it moves
    // a follower through the tank's line and can wake the next trash pack.
    // PvE followers should reach the already pulled target by normal movement.
    if (bot->GetMap() &&
        (bot->GetMap()->IsDungeon() || bot->GetMap()->IsRaid()) &&
        !bot->InBattleground() && !bot->InArena())
        return false;

    return sServerFacade->IsDistanceGreaterThan(AI_VALUE2(float, "distance", "current target"), (distance + sPlayerbotAIConfig->contactDistance));
}

ReachSpellAction::ReachSpellAction(PlayerbotAI* botAI)
    : ReachTargetAction(botAI, "reach spell", botAI->GetRange("spell"))
{
}

ReachPartyMemberToHealAction::ReachPartyMemberToHealAction(PlayerbotAI* botAI)
    : ReachTargetAction(botAI, "reach party member to heal", botAI->GetRange("heal"))
{
}

bool ReachPartyMemberToHealAction::Execute(Event /*event*/)
{
    Unit* target = GetTarget();
    if (!target)
        return false;

    if (!bot->IsWithinLOSInMap(target))
    {
        // Move close enough for the path generator to route around the
        // obstacle. ReachCombatTo intentionally stops once spell range is
        // satisfied and therefore cannot repair a blocked line of sight.
        return MoveTo(target, sPlayerbotAIConfig->contactDistance,
            MovementPriority::MOVEMENT_COMBAT);
    }

    return ReachCombatTo(target, distance);
}

bool ReachPartyMemberToHealAction::isUseful()
{
    if (bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr)
        return false;

    Unit* target = GetTarget();
    return target && (!bot->IsWithinCombatRange(target, distance) ||
        !bot->IsWithinLOSInMap(target));
}

std::string const ReachPartyMemberToHealAction::GetTargetName() { return "party member to heal"; }

ReachPartyMemberToResurrectAction::ReachPartyMemberToResurrectAction(PlayerbotAI* botAI)
    : ReachTargetAction(botAI, "reach party member to resurrect", botAI->GetRange("spell"))
{
}

std::string const ReachPartyMemberToResurrectAction::GetTargetName() { return "party member to resurrect"; }
