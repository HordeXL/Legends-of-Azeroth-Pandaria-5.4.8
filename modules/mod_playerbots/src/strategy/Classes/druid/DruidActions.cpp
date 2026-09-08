/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "DruidActions.h"

#include "Event.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"

bool DruidPartyHealAction::IsRoleAllowed()
{
    if (!botAI->IsGroupPveActivity() ||
        (bot->GetSpecialization() != SPEC_DRUID_BALANCE &&
         bot->GetSpecialization() != SPEC_DRUID_FERAL))
        return true;

    Unit* target = GetTarget();
    if (!target || !target->IsAlive() || !target->IsInWorld() ||
        !target->IsInCombat() || target->GetHealthPct() >= 20.0f ||
        target->GetMap() != bot->GetMap())
        return false;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group) group = bot->GetGroup();
    if (!group || !group->IsMember(target->GetGUID()))
        return false;

    // A living healer in the active map retains responsibility for healing.
    // Only rescue a critically injured party member when no such healer exists.
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member->IsAlive() && member->IsInWorld() &&
            member->GetMap() == bot->GetMap() && PlayerBotSpec::IsHeal(member, true))
            return false;
    }
    return true;
}

bool DruidPartyHealAction::isUseful()
{
    // Checked before caster-form prerequisites are queued by the engine.
    return IsRoleAllowed() && HealPartyMemberAction::isUseful();
}

bool DruidPartyHealAction::Execute(Event event)
{
    // Health, specialization and healer availability can change while queued.
    return IsRoleAllowed() && HealPartyMemberAction::Execute(event);
}

std::string const CastStarfallAction::GetTargetName()
{
    return botAI->IsGroupPveActivity() ? "self target" : "current target";
}

bool CastStarfallAction::isUseful()
{
    return (!botAI->IsGroupPveActivity() || (bot->IsInCombat() && !bot->HasAura(48505))) &&
        CastSpellAction::isUseful();
}

NextAction** CastAbolishPoisonAction::getAlternatives()
{
    return NextAction::merge(NextAction::array(0, new NextAction("cure poison"), nullptr),
                             CastSpellAction::getPrerequisites());
}

NextAction** CastAbolishPoisonOnPartyAction::getAlternatives()
{
    return NextAction::merge(NextAction::array(0, new NextAction("cure poison on party"), nullptr),
                             CastSpellAction::getPrerequisites());
}

Value<Unit*>* CastEntanglingRootsCcAction::GetTargetValue()
{
    return context->GetValue<Unit*>("cc target", "entangling roots");
}

bool CastEntanglingRootsCcAction::Execute(Event event) { return botAI->CastSpell("entangling roots", GetTarget()); }

Value<Unit*>* CastHibernateCcAction::GetTargetValue() { return context->GetValue<Unit*>("cc target", "hibernate"); }

bool CastHibernateCcAction::Execute(Event event) { return botAI->CastSpell("hibernate", GetTarget()); }

NextAction** CastReviveAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("caster form"), nullptr),
                             ResurrectPartyMemberAction::getPrerequisites());
}

NextAction** CastRebirthAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("caster form"), nullptr),
                             ResurrectPartyMemberAction::getPrerequisites());
}

bool CastRebirthAction::isUseful()
{
    return CastSpellAction::isUseful() &&
           AI_VALUE2(float, "distance", GetTargetName()) <= sPlayerbotAIConfig->spellDistance;
}

Unit* CastRejuvenationOnNotFullAction::GetTarget()
{
    Group* group = bot->GetGroup();
    MinValueCalculator calc(100);
    for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    {
        Player* player = gref->GetSource();
        if (!player)
            continue;
        if (player->isDead() || player->IsFullHealth())
        {
            continue;
        }
        if (player->GetDistance2d(bot) > sPlayerbotAIConfig->spellDistance)
        {
            continue;
        }
        if (botAI->HasAura("rejuvenation", player))
        {
            continue;
        }
        calc.probe(player->GetHealthPct(), player);
    }
    return (Unit*)calc.param;
}

bool CastRejuvenationOnNotFullAction::isUseful()
{
    return IsRoleAllowed() && GetTarget();
}
