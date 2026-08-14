/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_MONKSTRATEGIES_H
#define _PLAYERBOT_MONKSTRATEGIES_H

#include "CombatStrategy.h"
#include "MeleeCombatStrategy.h"
#include "NonCombatStrategy.h"

class PlayerbotAI;

class BrewmasterMonkStrategy : public MeleeCombatStrategy
{
public:
    BrewmasterMonkStrategy(PlayerbotAI* botAI) : MeleeCombatStrategy(botAI) {}
    std::string const getName() override { return "brewmaster"; }
    NextAction** getDefaultActions() override;
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

class WindwalkerMonkStrategy : public MeleeCombatStrategy
{
public:
    WindwalkerMonkStrategy(PlayerbotAI* botAI) : MeleeCombatStrategy(botAI) {}
    std::string const getName() override { return "windwalker"; }
    NextAction** getDefaultActions() override;
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

class MistweaverMonkStrategy : public CombatStrategy
{
public:
    MistweaverMonkStrategy(PlayerbotAI* botAI) : CombatStrategy(botAI) {}
    std::string const getName() override { return "mistweaver"; }
    NextAction** getDefaultActions() override;
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

class MonkCureStrategy : public Strategy
{
public:
    MonkCureStrategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    std::string const getName() override { return "cure"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

class MonkNonCombatStrategy : public NonCombatStrategy
{
public:
    MonkNonCombatStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) {}
    std::string const getName() override { return "nc"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override;
};

#endif
