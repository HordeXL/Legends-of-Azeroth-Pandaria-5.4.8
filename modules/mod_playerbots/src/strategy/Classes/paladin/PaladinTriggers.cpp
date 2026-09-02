/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "PaladinTriggers.h"

#include "PaladinActions.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"

bool SealTrigger::IsActive()
{
    switch (bot->GetSpecialization())
    {
        case SPEC_PALADIN_HOLY:
        case SPEC_PALADIN_PROTECTION:
            return !botAI->HasAura("seal of insight", bot);
        case SPEC_PALADIN_RETRIBUTION:
            // Righteousness remains a safe fallback if this character has
            // not learned Seal of Truth for any reason.
            return !botAI->HasAura("seal of truth", bot) &&
                !botAI->HasAura("seal of righteousness", bot);
        default:
            return !botAI->HasAnyAuraOf(bot, "seal of truth",
                "seal of insight", "seal of righteousness",
                "seal of command", nullptr);
    }
}
