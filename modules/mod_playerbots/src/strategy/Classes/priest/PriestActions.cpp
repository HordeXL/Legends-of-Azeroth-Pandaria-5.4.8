/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "PriestActions.h"

#include "Event.h"
#include "Playerbots.h"

bool CastRemoveShadowformAction::isUseful() { return botAI->HasAura("shadowform", AI_VALUE(Unit*, "self target")); }

bool CastRemoveShadowformAction::isPossible() { return true; }

bool CastRemoveShadowformAction::Execute(Event event)
{
    botAI->RemoveAura("shadowform");
    return true;
}

bool CastShadowOpeningAction::isUseful()
{
    Unit* target = GetTarget();
    if (!botAI->IsGroupPveActivity() || !bot->IsAlive() || !target ||
        !target->IsAlive() || !target->IsInWorld() ||
        target->GetMap() != bot->GetMap() || !target->CanHaveThreatList())
        return false;

    bool const hasOwnDot = botAI->HasAura("shadow word: pain", target, true) ||
        botAI->HasAura("vampiric touch", target, true);
    bool const hasOwnThreat = target->GetThreatManager().getThreat(bot) > 0.0f;
    return !hasOwnDot && !hasOwnThreat;
}

bool CastShadowOpeningAction::Execute(Event /*event*/)
{
    Unit* target = GetTarget();
    if (!target)
        return false;

    // Prefer direct damage. Shadow Word: Pain remains an instant fallback
    // while the bot is still settling into its caster position.
    if (botAI->CanCastSpell("mind blast", target) &&
        botAI->CastSpell("mind blast", target))
        return true;

    return botAI->CanCastSpell("shadow word: pain", target) &&
        botAI->CastSpell("shadow word: pain", target);
}

Unit* CastPowerWordShieldOnAlmostFullHealthBelowAction::GetTarget()
{
    Group* group = bot->GetGroup();
    for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    {
        Player* player = gref->GetSource();
        if (!player)
            continue;
        if (player->isDead())
        {
            continue;
        }
        if (player->GetHealthPct() > sPlayerbotAIConfig->almostFullHealth)
        {
            continue;
        }
        if (player->GetDistance2d(bot) > sPlayerbotAIConfig->spellDistance)
        {
            continue;
        }
        if (botAI->HasAnyAuraOf(player, "weakened soul", "power word: shield", nullptr))
        {
            continue;
        }
        return player;
    }
    return nullptr;
}

bool CastPowerWordShieldOnAlmostFullHealthBelowAction::isUseful()
{
    Group* group = bot->GetGroup();
    for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    {
        Player* player = gref->GetSource();
        if (!player)
            continue;
        if (player->isDead())
        {
            continue;
        }
        if (player->GetHealthPct() > sPlayerbotAIConfig->almostFullHealth)
        {
            continue;
        }
        if (player->GetDistance2d(bot) > sPlayerbotAIConfig->spellDistance)
        {
            continue;
        }
        if (botAI->HasAnyAuraOf(player, "weakened soul", "power word: shield", nullptr))
        {
            continue;
        }
        return true;
    }
    return false;
}

Unit* CastPowerWordShieldOnNotFullAction::GetTarget()
{
    Group* group = bot->GetGroup();
    MinValueCalculator calc(100);
    for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    {
        Player* player = gref->GetSource();
        if (!player)
            continue;
        if (player->isDead() || player->IsFullHealth())
        {
            continue;
        }
        if (player->GetDistance2d(bot) > sPlayerbotAIConfig->spellDistance)
        {
            continue;
        }
        if (botAI->HasAnyAuraOf(player, "weakened soul", "power word: shield", nullptr))
        {
            continue;
        }
        calc.probe(player->GetHealthPct(), player);
    }
    return (Unit*)calc.param;
}

bool CastPowerWordShieldOnNotFullAction::isUseful()
{
    return GetTarget();
}
