/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_ROGUETRIGGERS_H
#define _PLAYERBOT_ROGUETRIGGERS_H

#include "GenericTriggers.h"

class PlayerbotAI;

class RogueComboPointsTrigger : public Trigger
{
public:
    RogueComboPointsTrigger(PlayerbotAI* ai, bool dyingTarget = false)
        : Trigger(ai, dyingTarget ? "target with combo points almost dead" : "combo points available", 1),
          dyingTarget(dyingTarget) { }
    bool IsActive() override;
private:
    bool dyingTarget;
};

class RogueSliceAndDiceTrigger : public Trigger
{
public:
    RogueSliceAndDiceTrigger(PlayerbotAI* ai) : Trigger(ai, "slice and dice", 1) { }
    bool IsActive() override;
};

class RogueSubtletyBuilderTrigger : public Trigger
{
public:
    RogueSubtletyBuilderTrigger(PlayerbotAI* ai) : Trigger(ai, "subtlety builder", 1) { }
    bool IsActive() override;
};

#endif
