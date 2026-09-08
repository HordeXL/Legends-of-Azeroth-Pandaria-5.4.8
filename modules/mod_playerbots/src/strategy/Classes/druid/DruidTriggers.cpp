/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "DruidTriggers.h"

#include "Playerbots.h"

bool PveMoonkinFormTrigger::IsActive()
{
    return botAI->IsGroupPveActivity() && bot->IsAlive() && bot->IsInWorld() &&
        bot->GetSpecialization() == SPEC_DRUID_BALANCE && bot->HasSpell(24858) &&
        !bot->HasAura(24858) && !bot->IsMounted() && !bot->IsInFlight() &&
        !bot->IsBeingTeleported() && !bot->isSwimming() &&
        !bot->IsNonMeleeSpellCasted(false);
}

