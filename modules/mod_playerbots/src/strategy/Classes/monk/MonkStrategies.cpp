/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "MonkStrategies.h"

#include "Playerbots.h"

NextAction** BrewmasterMonkStrategy::getDefaultActions()
{
    return NextAction::array(0,
        new NextAction("stance of the sturdy ox", ACTION_HIGH + 5),
        new NextAction("keg smash", ACTION_DEFAULT + 0.8f),
        new NextAction("blackout kick", ACTION_DEFAULT + 0.7f),
        new NextAction("tiger palm", ACTION_DEFAULT + 0.6f),
        new NextAction("jab", ACTION_DEFAULT + 0.5f),
        new NextAction("melee", ACTION_DEFAULT), nullptr);
}

void BrewmasterMonkStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    MeleeCombatStrategy::InitTriggers(triggers);
    triggers.push_back(new TriggerNode("spear hand strike",
        NextAction::array(0, new NextAction("spear hand strike", ACTION_INTERRUPT), nullptr)));
    triggers.push_back(new TriggerNode("low health",
        NextAction::array(0, new NextAction("guard", ACTION_EMERGENCY + 3),
            new NextAction("fortifying brew", ACTION_EMERGENCY + 2),
            new NextAction("expel harm", ACTION_EMERGENCY + 1), nullptr)));
    triggers.push_back(new TriggerNode("medium aoe",
        NextAction::array(0, new NextAction("spinning crane kick", ACTION_HIGH + 2), nullptr)));
    triggers.push_back(new TriggerNode("lose aggro",
        NextAction::array(0, new NextAction("provoke", ACTION_HIGH + 3), nullptr)));
}

NextAction** WindwalkerMonkStrategy::getDefaultActions()
{
    return NextAction::array(0,
        new NextAction("stance of the fierce tiger", ACTION_HIGH + 5),
        new NextAction("rising sun kick", ACTION_DEFAULT + 0.9f),
        new NextAction("fists of fury", ACTION_DEFAULT + 0.8f),
        new NextAction("blackout kick", ACTION_DEFAULT + 0.7f),
        new NextAction("tiger palm", ACTION_DEFAULT + 0.6f),
        new NextAction("jab", ACTION_DEFAULT + 0.5f),
        new NextAction("melee", ACTION_DEFAULT), nullptr);
}

void WindwalkerMonkStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    MeleeCombatStrategy::InitTriggers(triggers);
    triggers.push_back(new TriggerNode("spear hand strike",
        NextAction::array(0, new NextAction("spear hand strike", ACTION_INTERRUPT), nullptr)));
    triggers.push_back(new TriggerNode("critical health",
        NextAction::array(0, new NextAction("fortifying brew", ACTION_EMERGENCY + 2),
            new NextAction("expel harm", ACTION_EMERGENCY + 1), nullptr)));
    triggers.push_back(new TriggerNode("medium aoe",
        NextAction::array(0, new NextAction("spinning crane kick", ACTION_HIGH + 2), nullptr)));
    triggers.push_back(new TriggerNode("often",
        NextAction::array(0, new NextAction("tigereye brew", ACTION_NORMAL + 2),
            new NextAction("energizing brew", ACTION_NORMAL + 1), nullptr)));
}

NextAction** MistweaverMonkStrategy::getDefaultActions()
{
    // Keep a safe damage fallback so that a surviving healer does not stand
    // idle after its damage partner dies.
    return NextAction::array(0,
        new NextAction("stance of the wise serpent", ACTION_HIGH + 5),
        new NextAction("attack enemy player", ACTION_DEFAULT + 0.4f),
        new NextAction("tiger palm", ACTION_DEFAULT + 0.3f),
        new NextAction("jab", ACTION_DEFAULT + 0.2f),
        new NextAction("melee", ACTION_DEFAULT), nullptr);
}

void MistweaverMonkStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    CombatStrategy::InitTriggers(triggers);
    triggers.push_back(new TriggerNode("spear hand strike",
        NextAction::array(0, new NextAction("spear hand strike", ACTION_INTERRUPT), nullptr)));
    triggers.push_back(new TriggerNode("party member critical health",
        NextAction::array(0, new NextAction("life cocoon on party", ACTION_EMERGENCY + 4),
            new NextAction("surging mist on party", ACTION_CRITICAL_HEAL + 3),
            new NextAction("enveloping mist on party", ACTION_CRITICAL_HEAL + 2),
            new NextAction("soothing mist on party", ACTION_CRITICAL_HEAL + 1), nullptr)));
    triggers.push_back(new TriggerNode("party member low health",
        NextAction::array(0, new NextAction("enveloping mist on party", ACTION_MEDIUM_HEAL + 3),
            new NextAction("surging mist on party", ACTION_MEDIUM_HEAL + 2),
            new NextAction("soothing mist on party", ACTION_MEDIUM_HEAL + 1), nullptr)));
    triggers.push_back(new TriggerNode("party member medium health",
        NextAction::array(0, new NextAction("renewing mist on party", ACTION_LIGHT_HEAL + 2),
            new NextAction("soothing mist on party", ACTION_LIGHT_HEAL + 1), nullptr)));
    triggers.push_back(new TriggerNode("party member to heal out of spell range",
        NextAction::array(0, new NextAction("reach party member to heal", ACTION_CRITICAL_HEAL + 10), nullptr)));
    triggers.push_back(new TriggerNode("critical health",
        NextAction::array(0, new NextAction("fortifying brew", ACTION_EMERGENCY + 2),
            new NextAction("expel harm", ACTION_EMERGENCY + 1), nullptr)));
    triggers.push_back(new TriggerNode("low mana",
        NextAction::array(0, new NextAction("mana tea", ACTION_HIGH + 2), nullptr)));
}

void MonkCureStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    triggers.push_back(new TriggerNode("cure poison",
        NextAction::array(0, new NextAction("detox", ACTION_DISPEL + 2), nullptr)));
    triggers.push_back(new TriggerNode("party member cure poison",
        NextAction::array(0, new NextAction("detox poison on party", ACTION_DISPEL + 1), nullptr)));
    triggers.push_back(new TriggerNode("cure disease",
        NextAction::array(0, new NextAction("detox", ACTION_DISPEL + 2), nullptr)));
    triggers.push_back(new TriggerNode("party member cure disease",
        NextAction::array(0, new NextAction("detox disease on party", ACTION_DISPEL + 1), nullptr)));
    triggers.push_back(new TriggerNode("cure magic",
        NextAction::array(0, new NextAction("detox", ACTION_DISPEL + 2), nullptr)));
    triggers.push_back(new TriggerNode("party member cure magic",
        NextAction::array(0, new NextAction("detox magic on party", ACTION_DISPEL + 1), nullptr)));
}

void MonkNonCombatStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    NonCombatStrategy::InitTriggers(triggers);
    triggers.push_back(new TriggerNode("party member dead",
        NextAction::array(0, new NextAction("resuscitate", ACTION_CRITICAL_HEAL + 10), nullptr)));
    triggers.push_back(new TriggerNode("party member critical health",
        NextAction::array(0, new NextAction("surging mist on party", ACTION_CRITICAL_HEAL + 2),
            new NextAction("soothing mist on party", ACTION_CRITICAL_HEAL + 1), nullptr)));
    triggers.push_back(new TriggerNode("party member low health",
        NextAction::array(0, new NextAction("enveloping mist on party", ACTION_MEDIUM_HEAL + 2),
            new NextAction("soothing mist on party", ACTION_MEDIUM_HEAL + 1), nullptr)));
    triggers.push_back(new TriggerNode("legacy of the emperor on party",
        NextAction::array(0, new NextAction("legacy of the emperor on party", ACTION_NORMAL + 2), nullptr)));
    triggers.push_back(new TriggerNode("legacy of the white tiger on party",
        NextAction::array(0, new NextAction("legacy of the white tiger on party", ACTION_NORMAL + 1), nullptr)));
}
