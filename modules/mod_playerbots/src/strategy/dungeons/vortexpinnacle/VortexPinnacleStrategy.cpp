/*
 * Playerbot strategy for The Vortex Pinnacle (normal and heroic).
 */

#include "VortexPinnacleStrategy.h"

#include "Creature.h"
#include "Playerbots.h"

namespace VortexPinnacleBot
{
namespace
{
Position const AsaadSafePosition = { -639.23f, 488.13f, 646.63f, 0.0f };

Creature* FindCreature(Player* bot, uint32 entry, float range)
{
    Creature* creature = bot->FindNearestCreature(entry, range, true);
    return creature && creature->IsAlive() ? creature : nullptr;
}

Creature* FindEngagedBoss(Player* bot, uint32 entry, float range = 120.0f)
{
    Creature* boss = FindCreature(bot, entry, range);
    return boss && boss->IsInCombat() ? boss : nullptr;
}

Unit* SelectPriorityTarget(PlayerbotAI* botAI)
{
    Player* bot = botAI->GetBot();
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE || !bot->IsInCombat() || !botAI->IsDps(bot))
        return nullptr;

    // Encounter adds first, then the dangerous healing/casting trash.  Only
    // select units already exposed as valid combat targets by the AI.
    uint32 const priority[] =
    {
        NPC_SKYFALL_STAR,
        NPC_TEMPLE_ADEPT,
        NPC_MINISTER_OF_AIR,
        NPC_YOUNG_STORM_DRAGON,
        NPC_HOWLING_GALE
    };

    GuidVector const& targets = botAI->GetAiObjectContext()->GetValue<GuidVector>("possible targets")->Get();
    for (uint32 entry : priority)
        for (ObjectGuid const& guid : targets)
            if (Unit* unit = botAI->GetUnit(guid))
                if (unit->GetEntry() == entry && unit->IsAlive() && bot->IsValidAttackTarget(unit) &&
                    bot->GetExactDist2d(unit) < 60.0f)
                    return unit;

    return nullptr;
}
}

void VortexPinnacleStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    triggers.push_back(new TriggerNode("vp asaad grounding field",
        NextAction::array(0, new NextAction("vp move to asaad grounding field", ACTION_MOVE + 10), nullptr)));
    triggers.push_back(new TriggerNode("vp asaad static cling",
        NextAction::array(0, new NextAction("vp jump static cling", ACTION_MOVE + 9), nullptr)));
    triggers.push_back(new TriggerNode("vp avoid twister",
        NextAction::array(0, new NextAction("vp avoid twister", ACTION_MOVE + 8), nullptr)));
    triggers.push_back(new TriggerNode("vp ertan safe ring",
        NextAction::array(0, new NextAction("vp move inside ertan ring", ACTION_MOVE + 7), nullptr)));
    triggers.push_back(new TriggerNode("vp altairus upwind",
        NextAction::array(0, new NextAction("vp face altairus wind", ACTION_MOVE + 6), nullptr)));
    triggers.push_back(new TriggerNode("vp face lurking tempest",
        NextAction::array(0, new NextAction("vp face lurking tempest", ACTION_MOVE + 6), nullptr)));
    triggers.push_back(new TriggerNode("vp priority target",
        NextAction::array(0, new NextAction("vp attack priority target", ACTION_RAID + 5), nullptr)));
}

void VortexPinnacleStrategy::InitMultipliers(std::vector<Multiplier*>& multipliers)
{
    multipliers.push_back(new VortexPinnacleMultiplier(botAI));
}

bool ErtanSafeRingTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE)
        return false;

    Creature* ertan = FindEngagedBoss(bot, NPC_GRAND_VIZIER_ERTAN);
    return ertan && bot->GetExactDist2d(ertan) > 18.0f;
}

bool LurkingTempestTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE || !bot->IsInCombat())
        return false;

    Creature* tempest = FindCreature(bot, NPC_LURKING_TEMPEST, 40.0f);
    return tempest && !bot->isInFront(tempest, 2.5f);
}

bool AltairusUpwindTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE || !FindEngagedBoss(bot, NPC_ALTAIRUS))
        return false;

    return FindCreature(bot, NPC_AIR_CURRENT, 120.0f) &&
        (!bot->HasAura(SPELL_UPWIND_OF_ALTAIRUS) || bot->HasAura(SPELL_DOWNWIND_OF_ALTAIRUS));
}

bool AltairusTwisterTrigger::IsActive()
{
    return bot->GetMapId() == MAP_VORTEX_PINNACLE && FindEngagedBoss(bot, NPC_ALTAIRUS) &&
        FindCreature(bot, NPC_TWISTER, 9.0f);
}

bool AsaadGroundingFieldTrigger::IsActive()
{
    return bot->GetMapId() == MAP_VORTEX_PINNACLE && FindEngagedBoss(bot, NPC_ASAAD) &&
        FindCreature(bot, NPC_UNSTABLE_GROUNDING_FIELD, 150.0f);
}

bool AsaadStaticClingTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE)
        return false;

    Creature* asaad = FindEngagedBoss(bot, NPC_ASAAD);
    return asaad && asaad->FindCurrentSpellBySpellId(SPELL_STATIC_CLING);
}

bool PriorityTargetTrigger::IsActive()
{
    Unit* priority = SelectPriorityTarget(botAI);
    return priority && priority != AI_VALUE(Unit*, "current target");
}

bool MoveInsideErtanRingAction::Execute(Event /*event*/)
{
    Creature* ertan = FindEngagedBoss(bot, NPC_GRAND_VIZIER_ERTAN);
    return ertan && MoveTo(ertan, 14.0f, MovementPriority::MOVEMENT_FORCED);
}

bool FaceLurkingTempestAction::Execute(Event /*event*/)
{
    Creature* tempest = FindCreature(bot, NPC_LURKING_TEMPEST, 40.0f);
    if (!tempest || bot->isInFront(tempest, 2.5f))
        return false;

    bot->SetFacingToObject(tempest);
    bot->SendMovementFlagUpdate();
    return true;
}

bool FaceAltairusWindAction::Execute(Event /*event*/)
{
    Creature* current = FindCreature(bot, NPC_AIR_CURRENT, 120.0f);
    if (!current)
        return false;

    // The encounter script considers players facing opposite the air-current
    // creature to be upwind.
    bot->SetFacingTo(Position::NormalizeOrientation(current->GetOrientation() + float(M_PI)));
    bot->SendMovementFlagUpdate();
    return true;
}

bool AvoidAltairusTwisterAction::Execute(Event /*event*/)
{
    Creature* twister = FindCreature(bot, NPC_TWISTER, 12.0f);
    return twister && bot->GetExactDist2d(twister) < 9.0f && MoveAway(twister, 13.0f);
}

bool MoveToAsaadGroundingFieldAction::Execute(Event /*event*/)
{
    if (!FindCreature(bot, NPC_UNSTABLE_GROUNDING_FIELD, 150.0f))
        return false;

    if (bot->GetExactDist2d(AsaadSafePosition) <= 2.5f)
    {
        if (bot->isMoving())
        {
            bot->StopMoving();
            bot->GetMotionMaster()->Clear();
        }
        return false;
    }

    return MoveTo(bot->GetMapId(), AsaadSafePosition.GetPositionX(), AsaadSafePosition.GetPositionY(),
        AsaadSafePosition.GetPositionZ(), false, false, false, true,
        MovementPriority::MOVEMENT_FORCED, true);
}

bool JumpStaticClingAction::Execute(Event /*event*/)
{
    float const distance = 2.0f;
    float const x = bot->GetPositionX() + std::cos(bot->GetOrientation()) * distance;
    float const y = bot->GetPositionY() + std::sin(bot->GetOrientation()) * distance;
    return JumpTo(bot->GetMapId(), x, y, bot->GetPositionZ(), MovementPriority::MOVEMENT_FORCED);
}

bool AttackPriorityTargetAction::Execute(Event /*event*/)
{
    Unit* target = SelectPriorityTarget(botAI);
    return target && Attack(target);
}

float VortexPinnacleMultiplier::GetValue(Action* action)
{
    if (bot->GetMapId() != MAP_VORTEX_PINNACLE ||
        !FindCreature(bot, NPC_UNSTABLE_GROUNDING_FIELD, 150.0f))
        return 1.0f;

    // Once Asaad begins drawing the grounding triangle, keep every role in
    // its safe centre.  Healing and other stationary spell actions remain
    // available, while generic follow/chase/attack movement cannot pull bots
    // back out before Supremacy of the Storm lands.
    if (dynamic_cast<MoveToAsaadGroundingFieldAction*>(action))
        return 1.0f;

    return dynamic_cast<MovementAction*>(action) ? 0.0f : 1.0f;
}

VortexPinnacleTriggerContext::VortexPinnacleTriggerContext()
{
    creators["vp ertan safe ring"] = [](PlayerbotAI* ai) -> Trigger* { return new ErtanSafeRingTrigger(ai); };
    creators["vp face lurking tempest"] = [](PlayerbotAI* ai) -> Trigger* { return new LurkingTempestTrigger(ai); };
    creators["vp altairus upwind"] = [](PlayerbotAI* ai) -> Trigger* { return new AltairusUpwindTrigger(ai); };
    creators["vp avoid twister"] = [](PlayerbotAI* ai) -> Trigger* { return new AltairusTwisterTrigger(ai); };
    creators["vp asaad grounding field"] = [](PlayerbotAI* ai) -> Trigger* { return new AsaadGroundingFieldTrigger(ai); };
    creators["vp asaad static cling"] = [](PlayerbotAI* ai) -> Trigger* { return new AsaadStaticClingTrigger(ai); };
    creators["vp priority target"] = [](PlayerbotAI* ai) -> Trigger* { return new PriorityTargetTrigger(ai); };
}

VortexPinnacleActionContext::VortexPinnacleActionContext()
{
    creators["vp move inside ertan ring"] = [](PlayerbotAI* ai) -> Action* { return new MoveInsideErtanRingAction(ai); };
    creators["vp face lurking tempest"] = [](PlayerbotAI* ai) -> Action* { return new FaceLurkingTempestAction(ai); };
    creators["vp face altairus wind"] = [](PlayerbotAI* ai) -> Action* { return new FaceAltairusWindAction(ai); };
    creators["vp avoid twister"] = [](PlayerbotAI* ai) -> Action* { return new AvoidAltairusTwisterAction(ai); };
    creators["vp move to asaad grounding field"] = [](PlayerbotAI* ai) -> Action* { return new MoveToAsaadGroundingFieldAction(ai); };
    creators["vp jump static cling"] = [](PlayerbotAI* ai) -> Action* { return new JumpStaticClingAction(ai); };
    creators["vp attack priority target"] = [](PlayerbotAI* ai) -> Action* { return new AttackPriorityTargetAction(ai); };
}
}
