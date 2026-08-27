/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_HUNTERTRIGGERS_H
#define _PLAYERBOT_HUNTERTRIGGERS_H

#include "GenericTriggers.h"
#include "Trigger.h"

class PlayerbotAI;

class PveAncientHysteriaBurnTrigger : public PveRaidHasteTrigger
{
public:
    PveAncientHysteriaBurnTrigger(PlayerbotAI* botAI)
        : PveRaidHasteTrigger(botAI, "pve ancient hysteria burn", 90355, 14.0f,
            PveRaidHasteTrigger::PROVIDER_ANCIENT_HYSTERIA, true) {}
};

#endif
