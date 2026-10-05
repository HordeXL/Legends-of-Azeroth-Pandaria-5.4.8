/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "AiObjectContext.h"

#include "Helper.h"
#include "ActionContext.h"

#include "Playerbots.h"

#include "SharedValueContext.h"
#include "StrategyContext.h"
#include "TriggerContext.h"
#include "PveRotationTriggerContext.h"
#include "ValueContext.h"
#include "WorldPacketActionContext.h"
#include "WorldPacketTriggerContext.h"
#include "OculusStrategy.h"
#include "VortexPinnacleStrategy.h"
#include "raids/RaidStrategyContext.h"
#include "raids/aq20/RaidAq20ActionContext.h"
#include "raids/aq20/RaidAq20TriggerContext.h"
#include "raids/blackwinglair/RaidBwlActionContext.h"
#include "raids/blackwinglair/RaidBwlTriggerContext.h"
#include "raids/eyeofeternity/RaidEoEActionContext.h"
#include "raids/eyeofeternity/RaidEoETriggerContext.h"
#include "raids/gruulslair/RaidGruulsLairActionContext.h"
#include "raids/gruulslair/RaidGruulsLairTriggerContext.h"
#include "raids/icecrown/RaidIccActionContext.h"
#include "raids/icecrown/RaidIccTriggerContext.h"
#include "raids/karazhan/RaidKarazhanActionContext.h"
#include "raids/karazhan/RaidKarazhanTriggerContext.h"
#include "raids/magtheridon/RaidMagtheridonActionContext.h"
#include "raids/magtheridon/RaidMagtheridonTriggerContext.h"
#include "raids/moltencore/RaidMcActionContext.h"
#include "raids/moltencore/RaidMcTriggerContext.h"
#include "raids/naxxramas/NaxxActionContext.h"
#include "raids/naxxramas/NaxxTriggerContext.h"
#include "raids/rubysanctum/RSActionContext.h"
#include "raids/rubysanctum/RSTriggerContext.h"
#include "raids/obsidiansanctum/RaidOsActionContext.h"
#include "raids/obsidiansanctum/RaidOsTriggerContext.h"
#include "raids/onyxia/RaidOnyxiaActionContext.h"
#include "raids/onyxia/RaidOnyxiaTriggerContext.h"
#include "raids/ulduar/RaidUlduarActionContext.h"
#include "raids/ulduar/RaidUlduarTriggerContext.h"
#include "raids/vaultofarchavon/RaidVoAActionContext.h"
#include "raids/vaultofarchavon/RaidVoATriggerContext.h"


AiObjectContext::AiObjectContext(PlayerbotAI* botAI) : PlayerbotAIAware(botAI)
{
    strategyContexts.Add(new StrategyContext());
    strategyContexts.Add(new MovementStrategyContext());
    strategyContexts.Add(new AssistStrategyContext());
    strategyContexts.Add(new OculusBot::OculusStrategyContext());
    strategyContexts.Add(new VortexPinnacleBot::VortexPinnacleStrategyContext());
    strategyContexts.Add(new RaidStrategyContext());

    actionContexts.Add(new ActionContext());
    actionContexts.Add(new WorldPacketActionContext());
    actionContexts.Add(new OculusBot::OculusActionContext());
    actionContexts.Add(new VortexPinnacleBot::VortexPinnacleActionContext());
    actionContexts.Add(new RaidAq20ActionContext());
    actionContexts.Add(new RaidMcActionContext());
    actionContexts.Add(new RaidBwlActionContext());
    actionContexts.Add(new RaidKarazhanActionContext());
    actionContexts.Add(new RaidMagtheridonActionContext());
    actionContexts.Add(new RaidGruulsLairActionContext());
    actionContexts.Add(new RaidOsActionContext());
    actionContexts.Add(new RaidEoEActionContext());
    actionContexts.Add(new RaidVoAActionContext());
    actionContexts.Add(new RaidUlduarActionContext());
    actionContexts.Add(new RaidOnyxiaActionContext());
    actionContexts.Add(new RaidIccActionContext());
    actionContexts.Add(new RaidNaxxActionContext());
    actionContexts.Add(new RaidRsActionContext());

    triggerContexts.Add(new TriggerContext());
    triggerContexts.Add(new WorldPacketTriggerContext());
    triggerContexts.Add(new PveRotationTriggerContext());
    triggerContexts.Add(new OculusBot::OculusTriggerContext());
    triggerContexts.Add(new VortexPinnacleBot::VortexPinnacleTriggerContext());
    triggerContexts.Add(new RaidAq20TriggerContext());
    triggerContexts.Add(new RaidMcTriggerContext());
    triggerContexts.Add(new RaidBwlTriggerContext());
    triggerContexts.Add(new RaidKarazhanTriggerContext());
    triggerContexts.Add(new RaidMagtheridonTriggerContext());
    triggerContexts.Add(new RaidGruulsLairTriggerContext());
    triggerContexts.Add(new RaidOsTriggerContext());
    triggerContexts.Add(new RaidEoETriggerContext());
    triggerContexts.Add(new RaidVoATriggerContext());
    triggerContexts.Add(new RaidUlduarTriggerContext());
    triggerContexts.Add(new RaidOnyxiaTriggerContext());
    triggerContexts.Add(new RaidIccTriggerContext());
    triggerContexts.Add(new RaidNaxxTriggerContext());
    triggerContexts.Add(new RaidRsTriggerContext());

    valueContexts.Add(new ValueContext());
    valueContexts.Add(sSharedValueContext);
}

void AiObjectContext::Update()
{
    strategyContexts.Update();
    triggerContexts.Update();
    actionContexts.Update();
    valueContexts.Update();
}

void AiObjectContext::Reset()
{
    strategyContexts.Reset();
    triggerContexts.Reset();
    actionContexts.Reset();
    valueContexts.Reset();
}

std::vector<std::string> AiObjectContext::Save()
{
    std::vector<std::string> result;

    std::set<std::string> names = valueContexts.GetCreated();
    for (std::set<std::string>::iterator i = names.begin(); i != names.end(); ++i)
    {
        UntypedValue* value = GetUntypedValue(*i);
        if (!value)
            continue;

        std::string const data = value->Save();
        if (data == "?")
            continue;

        std::string const name = *i;
        std::ostringstream out;
        out << name;

        out << ">" << data;
        result.push_back(out.str());
    }

    return result;
}

void AiObjectContext::Load(std::vector<std::string> data)
{
    for (std::vector<std::string>::iterator i = data.begin(); i != data.end(); ++i)
    {
        std::string const row = *i;
        std::vector<std::string> parts = split(row, '>');
        if (parts.size() != 2)
            continue;

        std::string const name = parts[0];
        std::string const text = parts[1];

        UntypedValue* value = GetUntypedValue(name);
        if (!value)
            continue;

        value->Load(text);
    }
}

Strategy* AiObjectContext::GetStrategy(std::string const name)
{
    Strategy* strategy = strategyContexts.GetContextObject(name, botAI);
    return strategy;
}

std::set<std::string> AiObjectContext::GetSiblingStrategy(std::string const name)
{
    return strategyContexts.GetSiblings(name);
}

Trigger* AiObjectContext::GetTrigger(std::string const name)
{
    Trigger* trigger = triggerContexts.GetContextObject(name, botAI);
    return trigger;
}

Action* AiObjectContext::GetAction(std::string const name)
{
    Action* action = actionContexts.GetContextObject(name, botAI);
    return action;
}

UntypedValue* AiObjectContext::GetUntypedValue(std::string const name)
{
    return valueContexts.GetContextObject(name, botAI);
}

std::set<std::string> AiObjectContext::GetValues() { return valueContexts.GetCreated(); }

std::set<std::string> AiObjectContext::GetSupportedStrategies() { return strategyContexts.supports(); }

std::set<std::string> AiObjectContext::GetSupportedActions() { return actionContexts.supports(); }

std::string const AiObjectContext::FormatValues()
{
    std::ostringstream out;
    std::set<std::string> names = valueContexts.GetCreated();
    for (std::set<std::string>::iterator i = names.begin(); i != names.end(); ++i, out << "|")
    {
        UntypedValue* value = GetUntypedValue(*i);
        if (!value)
            continue;

        std::string const text = value->Format();
        if (text == "?")
            continue;

        out << "{" << *i << "=" << text << "}";
    }

    return out.str();
}

void AiObjectContext::AddShared(NamedObjectContext<UntypedValue>* sharedValues) { valueContexts.Add(sharedValues); }
