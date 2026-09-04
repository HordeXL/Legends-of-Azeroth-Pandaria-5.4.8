/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "WarlockActions.h"

#include "Event.h"
#include "Playerbots.h"

namespace
{
bool IsPvPControlTarget(Player* bot, Unit* target)
{
    return bot && target && (bot->InBattleground() || bot->InArena()) &&
        target->GetCharmerOrOwnerPlayerOrPlayerItself();
}

bool IsPveInstanceTrash(Player* bot, Unit* target)
{
    if (!bot || !bot->GetMap() ||
        (!bot->GetMap()->IsDungeon() && !bot->GetMap()->IsRaid()) ||
        bot->InBattleground() || bot->InArena())
        return false;

    Creature* creature = target ? target->ToCreature() : nullptr;
    return !creature || (!creature->IsDungeonBoss() && !creature->isWorldBoss());
}
}

bool CastDarkSoulMiseryAction::isUseful()
{
    return !IsPveInstanceTrash(bot, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDarkSoulKnowledgeAction::isUseful()
{
    return !IsPveInstanceTrash(bot, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDarkSoulInstabilityAction::isUseful()
{
    return !IsPveInstanceTrash(bot, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastDrainSoulAction::isUseful() { /*return AI_VALUE2(uint32, "item count", "soul shard") < 10;*/ return std::rand() % 5 < 2; }

Value<Unit*>* CastBanishAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "banish"); }

bool CastBanishAction::Execute(Event event) { return botAI->CastSpell("banish", GetTarget()); }

Value<Unit*>* CastFearOnCcAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "fear"); }

bool CastFearOnCcAction::Execute(Event event) { return botAI->CastSpell("fear", GetTarget()); }

bool CastFearOnCcAction::isPossible()
{
    return IsPvPControlTarget(bot, GetTarget()) &&
        CastBuffSpellAction::isPossible();
}

bool CastFearOnCcAction::isUseful()
{
    return IsPvPControlTarget(bot, GetTarget()) &&
        CastBuffSpellAction::isUseful();
}

bool CastFearAction::isUseful()
{
    return IsPvPControlTarget(bot, GetTarget()) &&
        CastDebuffSpellAction::isUseful();
}

bool CastMortalCoilAction::isUseful()
{
    return IsPvPControlTarget(bot, GetTarget()) &&
        CastSpellAction::isUseful();
}

bool CastBloodHorrorAction::isUseful()
{
    return IsPvPControlTarget(bot, GetTarget()) &&
        CastSpellAction::isUseful();
}

bool CastLifeTapAction::isUseful() { return AI_VALUE2(uint8, "health", "self target") > sPlayerbotAIConfig->lowHealth; }

bool CastHandOfGuldanAction::Execute(Event event)
{
	return botAI->CastSpell(105174, GetTarget());
}

bool CastChaosBoltAction::isUseful()
{
	return botAI->HasAura("fire and brimstone", bot) || bot->GetPower(Powers::POWER_BURNING_EMBERS) >= 10;
}
bool CastIncinerateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(114654, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
bool CastImmolateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(108686, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
bool CastConflagrateAction::Execute(Event event)
{
	if (!isUseful() || !isPossible())
		return false;

	if (botAI->HasAura("fire and brimstone", bot))
		botAI->CastSpell(108685, GetTarget());
	else
		botAI->CastSpell(spell, GetTarget());

	return true;
}
