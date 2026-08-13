/*
 * This file is part of the Legends of Azeroth Pandaria Project.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#ifndef _PLAYERBOT_BATTLEGROUNDSTRATEGY_H
#define _PLAYERBOT_BATTLEGROUNDSTRATEGY_H

#include "Strategy.h"

class BattlegroundStrategy : public Strategy
{
public:
    explicit BattlegroundStrategy(PlayerbotAI* botAI) : Strategy(botAI) { }

    uint32 GetType() const override { return STRATEGY_TYPE_GENERIC; }
    std::string const getName() override { return "battleground"; }

    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        // The action is intentionally useful only while the bot is in a real
        // battleground.  During combat it keeps the current fight intact;
        // outside combat it selects and pursues the map objective.
        triggers.push_back(new TriggerNode("always trigger",
            NextAction::array(0, new NextAction("battleground objective", ACTION_RAID), nullptr)));
    }
};

#endif
