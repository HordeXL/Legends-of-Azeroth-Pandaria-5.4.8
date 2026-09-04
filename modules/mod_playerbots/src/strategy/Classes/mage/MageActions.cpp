/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "MageActions.h"

#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"
#include "ServerFacade.h"
#include "SharedDefines.h"

Value<Unit*>* CastPolymorphAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", getName()); }

namespace
{
bool IsPveInstance(Player* bot)
{
    return bot && bot->GetMap() &&
        (bot->GetMap()->IsDungeon() || bot->GetMap()->IsRaid()) &&
        !bot->InBattleground() && !bot->InArena();
}

bool IsPveInstanceTrash(Player* bot, Unit* target)
{
    if (!IsPveInstance(bot))
        return false;

    Creature* creature = target ? target->ToCreature() : nullptr;
    return !creature || (!creature->IsDungeonBoss() && !creature->isWorldBoss());
}
}

bool CastIcyVeinsAction::isUseful()
{
    return !IsPveInstanceTrash(bot, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastCombustionAction::isUseful()
{
    return !IsPveInstanceTrash(bot, GetTarget()) &&
        CastDebuffSpellAction::isUseful();
}

bool CastArcanePowerAction::isUseful()
{
    return !IsPveInstanceTrash(bot, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastFrostNovaAction::isUseful()
{
    if (IsPveInstance(bot))
        return false;

    Unit* target = AI_VALUE(Unit*, "current target");
    return sServerFacade->IsDistanceLessOrEqualThan(AI_VALUE2(float, "distance", GetTargetName()), 10.f);
}

bool CastBlinkAction::isUseful()
{
    if (IsPveInstance(bot))
        return false;

    Unit* target = AI_VALUE(Unit*, "current target");
    return sServerFacade->IsDistanceLessOrEqualThan(AI_VALUE2(float, "distance", GetTargetName()), 5.0f);
}

bool CastSlowAction::isUseful()
{
    if (IsPveInstance(bot))
        return false;

    Unit* target = AI_VALUE(Unit*, "current target");
    return sServerFacade->IsDistanceLessOrEqualThan(AI_VALUE2(float, "distance", GetTargetName()), 25.0f);
}

bool CastFrostjawAction::isUseful()
{
    return !IsPveInstance(bot) && CastSpellAction::isUseful();
}
bool CastDeepFreezeAction::isUseful()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target) return false;

    return !botAI->HasAura("deep freeze", target);
}
bool CastConeOfColdAction::isUseful()
{
    bool facingTarget = AI_VALUE2(bool, "facing", "current target");
    bool targetClose = sServerFacade->IsDistanceLessOrEqualThan(AI_VALUE2(float, "distance", GetTargetName()), 10.f);
    return facingTarget && targetClose;
}

bool CastFrozenOrbAction::isUseful()
{
    bool facingTarget = AI_VALUE2(bool, "facing", "current target");
    bool targetClose = sServerFacade->IsDistanceLessOrEqualThan(AI_VALUE2(float, "distance", GetTargetName()), 10.f);
    return facingTarget && targetClose;
}

bool CastDragonsBreathAction::isUseful()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;
    bool facingTarget = AI_VALUE2(bool, "facing", "current target");
    bool targetClose = bot->IsWithinCombatRange(target, 10.0f);
    return facingTarget && targetClose;
}

bool CastBlastWaveAction::isUseful()
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;
    bool targetClose = bot->IsWithinCombatRange(target, 10.0f);
    return targetClose;
}

Unit* CastFocusMagicOnPartyAction::GetTarget()
{
    Group* group = bot->GetGroup();
    if (!group)
        return nullptr;

    Unit* casterDps = nullptr;
    Unit* healer = nullptr;
    Unit* target = nullptr;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || member == bot || !member->IsAlive())
            continue;
        
        if (member->GetMap() != bot->GetMap() || bot->GetDistance(member) > sPlayerbotAIConfig->spellDistance)
            continue;

        if (member->HasAura(54646))
            continue;

        if (member->GetClass() == CLASS_MAGE)
            return member;

        if (!casterDps && PlayerBotSpec::IsCaster(member) && PlayerBotSpec::IsDps(member))
            casterDps = member;
        
        if (!healer && PlayerBotSpec::IsHeal(member))
            healer = member;

        if (!target)
            target = member;
    }
    
    if (casterDps)
        return casterDps;

    if (healer)
        return healer;

    return target;
}

bool CastRuneOfPowerAction::Execute(Event event)
{
    return botAI->CastSpell(spell, bot);
}
