#include "AhnQirajStrategy.h"
#include "FollowActions.h"

#include <cstddef>
#include <cmath>

#include "Event.h"
#include "Formations.h"
#include "GroupFollowFormation.h"
#include "PlayerbotSpec.h"
#include "LastMovementValue.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ServerFacade.h"
#include "SharedDefines.h"

bool FollowAction::UseGroupFollowFormation()
{
    Player* master = GetMaster();
    return master && master != bot && bot->GetGroup() &&
        master->GetGroup() == bot->GetGroup() && master->IsInWorld() &&
        master->GetMap() == bot->GetMap() && master->IsAlive() && bot->IsAlive() &&
        !bot->InBattleground() && !master->IsInCombat() && !bot->IsInCombat() &&
        botAI->GetState() == BOT_STATE_NON_COMBAT;
}

WorldLocation FollowAction::GetGroupFollowLocation()
{
    Player* master = GetMaster();
    bool const tank = PlayerBotSpec::IsTank(bot, true);
    std::size_t slot = 0;
    for (GroupReference* ref = bot->GetGroup()->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member != master && member->IsInWorld() && member->IsAlive() &&
            member->GetMap() == bot->GetMap() &&
            PlayerBotSpec::IsTank(member, true) == tank && member->GetGUID() < bot->GetGUID())
            ++slot;
    }

    auto const offset = GroupFollowFormation::GetOffset(tank, slot);
    float const orientation = master->GetOrientation();
    // Narrow the formation if a wall blocks a slot; never use unchecked coordinates.
    for (float scale : {1.0f, 0.5f, 0.25f})
    {
        float x = master->GetPositionX() + scale *
            (std::cos(orientation) * offset.forward - std::sin(orientation) * offset.sideways);
        float y = master->GetPositionY() + scale *
            (std::sin(orientation) * offset.forward + std::cos(orientation) * offset.sideways);
        float z = master->GetPositionZ();
        if (master->GetMap()->CheckCollisionAndGetValidCoords(master,
            master->GetPositionX(), master->GetPositionY(), master->GetPositionZ(), x, y, z))
            return WorldLocation(master->GetMapId(), x, y, z);
    }
    return WorldLocation(master->GetMapId(), master->GetPositionX(),
        master->GetPositionY(), master->GetPositionZ());
}

bool FollowAction::Execute(Event event)
{
    if (AhnQirajStrategy::IsActive(bot)) return false;
    if (bot->HasWorldBossStagingAccess() &&
        !bot->IsWorldBossStagingCleanup() &&
        !bot->IsWorldBossStagingEncounterStarted())
    {
        Player* master = GetMaster();
        if (!master || !master->IsInWorld() ||
            master->GetMap() != bot->GetMap() || !CanDeadFollow(master) ||
            bot->GetDistance(master) <= 4.0f ||
            bot->IsNonMeleeSpellCasted(true, false, true))
            return false;

        // All pre-pull bots share one compact point behind the requester.
        // This avoids the roster-wide angular formation and remains still
        // while the requester is standing and the raid is buffing.
        return Follow(master, 2.0f, static_cast<float>(M_PI));
    }

    if (UseGroupFollowFormation())
    {
        if (GetMaster()->HasUnitState(UNIT_STATE_IN_FLIGHT) ||
            bot->IsNonMeleeSpellCasted(true, false, true) ||
            botAI->HasStrategy("move from group", BOT_STATE_NON_COMBAT))
            return false;

        WorldLocation const loc = GetGroupFollowLocation();
        if (bot->GetExactDist2d(loc.GetPositionX(), loc.GetPositionY()) <= 1.0f)
            return false;
        return MoveTo(loc.GetMapId(), loc.GetPositionX(), loc.GetPositionY(),
            loc.GetPositionZ(), false, false, true, false, MovementPriority::MOVEMENT_NORMAL, true);
    }

    if (botAI->IsLfgAutoQueueControlled() && botAI->IsGroupPveActivity())
    {
        Player* master = GetMaster();
        if (!master || !master->IsInWorld() ||
            master->GetMap() != bot->GetMap() || !CanDeadFollow(master))
            return false;

        // No Chaos/Circle/Arrow offsets in a managed instance. A stationary
        // requester must not make followers rotate into an untouched pack.
        // Stay close outside combat, but allow enough room to reach a ranged
        // requester's enemy without the follow action pulling us back.
        float const followRadius = botAI->GetState() == BOT_STATE_COMBAT ?
            60.0f : 4.0f;
        if (bot->GetDistance(master) <= followRadius ||
            bot->IsNonMeleeSpellCasted(true, false, true))
            return false;
        return Follow(master, 2.0f, static_cast<float>(M_PI));
    }

    Formation* formation = AI_VALUE(Formation*, "formation");
    std::string const target = formation->GetTargetName();

    bool moved = false;
    if (!target.empty())
    {
        moved = Follow(AI_VALUE(Unit*, target));
    }
    else
    {
        WorldLocation loc = formation->GetLocation();
        if (Formation::IsNullLocation(loc) || loc.GetMapId() == -1)
            return false;

        MovementPriority priority = botAI->GetState() == BOT_STATE_COMBAT ? MovementPriority::MOVEMENT_COMBAT : MovementPriority::MOVEMENT_NORMAL;
        moved = MoveTo(loc.GetMapId(), loc.GetPositionX(), loc.GetPositionY(), loc.GetPositionZ(), false, false, false,
            true, priority, true);
    }

    if (Pet* pet = bot->GetPet())
    {
        //botAI->PetFollow();
    }

    return moved;
}

bool FollowAction::isUseful()
{
    if (AhnQirajStrategy::IsActive(bot)) return false;
    if (bot->HasWorldBossStagingAccess() &&
        !bot->IsWorldBossStagingCleanup() &&
        !bot->IsWorldBossStagingEncounterStarted())
    {
        Player* master = GetMaster();
        return master && master != bot && master->IsInWorld() &&
            master->GetMap() == bot->GetMap() && CanDeadFollow(master) &&
            !master->HasUnitState(UNIT_STATE_IN_FLIGHT) &&
            !bot->IsNonMeleeSpellCasted(true, false, true) &&
            bot->GetDistance(master) > 4.0f;
    }

    if (UseGroupFollowFormation())
    {
        if (GetMaster()->HasUnitState(UNIT_STATE_IN_FLIGHT) ||
            bot->IsNonMeleeSpellCasted(true, false, true) ||
            botAI->HasStrategy("move from group", BOT_STATE_NON_COMBAT))
            return false;

        WorldLocation const loc = GetGroupFollowLocation();
        return bot->GetExactDist2d(loc.GetPositionX(), loc.GetPositionY()) > 1.0f;
    }

    if (botAI->IsLfgAutoQueueControlled() && botAI->IsGroupPveActivity())
    {
        Player* master = GetMaster();
        // Combat positioning/healing owns normal in-fight movement. Do not
        // oscillate between ranged formation and a two-yard follow point.
        float const followRadius = botAI->GetState() == BOT_STATE_COMBAT ?
            60.0f : 4.0f;
        return master && master != bot && master->IsInWorld() &&
            master->GetMap() == bot->GetMap() && CanDeadFollow(master) &&
            !master->HasUnitState(UNIT_STATE_IN_FLIGHT) &&
            !bot->IsNonMeleeSpellCasted(true, false, true) &&
            bot->GetDistance(master) > followRadius;
    }

    // move from group takes priority over follow as it's added and removed automatically
    // (without removing/adding follow)
    if (botAI->HasStrategy("move from group", BOT_STATE_COMBAT) ||
        botAI->HasStrategy("move from group", BOT_STATE_NON_COMBAT))
        return false;

    if (bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr)
        return false;

    Formation* formation = AI_VALUE(Formation*, "formation");
    if (!formation)
        return false;

    std::string const target = formation->GetTargetName();

    Unit* fTarget = nullptr;
    if (!target.empty())
        fTarget = AI_VALUE(Unit*, target);
    else
        fTarget = AI_VALUE(Unit*, "master target");

    if (fTarget)
    {
        if (fTarget->HasUnitState(UNIT_STATE_IN_FLIGHT))
            return false;

        if (!CanDeadFollow(fTarget))
            return false;

        if (fTarget->GetGUID() == bot->GetGUID())
            return false;
    }

    float distance = 0.f;
    if (!target.empty())
    {
        distance = AI_VALUE2(float, "distance", target);
    }
    else
    {
        WorldLocation loc = formation->GetLocation();
        if (Formation::IsNullLocation(loc) || bot->GetMapId() != loc.GetMapId())
            return false;

        distance = bot->GetDistance(loc.GetPositionX(), loc.GetPositionY(), loc.GetPositionZ());
    }

    return sServerFacade->IsDistanceGreaterThan(distance, formation->GetMaxDistance());
}

bool FollowAction::CanDeadFollow(Unit* target)
{
    // Move to corpse when dead and player is alive or not a ghost.
    if (!bot->IsAlive() && (target->IsAlive() || !target->HasFlag(PLAYER_FIELD_PLAYER_FLAGS, PLAYER_FLAGS_GHOST)))
        return false;

    return true;
}

bool FleeToMasterAction::Execute(Event event)
{
    Unit* fTarget = AI_VALUE(Unit*, "master target");
    bool canFollow = Follow(fTarget);
    if (!canFollow)
    {
        // botAI->SetNextCheckDelay(5000);
        return false;
    }

    WorldPosition targetPos(fTarget);
    WorldPosition bosPos(bot);
    float distance = bosPos.fDist(targetPos);

    if (distance < sPlayerbotAIConfig->reactDistance * 3)
    {
        if (!urand(0, 3))
            botAI->TellMaster("I am close, wait for me!");
    }
    else if (distance < 1000)
    {
        if (!urand(0, 10))
            botAI->TellMaster("I heading to your position.");
    }
    else if (!urand(0, 20))
        botAI->TellMaster("I am traveling to your position.");

    botAI->SetNextCheckDelay(3000);

    return true;
}

bool FleeToMasterAction::isUseful()
{
    if (!botAI->GetGroupMaster())
        return false;

    if (botAI->GetGroupMaster() == bot)
        return false;

    Unit* target = AI_VALUE(Unit*, "current target");
    if (target && botAI->GetGroupMaster()->GetTarget() == target->GetGUID())
        return false;

    if (!botAI->HasStrategy("follow", BOT_STATE_NON_COMBAT))
        return false;

    Unit* fTarget = AI_VALUE(Unit*, "master target");

    if (!CanDeadFollow(fTarget))
        return false;

    return true;
}
