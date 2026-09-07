/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_PRIESTTRIGGERS_H
#define _PLAYERBOT_PRIESTTRIGGERS_H

#include "SharedDefines.h"
#include "GenericTriggers.h"
#include "Playerbots.h"

class PlayerbotAI;

// MoP Devouring Plague spends all available orbs and scales its damage
// with the number spent. Do not treat it as an ordinary one-orb DoT.
class DevouringPlagueTrigger : public DebuffTrigger
{
public:
    DevouringPlagueTrigger(PlayerbotAI* ai)
        : DebuffTrigger(ai, "devouring plague", 1, true, 0.0f) {}

    bool IsActive() override
    {
        return bot->GetPower(POWER_SHADOW_ORBS) >= 3 && DebuffTrigger::IsActive();
    }
};

#endif
