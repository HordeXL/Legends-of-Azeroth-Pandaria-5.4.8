/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "MovementActions.h"

#include <cfloat>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <string>
#include <algorithm>

#include "Event.h"
#include "PositionValue.h"
#include "G3D/Vector3.h"
#include "GameObject.h"
#include "AreaTrigger.h"
#include "DynamicObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "LastMovementValue.h"
#include "Map.h"
#include "ManaTideCoordination.h"
#include "MotionMaster.h"
#include "MoveSplineInitArgs.h"
#include "MovementGenerator.h"
#include "ObjectDefines.h"
#include "ObjectGuid.h"
#include "PathGenerator.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"
#include "Position.h"

#include "Random.h"
#include "ServerFacade.h"
#include "SharedDefines.h"
#include "SpellAuraEffects.h"
#include "Spell.h"
#include "SpellInfo.h"

#include "TargetedMovementGenerator.h"
#include "Timer.h"
#include "Transport.h"
#include "Unit.h"
#include "Vehicle.h"
#include "WaypointMovementGenerator.h"
#include "Corpse.h"
#include "Battleground.h"
#include "BattlegroundAB.h"
#include "BattlegroundAV.h"
#include "BattlegroundBFG.h"
#include "BattlegroundDG.h"
#include "BattlegroundEY.h"
#include "BattlegroundIC.h"
#include "BattlegroundSA.h"
#include "BattlegroundSM.h"
#include "BattlegroundTOK.h"
#include "BattlegroundTP.h"
#include "BattlegroundWS.h"
#include "ObjectAccessor.h"

MovementAction::MovementAction(PlayerbotAI* botAI, std::string const name) : Action(botAI, name)
{
    bot = botAI->GetBot();
}

void MovementAction::ClearIdleState()
{
    context->GetValue<time_t>("stay time")->Set(0);
    context->GetValue<PositionMap&>("position")->Get()["random"].Reset();
}

void MovementAction::WaitForReach(float distance)
{
    float delay = 1000.0f * MoveDelay(distance);

    if (delay > sPlayerbotAIConfig->maxWaitForMove)
        delay = sPlayerbotAIConfig->maxWaitForMove;

    Unit* target = *botAI->GetAiObjectContext()->GetValue<Unit*>("current target");
    Unit* player = *botAI->GetAiObjectContext()->GetValue<Unit*>("enemy player target");
    if ((player || target) && delay > sPlayerbotAIConfig->globalCoolDown)
        delay = sPlayerbotAIConfig->globalCoolDown;

    if (delay < 0)
        delay = 0;

    botAI->SetNextCheckDelay((uint32)delay);
}

void MovementAction::UpdateMovementState()
{
    auto botInLiquidState = bot->GetLiquidStatus();

    if ((botInLiquidState & LIQUID_MAP_IN_WATER) || (botInLiquidState & LIQUID_MAP_UNDER_WATER))
    {
        bot->SetSwim(true);
    }
    else
    {
        bot->SetSwim(false);
    }

    bool onGround = bot->GetPositionZ() < bot->GetMapWaterOrGroundLevel(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ()) + 1.0f;

    // Keep bot->SendMovementFlagUpdate() withing the if statements to not intefere with bot behavior on ground/(shallow) waters
    if (!bot->HasUnitMovementFlag(MOVEMENTFLAG_FLYING) &&
        bot->HasAuraType(SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED) && !onGround)
    {
        bot->AddUnitMovementFlag(MOVEMENTFLAG_FLYING);
        bot->SendMovementFlagUpdate();
    }

    else if (bot->HasUnitMovementFlag(MOVEMENTFLAG_FLYING) &&
        (!bot->HasAuraType(SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED) || onGround))
    {
        bot->RemoveUnitMovementFlag(MOVEMENTFLAG_FLYING);
        bot->SendMovementFlagUpdate();
    }
}

bool MovementAction::ChaseTo(WorldObject* obj, float distance, float angle)
{
    if (!IsMovingAllowed())
    {
        return false;
    }

    if (Vehicle* vehicle = bot->GetVehicle())
    {
        VehicleSeatEntry const* seat = vehicle->GetSeatForPassenger(bot);
        if (!seat || !seat->CanControl())
            return false;

        // vehicle->GetMotionMaster()->Clear();
        vehicle->GetBase()->GetMotionMaster()->MoveChase((Unit*)obj, 30.0f);
        return true;
    }

    UpdateMovementState();

    if (!bot->IsStandState())
        bot->SetStandState(UNIT_STAND_STATE_STAND);

    if (bot->IsNonMeleeSpellCasted(true))
    {
        bot->CastStop();
        botAI->InterruptSpell();
    }

    bot->GetMotionMaster()->MoveChase((Unit*)obj, distance);

    // TODO shouldnt this use "last movement" value?
    WaitForReach(bot->GetExactDist2d(obj) - distance);
    return true;
}

bool MovementAction::ReachCombatTo(Unit* target, float distance)
{
    if (!IsMovingAllowed(target))
        return false;

    float bx = bot->GetPositionX();
    float by = bot->GetPositionY();
    float bz = bot->GetPositionZ();

    float tx = target->GetPositionX();
    float ty = target->GetPositionY();
    float tz = target->GetPositionZ();
    float combatDistance = bot->GetCombatReach() + target->GetCombatReach();
    distance += combatDistance;

    if (bot->GetExactDist(tx, ty, tz) <= distance)
        return false;

    PathGenerator path(bot);
    path.CalculatePath(tx, ty, tz, false);
    PathType type = path.GetPathType();
    int typeOk = PATHFIND_NORMAL | PATHFIND_INCOMPLETE | PATHFIND_SHORTCUT;
    if (!(type & typeOk))
        return false;
    float shortenTo = distance;

    // Avoid walking too far when moving towards each other
    float disToGo = bot->GetExactDist(tx, ty, tz) - distance;
    if (disToGo >= 10.0f)
        shortenTo = disToGo / 2 + distance;

    path.ShortenPathUntilDist(G3D::Vector3(tx, ty, tz), shortenTo);
    G3D::Vector3 endPos = path.GetPath().back();
    return MoveTo(target->GetMapId(), endPos.x, endPos.y, endPos.z, false, false, false, false,
        MovementPriority::MOVEMENT_COMBAT, true);
}

bool MovementAction::IsDuplicateMove(uint32 mapId, float x, float y, float z)
{
    LastMovement& lastMove = *context->GetValue<LastMovement&>("last movement");

    // heuristic 5s
    if (lastMove.msTime + sPlayerbotAIConfig->maxWaitForMove < getMSTime() ||
        lastMove.lastMoveShort.GetExactDist(x, y, z) > 0.01f)
        return false;

    return true;
}

bool MovementAction::IsWaitingForLastMove(MovementPriority priority)
{
    LastMovement& lastMove = *context->GetValue<LastMovement&>("last movement");

    if (priority > lastMove.priority)
        return false;

    // heuristic 5s
    if (lastMove.lastdelayTime + lastMove.msTime > getMSTime())
        return true;

    return false;
}

float MovementAction::MoveDelay(float distance, bool backwards)
{
    float speed;
    if (bot->isSwimming())
    {
        speed = backwards ? bot->GetSpeed(MOVE_SWIM_BACK) : bot->GetSpeed(MOVE_SWIM);
    }
    else if (bot->IsFlying())
    {
        speed = backwards ? bot->GetSpeed(MOVE_FLIGHT_BACK) : bot->GetSpeed(MOVE_FLIGHT);
    }
    else
    {
        speed = backwards ? bot->GetSpeed(MOVE_RUN_BACK) : bot->GetSpeed(MOVE_RUN);
    }
    float delay = distance / speed;
    return delay;
}

bool MovementAction::MoveTo(WorldObject* target, float distance, MovementPriority priority)
{
    if (!IsMovingAllowed(target))
        return false;

    float bx = bot->GetPositionX();
    float by = bot->GetPositionY();
    float bz = bot->GetPositionZ();

    float tx = target->GetPositionX();
    float ty = target->GetPositionY();
    float tz = target->GetPositionZ();

    float distanceToTarget = bot->GetDistance(target);
    float angle = bot->GetAngle(target);
    float needToGo = distanceToTarget - distance;

    float maxDistance = sPlayerbotAIConfig->spellDistance;
    if (needToGo > 0 && needToGo > maxDistance)
        needToGo = maxDistance;
    else if (needToGo < 0 && needToGo < -maxDistance)
        needToGo = -maxDistance;

    float dx = cos(angle) * needToGo + bx;
    float dy = sin(angle) * needToGo + by;
    float dz;  // = std::max(bz, tz); // calc accurate z position to avoid stuck
    if (distanceToTarget > CONTACT_DISTANCE)
    {
        dz = bz + (tz - bz) * (needToGo / distanceToTarget);
    }
    else
    {
        dz = tz;
    }
    return MoveTo(target->GetMapId(), dx, dy, dz, false, false, false, false, priority);
}

bool MovementAction::MoveTo(uint32 mapId, float x, float y, float z, bool idle, bool react, bool normal_only,
    bool exact_waypoint, MovementPriority priority, bool lessDelay, bool backwards)
{
    UpdateMovementState();
    if (!IsMovingAllowed(mapId, x, y, z))
    {
        return false;
    }
    if (IsDuplicateMove(mapId, x, y, z))
    {
        return false;
    }
    if (IsWaitingForLastMove(priority))
    {
        return false;
    }
    bool generatePath = !bot->IsFlying() && !bot->IsUnderWater() && !bot->IsInWater();
    bool disableMoveSplinePath = sPlayerbotAIConfig->disableMoveSplinePath >= 2 ||
        (sPlayerbotAIConfig->disableMoveSplinePath == 1 && bot->InBattleground());
    if (Vehicle* vehicle = bot->GetVehicle())
    {
        VehicleSeatEntry const* seat = vehicle->GetSeatForPassenger(bot);
        Unit* vehicleBase = vehicle->GetBase();
        generatePath = vehicleBase->CanFly();
        if (!vehicleBase || !seat || !seat->CanControl())  // is passenger and cant move anyway
            return false;

        float distance = vehicleBase->GetExactDist(x, y, z);  // use vehicle distance, not bot
        if (distance > 0.01f)
        {
            MotionMaster& mm = *vehicleBase->GetMotionMaster();  // need to move vehicle, not bot
            mm.Clear();
            if (!backwards)
            {
                mm.MovePoint(0, x, y, z, generatePath);
            }
            else
            {
                mm.MovePointBackwards(0, x, y, z, generatePath);
            }
            float speed = backwards ? vehicleBase->GetSpeed(MOVE_RUN_BACK) : vehicleBase->GetSpeed(MOVE_RUN);
            float delay = 1000.0f * (distance / speed);
            if (lessDelay)
            {
                delay -= botAI->GetReactDelay();
            }
            delay = std::max(.0f, delay);
            delay = std::min((float)sPlayerbotAIConfig->maxWaitForMove, delay);
            AI_VALUE(LastMovement&, "last movement").Set(mapId, x, y, z, bot->GetOrientation(), delay, priority);
            return true;
        }
    }
    else if (exact_waypoint || disableMoveSplinePath || !generatePath)
    {
        float distance = bot->GetExactDist(x, y, z);
        if (distance > 0.01f)
        {
            if (bot->IsSitState())
                bot->SetStandState(UNIT_STAND_STATE_STAND);

            MotionMaster& mm = *bot->GetMotionMaster();
            mm.Clear();
            if (!backwards)
            {
                mm.MovePoint(0, x, y, z, generatePath);
            }
            else
            {
                mm.MovePointBackwards(0, x, y, z, generatePath);
            }
            float delay = 1000.0f * MoveDelay(distance, backwards);
            if (lessDelay)
            {
                delay -= botAI->GetReactDelay();
            }
            delay = std::max(.0f, delay);
            delay = std::min((float)sPlayerbotAIConfig->maxWaitForMove, delay);
            AI_VALUE(LastMovement&, "last movement").Set(mapId, x, y, z, bot->GetOrientation(), delay, priority);
            return true;
        }
    }
    else
    {
        float modifiedZ;
        Movement::PointsArray path = SearchForBestPath(x, y, z, modifiedZ, sPlayerbotAIConfig->maxMovementSearchTime, normal_only);
        if (modifiedZ == INVALID_HEIGHT)
        {
            return false;
        }
        float distance = bot->GetExactDist(x, y, modifiedZ);
        if (distance > 0.01f)
        {
            if (bot->IsSitState())
                bot->SetStandState(UNIT_STAND_STATE_STAND);

            MotionMaster& mm = *bot->GetMotionMaster();
            if (path.empty())
                return false;
            G3D::Vector3 endP = path.back();
            mm.Clear();
            if (!backwards)
            {
                mm.MovePoint(0, endP.x, endP.y, endP.z, generatePath);
            }
            else
            {
                mm.MovePointBackwards(0, endP.x, endP.y, endP.z, generatePath);
            }
            distance = bot->GetExactDist(endP.x, endP.y, endP.z);
            float delay = 1000.0f * MoveDelay(distance, backwards);
            if (lessDelay)
            {
                delay -= botAI->GetReactDelay();
            }
            delay = std::max(.0f, delay);
            delay = std::min((float)sPlayerbotAIConfig->maxWaitForMove, delay);
            AI_VALUE(LastMovement&, "last movement").Set(mapId, endP.x, endP.y,
                endP.z, bot->GetOrientation(), delay, priority);
            return true;
        }
    }
    return false;
}

bool MoveRandomAction::Execute(Event event)
{
    float distance = sPlayerbotAIConfig->tooCloseDistance + urand(10, 30);
    const float x = bot->GetPositionX();
    const float y = bot->GetPositionY();
    const float z = bot->GetPositionZ();
    int attempts = 5;
    Map* map = bot->GetMap();
    while (--attempts)
    {
        float angle = (float)rand_norm() * 2 * static_cast<float>(M_PI);
        float dx = x + distance * cos(angle);
        float dy = y + distance * sin(angle);
        float dz = z;
        if (!map->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
            dx, dy, dz))
            continue;

        if (map->IsInWater(bot->GetPhaseMask(), dx, dy, dz))
            continue;

        bool moved = MoveTo(bot->GetMapId(), dx, dy, dz, false, false, false, true);
        if (moved)
            return true;
    }

    return false;
}

bool MovementAction::MoveNear(uint32 mapId, float x, float y, float z, float distance, MovementPriority priority)
{
    float angle = GetFollowAngle();
    return MoveTo(mapId, x + cos(angle) * distance, y + sin(angle) * distance, z, false, false, false, false, priority);
}

bool MovementAction::MoveNear(WorldObject* target, float distance, MovementPriority priority)
{
    if (!target)
        return false;

    distance += target->GetCombatReach();

    float x = target->GetPositionX();
    float y = target->GetPositionY();
    float z = target->GetPositionZ();
    float followAngle = GetFollowAngle();

    for (float angle = followAngle; angle <= followAngle + static_cast<float>(2 * M_PI);
        angle += static_cast<float>(M_PI / 4.f))
    {
        float x = target->GetPositionX() + cos(angle) * distance;
        float y = target->GetPositionY() + sin(angle) * distance;
        float z = target->GetPositionZ();

        if (!bot->IsWithinLOS(x, y, z))
            continue;

        bool moved = MoveTo(target->GetMapId(), x, y, z, false, false, false, false, priority);
        if (moved)
            return true;
    }

    // botAI->TellError("All paths not in LOS");
    return false;
}

float MovementAction::GetFollowAngle()
{
    Player* master = GetMaster();
    Group* group = master ? master->GetGroup() : bot->GetGroup();
    if (!group)
        return 0.0f;

    uint32 index = 1;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        if (ref->GetSource() == master)
            continue;

        if (ref->GetSource() == bot)
            return 2 * M_PI / (group->GetMembersCount() - 1) * index;

        ++index;
    }

    return 0;
}

bool MoveRandomAction::isUseful()
{
    return true;
}

bool MovementAction::IsMovingAllowed(WorldObject* target)
{
    if (!target)
        return false;

    if (bot->GetMapId() != target->GetMapId())
        return false;

    return IsMovingAllowed();
}

bool MovementAction::IsMovingAllowed(uint32 mapId, float x, float y, float z)
{
    return IsMovingAllowed();
}

bool MovementAction::IsMovingAllowed()
{
    // do not allow if not vehicle driver
    if (botAI->IsInVehicle() && !botAI->IsInVehicle(true))
        return false;

    if (bot->isFrozen() || bot->IsPolymorphed() || (bot->isDead() && !bot->HasPlayerFlag(PLAYER_FLAGS_GHOST)) ||
        bot->IsBeingTeleported() || bot->HasRootAura() || bot->HasSpiritOfRedemptionAura() ||
        bot->HasConfuseAura() || bot->IsCharmed() || bot->HasStunAura() ||
        bot->IsInFlight() || bot->HasUnitState(UNIT_STATE_LOST_CONTROL))
        return false;

    if (bot->GetMotionMaster()->GetMotionSlotType(MOTION_SLOT_CONTROLLED) != NULL_MOTION_TYPE)
    {
        return false;
    }

    return bot->GetMotionMaster()->GetCurrentMovementGeneratorType() != FLIGHT_MOTION_TYPE;
}

bool MoveRandomAction::isPossible()
{
    if (bot->IsInCombat() ||
        !AI_VALUE(bool, "can move around") ||
        !bot->CanFreeMove() ||
        !botAI->CanMove()) return false;

    return true;
}

bool MovementAction::Follow(Unit* target, float distance) { return Follow(target, distance, GetFollowAngle()); }
bool MovementAction::Follow(Unit* target, float distance, float angle)
{
    UpdateMovementState();

    if (!target)
        return false;

    if (!bot->InBattleground() && sServerFacade->IsDistanceLessOrEqualThan(sServerFacade->GetDistance2d(bot, target),
        sPlayerbotAIConfig->followDistance))
    {
        // botAI->TellError("No need to follow");
        return false;
    }

    // Move to target corpse if alive.
    if (!target->IsAlive() && bot->IsAlive() && target->GetGUID().IsPlayer())
    {
        Player* pTarget = (Player*)target;

        Corpse* corpse = pTarget->GetCorpse();

        if (corpse)
        {
            WorldPosition botPos(bot);
            WorldPosition cPos(corpse);

            if (botPos.fDist(cPos) > sPlayerbotAIConfig->spellDistance)
                return MoveTo(cPos.getMapId(), cPos.getX(), cPos.getY(), cPos.getZ());
        }
    }

    if (sServerFacade->IsDistanceGreaterOrEqualThan(sServerFacade->GetDistance2d(bot, target),
        sPlayerbotAIConfig->sightDistance))
    {
        if (target->GetGUID().IsPlayer())
        {
            Player* pTarget = (Player*)target;

            PlayerbotAI* targetBotAI = GET_PLAYERBOT_AI(pTarget);
            if (targetBotAI)  // Try to move to where the bot is going if it is closer and in the same direction.
            {
                WorldPosition botPos(bot);
                WorldPosition tarPos(target);
                WorldPosition longMove =
                    targetBotAI->GetAiObjectContext()->GetValue<WorldPosition>("last long move")->Get();

                if (longMove)
                {
                    float lDist = botPos.fDist(longMove);
                    float tDist = botPos.fDist(tarPos);
                    float ang = botPos.getAngleBetween(tarPos, longMove);
                    if ((lDist * 1.5 < tDist && ang < static_cast<float>(M_PI) / 2) ||
                        target->HasUnitState(UNIT_STATE_IN_FLIGHT))
                    {
                        return MoveTo(longMove.getMapId(), longMove.getX(), longMove.getY(), longMove.getZ());
                    }
                }
            }
            else
            {
                if (pTarget->HasUnitState(UNIT_STATE_IN_FLIGHT))  // Move to where the player is flying to.
                {
                    TaxiPathNodeList const& tMap = static_cast<FlightPathMovementGenerator*>(pTarget->GetMotionMaster()->top())->GetPath();
                    if (!tMap.empty())
                    {
                        /*const TaxiPathNodeEntry& tEnd = tMap[tMap.GetTotalLength()];
                        return MoveTo(tEnd.MapId, tEnd.LocX, tEnd.LocY, tEnd.LocZ);*/
                    }
                }
            }
        }

        if (!target->HasUnitState(UNIT_STATE_IN_FLIGHT))
            return MoveTo(target, sPlayerbotAIConfig->followDistance);
    }

    if (sServerFacade->IsDistanceLessOrEqualThan(sServerFacade->GetDistance2d(bot, target),
        sPlayerbotAIConfig->followDistance))
    {
        // botAI->TellError("No need to follow");
        return false;
    }

    if (target->IsFriendlyTo(bot) && bot->IsMounted() && AI_VALUE(GuidVector, "all targets").empty())
        distance += angle;

    if (!bot->InBattleground() && sServerFacade->IsDistanceLessOrEqualThan(sServerFacade->GetDistance2d(bot, target),
        sPlayerbotAIConfig->followDistance))
    {
        // botAI->TellError("No need to follow");
        return false;
    }

    bot->HandleEmoteCommand(0);

    if (bot->IsSitState())
        bot->SetStandState(UNIT_STAND_STATE_STAND);

    if (bot->IsNonMeleeSpellCasted(true))
    {
        bot->CastStop();
        botAI->InterruptSpell();
    }

    // AI_VALUE(LastMovement&, "last movement").Set(target);
    ClearIdleState();

    if (bot->GetMotionMaster()->GetCurrentMovementGeneratorType() == FOLLOW_MOTION_TYPE)
    {
        Unit* currentTarget = sServerFacade->GetChaseTarget(bot);
        if (currentTarget && currentTarget->GetGUID() == target->GetGUID())
            return false;
    }

    if (bot->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
        bot->GetMotionMaster()->Clear();

    bot->GetMotionMaster()->MoveFollow(target, distance, angle);
    return true;
}

const Movement::PointsArray MovementAction::SearchForBestPath(float x, float y, float z, float& modified_z,
    int maxSearchCount, bool normal_only, float step)
{
    bool found = false;
    modified_z = INVALID_HEIGHT;
    float tempZ = bot->GetMapHeight(x, y, z);
    PathGenerator gen(bot);
    gen.CalculatePath(x, y, tempZ);
    Movement::PointsArray result = gen.GetPath();
    float min_length = gen.getPathLength();
    int typeOk = PATHFIND_NORMAL | PATHFIND_INCOMPLETE;
    if ((gen.GetPathType() & typeOk) && abs(tempZ - z) < 0.5f)
    {
        modified_z = tempZ;
        return result;
    }
    // Start searching
    if (gen.GetPathType() & typeOk)
    {
        modified_z = tempZ;
        found = true;
    }
    int count = 1;
    for (float delta = step; count < maxSearchCount / 2 + 1; count++, delta += step)
    {
        tempZ = bot->GetMapHeight(x, y, z + delta);
        if (tempZ == INVALID_HEIGHT)
        {
            continue;
        }
        PathGenerator gen(bot);
        gen.CalculatePath(x, y, tempZ);
        if ((gen.GetPathType() & typeOk) && gen.getPathLength() < min_length)
        {
            found = true;
            min_length = gen.getPathLength();
            result = gen.GetPath();
            modified_z = tempZ;
        }
    }
    for (float delta = -step; count < maxSearchCount; count++, delta -= step)
    {
        tempZ = bot->GetMapHeight(x, y, z + delta);
        if (tempZ == INVALID_HEIGHT)
        {
            continue;
        }
        PathGenerator gen(bot);
        gen.CalculatePath(x, y, tempZ);
        if ((gen.GetPathType() & typeOk) && gen.getPathLength() < min_length)
        {
            found = true;
            min_length = gen.getPathLength();
            result = gen.GetPath();
            modified_z = tempZ;
        }
    }
    if (!found && normal_only)
    {
        modified_z = INVALID_HEIGHT;
        return Movement::PointsArray{};
    }
    if (!found && !normal_only)
    {
        return result;
    }
    return result;
}

bool MovementAction::MoveAway(Unit* target, float distance, bool backwards)
{
    if (!target)
    {
        return false;
    }
    float init_angle = target->GetAngle(bot);
    for (float delta = 0; delta <= M_PI / 2; delta += M_PI / 8)
    {
        float angle = init_angle + delta;
        float dx = bot->GetPositionX() + cos(angle) * distance;
        float dy = bot->GetPositionY() + sin(angle) * distance;
        float dz = bot->GetPositionZ();
        bool exact = true;
        if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(),
            bot->GetPositionZ(), dx, dy, dz))
        {
            // disable prediction if position is invalid
            dx = bot->GetPositionX() + cos(angle) * distance;
            dy = bot->GetPositionY() + sin(angle) * distance;
            dz = bot->GetPositionZ();
            exact = false;
        }
        if (MoveTo(target->GetMapId(), dx, dy, dz, false, false, true, exact, MovementPriority::MOVEMENT_COMBAT, false, backwards))
        {
            return true;
        }
        if (delta == 0)
        {
            continue;
        }
        exact = true;
        angle = init_angle - delta;
        dx = bot->GetPositionX() + cos(angle) * distance;
        dy = bot->GetPositionY() + sin(angle) * distance;
        dz = bot->GetPositionZ();
        if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(),
            bot->GetPositionZ(), dx, dy, dz))
        {
            // disable prediction if position is invalid
            dx = bot->GetPositionX() + cos(angle) * distance;
            dy = bot->GetPositionY() + sin(angle) * distance;
            dz = bot->GetPositionZ();
            exact = false;
        }
        if (MoveTo(target->GetMapId(), dx, dy, dz, false, false, true, exact, MovementPriority::MOVEMENT_COMBAT, false, backwards))
        {
            return true;
        }
    }
    return false;
}

bool MovementAction::Move(float angle, float distance)
{
    float x = bot->GetPositionX() + cos(angle) * distance;
    float y = bot->GetPositionY() + sin(angle) * distance;

    //TODO do we need GetMapWaterOrGroundLevel() if we're using CheckCollisionAndGetValidCoords() ?
    float z = bot->GetMapWaterOrGroundLevel(x, y, bot->GetPositionZ());
    if (z == -100000.0f || z == -200000.0f)
        z = bot->GetPositionZ();
    if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(),
        bot->GetPositionZ(), x, y, z, false))
        return false;

    return MoveTo(bot->GetMapId(), x, y, z);
}

// just calculates average position of group and runs away from that position
bool MovementAction::MoveFromGroup(float distance)
{
    if (Group* group = bot->GetGroup())
    {
        uint32 mapId = bot->GetMapId();
        float closestDist = FLT_MAX;
        float x = 0.0f;
        float y = 0.0f;
        uint32 count = 0;

        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
        {
            Player* player = gref->GetSource();
            if (!player || player == bot || !player->IsAlive() || player->GetMapId() != mapId)
                continue;
            float dist = bot->GetDistance2d(player);
            if (closestDist > dist)
                closestDist = dist;
            x += player->GetPositionX();
            y += player->GetPositionY();
            count++;
        }

        if (count && closestDist < distance)
        {
            x /= count;
            y /= count;
            // x and y are now average position of the group members
            float angle = bot->GetAngle(x, y) + M_PI;
            return Move(angle, distance - closestDist);
        }
    }
    return false;
}

bool MovementAction::Flee(Unit* target)
{
    return true;
    //Player* master = GetMaster();
    //if (!target)
    //    target = master;

    //if (!target)
    //    return false;

    //if (!IsMovingAllowed())
    //{
    //    botAI->TellError("I am stuck while fleeing");
    //    return false;
    //}

    //bool foundFlee = false;
    //time_t lastFlee = AI_VALUE(LastMovement&, "last movement").lastFlee;
    //time_t now = time(0);
    //uint32 fleeDelay = urand(2, sPlayerbotAIConfig->returnDelay / 1000);

    //if (lastFlee)
    //{
    //    if ((now - lastFlee) <= fleeDelay)
    //    {
    //        return false;
    //    }
    //}

    //HostileReference* ref = target->GetThreatManager().getCurrentVictim();
    //if (ref && ref->getTarget() == bot)  // bot is target - try to flee to tank or master
    //{
    //    if (Group* group = bot->GetGroup())
    //    {
    //        Unit* fleeTarget = nullptr;
    //        float fleeDistance = sPlayerbotAIConfig->sightDistance;

    //        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    //        {
    //            Player* player = gref->GetSource();
    //            if (!player || player == bot || !player->IsAlive())
    //                continue;

    //            if (PlayerBotSpec::IsTank(player))
    //            {
    //                float distanceToTank = sServerFacade->GetDistance2d(bot, player);
    //                float distanceToTarget = sServerFacade->GetDistance2d(bot, target);
    //                if (distanceToTank < fleeDistance)
    //                {
    //                    fleeTarget = player;
    //                    fleeDistance = distanceToTank;
    //                }
    //            }
    //        }

    //        if (fleeTarget)
    //            foundFlee = MoveNear(fleeTarget);

    //        if ((!fleeTarget || !foundFlee) && master)
    //        {
    //            foundFlee = MoveNear(master);
    //        }
    //    }
    //}
    //else  // bot is not targeted, try to flee dps/healers
    //{
    //    bool isHealer = PlayerBotSpec::IsHeal(bot);
    //    bool isDps = !isHealer && !PlayerBotSpec::IsTank(bot);
    //    bool isTank = PlayerBotSpec::IsTank(bot);
    //    bool needHealer = !isHealer && AI_VALUE2(uint8, "health", "self target") < 50;
    //    bool isRanged = PlayerBotSpec::IsRanged(bot);

    //    Group* group = bot->GetGroup();
    //    if (group)
    //    {
    //        Unit* fleeTarget = nullptr;
    //        float fleeDistance = botAI->GetRange("shoot") * 1.5f;
    //        Unit* spareTarget = nullptr;
    //        float spareDistance = botAI->GetRange("shoot") * 2.0f;
    //        std::vector<Unit*> possibleTargets;

    //        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
    //        {
    //            Player* player = gref->GetSource();
    //            if (!player || player == bot || !player->IsAlive())
    //                continue;

    //            if ((isHealer && PlayerBotSpec::IsHeal(player)) || needHealer)
    //            {
    //                float distanceToHealer = sServerFacade->GetDistance2d(bot, player);
    //                float distanceToTarget = sServerFacade->GetDistance2d(player, target);
    //                if (distanceToHealer < fleeDistance &&
    //                    distanceToTarget >(botAI->GetRange("shoot") / 2 + sPlayerbotAIConfig->followDistance) &&
    //                    (needHealer || player->IsWithinLOSInMap(target)))
    //                {
    //                    fleeTarget = player;
    //                    fleeDistance = distanceToHealer;
    //                    possibleTargets.push_back(fleeTarget);
    //                }
    //            }
    //            else if (isRanged && PlayerBotSpec::IsRanged(player))
    //            {
    //                float distanceToRanged = sServerFacade->GetDistance2d(bot, player);
    //                float distanceToTarget = sServerFacade->GetDistance2d(player, target);
    //                if (distanceToRanged < fleeDistance &&
    //                    distanceToTarget >(botAI->GetRange("shoot") / 2 + sPlayerbotAIConfig->followDistance) &&
    //                    player->IsWithinLOSInMap(target))
    //                {
    //                    fleeTarget = player;
    //                    fleeDistance = distanceToRanged;
    //                    possibleTargets.push_back(fleeTarget);
    //                }
    //            }
    //            // remember any group member in case no one else found
    //            float distanceToFlee = sServerFacade->GetDistance2d(bot, player);
    //            float distanceToTarget = sServerFacade->GetDistance2d(player, target);
    //            if (distanceToFlee < spareDistance &&
    //                distanceToTarget >(botAI->GetRange("shoot") / 2 + sPlayerbotAIConfig->followDistance) &&
    //                player->IsWithinLOSInMap(target))
    //            {
    //                spareTarget = player;
    //                spareDistance = distanceToFlee;
    //                possibleTargets.push_back(fleeTarget);
    //            }
    //        }

    //        if (!possibleTargets.empty())
    //            fleeTarget = possibleTargets[urand(0, possibleTargets.size() - 1)];

    //        if (!fleeTarget)
    //            fleeTarget = spareTarget;

    //        if (fleeTarget)
    //            foundFlee = MoveNear(fleeTarget);

    //        if ((!fleeTarget || !foundFlee) && master && master->IsAlive() && master->IsWithinLOSInMap(target))
    //        {
    //            float distanceToTarget = sServerFacade->GetDistance2d(master, target);
    //            if (distanceToTarget > (botAI->GetRange("shoot") / 2 + sPlayerbotAIConfig->followDistance))
    //                foundFlee = MoveNear(master);
    //        }
    //    }
    //}

    //if ((foundFlee || lastFlee) && bot->GetGroup())
    //{
    //    if (!lastFlee)
    //    {
    //        AI_VALUE(LastMovement&, "last movement").lastFlee = now;
    //    }
    //    else
    //    {
    //        if ((now - lastFlee) > fleeDelay)
    //        {
    //            AI_VALUE(LastMovement&, "last movement").lastFlee = 0;
    //        }
    //        else
    //            return false;
    //    }
    //}

    //FleeManager manager(bot, botAI->GetRange("flee"), bot->GetAngle(target) + M_PI);
    //if (!manager.isUseful())
    //    return false;

    //float rx, ry, rz;
    //if (!manager.CalculateDestination(&rx, &ry, &rz))
    //{
    //    botAI->TellError("Nowhere to flee");
    //    return false;
    //}

    //bool result = MoveTo(target->GetMapId(), rx, ry, rz);

    //if (result)
    //    AI_VALUE(LastMovement&, "last movement").lastFlee = time(nullptr);

    //return result;
}

Position MovementAction::BestPositionForMeleeToFlee(Position pos, float radius)
{
    Unit* currentTarget = AI_VALUE(Unit*, "current target");
    std::vector<CheckAngle> possibleAngles;
    if (currentTarget)
    {
        // Normally, move to left or right is the best position
        bool isTanking = (currentTarget->CanFreeMove()) && (currentTarget->GetVictim() == bot);
        float angle = bot->GetAngle(currentTarget);
        float angleLeft = angle + (float)M_PI / 2;
        float angleRight = angle - (float)M_PI / 2;
        possibleAngles.push_back({ angleLeft, false });
        possibleAngles.push_back({ angleRight, false });
        possibleAngles.push_back({ angle, true });
        if (isTanking)
        {
            possibleAngles.push_back({ angle + (float)M_PI, false });
            possibleAngles.push_back({ bot->GetAngle(&pos) - (float)M_PI, false });
        }
    }
    else
    {
        float angleTo = bot->GetAngle(&pos) - (float)M_PI;
        possibleAngles.push_back({ angleTo, false });
    }
    float farestDis = 0.0f;
    Position bestPos;
    for (CheckAngle& checkAngle : possibleAngles)
    {
        float angle = checkAngle.angle;
        std::list<FleeInfo>& infoList = AI_VALUE(std::list<FleeInfo>&, "recently flee info");
        if (!CheckLastFlee(angle, infoList))
        {
            continue;
        }
        bool strict = checkAngle.strict;
        float fleeDis = std::min(radius + 1.0f, sPlayerbotAIConfig->fleeDistance);
        float dx = bot->GetPositionX() + cos(angle) * fleeDis;
        float dy = bot->GetPositionY() + sin(angle) * fleeDis;
        float dz = bot->GetPositionZ();
        if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(),
            bot->GetPositionZ(), dx, dy, dz))
        {
            continue;
        }
        Position fleePos{ dx, dy, dz };
        if (strict && currentTarget &&
            fleePos.GetExactDist(currentTarget) - currentTarget->GetCombatReach() >
            sPlayerbotAIConfig->tooCloseDistance &&
            bot->IsWithinMeleeRange(currentTarget))
        {
            continue;
        }
        if (pos.GetExactDist(fleePos) > farestDis)
        {
            farestDis = pos.GetExactDist(fleePos);
            bestPos = fleePos;
        }
    }
    if (farestDis > 0.0f)
    {
        return bestPos;
    }
    return Position();
}

Position MovementAction::BestPositionForRangedToFlee(Position pos, float radius)
{
    Unit* currentTarget = AI_VALUE(Unit*, "current target");
    std::vector<CheckAngle> possibleAngles;
    float angleToTarget = 0.0f;
    float angleFleeFromCenter = bot->GetAngle(&pos) - (float)M_PI;
    if (currentTarget)
    {
        // Normally, move to left or right is the best position
        angleToTarget = bot->GetAngle(currentTarget);
        float angleLeft = angleToTarget + (float)M_PI / 2;
        float angleRight = angleToTarget - (float)M_PI / 2;
        possibleAngles.push_back({ angleLeft, false });
        possibleAngles.push_back({ angleRight, false });
        possibleAngles.push_back({ angleToTarget + (float)M_PI, true });
        possibleAngles.push_back({ angleToTarget, true });
        possibleAngles.push_back({ angleFleeFromCenter, true });
    }
    else
    {
        possibleAngles.push_back({ angleFleeFromCenter, false });
    }
    float farestDis = 0.0f;
    Position bestPos;
    for (CheckAngle& checkAngle : possibleAngles)
    {
        float angle = checkAngle.angle;
        std::list<FleeInfo>& infoList = AI_VALUE(std::list<FleeInfo>&, "recently flee info");
        if (!CheckLastFlee(angle, infoList))
        {
            continue;
        }
        bool strict = checkAngle.strict;
        float fleeDis = std::min(radius + 1.0f, sPlayerbotAIConfig->fleeDistance);
        float dx = bot->GetPositionX() + cos(angle) * fleeDis;
        float dy = bot->GetPositionY() + sin(angle) * fleeDis;
        float dz = bot->GetPositionZ();
        if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(),
            bot->GetPositionZ(), dx, dy, dz))
        {
            continue;
        }
        Position fleePos{ dx, dy, dz };
        if (strict && currentTarget &&
            fleePos.GetExactDist(currentTarget) - currentTarget->GetCombatReach() > sPlayerbotAIConfig->spellDistance)
        {
            continue;
        }
        if (strict && currentTarget &&
            fleePos.GetExactDist(currentTarget) - currentTarget->GetCombatReach() <
            (sPlayerbotAIConfig->tooCloseDistance))
        {
            continue;
        }

        if (pos.GetExactDist(fleePos) > farestDis)
        {
            farestDis = pos.GetExactDist(fleePos);
            bestPos = fleePos;
        }
    }
    if (farestDis > 0.0f)
    {
        return bestPos;
    }
    return Position();
}

bool MovementAction::FleePosition(Position pos, float radius, uint32 minInterval)
{
    std::list<FleeInfo>& infoList = AI_VALUE(std::list<FleeInfo>&, "recently flee info");

    if (!infoList.empty() && infoList.back().timestamp + minInterval > getMSTime())
        return false;

    Position bestPos;
    if (PlayerBotSpec::IsMelee(bot))
    {
        bestPos = BestPositionForMeleeToFlee(pos, radius);
    }
    else
    {
        bestPos = BestPositionForRangedToFlee(pos, radius);
    }
    if (bestPos != Position())
    {
        if (MoveTo(bot->GetMapId(), bestPos.GetPositionX(), bestPos.GetPositionY(), bestPos.GetPositionZ(), false,
            false, true, false, MovementPriority::MOVEMENT_COMBAT))
        {
            uint32 curTS = getMSTime();
            while (!infoList.empty())
            {
                if (infoList.size() > 10 || infoList.front().timestamp + 5000 < curTS)
                {
                    infoList.pop_front();
                }
                else
                {
                    break;
                }
            }
            infoList.push_back({ pos, radius, bot->GetAngle(&bestPos), curTS });
            return true;
        }
    }
    return false;
}

bool MovementAction::CheckLastFlee(float curAngle, std::list<FleeInfo>& infoList)
{
    uint32 curTS = getMSTime();
    curAngle = Position::NormalizeOrientation(curAngle);
    while (!infoList.empty())
    {
        if (infoList.size() > 10 || infoList.front().timestamp + 5000 < curTS)
        {
            infoList.pop_front();
        }
        else
        {
            break;
        }
    }
    for (FleeInfo& info : infoList)
    {
        // more than 5 sec
        if (info.timestamp + 5000 < curTS)
        {
            continue;
        }
        float revAngle = Position::NormalizeOrientation(info.angle + M_PI);
        // angle too close
        if (fabs(revAngle - curAngle) < M_PI / 4)
        {
            return false;
        }
    }
    return true;
}

bool RunAwayAction::Execute(Event event) { return Flee(AI_VALUE(Unit*, "master target")); }

bool SetFacingTargetAction::Execute(Event event)
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;

    if (bot->HasUnitState(UNIT_STATE_IN_FLIGHT))
        return true;

    sServerFacade->SetFacingTo(bot, target);
    botAI->SetNextCheckDelay(sPlayerbotAIConfig->reactDelay);
    return true;
}

bool SetFacingTargetAction::isUseful()
{
    return !AI_VALUE2(bool, "facing", "current target");
}

bool SetFacingTargetAction::isPossible()
{
    if (bot->isFrozen() || bot->IsPolymorphed() || (bot->isDead() && !bot->HasPlayerFlag(PLAYER_FLAGS_GHOST)) ||
        bot->IsBeingTeleported() || bot->HasConfuseAura() || bot->IsCharmed() ||
        bot->HasStunAura() || bot->IsInFlight() ||
        bot->HasUnitState(UNIT_STATE_LOST_CONTROL))
        return false;

    return true;
}

bool MoveFromGroupAction::Execute(Event event)
{
    float distance = atoi(event.getParam().c_str());
    if (!distance)
        distance = 20.0f; // flee distance from config is too small for this
    return MoveFromGroup(distance);
}

bool MoveToManaTideAction::isUseful()
{
    if (!ManaTideCoordination::IsManaBeneficiary(bot) ||
        bot->GetPowerPct(POWER_MANA) >= sPlayerbotAIConfig->mediumMana ||
        bot->IsNonMeleeSpellCasted(true))
    {
        return false;
    }

    Creature* totem = ManaTideCoordination::FindActiveGroupTotem(bot);
    return totem && bot->GetDistance(totem) > 32.0f;
}

bool MoveToManaTideAction::Execute([[maybe_unused]] Event event)
{
    Creature* totem = ManaTideCoordination::FindActiveGroupTotem(bot);
    if (!totem || bot->GetDistance(totem) <= ManaTideCoordination::MoveInsideRadius)
        return false;

    return MoveTo(totem, ManaTideCoordination::MoveInsideRadius,
                  MovementPriority::MOVEMENT_COMBAT);
}

bool AvoidAoeAction::FindNearestHazard(Position& position, float& radius) const
{
    if (!bot || !bot->IsInWorld() || !bot->IsAlive() || !bot->IsInCombat())
        return false;

    constexpr float searchRadius = 16.0f;
    std::list<WorldObject*> nearbyObjects;
    Trinity::AllWorldObjectsInRange check(bot, searchRadius);
    Trinity::WorldObjectListSearcher<Trinity::AllWorldObjectsInRange> searcher(
        bot, nearbyObjects, check);
    bot->VisitNearbyObject(searchRadius, searcher);

    bool found = false;
    float nearestDistance = FLT_MAX;
    for (WorldObject* object : nearbyObjects)
    {
        if (!object || !object->IsInWorld())
            continue;

        Unit* caster = nullptr;
        uint32 spellId = 0;
        float hazardRadius = 0.0f;

        if (DynamicObject* dynamicObject = object->ToDynObject())
        {
            if (dynamicObject->GetType() != DYNAMIC_OBJECT_AREA_SPELL)
                continue;

            caster = dynamicObject->GetCaster();
            spellId = dynamicObject->GetSpellId();
            hazardRadius = dynamicObject->GetRadius();
        }
        else if (AreaTrigger* areaTrigger = object->ToAreaTrigger())
        {
            caster = areaTrigger->GetCaster();
            spellId = areaTrigger->GetSpellId();
            hazardRadius = std::max(areaTrigger->GetScaleX(), areaTrigger->GetScaleY());
        }
        else
            continue;

        // Do not guess about ownerless triggers or run out of friendly ground
        // effects.  A hazard must have a hostile caster and a non-positive
        // spell in this 5.4.8 spell store.
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!caster || !spellInfo || spellInfo->IsPositive() ||
            !bot->IsValidAttackTarget(caster))
            continue;

        // Some AreaTrigger records do not expose their visual radius.  Use a
        // conservative minimum while clamping malformed data so one bad DBC
        // row cannot make a bot flee across an encounter room.
        hazardRadius = std::max(2.0f, std::min(hazardRadius, 12.0f));
        float distance = bot->GetExactDist2d(object);
        if (distance > hazardRadius + 0.75f || distance >= nearestDistance)
            continue;

        position.Relocate(object);
        radius = hazardRadius + 2.0f;
        nearestDistance = distance;
        found = true;
    }

    return found;
}

bool AvoidAoeAction::isUseful()
{
    Position position;
    float radius = 0.0f;
    return FindNearestHazard(position, radius);
}

bool AvoidAoeAction::Execute(Event /*event*/)
{
    Position position;
    float radius = 0.0f;
    if (!FindNearestHazard(position, radius))
        return false;

    return FleePosition(position, radius, 500);
}

BossMechanicsAction::Reaction BossMechanicsAction::GetReaction() const
{
    if (!bot || !bot->IsInWorld() || !bot->IsAlive() || !bot->IsInCombat())
        return Reaction::None;

    // Galleon (entry 62346), local boss_galion.cpp: every minute the boss
    // summons six Salyin Warmongers (entry 62351).  Damage dealers and the
    // off-tank must clear these adds; healers keep healing and the tank who is
    // actively holding Galleon must not turn or abandon the boss.
    if (!PlayerBotSpec::IsHeal(bot, true))
    {
        if (Creature* galleon = bot->FindNearestCreature(62346, 200.0f, true))
        {
            bool isMainTank = PlayerBotSpec::IsMainTank(bot);
            if (!isMainTank)
            {
                if (Creature* warmonger = bot->FindNearestCreature(62351, 100.0f, true))
                {
                    if (PlayerBotSpec::IsAssistTank(bot) &&
                        warmonger->GetVictim() == bot &&
                        bot->GetExactDist2d(galleon) < 20.0f)
                        return Reaction::PositionGalleonOffTank;

                    Unit* currentTarget = context->GetValue<Unit*>("current target")->Get();
                    if ((currentTarget != warmonger ||
                         (PlayerBotSpec::IsAssistTank(bot) &&
                          warmonger->GetVictim() != bot)) &&
                        bot->IsValidAttackTarget(warmonger) &&
                        bot->IsWithinLOSInMap(warmonger))
                        return Reaction::FocusGalleonWarmonger;
                }
            }
        }
    }

    // Sha of Anger (entries 60491/56439), local boss_sha_of_anger.cpp:
    // 119622 is the six-second warning immediately before Dominate Mind
    // (119626). Separating the warned target avoids stacking controlled
    // players on healers and melee while the raid switches to free them.
    if (bot->HasAura(119622) && bot->GetGroup() &&
        (bot->FindNearestCreature(60491, 250.0f, true) ||
         bot->FindNearestCreature(56439, 250.0f, true)))
        return Reaction::SpreadShaDominateWarning;

    // Nalak (entry 69099), local boss_nalak.cpp:
    // 136339 applies Lightning Tether and the local spell script increases
    // damage with target distance, using 20 yards as the near/far boundary.
    if (Creature* nalak = bot->FindNearestCreature(69099, 200.0f, true))
    {
        // Arc Nova (136338) is Nalak's close-range burst. Move outside the
        // local spell's effective melee cluster while its cast is visible.
        if (Spell* spell = nalak->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            if (spell->GetSpellInfo() && spell->GetSpellInfo()->Id == 136338 &&
                bot->GetExactDist2d(nalak) < 42.0f)
                return Reaction::FleeNalakArcNova;

        if (bot->HasAura(136339) && bot->GetExactDist2d(nalak) > 18.0f)
            return Reaction::ApproachNalak;
    }

    // The same local script applies Storm Cloud (136340) to ranged/non-tank
    // players. Its hostile area effect must be carried away from the group.
    if (bot->HasAura(136340) && bot->GetGroup())
        return Reaction::SpreadStormCloud;

    // Oondasta (entry 69161), local boss_oondasta.cpp: Spiritfire Beam
    // (137508) is deliberately cast on a non-tank and is documented by that
    // script as a many-target chain. The selected player must separate from
    // nearby members while the beam aura is present.
    if (bot->HasAura(137508) && bot->GetGroup() &&
        bot->FindNearestCreature(69161, 200.0f, true))
        return Reaction::SpreadOondastaBeam;

    // Alpha Male (138391/138390) deliberately makes Oondasta immune to
    // taunts and gives tank specializations extra threat.  The secondary
    // tank therefore has to keep attacking from the current tank's side so
    // it remains second on threat and can inherit the boss cleanly if the
    // marked tank dies.  Do not fabricate a taunt or a stack swap that the
    // local encounter script does not contain.
    if (Creature* oondasta = bot->FindNearestCreature(69161, 200.0f, true))
    {
        if (PlayerBotSpec::IsAssistTank(bot) && bot->GetGroup())
        {
            Player* mainTank = nullptr;
            for (GroupReference* ref = bot->GetGroup()->GetFirstMember(); ref;
                ref = ref->next())
            {
                Player* member = ref->GetSource();
                if (member && member->IsAlive() &&
                    PlayerBotSpec::IsMainTank(member))
                {
                    mainTank = member;
                    break;
                }
            }

            if (mainTank && oondasta->GetVictim() == mainTank)
            {
                Unit* currentTarget =
                    context->GetValue<Unit*>("current target")->Get();
                if (currentTarget != oondasta || bot->GetVictim() != oondasta ||
                    bot->GetExactDist2d(mainTank) > 8.0f)
                    return Reaction::MaintainOondastaOffTank;
            }
        }
    }

    // Frill Blast (137505) is explicitly a channel in boss_oondasta.cpp.
    // Oondasta keeps the cast orientation, so players step behind him rather
    // than trying to outrange or remain in the frontal cone.
    if (Creature* oondasta = bot->FindNearestCreature(69161, 200.0f, true))
        if (Spell* spell = oondasta->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            if (spell->GetSpellInfo() && spell->GetSpellInfo()->Id == 137505)
                return Reaction::AvoidOondastaFrillBlast;

    // Ordos (entry 72057), local boss_ordos.cpp: Burning Soul (144689,
    // effect aura 144690) is a selected-player mechanic. Keep either spell ID
    // because the caster and target aura differ in this 5.4.8 implementation.
    if ((bot->HasAura(144689) || bot->HasAura(144690)) && bot->GetGroup() &&
        bot->FindNearestCreature(72057, 200.0f, true))
        return Reaction::SpreadOrdosBurningSoul;

    // Magma Crush (144688) divides its damage by the number of players hit.
    // During the cast, everyone except a Burning Soul carrier stacks on the
    // current tank.  Burning Soul is checked first above and therefore keeps
    // its higher-priority spread response.
    if (Creature* ordos = bot->FindNearestCreature(72057, 200.0f, true))
    {
        if (Spell* spell = ordos->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            if (spell->GetSpellInfo() && spell->GetSpellInfo()->Id == 144688 &&
                ordos->GetVictim() && ordos->GetVictim()->GetTypeId() == TYPEID_PLAYER &&
                bot->GetExactDist2d(ordos->GetVictim()) > 7.0f)
                return Reaction::StackOrdosMagmaCrush;
    }

    // Chi-Ji, local boss_chi_ji.cpp: Beacon of Hope (entry 71978) is the
    // intended recovery location. Injured players move into it; Crane Rush
    // (144470/144495) is handled by leaving the boss rather than standing in
    // its repeated damage path.
    if (bot->FindNearestCreature(71952, 200.0f, true))
    {
        if ((bot->HasAura(144470) || bot->HasAura(144495)))
            return Reaction::FleeChiJiCraneRush;
        if (bot->GetHealthPct() < 70.0f &&
            bot->FindNearestCreature(71978, 100.0f, true))
            return Reaction::MoveChiJiBeacon;
    }

    // Xuen's Crackling Lightning is a chain spell in boss_xuen.cpp. A marked
    // target must create room from the raid while its effect aura is active.
    if ((bot->HasAura(144633) || bot->HasAura(144635)) && bot->GetGroup() &&
        bot->FindNearestCreature(71953, 200.0f, true))
        return Reaction::SpreadXuenLightning;

    // Niuzao's charge aura (144608/144609) drives the boss across the arena.
    // Moving away from him is a conservative pathing-safe response; Massive
    // Quake and other persistent floor effects remain covered by avoid aoe.
    if (Creature* niuzao = bot->FindNearestCreature(71954, 200.0f, true))
        if (niuzao->HasAura(144608) || bot->HasAura(144609))
            return Reaction::FleeNiuzaoCharge;

    // Yu'lon's Jadefire Breath (144530) is a frontal attack in the local
    // 5.4.8 boss script. Non-tanks move behind her while the cast is visible;
    // the active tank keeps the boss facing away from the raid.
    if (Creature* yulon = bot->FindNearestCreature(71955, 200.0f, true))
        if (!PlayerBotSpec::IsTank(bot, true) || yulon->GetVictim() != bot)
            if (Spell* spell = yulon->GetCurrentSpell(CURRENT_GENERIC_SPELL))
                if (spell->GetSpellInfo() && spell->GetSpellInfo()->Id == 144530)
                    return Reaction::AvoidYuLonJadefireBreath;

    return Reaction::None;
}

bool BossMechanicsAction::isUseful()
{
    return GetReaction() != Reaction::None;
}

bool BossMechanicsAction::Execute(Event /*event*/)
{
    switch (GetReaction())
    {
        case Reaction::ApproachNalak:
            if (Creature* nalak = bot->FindNearestCreature(69099, 200.0f, true))
                return MoveTo(nalak, 15.0f, MovementPriority::MOVEMENT_FORCED);
            break;
        case Reaction::FleeNalakArcNova:
            if (Creature* nalak = bot->FindNearestCreature(69099, 200.0f, true))
                return MoveAway(nalak, 45.0f);
            break;
        case Reaction::FocusGalleonWarmonger:
            if (Creature* warmonger = bot->FindNearestCreature(62351, 100.0f, true))
            {
                if (!bot->IsValidAttackTarget(warmonger) ||
                    !bot->IsWithinLOSInMap(warmonger))
                    break;

                Unit* oldTarget = context->GetValue<Unit*>("current target")->Get();
                context->GetValue<Unit*>("old target")->Set(oldTarget);
                context->GetValue<Unit*>("current target")->Set(warmonger);
                context->GetValue<ObjectGuid>("pull target")->Set(warmonger->GetGUID());
                context->GetValue<GuidVector>("prioritized targets")->Set(
                    { warmonger->GetGUID() });
                bot->SetSelection(warmonger->GetGUID());
                bot->SetTarget(warmonger->GetGUID());

                bool melee = bot->IsWithinMeleeRange(warmonger) ||
                    PlayerBotSpec::IsMelee(bot);
                if (bot->GetVictim() != warmonger)
                    bot->Attack(warmonger, melee);

                // The off-tank must establish ownership before dragging the
                // add pack away from Galleon. The five tank classes use
                // different action names in this module.
                if (PlayerBotSpec::IsAssistTank(bot) && warmonger->GetVictim() != bot)
                {
                    char const* tauntAction = nullptr;
                    switch (bot->GetClass())
                    {
                        case CLASS_WARRIOR:      tauntAction = "taunt"; break;
                        case CLASS_PALADIN:
                        case CLASS_DRUID:
                        case CLASS_DEATH_KNIGHT: tauntAction = "taunt spell"; break;
                        case CLASS_MONK:         tauntAction = "provoke"; break;
                        default: break;
                    }
                    if (tauntAction)
                        botAI->DoSpecificAction(tauntAction, Event(), true);
                }
                botAI->ChangeEngine(BOT_STATE_COMBAT);
                return true;
            }
            break;
        case Reaction::PositionGalleonOffTank:
            if (Creature* galleon = bot->FindNearestCreature(62346, 200.0f, true))
            {
                // Hold the add pack on Galleon's left flank. This keeps it
                // away from the main tank and out of the raid stack behind
                // the boss, while remaining close enough for add DPS/heals.
                float angle = Position::NormalizeOrientation(
                    galleon->GetOrientation() + float(M_PI_2));
                float x = galleon->GetPositionX();
                float y = galleon->GetPositionY();
                float z = galleon->GetPositionZ();
                galleon->GetNearPoint(bot, x, y, z, bot->GetObjectSize(),
                    24.0f, angle);
                return MoveTo(bot->GetMapId(), x, y, z, false, false, false,
                    true, MovementPriority::MOVEMENT_FORCED);
            }
            break;
        case Reaction::SpreadShaDominateWarning:
            return MoveFromGroup(18.0f);
        case Reaction::SpreadStormCloud:
            return MoveFromGroup(30.0f);
        case Reaction::SpreadOondastaBeam:
            return MoveFromGroup(22.0f);
        case Reaction::MaintainOondastaOffTank:
            if (Creature* oondasta = bot->FindNearestCreature(69161, 200.0f, true))
            {
                Player* mainTank = nullptr;
                if (Group* group = bot->GetGroup())
                {
                    for (GroupReference* ref = group->GetFirstMember(); ref;
                        ref = ref->next())
                    {
                        Player* member = ref->GetSource();
                        if (member && member->IsAlive() &&
                            PlayerBotSpec::IsMainTank(member))
                        {
                            mainTank = member;
                            break;
                        }
                    }
                }

                if (!mainTank || oondasta->GetVictim() != mainTank ||
                    !bot->IsValidAttackTarget(oondasta))
                    break;

                context->GetValue<Unit*>("current target")->Set(oondasta);
                context->GetValue<ObjectGuid>("pull target")->Set(
                    oondasta->GetGUID());
                bot->SetSelection(oondasta->GetGUID());
                bot->SetTarget(oondasta->GetGUID());
                if (bot->GetVictim() != oondasta)
                    bot->Attack(oondasta, true);
                botAI->ChangeEngine(BOT_STATE_COMBAT);

                if (bot->GetExactDist2d(mainTank) > 8.0f)
                    return MoveTo(mainTank, 5.0f,
                        MovementPriority::MOVEMENT_FORCED);
                return true;
            }
            break;
        case Reaction::AvoidOondastaFrillBlast:
            if (Creature* oondasta = bot->FindNearestCreature(69161, 200.0f, true))
            {
                float x = oondasta->GetPositionX();
                float y = oondasta->GetPositionY();
                float z = oondasta->GetPositionZ();
                oondasta->GetNearPoint(bot, x, y, z, bot->GetObjectSize(),
                    10.0f, Position::NormalizeOrientation(
                        oondasta->GetOrientation() + float(M_PI)));
                return MoveTo(bot->GetMapId(), x, y, z, false, false, false,
                    true, MovementPriority::MOVEMENT_FORCED);
            }
            break;
        case Reaction::StackOrdosMagmaCrush:
            if (Creature* ordos = bot->FindNearestCreature(72057, 200.0f, true))
                if (Unit* tank = ordos->GetVictim())
                    return MoveTo(tank, 4.0f, MovementPriority::MOVEMENT_FORCED);
            break;
        case Reaction::SpreadOrdosBurningSoul:
            return MoveFromGroup(20.0f);
        case Reaction::MoveChiJiBeacon:
            if (Creature* beacon = bot->FindNearestCreature(71978, 100.0f, true))
                return MoveTo(beacon, 3.0f, MovementPriority::MOVEMENT_FORCED);
            break;
        case Reaction::FleeChiJiCraneRush:
            if (Creature* chiJi = bot->FindNearestCreature(71952, 200.0f, true))
                return MoveAway(chiJi, 30.0f);
            break;
        case Reaction::SpreadXuenLightning:
            return MoveFromGroup(14.0f);
        case Reaction::FleeNiuzaoCharge:
            if (Creature* niuzao = bot->FindNearestCreature(71954, 200.0f, true))
                return MoveAway(niuzao, 35.0f);
            break;
        case Reaction::AvoidYuLonJadefireBreath:
            if (Creature* yulon = bot->FindNearestCreature(71955, 200.0f, true))
            {
                float x = yulon->GetPositionX();
                float y = yulon->GetPositionY();
                float z = yulon->GetPositionZ();
                yulon->GetNearPoint(bot, x, y, z, bot->GetObjectSize(),
                    10.0f, Position::NormalizeOrientation(
                        yulon->GetOrientation() + float(M_PI)));
                return MoveTo(bot->GetMapId(), x, y, z, false, false, false,
                    true, MovementPriority::MOVEMENT_FORCED);
            }
            break;
        case Reaction::None:
            break;
    }
    return false;
}

bool FleeAction::Execute(Event event)
{
    return MoveAway(AI_VALUE(Unit*, "current target"), sPlayerbotAIConfig->fleeDistance, true);
}

bool FleeAction::isUseful()
{
    // Generic flee is a PvP kiting action: it pulls mobs away from the tank
    // and can drag the raid into another pack. Scripted boss avoidance uses
    // BossMechanicsAction and is intentionally not affected by this guard.
    if (bot->GetMap() &&
        (bot->GetMap()->IsDungeon() || bot->GetMap()->IsRaid()) &&
        !bot->InBattleground() && !bot->InArena())
        return false;

    if (bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr)
    {
        return false;
    }
    return true;
}

bool CombatFormationMoveAction::isUseful()
{
    if (getMSTime() - moveInterval < lastMoveTimer)
    {
        return false;
    }

    Map* map = bot->GetMap();
    if (!map || (!map->IsDungeon() && !map->IsRaid()) ||
        bot->InBattleground() || bot->InArena() || !bot->IsInCombat() ||
        !PlayerBotSpec::IsRanged(bot, true))
    {
        return false;
    }

    // Do not cancel a useful cast merely to improve positioning.
    if (bot->IsNonMeleeSpellCasted(true, false, true))
    {
        return false;
    }

    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsInWorld() || !target->IsAlive() ||
        target->GetMapId() != bot->GetMapId() || !bot->IsValidAttackTarget(target))
    {
        return false;
    }

    // Kiting an enemy that is already attacking this bot separates the pack
    // from the tank and may pull more trash. Hold position until aggro is
    // recovered; defensive actions remain available to the class strategy.
    if (target->GetVictim() == bot)
        return false;

    float const edgeDistance = std::max(0.0f, bot->GetExactDist2d(target) -
        bot->GetCombatReach() - target->GetCombatReach());
    float const minimumRange = std::min(14.0f,
        std::max(8.0f, sPlayerbotAIConfig->spellDistance - 10.0f));
    return edgeDistance < minimumRange;
}

bool CombatFormationMoveAction::Execute(Event /*event*/)
{
    if (bot->IsNonMeleeSpellCasted(true, false, true))
        return false;

    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target || !target->IsInWorld() || !target->IsAlive() ||
        target->GetMapId() != bot->GetMapId() || !bot->IsValidAttackTarget(target) ||
        target->GetVictim() == bot || !PlayerBotSpec::IsRanged(bot, true))
    {
        return false;
    }

    float const desiredRange = std::min(24.0f,
        std::max(16.0f, sPlayerbotAIConfig->spellDistance - 4.0f));
    float const centerDistance = desiredRange + bot->GetCombatReach() + target->GetCombatReach();
    float const initialAngle = target->GetAngle(bot);

    // Preserve the side of the encounter the bot already occupies. This
    // moves ranged characters away from the target without running through
    // the boss/tank or selecting a random direction toward another pack.
    static float const angleOffsets[] =
    {
        0.0f,
        static_cast<float>(M_PI / 8.0),
        static_cast<float>(-M_PI / 8.0),
        static_cast<float>(M_PI / 4.0),
        static_cast<float>(-M_PI / 4.0)
    };

    for (float const offset : angleOffsets)
    {
        float const angle = Position::NormalizeOrientation(initialAngle + offset);
        float x = target->GetPositionX() + std::cos(angle) * centerDistance;
        float y = target->GetPositionY() + std::sin(angle) * centerDistance;
        float z = target->GetPositionZ();

        if (!bot->GetMap()->CheckCollisionAndGetValidCoords(bot,
                bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), x, y, z, false))
        {
            continue;
        }

        // A ranged position is only useful if the target remains visible
        // from it. Check both directions because some map objects have
        // asymmetric collision data.
        if (!target->IsWithinLOS(x, y, z) || !bot->IsWithinLOS(x, y, z))
            continue;

        if (MoveTo(bot->GetMapId(), x, y, z, false, false, true, false,
                MovementPriority::MOVEMENT_COMBAT, true))
        {
            lastMoveTimer = getMSTime();
            return true;
        }
    }

    return false;
}

Position CombatFormationMoveAction::AverageGroupPos(float dis, bool ranged, bool self)
{
    float averageX = 0, averageY = 0, averageZ = 0;
    int cnt = 0;
    Group* group = bot->GetGroup();
    if (!group)
    {
        return Position();
    }
    Group::MemberSlotList const& groupSlot = group->GetMemberSlots();
    for (Group::member_citerator itr = groupSlot.begin(); itr != groupSlot.end(); itr++)
    {
        Player* member = ObjectAccessor::FindPlayer(itr->guid);
        if (!member)
            continue;

        if (!self && member == bot)
            continue;

        if (ranged && !PlayerBotSpec::IsRanged(member))
            continue;

        if (!member->IsAlive() || member->GetMapId() != bot->GetMapId() || member->IsCharmed() ||
            sServerFacade->GetDistance2d(bot, member) > dis)
            continue;

        averageX += member->GetPositionX();
        averageY += member->GetPositionY();
        averageZ += member->GetPositionZ();
        ++cnt;
    }

    if (!cnt)
        return Position();

    averageX /= cnt;
    averageY /= cnt;
    averageZ /= cnt;
    return Position(averageX, averageY, averageZ);
}

float CombatFormationMoveAction::AverageGroupAngle(Unit* from, bool ranged, bool self)
{
    Group* group = bot->GetGroup();
    if (!from || !group)
    {
        return 0.0f;
    }
    // float average = 0.0f;
    float sumX = 0.0f;
    float sumY = 0.0f;
    int cnt = 0;
    Group::MemberSlotList const& groupSlot = group->GetMemberSlots();
    for (Group::member_citerator itr = groupSlot.begin(); itr != groupSlot.end(); itr++)
    {
        Player* member = ObjectAccessor::FindPlayer(itr->guid);
        if (!member)
            continue;

        if (!self && member == bot)
            continue;

        if (ranged && !PlayerBotSpec::IsRanged(member))
            continue;

        if (!member->IsAlive() || member->GetMapId() != bot->GetMapId() || member->IsCharmed() ||
            sServerFacade->GetDistance2d(bot, member) > sPlayerbotAIConfig->sightDistance)
            continue;

        cnt++;
        sumX += member->GetPositionX() - from->GetPositionX();
        sumY += member->GetPositionY() - from->GetPositionY();
    }
    if (cnt == 0)
        return 0.0f;

    // unnecessary division
    // sumX /= cnt;
    // sumY /= cnt;

    return atan2(sumY, sumX);
}

Position CombatFormationMoveAction::GetNearestPosition(const std::vector<Position>& positions)
{
    Position result;
    for (const Position& pos : positions)
    {
        if (bot->GetExactDist(pos) < bot->GetExactDist(result))
            result = pos;
    }
    return result;
}

Player* CombatFormationMoveAction::NearestGroupMember(float dis)
{
    float nearestDis = 10000.0f;
    Player* result = nullptr;
    Group* group = bot->GetGroup();
    if (!group)
    {
        return result;
    }
    Group::MemberSlotList const& groupSlot = group->GetMemberSlots();
    for (Group::member_citerator itr = groupSlot.begin(); itr != groupSlot.end(); itr++)
    {
        Player* member = ObjectAccessor::FindPlayer(itr->guid);
        if (!member || !member->IsAlive() || member == bot || member->GetMapId() != bot->GetMapId() ||
            member->IsCharmed() || sServerFacade->GetDistance2d(bot, member) > dis)
            continue;
        if (nearestDis > bot->GetExactDist(member))
        {
            result = member;
            nearestDis = bot->GetExactDist(member);
        }
    }
    return result;
}

bool TankFaceAction::Execute(Event event)
{
    Unit* target = AI_VALUE(Unit*, "current target");
    if (!target)
        return false;

    if (!bot->GetGroup())
        return false;

    if (!bot->IsWithinMeleeRange(target) || target->isMoving())
        return false;

    if (!AI_VALUE2(bool, "has aggro", "current target"))
        return false;

    float averageAngle = AverageGroupAngle(target, true);

    if (averageAngle == 0.0f)
        return false;

    float deltaAngle = Position::NormalizeOrientation(averageAngle - target->GetAngle(bot));
    if (deltaAngle > M_PI)
        deltaAngle -= 2.0f * M_PI; // -PI..PI

    float tolerable = M_PI_2;

    if (fabs(deltaAngle) > tolerable)
        return false;

    float goodAngle1 = Position::NormalizeOrientation(averageAngle + M_PI * 3 / 5);
    float goodAngle2 = Position::NormalizeOrientation(averageAngle - M_PI * 3 / 5);

    // if dist < bot->GetMeleeRange(target) / 2, target will move backward
    float dist = std::max(bot->GetExactDist(target), bot->GetMeleeRange(target) / 2) - bot->GetCombatReach() - target->GetCombatReach();
    std::vector<Position> availablePos;
    float x, y, z;
    target->GetNearPoint(bot, x, y, z, 0.0f, dist, goodAngle1);
    if (bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
        x, y, z))
    {
        /// @todo: movement control now is a mess, prepare to rewrite
        std::list<FleeInfo>& infoList = AI_VALUE(std::list<FleeInfo>&, "recently flee info");
        Position pos(x, y, z);
        float angle = bot->GetAngle(&pos);
        if (CheckLastFlee(angle, infoList))
        {
            availablePos.push_back(Position(x, y, z));
        }
    }
    target->GetNearPoint(bot, x, y, z, 0.0f, dist, goodAngle2);
    if (bot->GetMap()->CheckCollisionAndGetValidCoords(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
        x, y, z))
    {
        std::list<FleeInfo>& infoList = AI_VALUE(std::list<FleeInfo>&, "recently flee info");
        Position pos(x, y, z);
        float angle = bot->GetAngle(&pos);
        if (CheckLastFlee(angle, infoList))
        {
            availablePos.push_back(Position(x, y, z));
        }
    }
    if (availablePos.empty())
        return false;
    Position nearest = GetNearestPosition(availablePos);
    return MoveTo(bot->GetMapId(), nearest.GetPositionX(), nearest.GetPositionY(), nearest.GetPositionZ(), false, false, false, true, MovementPriority::MOVEMENT_COMBAT);
}

bool BattlegroundObjectiveAction::isUseful()
{
    Battleground* bg = bot->GetBattleground();
    return bg && bg->IsBattleground() &&
        (bg->GetStatus() == STATUS_WAIT_JOIN || bg->GetStatus() == STATUS_IN_PROGRESS);
}

bool BattlegroundObjectiveAction::EngageEnemy(Player* enemy)
{
    if (!enemy || !enemy->IsInWorld() || enemy->isDead() ||
        enemy->GetMapId() != bot->GetMapId() ||
        !bot->IsValidAttackTarget(enemy) || !bot->IsWithinLOSInMap(enemy) ||
        std::fabs(bot->GetPositionZ() - enemy->GetPositionZ()) > 15.0f)
        return false;

    Unit* currentTarget = context->GetValue<Unit*>("current target")->Get();
    context->GetValue<Unit*>("old target")->Set(currentTarget);
    context->GetValue<Unit*>("current target")->Set(enemy);
    context->GetValue<ObjectGuid>("pull target")->Set(enemy->GetGUID());
    context->GetValue<GuidVector>("prioritized targets")->Set({ enemy->GetGUID() });
    bot->SetSelection(enemy->GetGUID());
    bot->SetTarget(enemy->GetGUID());

    bool melee = bot->IsWithinMeleeRange(enemy) || PlayerBotSpec::IsMelee(bot);
    if (bot->GetVictim() != enemy)
        bot->Attack(enemy, melee);
    botAI->ChangeEngine(BOT_STATE_COMBAT);
    return true;
}

bool BattlegroundObjectiveAction::MoveToOrUse(GameObject* object, float interactDistance)
{
    if (!object || !object->IsInWorld() || !object->isSpawned())
        return false;

    if (bot->GetDistance(object) <= interactDistance &&
        bot->CanUseBattlegroundObject(object))
    {
        bot->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);
        bot->RemoveAurasByType(SPELL_AURA_MOD_INVISIBILITY);
        if (Battleground* bg = bot->GetBattleground())
            bg->EventPlayerClickedOnFlag(bot, object);
        return true;
    }

    return MoveTo(object, interactDistance - 1.0f,
        MovementPriority::MOVEMENT_FORCED);
}

bool BattlegroundObjectiveAction::TryBattlegroundMount()
{
    time_t now = time(nullptr);
    if (now < nextMountAttempt)
        return false;

    // "mount" is a non-combat strategy name in this module, not a concrete
    // ActionContext action. Calling DoSpecificAction("mount") therefore never
    // cast anything inside a BG. Locate a real learned mount spell and cast it
    // through the normal PlayerbotAI spell validation instead.
    std::vector<uint32> mountSpells;
    for (auto const& spellPair : bot->GetSpellMap())
    {
        PlayerSpell const* learned = spellPair.second;
        if (!learned || learned->state == PLAYERSPELL_REMOVED || !learned->active)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellPair.first);
        if (!spellInfo || spellInfo->IsPassive() ||
            !spellInfo->HasAura(SPELL_AURA_MOUNTED))
            continue;

        mountSpells.push_back(spellPair.first);
    }

    // Prefer the newest learned rank/variant, but fall back through every
    // mount because the current BG/map can reject a flying-only or otherwise
    // unsuitable spell while accepting a normal ground mount.
    std::sort(mountSpells.rbegin(), mountSpells.rend());
    for (uint32 spellId : mountSpells)
    {
        if (!botAI->CanCastSpell(spellId, bot) ||
            !botAI->CastSpell(spellId, bot))
            continue;

        nextMountAttempt = now + 5;
        TC_LOG_INFO("server",
            "Playerbot BG mount cast bot=%s guid=%u spell=%u map=%u",
            bot->GetName().c_str(), bot->GetGUID().GetCounter(), spellId,
            bot->GetMapId());
        return true;
    }

    nextMountAttempt = now + 5;
    return false;
}

bool BattlegroundObjectiveAction::Execute(Event /*event*/)
{
    Battleground* bg = bot->GetBattleground();
    if (!bg || bg->IsArena())
        return false;

    if (bg->GetStatus() == STATUS_WAIT_JOIN)
    {
        // Request-driven BG lifecycle owns the one successful preparation
        // cast per bot. Calling the helper again from this high-frequency
        // objective action caused mutually exclusive buffs to be recast.
        return true;
    }

    if (bg->GetStatus() != STATUS_IN_PROGRESS || bot->IsBeingTeleported())
        return false;

    // Dead BG players must remain at the Spirit Guide until the native
    // resurrection wave revives them. Returning false here allowed unrelated
    // non-combat movement actions to make ghosts run away from the resurrection
    // area and miss every subsequent wave.
    if (!bot->IsAlive())
    {
        bot->GetMotionMaster()->Clear();
        return true;
    }

    // Objective movement must never make a bot passive while an enemy is
    // actively damaging it. In particular, a stealthed flag defender can be
    // attacked before EnemyPlayerValue has refreshed; previously it could
    // keep holding its defensive position without retaliating. The attacker's
    // presence in Unit::getAttackers() is authoritative server-side evidence
    // that combat has begun, so hand it to the normal combat engine before any
    // flag, node or vehicle navigation is considered.
    for (Unit* attacker : bot->getAttackers())
    {
        Player* enemy = attacker ? attacker->ToPlayer() : nullptr;
        if (enemy && enemy->IsAlive() && EngageEnemy(enemy))
            return true;
    }

    TeamId ownTeam = bot->GetBGTeamId();
    TeamId enemyTeam = ownTeam == TEAM_ALLIANCE ? TEAM_HORDE : TEAM_ALLIANCE;

    // Flag-carrier threats override every navigation role in CTF maps.
    uint32 type = bg->GetTypeID();
    if (type == BATTLEGROUND_RB)
        type = bg->GetTypeID(true);
    bool ctf = type == BATTLEGROUND_WS || type == BATTLEGROUND_TP;

    // Use mounts for long outdoor objective travel, but never while fighting
    // or carrying a battleground objective.  This check runs before map role
    // selection so it also applies to node/resource maps.  IsOutdoors keeps
    // bots from mounting inside flag rooms and other enclosed spawn buildings.
    bool carryingFlagAura = bot->HasAura(23333) || bot->HasAura(23335) ||
        bot->HasAura(34976);
    if ((carryingFlagAura || bot->IsInCombat() || !bot->getAttackers().empty()) &&
        bot->IsMounted())
        bot->Dismount();
    else if (!carryingFlagAura && !bot->IsMounted() && !bot->IsInCombat() &&
        bot->getAttackers().empty() && bot->IsOutdoors())
    {
        Unit* nearbyEnemy = context->GetValue<Unit*>("enemy player target")->Get();
        if ((!nearbyEnemy || bot->GetDistance(nearbyEnemy) > 45.0f) &&
            TryBattlegroundMount())
            return true;
    }

    if (ctf)
    {
        ObjectGuid enemyCarrierGuid = bg->GetFlagPickerGUID(ownTeam);
        ObjectGuid allyCarrierGuid = bg->GetFlagPickerGUID(enemyTeam);
        Player* enemyCarrier = ObjectAccessor::FindConnectedPlayer(enemyCarrierGuid);
        Player* allyCarrier = ObjectAccessor::FindConnectedPlayer(allyCarrierGuid);
        bool carryingEnemyFlag = allyCarrierGuid == bot->GetGUID();
        uint32 roleSlot = bot->GetGUID().GetCounter() % 10;
        bool stealthDefender = (bot->GetClass() == CLASS_ROGUE ||
            bot->GetClass() == CLASS_DRUID) &&
            roleSlot == 2;
        bool defender = stealthDefender || roleSlot == 0 || roleSlot == 5;
        bool escort = allyCarrier && !carryingEnemyFlag && !defender;

        // Combat is normally retained, but dedicated flag runners and escorts
        // must not spend an entire timed match chasing an unrelated target.
        // Never disengage while somebody is actually attacking this bot, while
        // low on health, or while the current victim is threatening our carrier.
        Unit* victim = bot->GetVictim();
        if (victim && victim->IsPlayer() && victim->IsAlive())
        {
            bool victimReachable = bot->IsWithinLOSInMap(victim) &&
                std::fabs(bot->GetPositionZ() - victim->GetPositionZ()) <= 15.0f;
            bool victimThreatensCarrier = false;
            if (allyCarrier)
                for (Unit* attacker : allyCarrier->getAttackers())
                    if (attacker == victim)
                    {
                        victimThreatensCarrier = true;
                        break;
                    }

            Player* victimPlayer = victim->ToPlayer();
            bool victimNearEnemyGraveyard = false;
            if (victimPlayer)
                if (WorldSafeLocsEntry const* graveyard =
                    bg->GetClosestGraveYard(victimPlayer))
                    victimNearEnemyGraveyard = victimPlayer->GetDistance(
                        graveyard->x, graveyard->y, graveyard->z) < 55.0f;

            bool runnerMayDisengage = !allyCarrier && !defender &&
                bot->GetDistance(victim) > 25.0f;
            bool escortMayDisengage = escort && !victimThreatensCarrier &&
                bot->GetDistance(allyCarrier) > 30.0f;
            bool graveyardMayDisengage = !victimThreatensCarrier &&
                victimNearEnemyGraveyard;
            if ((!victimReachable || runnerMayDisengage ||
                escortMayDisengage || graveyardMayDisengage) &&
                bot->getAttackers().empty() && bot->GetHealthPct() > 50.0f)
            {
                context->GetValue<Unit*>("current target")->Set(nullptr);
                bot->SetTarget(ObjectGuid::Empty);
                bot->SetSelection(ObjectGuid());
                bot->AttackStop();
                botAI->ChangeEngine(BOT_STATE_NON_COMBAT);
            }
            else
                return false;
        }

        uint32 ownFlagObject = 0;
        uint32 enemyFlagObject = 0;
        if (type == BATTLEGROUND_WS)
        {
            ownFlagObject = ownTeam == TEAM_ALLIANCE ?
                BG_WS_OBJECT_A_FLAG : BG_WS_OBJECT_H_FLAG;
            enemyFlagObject = enemyTeam == TEAM_ALLIANCE ?
                BG_WS_OBJECT_A_FLAG : BG_WS_OBJECT_H_FLAG;
        }
        else
        {
            ownFlagObject = ownTeam == TEAM_ALLIANCE ?
                BG_TP_OBJECT_A_FLAG : BG_TP_OBJECT_H_FLAG;
            enemyFlagObject = enemyTeam == TEAM_ALLIANCE ?
                BG_TP_OBJECT_A_FLAG : BG_TP_OBJECT_H_FLAG;
        }

        // Dropped flags are dynamic gameobjects and therefore are not found
        // through the two base-object indices above. Return our dropped flag
        // before resuming a defensive role, and let attackers recover a
        // nearby dropped enemy flag instead of running to its empty base.
        ObjectGuid ownDroppedFlag;
        ObjectGuid enemyDroppedFlag;
        uint32 ownFaction = ownTeam == TEAM_ALLIANCE ? ALLIANCE : HORDE;
        uint32 enemyFaction = enemyTeam == TEAM_ALLIANCE ? ALLIANCE : HORDE;
        if (type == BATTLEGROUND_WS)
        {
            if (BattlegroundWS* ws = dynamic_cast<BattlegroundWS*>(bg))
            {
                ownDroppedFlag = ws->GetDroppedFlagGUID(ownFaction);
                enemyDroppedFlag = ws->GetDroppedFlagGUID(enemyFaction);
            }
        }
        else if (BattlegroundTP* tp = dynamic_cast<BattlegroundTP*>(bg))
        {
            ownDroppedFlag = tp->GetDroppedFlagGUID(ownFaction);
            enemyDroppedFlag = tp->GetDroppedFlagGUID(enemyFaction);
        }

        if (ownDroppedFlag)
            if (GameObject* dropped = bg->GetBgMap()->GetGameObject(ownDroppedFlag))
                if ((defender || bot->GetDistance(dropped) < 45.0f) &&
                    MoveToOrUse(dropped))
                    return true;

        if (enemyDroppedFlag)
            if (GameObject* dropped = bg->GetBgMap()->GetGameObject(enemyDroppedFlag))
                if (!defender && bot->GetDistance(dropped) < 160.0f &&
                    MoveToOrUse(dropped))
                    return true;

        if (carryingEnemyFlag)
        {
            GameObject* ownBase = bg->GetBGObject(ownFlagObject);

            // A real client reports the capture area's trigger when it crosses
            // the scoring zone. A server-controlled playerbot does not emit that
            // client packet, so reaching a spawned own flag would otherwise leave
            // it standing in the flag room forever. Use the Battleground's normal
            // capture handler only after the carrier is physically at its returned
            // own flag; all native status, flag-state and score checks still apply.
            if (ownBase && ownBase->IsInWorld() && ownBase->isSpawned() &&
                bot->GetDistance(ownBase) <= 15.0f)
            {
                uint32 scoreBefore = bg->GetTeamScore(ownTeam);
                float distance = bot->GetDistance(ownBase);
                if (type == BATTLEGROUND_WS)
                {
                    if (BattlegroundWS* ws = dynamic_cast<BattlegroundWS*>(bg))
                        ws->EventPlayerCapturedFlag(bot);
                }
                else if (BattlegroundTP* tp = dynamic_cast<BattlegroundTP*>(bg))
                    tp->EventPlayerCapturedFlag(bot);

                TC_LOG_INFO("server",
                    "Playerbot CTF capture attempt bot=%s guid=%u bg=%u distance=%.2f score=%u->%u carrier=%u",
                    bot->GetName().c_str(), bot->GetGUID().GetCounter(), type,
                    distance, scoreBefore, bg->GetTeamScore(ownTeam),
                    bg->GetFlagPickerGUID(enemyTeam) == bot->GetGUID() ? 1u : 0u);

                return true;
            }

            return ownBase && MoveTo(ownBase, 2.0f,
                MovementPriority::MOVEMENT_FORCED);
        }

        // When a player or bot has the enemy flag, most mobile teammates form
        // an escort. First attack enemies that are actually hitting the carrier;
        // otherwise stay close enough to peel, heal and crowd-control rather
        // than continuing an unrelated midfield fight.
        if (escort)
        {
            Player* closestThreat = nullptr;
            float closestDistance = 120.0f;
            for (Unit* attacker : allyCarrier->getAttackers())
            {
                Player* enemy = attacker ? attacker->ToPlayer() : nullptr;
                if (!enemy || !enemy->IsAlive())
                    continue;

                float distance = bot->GetDistance(enemy);
                if (distance < closestDistance)
                {
                    closestDistance = distance;
                    closestThreat = enemy;
                }
            }

            if (closestThreat && EngageEnemy(closestThreat))
                return true;

            return MoveTo(allyCarrier, 9.0f,
                MovementPriority::MOVEMENT_FORCED);
        }

        // Only the defensive/interceptor group abandons its assignment to hunt
        // the enemy carrier. Previously the whole team did so, leaving its own
        // carrier completely unprotected whenever both flags were held.
        if (enemyCarrier && defender && bot->GetDistance(enemyCarrier) < 180.0f &&
            EngageEnemy(enemyCarrier))
            return true;

        if (defender)
        {
            if (!bot->IsInCombat() && stealthDefender)
            {
                if (bot->GetClass() == CLASS_ROGUE)
                    botAI->DoSpecificAction("stealth", Event(), true);
                else if (bot->GetClass() == CLASS_DRUID)
                    botAI->DoSpecificAction("prowl", Event(), true);
            }

            GameObject* ownBase = bg->GetBGObject(ownFlagObject);
            if (ownBase && bot->GetDistance(ownBase) > 18.0f)
                return MoveTo(ownBase, 10.0f,
                    MovementPriority::MOVEMENT_FORCED);

            // A defender holds position until an intruder is detected.
            if (Unit* nearbyEnemy = context->GetValue<Unit*>("enemy player target")->Get())
                if (bot->GetDistance(nearbyEnemy) < 45.0f)
                    return EngageEnemy(nearbyEnemy->ToPlayer());
            return true;
        }

        return MoveToOrUse(bg->GetBGObject(enemyFlagObject));
    }

    // Do not abandon a non-CTF fight already in progress. The class combat
    // engine remains responsible for damage, healing, dispels and crowd control.
    Unit* victim = bot->GetVictim();
    if (victim && victim->IsPlayer() && victim->IsAlive())
    {
        if (bot->IsWithinLOSInMap(victim) &&
            std::fabs(bot->GetPositionZ() - victim->GetPositionZ()) <= 15.0f)
            return false;

        if (bot->getAttackers().empty())
        {
            context->GetValue<Unit*>("current target")->Set(nullptr);
            bot->SetTarget(ObjectGuid::Empty);
            bot->SetSelection(ObjectGuid());
            bot->AttackStop();
            botAI->ChangeEngine(BOT_STATE_NON_COMBAT);
        }
    }

    // Fight nearby enemies or enemies attacking a group member before
    // returning to the objective.  EnemyPlayerValue also prioritizes weak
    // enemies and visible flag carriers.
    if (Unit* nearbyEnemy = context->GetValue<Unit*>("enemy player target")->Get())
        if (bot->GetDistance(nearbyEnemy) < 40.0f &&
            EngageEnemy(nearbyEnemy->ToPlayer()))
            return true;

    // Capture-point maps: choose a stable per-bot node so the whole team does
    // not form one train.  Visible hostile/neutral banners are clicked only
    // after the normal core CanUseBattlegroundObject validation succeeds.
    if (type == BATTLEGROUND_AB)
    {
        uint8 node = bot->GetGUID().GetCounter() % BG_AB_DYNAMIC_NODES_COUNT;
        uint32 first = node * 8;
        for (uint32 offset = 0; offset < 5; ++offset)
            if (GameObject* banner = bg->GetBGObject(first + offset))
                if (banner->isSpawned() && MoveToOrUse(banner))
                    return true;
    }
    else if (type == BATTLEGROUND_BFG)
    {
        uint8 node = bot->GetGUID().GetCounter() % BG_BFG_DYNAMIC_NODES_COUNT;
        uint32 first = node * 8;
        for (uint32 offset = 0; offset < 5; ++offset)
            if (GameObject* banner = bg->GetBGObject(first + offset))
                if (banner->isSpawned() && MoveToOrUse(banner))
                    return true;
    }
    else if (type == BATTLEGROUND_TOK)
    {
        for (uint32 offset = 0; offset < BG_TOK_MAX_ORBS; ++offset)
        {
            uint32 index = BG_TOK_OBJECT_ORB_1 +
                ((offset + bot->GetGUID().GetCounter()) % BG_TOK_MAX_ORBS);
            if (GameObject* orb = bg->GetBGObject(index))
                if (orb->isSpawned() && MoveToOrUse(orb))
                    return true;
        }
    }

    // Eye of the Storm combines proximity-controlled towers with one flag.
    // Flag carriers are escorted/intercepted; otherwise part of the team
    // captures towers while the rest contests the central flag.
    else if (type == BATTLEGROUND_EY)
    {
        ObjectGuid carrierGuid = bg->GetFlagPickerGUID();
        if (carrierGuid)
        {
            if (Player* carrier = ObjectAccessor::FindConnectedPlayer(carrierGuid))
            {
                if (carrier == bot)
                {
                    uint8 point = bot->GetGUID().GetCounter() % EY_POINTS_MAX;
                    return MoveTo(bg->GetMapId(), BG_EY_TriggerPositions[point][0],
                        BG_EY_TriggerPositions[point][1], BG_EY_TriggerPositions[point][2],
                        false, true, false, false, MovementPriority::MOVEMENT_FORCED);
                }

                if (carrier->GetBGTeamId() != ownTeam)
                    return EngageEnemy(carrier);

                if (bot->GetGUID().GetCounter() % 3 == 0)
                    return MoveTo(carrier, 8.0f, MovementPriority::MOVEMENT_FORCED);
            }
        }

        if (bot->GetGUID().GetCounter() % 3 == 1)
            return MoveToOrUse(bg->GetBGObject(BG_EY_OBJECT_FLAG_NETHERSTORM));

        uint8 point = bot->GetGUID().GetCounter() % EY_POINTS_MAX;
        return MoveTo(bg->GetMapId(), BG_EY_TriggerPositions[point][0],
            BG_EY_TriggerPositions[point][1], BG_EY_TriggerPositions[point][2],
            false, true, false, false, MovementPriority::MOVEMENT_FORCED);
    }

    // Deepwind Gorge: split between mine capture points and cart duty.  All
    // pickup/capture credit remains in BattlegroundDG's normal handlers.
    else if (type == BATTLEGROUND_DG)
    {
        ObjectGuid enemyCartCarrier = bg->GetFlagPickerGUID(ownTeam);
        if (Player* carrier = ObjectAccessor::FindConnectedPlayer(enemyCartCarrier))
            if (EngageEnemy(carrier))
                return true;

        ObjectGuid friendlyCartCarrier = bg->GetFlagPickerGUID(enemyTeam);
        if (friendlyCartCarrier == bot->GetGUID())
        {
            uint8 base = ownTeam == TEAM_ALLIANCE ? 0 : 1;
            return MoveTo(bg->GetMapId(), BG_DG_CartPositions[base][0],
                BG_DG_CartPositions[base][1], BG_DG_CartPositions[base][2],
                false, true, false, false, MovementPriority::MOVEMENT_FORCED);
        }

        if (friendlyCartCarrier && bot->GetGUID().GetCounter() % 4 == 1)
            if (Player* carrier = ObjectAccessor::FindConnectedPlayer(friendlyCartCarrier))
                return MoveTo(carrier, 8.0f, MovementPriority::MOVEMENT_FORCED);

        if (bot->GetGUID().GetCounter() % 4 == 0)
        {
            uint32 cart = enemyTeam == TEAM_ALLIANCE ?
                BG_DG_OBJECT_CART_ALLIANCE : BG_DG_OBJECT_CART_HORDE;
            if (MoveToOrUse(bg->GetBGObject(cart)))
                return true;

            uint32 dropped = enemyTeam == TEAM_ALLIANCE ?
                BG_DG_OBJECT_CART_ALLY_GROUND : BG_DG_OBJECT_CART_HORDE_GROUND;
            if (MoveToOrUse(bg->GetBGObject(dropped)))
                return true;
        }

        uint8 node = bot->GetGUID().GetCounter() % BG_DG_ALL_NODES_COUNT;
        if (Creature* capturePoint = bg->GetBGCreature(
            BG_DG_OBJECT_CAPT_POINT_START + node))
        {
            if (bot->GetDistance(capturePoint) <= 8.0f &&
                bg->CanSeeSpellClick(bot, capturePoint))
            {
                bot->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);
                bot->RemoveAurasByType(SPELL_AURA_MOD_INVISIBILITY);
                bg->EventPlayerClickedOnFlag(bot, capturePoint);
                return true;
            }
            return MoveTo(capturePoint, 6.0f, MovementPriority::MOVEMENT_FORCED);
        }
    }

    // Silvershard carts are controlled by proximity.  Stable distribution
    // prevents every bot from following the same cart.
    else if (type == BATTLEGROUND_SM)
    {
        uint8 firstCart = bot->GetGUID().GetCounter() % SM_MINE_CART_MAX;
        for (uint8 offset = 0; offset < SM_MINE_CART_MAX; ++offset)
        {
            uint8 cart = (firstCart + offset) % SM_MINE_CART_MAX;
            if (Creature* mineCart = bg->GetBGCreature(BG_SM_CartTypes[cart]))
                if (mineCart->IsAlive())
                    return MoveTo(mineCart, 8.0f, MovementPriority::MOVEMENT_FORCED);
        }
    }

    // Alterac Valley has many dynamically swapped banner objects.  Walk a
    // stable, per-bot order and use only a currently spawned, faction-valid
    // banner; the AV script still validates assault versus defence.
    else if (type == BATTLEGROUND_AV)
    {
        uint32 first = bot->GetGUID().GetCounter() %
            (BG_AV_OBJECT_FLAG_N_SNOWFALL_GRAVE + 1);
        for (uint32 offset = 0; offset <= BG_AV_OBJECT_FLAG_N_SNOWFALL_GRAVE; ++offset)
        {
            uint32 index = (first + offset) %
                (BG_AV_OBJECT_FLAG_N_SNOWFALL_GRAVE + 1);
            if (GameObject* banner = bg->GetBGObject(index))
                if (banner->isSpawned() && bot->CanUseBattlegroundObject(banner) &&
                    MoveToOrUse(banner))
                    return true;
        }
    }

    // Isle of Conquest node banners are replaced in-place as ownership
    // changes.  Prefer the five strategic resource/vehicle nodes, then push
    // the enemy keep commander when no usable node remains.
    else if (type == BATTLEGROUND_IC)
    {
        uint8 firstNode = bot->GetGUID().GetCounter() % 5;
        for (uint8 offset = 0; offset < 5; ++offset)
        {
            uint8 node = (firstNode + offset) % 5;
            if (GameObject* banner = bg->GetBGObject(nodePointInitial[node].gameobject_type))
                if (banner->isSpawned() && bot->CanUseBattlegroundObject(banner) &&
                    MoveToOrUse(banner))
                    return true;
        }

        uint32 commander = ownTeam == TEAM_ALLIANCE ?
            BG_IC_NPC_OVERLORD_AGMAR : BG_IC_NPC_HIGH_COMMANDER_HALFORD_WYRMBANE;
        if (Creature* boss = bg->GetBGCreature(commander))
        {
            if (boss->IsAlive() && bot->IsValidAttackTarget(boss))
            {
                bot->SetSelection(boss->GetGUID());
                bot->SetTarget(boss->GetGUID());
                if (bot->GetDistance(boss) <= 35.0f)
                {
                    bot->Attack(boss, PlayerBotSpec::IsMelee(bot));
                    botAI->ChangeEngine(BOT_STATE_COMBAT);
                    return true;
                }
                return MoveTo(boss, 20.0f, MovementPriority::MOVEMENT_FORCED);
            }
        }
    }

    // Strand of the Ancients: attackers preferentially enter an available
    // demolisher and drive it toward the relic.  Defenders spread across the
    // outer gates and fall back toward the relic.  Gate damage remains a
    // vehicle/class-combat responsibility, never fabricated objective credit.
    else if (type == BATTLEGROUND_SA)
    {
        BattlegroundSA* strand = dynamic_cast<BattlegroundSA*>(bg);
        bool attacker = strand && strand->Attackers == ownTeam;
        if (attacker && !bot->GetVehicle())
        {
            uint8 firstDemolisher = bot->GetGUID().GetCounter() % 8;
            for (uint8 offset = 0; offset < 8; ++offset)
            {
                uint32 index = BG_SA_DEMOLISHER_1 +
                    ((firstDemolisher + offset) % 8);
                if (Creature* demolisher = bg->GetBGCreature(index))
                {
                    if (!demolisher->IsAlive() || !demolisher->IsFriendlyTo(bot))
                        continue;
                    if (bot->GetDistance(demolisher) <= 5.0f)
                    {
                        demolisher->HandleSpellClick(bot);
                        return true;
                    }
                    return MoveTo(demolisher, 3.0f,
                        MovementPriority::MOVEMENT_FORCED);
                }
            }
        }

        if (!attacker)
        {
            uint32 gate = (bot->GetGUID().GetCounter() % 2) ?
                BG_SA_GREEN_GATE : BG_SA_BLUE_GATE;
            if (GameObject* gateObject = bg->GetBGObject(gate))
                if (gateObject->IsInWorld() && bot->GetDistance(gateObject) > 22.0f)
                    return MoveTo(gateObject, 16.0f,
                        MovementPriority::MOVEMENT_FORCED);
        }

        if (GameObject* relic = bg->GetBGObject(BG_SA_TITAN_RELIC))
            return MoveTo(relic, attacker ? 4.0f : 18.0f,
                MovementPriority::MOVEMENT_FORCED);
    }

    // Safe fallback for any future map: advance toward the centre line
    // between both spawn points.
    // This keeps bots participating and fighting without fabricating direct
    // objective credit or bypassing the battleground's normal handlers.
    float ownX, ownY, ownZ, ownO;
    float enemyX, enemyY, enemyZ, enemyO;
    bg->GetTeamStartLoc(ownTeam == TEAM_ALLIANCE ? ALLIANCE : HORDE,
        ownX, ownY, ownZ, ownO);
    bg->GetTeamStartLoc(enemyTeam == TEAM_ALLIANCE ? ALLIANCE : HORDE,
        enemyX, enemyY, enemyZ, enemyO);
    float lane = float(bot->GetGUID().GetCounter() % 5) * 0.08f - 0.16f;
    float targetX = (ownX + enemyX) * 0.5f + (enemyY - ownY) * lane;
    float targetY = (ownY + enemyY) * 0.5f - (enemyX - ownX) * lane;
    float targetZ = (ownZ + enemyZ) * 0.5f;
    return MoveTo(bg->GetMapId(), targetX, targetY, targetZ, false, true,
        false, false, MovementPriority::MOVEMENT_FORCED);
}
