/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "RogueTriggers.h"

#include "GenericTriggers.h"
#include "Playerbots.h"
#include "ServerFacade.h"
#include "AiFactory.h"

bool RogueComboPointsTrigger::IsActive()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsAlive() || target != bot->GetComboTarget())
        return false;

    return dyingTarget ? bot->GetComboPoints() > 0 && target->GetHealthPct() < 20.0f
        : bot->GetComboPoints() >= 4;
}

bool RogueSliceAndDiceTrigger::IsActive()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsAlive() || target != bot->GetComboTarget() || !bot->GetComboPoints())
        return false;

    Aura* aura = bot->GetAura(5171);
    // Establish the buff early, then refresh with a useful number of points.
    return !aura || (aura->GetDuration() <= 3000 && bot->GetComboPoints() >= 4);
}

bool RogueSubtletyBuilderTrigger::IsActive()
{
    return botAI->IsGroupPveActivity() &&
        AiFactory::GetPlayerSpecTab(bot) == Specializations::SPEC_ROGUE_SUBTLETY &&
        AI_VALUE2(uint8, "combo", "current target") < 4;
}
