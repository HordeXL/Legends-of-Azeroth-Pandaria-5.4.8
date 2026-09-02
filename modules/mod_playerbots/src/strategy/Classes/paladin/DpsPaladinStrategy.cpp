/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "DpsPaladinStrategy.h"

#include "Playerbots.h"
#include "Strategy.h"

class DpsPaladinStrategyActionNodeFactory : public NamedObjectFactory<ActionNode>
{
public:
    DpsPaladinStrategyActionNodeFactory()
    {
        
    }

private:
    
};

DpsPaladinStrategy::DpsPaladinStrategy(PlayerbotAI* botAI) : GenericPaladinStrategy(botAI)
{
    actionNodeFactories.Add(new DpsPaladinStrategyActionNodeFactory());
}

NextAction** DpsPaladinStrategy::getDefaultActions()
{
    return NextAction::array(0,
                             new NextAction("inquisition", ACTION_DEFAULT + 1.0f),
                             new NextAction("hammer of wrath", ACTION_DEFAULT + 0.95f),
                             new NextAction("templar's verdict", ACTION_DEFAULT + 0.9f),
                             new NextAction("exorcism", ACTION_DEFAULT + 0.85f),
                             new NextAction("crusader strike", ACTION_DEFAULT + 0.8f),
                             new NextAction("judgement", ACTION_DEFAULT + 0.75f),
                             new NextAction("melee", ACTION_DEFAULT + 0.6f),
                             nullptr);
}

void DpsPaladinStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    GenericPaladinStrategy::InitTriggers(triggers);

    triggers.push_back(new TriggerNode("seal", NextAction::array(0, new NextAction("seal of truth", ACTION_HIGH), nullptr)));
    triggers.push_back(new TriggerNode("enemy out of melee", NextAction::array(0, new NextAction("reach melee", ACTION_HIGH + 1), NULL)));
    triggers.push_back(new TriggerNode("medium aoe", NextAction::array(0,
        new NextAction("divine storm", ACTION_HIGH + 2),
        new NextAction("hammer of the righteous", ACTION_HIGH + 1), nullptr)));
}
