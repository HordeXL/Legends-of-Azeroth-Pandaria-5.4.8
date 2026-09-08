/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "GenericRogueNonCombatStrategy.h"

#include "Playerbots.h"

GenericRogueNonCombatStrategy::GenericRogueNonCombatStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI)
{
}

void GenericRogueNonCombatStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    NonCombatStrategy::InitTriggers(triggers);

    triggers.push_back(new TriggerNode("pve deadly poison",
        NextAction::array(0, new NextAction("deadly poison", ACTION_HIGH + 10), nullptr)));

    triggers.push_back(new TriggerNode("player has flag",
                                       NextAction::array(0, new NextAction("sprint", ACTION_EMERGENCY + 1), nullptr)));
    triggers.push_back(new TriggerNode("enemy flagcarrier near",
                                       NextAction::array(0, new NextAction("sprint", ACTION_EMERGENCY + 2), nullptr)));
    triggers.push_back(new TriggerNode("often", NextAction::array(0, new NextAction("unstealth", 30.0f), NULL)));
}
