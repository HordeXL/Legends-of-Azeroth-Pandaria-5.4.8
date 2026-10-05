/*
 * Oculus playerbot strategy, adapted from mod-playerbots to the Pandaria
 * 5.4.8 playerbot and vehicle APIs.
 */

#include "OculusStrategy.h"

#include "Creature.h"
#include "Group.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"
#include "Vehicle.h"

namespace OculusBot
{
namespace
{
Position const UromSafePositions[] =
{
    { 1138.88f, 1052.22f, 508.36f, 0.0f },
    { 1084.62f, 1079.71f, 508.36f, 0.0f },
    { 1087.42f, 1020.13f, 508.36f, 0.0f }
};

uint32 EssenceSpell(uint32 itemId)
{
    switch (itemId)
    {
        case ITEM_AMBER_ESSENCE:   return SPELL_AMBER_ESSENCE;
        case ITEM_EMERALD_ESSENCE: return SPELL_EMERALD_ESSENCE;
        case ITEM_RUBY_ESSENCE:    return SPELL_RUBY_ESSENCE;
        default:                   return 0;
    }
}

uint32 AssignedEssence(Player* bot, Player* master)
{
    // Two amber, two emerald and one ruby is the upstream default.  Reserve
    // the real player's selected colour before assigning the bots in stable
    // group order.
    int8 remaining[] = { 2, 2, 1 };
    uint32 const items[] = { ITEM_AMBER_ESSENCE, ITEM_EMERALD_ESSENCE, ITEM_RUBY_ESSENCE };

    if (Unit* masterDrake = master ? master->GetVehicleBase() : nullptr)
    {
        if (masterDrake->GetEntry() == NPC_AMBER_DRAKE)
            --remaining[0];
        else if (masterDrake->GetEntry() == NPC_EMERALD_DRAKE)
            --remaining[1];
        else if (masterDrake->GetEntry() == NPC_RUBY_DRAKE)
            --remaining[2];
    }

    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group)
        group = bot->GetGroup();

    if (!group)
        return ITEM_AMBER_ESSENCE;

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || member == master || !GET_PLAYERBOT_AI(member))
            continue;

        uint32 assigned = ITEM_AMBER_ESSENCE;
        for (uint8 i = 0; i < 3; ++i)
        {
            if (remaining[i] > 0)
            {
                assigned = items[i];
                --remaining[i];
                break;
            }
        }

        if (member == bot)
            return assigned;
    }

    return ITEM_AMBER_ESSENCE;
}
}

bool IsDrake(Unit const* unit)
{
    if (!unit)
        return false;

    uint32 const entry = unit->GetEntry();
    return entry == NPC_AMBER_DRAKE || entry == NPC_EMERALD_DRAKE || entry == NPC_RUBY_DRAKE;
}

void OculusStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    triggers.push_back(new TriggerNode("oculus unstable sphere",
        NextAction::array(0, new NextAction("oculus avoid unstable sphere", ACTION_MOVE + 5), nullptr)));
    triggers.push_back(new TriggerNode("oculus drake mount",
        NextAction::array(0, new NextAction("oculus mount drake", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("oculus drake dismount",
        NextAction::array(0, new NextAction("oculus dismount drake", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("oculus drake fly",
        NextAction::array(0, new NextAction("oculus fly drake", ACTION_MOVE + 4), nullptr)));
    triggers.push_back(new TriggerNode("oculus drake combat",
        NextAction::array(0, new NextAction("oculus drake attack", ACTION_RAID + 4), nullptr)));
    triggers.push_back(new TriggerNode("oculus urom explosion",
        NextAction::array(0, new NextAction("oculus avoid urom explosion", ACTION_RAID + 5), nullptr)));
    triggers.push_back(new TriggerNode("oculus time bomb",
        NextAction::array(0, new NextAction("oculus spread time bomb", ACTION_MOVE + 6), nullptr)));
}

void OculusStrategy::InitMultipliers(std::vector<Multiplier*>& multipliers)
{
    multipliers.push_back(new OculusMultiplier(botAI));
}

bool UnstableSphereTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_OCULUS || PlayerBotSpec::IsTank(bot, true))
        return false;

    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
        if (Unit* unit = botAI->GetUnit(guid))
            if (unit->GetEntry() == NPC_UNSTABLE_SPHERE && bot->GetExactDist2d(unit) < 14.0f)
                return true;

    return false;
}

bool DrakeMountTrigger::IsActive()
{
    Player* master = GetMaster();
    return bot->GetMapId() == MAP_OCULUS && master && IsDrake(master->GetVehicleBase()) && !bot->GetVehicleBase();
}

bool DrakeDismountTrigger::IsActive()
{
    Player* master = GetMaster();
    return bot->GetMapId() == MAP_OCULUS && master && !IsDrake(master->GetVehicleBase()) && IsDrake(bot->GetVehicleBase());
}

bool DrakeFlyTrigger::IsActive()
{
    Player* master = GetMaster();
    return bot->GetMapId() == MAP_OCULUS && master && IsDrake(master->GetVehicleBase()) && IsDrake(bot->GetVehicleBase());
}

bool DrakeCombatTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_OCULUS || !IsDrake(bot->GetVehicleBase()))
        return false;

    if (Unit* target = AI_VALUE(Unit*, "current target"))
        if (target->IsAlive() && bot->IsValidAttackTarget(target))
            return true;

    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
        if (Unit* unit = botAI->GetUnit(guid))
            if (unit->IsAlive() && unit->IsInCombat())
                return true;

    return false;
}

bool UromExplosionTrigger::IsActive()
{
    if (bot->GetMapId() != MAP_OCULUS || bot->GetVehicleBase())
        return false;

    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
        if (Unit* unit = botAI->GetUnit(guid))
            if (unit->GetEntry() == NPC_MAGE_LORD_UROM &&
                (unit->FindCurrentSpellBySpellId(SPELL_UROM_EXPLOSION_NORMAL) ||
                 unit->FindCurrentSpellBySpellId(SPELL_UROM_EXPLOSION_HEROIC)))
                return true;

    return false;
}

bool UromTimeBombTrigger::IsActive()
{
    return bot->GetMapId() == MAP_OCULUS &&
        (bot->HasAura(SPELL_UROM_TIME_BOMB_NORMAL) || bot->HasAura(SPELL_UROM_TIME_BOMB_HEROIC));
}

bool AvoidUnstableSphereAction::Execute(Event /*event*/)
{
    Unit* nearest = nullptr;
    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
    {
        Unit* unit = botAI->GetUnit(guid);
        if (unit && unit->GetEntry() == NPC_UNSTABLE_SPHERE &&
            (!nearest || bot->GetExactDist2d(unit) < bot->GetExactDist2d(nearest)))
            nearest = unit;
    }

    return nearest && bot->GetExactDist2d(nearest) < 14.0f && MoveAway(nearest, 15.0f);
}

bool MountDrakeAction::isPossible()
{
    return bot->GetMapId() == MAP_OCULUS && !bot->GetVehicleBase();
}

bool MountDrakeAction::Execute(Event /*event*/)
{
    Player* master = GetMaster();
    if (!master || !IsDrake(master->GetVehicleBase()))
        return false;

    uint32 const assignedItem = AssignedEssence(bot, master);
    uint32 const allItems[] = { ITEM_AMBER_ESSENCE, ITEM_EMERALD_ESSENCE, ITEM_RUBY_ESSENCE };

    for (uint32 itemId : allItems)
    {
        if (itemId != assignedItem && bot->HasItemCount(itemId, 1))
            bot->DestroyItemCount(itemId, 1, true, false);
    }

    Item* essence = bot->GetItemByEntry(assignedItem);
    if (!essence)
    {
        bot->AddItem(assignedItem, 1);
        return false;
    }

    if (bot->CanUseItem(essence) != EQUIP_ERR_OK || bot->IsNonMeleeSpellCasted(true))
        return false;

    if (bot->isMoving())
    {
        bot->StopMoving();
        bot->GetMotionMaster()->Clear();
        return false;
    }

    uint32 const spellId = EssenceSpell(assignedItem);
    if (!spellId || bot->HasSpellCooldown(spellId))
        return false;

    bot->CastSpell(bot, spellId, false, essence);
    return true;
}

bool DismountDrakeAction::Execute(Event /*event*/)
{
    if (!bot->GetVehicle())
        return false;

    bot->ExitVehicle();
    return true;
}

bool FlyDrakeAction::Execute(Event /*event*/)
{
    Player* master = GetMaster();
    Unit* drake = bot->GetVehicleBase();
    Unit* masterDrake = master ? master->GetVehicleBase() : nullptr;
    if (!IsDrake(drake) || !IsDrake(masterDrake))
        return false;

    Unit* eregos = nullptr;
    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
        if (Unit* unit = botAI->GetUnit(guid))
            if (unit->GetEntry() == NPC_LEY_GUARDIAN_EREGOS && unit->IsAlive())
            {
                eregos = unit;
                break;
            }

    if (eregos && !eregos->HasAura(SPELL_EREGOS_PLANAR_SHIFT))
    {
        if (drake->GetExactDist(eregos) > 55.0f)
            return MoveTo(eregos, 50.0f, MovementPriority::MOVEMENT_FORCED);

        drake->SetFacingToObject(eregos);
        drake->GetMotionMaster()->MoveIdle();
        drake->SendMovementFlagUpdate();
        return true;
    }

    if (drake->GetExactDist(masterDrake) > 18.0f)
    {
        float const angle = float(bot->GetGUID().GetCounter() % 5) * (2.0f * M_PI / 5.0f);
        drake->SetCanFly(true);
        drake->GetMotionMaster()->MoveFollow(masterDrake, 14.0f, angle);
        drake->SendMovementFlagUpdate();
        return true;
    }

    return false;
}

Unit* DrakeAttackAction::SelectTarget()
{
    if (Unit* target = AI_VALUE(Unit*, "current target"))
        if (target->IsAlive() && bot->IsValidAttackTarget(target))
            return target;

    if (Player* master = GetMaster())
        if (Unit* target = master->GetSelectedUnit())
            if (target->IsAlive() && target->GetMap() == bot->GetMap() && bot->IsValidAttackTarget(target))
                return target;

    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "possible targets"))
        if (Unit* unit = botAI->GetUnit(guid))
            if (unit->IsAlive() && unit->IsInCombat() && bot->IsValidAttackTarget(unit))
                return unit;

    return nullptr;
}

bool DrakeAttackAction::Cast(Unit* caster, Unit* target, uint32 spellId)
{
    if (!caster || !target || caster->GetExactDist(target) > 60.0f ||
        !caster->IsWithinLOSInMap(target) || caster->HasUnitState(UNIT_STATE_CASTING))
        return false;

    if (Creature* creature = caster->ToCreature())
        if (creature->HasSpellCooldown(spellId))
            return false;

    caster->CastSpell(target, spellId, false);
    return true;
}

bool DrakeAttackAction::Amber(Unit* drake, Unit* target)
{
    Aura* charges = target->GetAura(SPELL_SHOCK_CHARGE, drake->GetGUID());
    if (charges && charges->GetStackAmount() >= 9)
        return Cast(drake, target, SPELL_SHOCK_LANCE);

    if (target->HasAura(SPELL_EREGOS_ENRAGED_ASSAULT) && !target->HasAura(SPELL_STOP_TIME))
        if (Cast(drake, target, SPELL_STOP_TIME))
            return true;

    if (!drake->FindCurrentSpellBySpellId(SPELL_TEMPORAL_RIFT))
        return Cast(drake, target, SPELL_TEMPORAL_RIFT);

    return false;
}

bool DrakeAttackAction::Emerald(Unit* drake, Unit* target)
{
    Aura* poison = target->GetAura(SPELL_LEECHING_POISON, drake->GetGUID());
    if (!poison || poison->GetStackAmount() < 3 || poison->GetDuration() < 4000)
        return Cast(drake, target, SPELL_LEECHING_POISON);

    if ((!target->HasAura(SPELL_TOUCH_THE_NIGHTMARE) || drake->HealthAbovePct(90)) &&
        Cast(drake, target, SPELL_TOUCH_THE_NIGHTMARE))
        return true;

    Unit* healTarget = nullptr;
    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "group members"))
    {
        Unit* member = botAI->GetUnit(guid);
        Unit* memberDrake = member ? member->GetVehicleBase() : nullptr;
        if (IsDrake(memberDrake) && !memberDrake->IsFullHealth() &&
            (!healTarget || memberDrake->GetHealthPct() < healTarget->GetHealthPct()))
            healTarget = memberDrake;
    }

    if (healTarget && Cast(drake, healTarget, SPELL_DREAM_FUNNEL))
        return true;

    return Cast(drake, target, SPELL_LEECHING_POISON);
}

bool DrakeAttackAction::Ruby(Unit* drake, Unit* target)
{
    Aura* charges = drake->GetAura(SPELL_EVASIVE_CHARGES);
    Aura* maneuvers = drake->GetAura(SPELL_EVASIVE_MANEUVERS);

    if (charges && maneuvers && maneuvers->GetDuration() > 10000 && charges->GetStackAmount() >= 5)
        if (Cast(drake, drake, SPELL_MARTYR))
            return true;

    if (charges && charges->GetStackAmount() >= 10)
        if (Cast(drake, drake, SPELL_EVASIVE_MANEUVERS))
            return true;

    return Cast(drake, target, SPELL_SEARING_WRATH);
}

bool DrakeAttackAction::Execute(Event /*event*/)
{
    Unit* drake = bot->GetVehicleBase();
    Unit* target = SelectTarget();
    if (!IsDrake(drake) || !target || target->HasAura(SPELL_EREGOS_PLANAR_SHIFT))
        return false;

    switch (drake->GetEntry())
    {
        case NPC_AMBER_DRAKE:   return Amber(drake, target);
        case NPC_EMERALD_DRAKE: return Emerald(drake, target);
        case NPC_RUBY_DRAKE:    return Ruby(drake, target);
        default:                return false;
    }
}

bool AvoidUromExplosionAction::Execute(Event /*event*/)
{
    Position const* closest = nullptr;
    for (Position const& position : UromSafePositions)
        if (!closest || bot->GetExactDist(position) < bot->GetExactDist(*closest))
            closest = &position;

    return closest && MoveNear(bot->GetMapId(), closest->GetPositionX(), closest->GetPositionY(),
        closest->GetPositionZ(), 2.0f, MovementPriority::MOVEMENT_FORCED);
}

bool SpreadTimeBombAction::Execute(Event /*event*/)
{
    for (ObjectGuid const& guid : AI_VALUE(GuidVector, "group members"))
    {
        if (guid == bot->GetGUID())
            continue;

        if (Unit* member = botAI->GetUnit(guid))
            if (bot->GetExactDist2d(member) < 12.0f)
                return MoveAway(member, 12.0f);
    }

    return false;
}

float OculusMultiplier::GetValue(Action* action)
{
    if (bot->GetMapId() != MAP_OCULUS)
        return 1.0f;

    Player* master = GetMaster();
    if (master && IsDrake(master->GetVehicleBase()) && !bot->GetVehicleBase())
        return dynamic_cast<MountDrakeAction*>(action) ? 1.0f : 0.0f;

    if (IsDrake(bot->GetVehicleBase()))
    {
        if (dynamic_cast<FlyDrakeAction*>(action) || dynamic_cast<DrakeAttackAction*>(action) ||
            dynamic_cast<DismountDrakeAction*>(action))
            return 1.0f;
        return 0.0f;
    }

    return 1.0f;
}

OculusTriggerContext::OculusTriggerContext()
{
    creators["oculus unstable sphere"] = [](PlayerbotAI* ai) -> Trigger* { return new UnstableSphereTrigger(ai); };
    creators["oculus drake mount"] = [](PlayerbotAI* ai) -> Trigger* { return new DrakeMountTrigger(ai); };
    creators["oculus drake dismount"] = [](PlayerbotAI* ai) -> Trigger* { return new DrakeDismountTrigger(ai); };
    creators["oculus drake fly"] = [](PlayerbotAI* ai) -> Trigger* { return new DrakeFlyTrigger(ai); };
    creators["oculus drake combat"] = [](PlayerbotAI* ai) -> Trigger* { return new DrakeCombatTrigger(ai); };
    creators["oculus urom explosion"] = [](PlayerbotAI* ai) -> Trigger* { return new UromExplosionTrigger(ai); };
    creators["oculus time bomb"] = [](PlayerbotAI* ai) -> Trigger* { return new UromTimeBombTrigger(ai); };
}

OculusActionContext::OculusActionContext()
{
    creators["oculus avoid unstable sphere"] = [](PlayerbotAI* ai) -> Action* { return new AvoidUnstableSphereAction(ai); };
    creators["oculus mount drake"] = [](PlayerbotAI* ai) -> Action* { return new MountDrakeAction(ai); };
    creators["oculus dismount drake"] = [](PlayerbotAI* ai) -> Action* { return new DismountDrakeAction(ai); };
    creators["oculus fly drake"] = [](PlayerbotAI* ai) -> Action* { return new FlyDrakeAction(ai); };
    creators["oculus drake attack"] = [](PlayerbotAI* ai) -> Action* { return new DrakeAttackAction(ai); };
    creators["oculus avoid urom explosion"] = [](PlayerbotAI* ai) -> Action* { return new AvoidUromExplosionAction(ai); };
    creators["oculus spread time bomb"] = [](PlayerbotAI* ai) -> Action* { return new SpreadTimeBombAction(ai); };
}
}
