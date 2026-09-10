/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "DKActions.h"

#include "Duration.h"
#include "GenericSpellActions.h"
#include "Playerbots.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

bool CastPestilenceAction::isUseful()
{
    if (!botAI->IsGroupPveActivity()) return CastSpellAction::isUseful();
    Unit* target = GetTarget();
    if (!target) return false;
    bool const frost = target->HasAura(55095, bot->GetGUID());
    bool const blood = target->HasAura(55078, bot->GetGUID());
    if (!frost && !blood) return false;
    // AttackersValue stores GuidVector, not std::list<ObjectGuid>. The typed
    // context lookup returns null for a mismatched type.
    for (ObjectGuid guid : AI_VALUE(GuidVector, "attackers"))
        if (Unit* other = botAI->GetUnit(guid))
            if (other != target && other->IsAlive() && target->IsWithinDistInMap(other, 10.0f) &&
                ((frost && !other->HasAura(55095, bot->GetGUID())) ||
                 (blood && !other->HasAura(55078, bot->GetGUID()))))
                return CastSpellAction::isUseful();
    return false;
}

namespace
{
bool IsGroupPveTrash(PlayerbotAI* botAI, Unit* target)
{
    if (!botAI || !botAI->IsGroupPveActivity())
        return false;

    Creature* creature = target ? target->ToCreature() : nullptr;
    return !creature || (!creature->IsDungeonBoss() && !creature->isWorldBoss());
}
}

bool CastArmyOfTheDeadAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

bool CastSummonGargoyleAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastSpellAction::isUseful();
}

bool CastDarkTransformationAction::isUseful()
{
    if (bot->GetSpecialization() !=
        Specializations::SPEC_DEATH_KNIGHT_UNHOLY)
    {
        return false;
    }

    Unit* pet = GetTarget();
    Aura* playerStacks = bot->GetAura(91342);
    Aura* petStacks = pet ? pet->GetAura(91342) : nullptr;
    bool const ready = bot->HasAura(93426) ||
        (playerStacks && playerStacks->GetStackAmount() >= 5) ||
        (petStacks && petStacks->GetStackAmount() >= 5);
    return pet && pet->IsAlive() && ready && !pet->HasAura(63560) &&
        CastSpellAction::isUseful();
}

bool CastEmpowerRuneWeaponAction::isUseful()
{
    return !IsGroupPveTrash(botAI, AI_VALUE(Unit*, "current target")) &&
        CastBuffSpellAction::isUseful();
}

NextAction** CastDeathchillAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("frost presence"), nullptr),
                             CastSpellAction::getPrerequisites());
}

NextAction** CastUnholyMeleeSpellAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("unholy presence"), nullptr),
                             CastMeleeSpellAction::getPrerequisites());
}

NextAction** CastFrostMeleeSpellAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("frost presence"), nullptr),
                             CastMeleeSpellAction::getPrerequisites());
}

NextAction** CastBloodMeleeSpellAction::getPrerequisites()
{
    return NextAction::merge(NextAction::array(0, new NextAction("blood presence"), nullptr),
                             CastMeleeSpellAction::getPrerequisites());
}

bool CastRaiseDeadAction::Execute(Event event)
{
    bool result = CastBuffSpellAction::Execute(event);
    if (!result)
    {
        return false;
    }
    uint32 spellId = AI_VALUE2(uint32, "spell id", spell);
    // const SpellInfo *spellInfo = sSpellMgr->GetSpellInfo(spellId);
    bot->AddSpellCooldown(spellId, 0, 3 * 60 * 1000);
    return true;
}
