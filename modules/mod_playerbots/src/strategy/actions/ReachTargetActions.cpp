/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "ReachTargetActions.h"

#include "Event.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "ServerFacade.h"
#include "Spell.h"
#include "SpellInfo.h"

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
    if (WaitForTankPull(target))
        return false;

    // Niuzao's Charge aura lasts for the complete perimeter circuit. Chasing
    // the moving boss scatters melee across the arena; hold the safe position
    // and resume normal reach movement when the circuit ends.
    if (target && target->GetEntry() == 71954)
    {
        bool charging = target->HasAura(144608);
        if (Spell* spell = target->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            charging = charging || (spell->GetSpellInfo() &&
                spell->GetSpellInfo()->Id == 144608);
        if (charging)
            return false;
    }

    // During a staged Yu'lon fight, direct reach movement repeatedly chooses
    // the shortest line through a pool, then competes with the opposite
    // hazard-escape command. Non-tanks must let the formation and
    // boss-mechanics actions choose safe intermediate points.
    if (target && target->GetEntry() == 71955 &&
        bot->HasWorldBossStagingAccess() && target->GetVictim() != bot)
        return false;

    // Chi-Ji's Crane Rush repeatedly sends Blazing Nova children out from
    // the boss. Do not let ordinary melee/spell reach movement override the
    // forced lane dodge and immediately chase back into the next child.
    if (target && target->GetEntry() == 71952)
    {
        // Do not chase Chi-Ji out of Beacon of Hope while Blazing Song is
        // imminent or active. Boss mechanics moves tanks and damage dealers
        // into the shield and ordinary reach resumes after it despawns.
        if (bot->FindNearestCreature(71978, 120.0f, true))
            return false;

        bool craneRush = target->HasAura(144470);
        if (Spell* spell = target->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            craneRush = craneRush || (spell->GetSpellInfo() &&
                spell->GetSpellInfo()->Id == 144470);
        if (craneRush || bot->FindNearestCreature(71990, 120.0f, true))
            return false;

        // Firestorm's floor summon (71971, ten-yard damage radius) persists
        // after the forced dodge. If ordinary melee reach resumes while the
        // summon is still beside the bot, it walks straight back into the
        // same hazard and repeats that cycle on every formation update.
        if (bot->FindNearestCreature(71971, 24.0f, true))
            return false;
    }

    // float dis = distance + CONTACT_DISTANCE;
    return target &&
        !bot->IsWithinCombatRange(target, distance);  // sServerFacade->IsDistanceGreaterThan(AI_VALUE2(float,
    // "distance", GetTargetName()), distance);
}

std::string const ReachTargetAction::GetTargetName() { return "current target"; }

bool ReachMeleeAction::isUseful()
{
    Unit* target = GetTarget();
    // Chi-Ji's encounter formation selects a reachable point at the edge of
    // the boss's melee circle and routes around Firestorms. The generic
    // center-directed chase would override it, walk into a vortex, and make
    // different melee classes stop at visibly different depths in the boss.
    // The active tank remains on ordinary chase/tank-facing logic.
    if (target && target->GetEntry() == 71952 &&
        bot->HasWorldBossStagingAccess() && target->GetVictim() != bot)
        return false;

    return ReachTargetAction::isUseful();
}

CastReachTargetSpellAction::CastReachTargetSpellAction(PlayerbotAI* botAI, std::string const spell, float distance)
    : CastSpellAction(botAI, spell), distance(distance)
{
}
bool CastReachTargetSpellAction::isUseful()
{
    // Charge-style movement is useful in PvP, but in a dungeon/raid it moves
    // a follower through the tank's line and can wake the next trash pack.
    // PvE followers should reach the already pulled target by normal movement.
    if (botAI->IsGroupPveActivity())
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
