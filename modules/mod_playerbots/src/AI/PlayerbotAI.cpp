/*
* This file is part of the Legends of Azeroth Pandaria Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "PlayerbotAI.h"

#include <cmath>
#include <mutex>
#include <sstream>
#include <string>

#include "AiFactory.h"
#include "ChannelMgr.h"
#include "CreatureAIImpl.h"
#include "Engine.h"
#include "ExternalEventHelper.h"
#include "GuildMgr.h"
#include "Helper.h"
#include "LastMovementValue.h"
#include "LastSpellCastValue.h"
#include "LFGMgr.h"
#include "MapManager.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "Player.h"
#include "PositionValue.h"
#include "PointMovementGenerator.h"
#include "Playerbots.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "PerformanceMonitor.h"
#include "RandomPlayerbotMgr.h"
#include "ServerFacade.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SocialMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "Transport.h"
#include "TradeData.h"
#include "Unit.h"
#include "Vehicle.h"
#include "UpdateFields.h"

PlayerbotChatHandler::PlayerbotChatHandler(Player* pMasterPlayer) : ChatHandler(pMasterPlayer->GetSession())
{
}

uint32 PlayerbotChatHandler::extractQuestId(std::string const str)
{
    char* source = (char*)str.c_str();
    char* cId = extractKeyFromLink(source, "Hquest");
    return cId ? atol(cId) : 0;
}

void PacketHandlingHelper::AddHandler(uint16 opcode, std::string const handler)
{
    _handlers[opcode] = handler;
}

void PacketHandlingHelper::Handle(ExternalEventHelper& helper)
{
    while (!_queue.empty())
    {
        helper.HandlePacket(_handlers, _queue.top());
        _queue.pop();
    }
}

void PacketHandlingHelper::AddPacket(WorldPacket const& packet)
{
    if (packet.empty())
        return;
    // assert(handlers);
    // assert(packet);
    // assert(packet.GetOpcode());
    if (_handlers.find(packet.GetOpcode()) != _handlers.end())
        _queue.push(WorldPacket(packet));
}

PlayerbotAI::PlayerbotAI()
    : PlayerbotAIBase(true),
    _isBotInitializing{ true },
    bot(nullptr),
    accountId(0),
    master(nullptr),
    _aiObjectContext{ nullptr },
    _currentEngine{ nullptr },
    _engines{ nullptr },
    _currentState(BOT_STATE_NON_COMBAT)
{
    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
        _engines[i] = nullptr;

    for (uint8 i = 0; i < MAX_ACTIVITY_TYPE; i++)
    {
        _allowActiveCheckTimer[i] = time(nullptr);
        _allowActive[i] = false;
    }
}

PlayerbotAI::PlayerbotAI(Player* bot)
    : PlayerbotAIBase(true),
    _isBotInitializing{ true },
    bot(bot),
    master(nullptr),
    _aiObjectContext{ nullptr },
    _currentEngine{ nullptr },
    _engines{ nullptr }
{
    for (uint8 i = 0; i < MAX_ACTIVITY_TYPE; i++)
    {
        _allowActiveCheckTimer[i] = time(nullptr);
        _allowActive[i] = false;
    }

    accountId = bot->GetSession()->GetAccountId();
    _aiObjectContext = AiFactory::createAiObjectContext(bot, this);
    _engines[BOT_STATE_COMBAT] = AiFactory::createCombatEngine(bot, this, _aiObjectContext);
    _engines[BOT_STATE_NON_COMBAT] = AiFactory::createNonCombatEngine(bot, this, _aiObjectContext);
    _engines[BOT_STATE_DEAD] = AiFactory::createDeadEngine(bot, this, _aiObjectContext);

    _currentEngine = _engines[BOT_STATE_NON_COMBAT];
    _currentState = BOT_STATE_NON_COMBAT;
    _rpgInfo.status = NewRpgStatus::IDLE;

    masterIncomingPacketHandlers.AddHandler(CMSG_GROUP_DISBAND, "uninvite");
    masterIncomingPacketHandlers.AddHandler(CMSG_GROUP_UNINVITE_GUID, "uninvite guid");
    masterIncomingPacketHandlers.AddHandler(CMSG_REPOP_REQUEST, "release spirit");
    masterIncomingPacketHandlers.AddHandler(CMSG_RECLAIM_CORPSE, "revive from corpse");

    botOutgoingPacketHandlers.AddHandler(SMSG_LEVELUP_INFO, "levelup");
    botOutgoingPacketHandlers.AddHandler(SMSG_GROUP_INVITE, "group invite");
    botOutgoingPacketHandlers.AddHandler(SMSG_GROUP_DESTROYED, "group destroyed");
}

PlayerbotAI::~PlayerbotAI()
{
    // Logout can be initiated by a world-thread queue/group coordinator while
    // the map worker is still finishing an AI action. Do not destroy cached
    // Action/Value objects until every action entry point has returned.
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
    {
        if (_engines[i])
            delete _engines[i];
    }

    if (_aiObjectContext)
        delete _aiObjectContext;
}

void PlayerbotAI::SetLfgAutoQueueControl(bool reserved,
    uint32 requesterGuid, bool initializeInDungeon)
{
    _lfgAutoQueueRequesterGuid.store(requesterGuid);
    if (initializeInDungeon)
        _lfgAutoQueueInitializePending.store(true);
    else if (!requesterGuid)
    {
        _lfgAutoQueueInitializePending.store(false);
        _lfgPreparationBuffPending.store(false);
    }
    // Publish the reservation flag last. In particular, a map update which
    // observes reservation release must also observe the pending in-dungeon
    // initialization request posted above.
    _lfgAutoQueueReserved.store(reserved);
}

bool PlayerbotAI::IsLfgAutoQueueReserved() const
{
    return _lfgAutoQueueReserved.load();
}

bool PlayerbotAI::CanLfgAutoQueueEngage(Unit const* target) const
{
    uint32 requesterGuid = _lfgAutoQueueRequesterGuid.load();
    if (!requesterGuid)
        return true;

    Player* requester = ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(requesterGuid));
    if (!requester || !requester->IsInWorld())
        return false;

    if (!target || target->GetMap() != requester->GetMap())
        return false;

    // The old check allowed every hostile target as soon as the requester was
    // in combat. That let a filler chain-pull unrelated packs while the real
    // player was still fighting the first one. LFG fillers may now engage only
    // the requester's actual target or an enemy already attacking the party.
    if (requester->GetVictim() == target)
        return true;

    for (Unit* attacker : requester->getAttackers())
        if (attacker == target)
            return true;

    if (Unit* victim = target->GetVictim())
    {
        if (Player* victimOwner =
            victim->GetCharmerOrOwnerPlayerOrPlayerItself())
        {
            if (victimOwner == requester ||
                requester->IsInSameGroupWith(victimOwner))
                return true;
        }
    }

    return false;
}

uint32 PlayerbotAI::GetReactDelay()
{
    uint32 base = sPlayerbotAIConfig->reactDelay;  // Default 100(ms)

    // If dynamic react delay is disabled, use a static calculation
    if (!sPlayerbotAIConfig->dynamicReactDelay)
    {
        if (HasRealPlayerMaster())
            return base;

        bool inBG = bot->InBattleground() || bot->InArena();
        if (/*sPlayerbotAIConfig->fastReactInBG &&*/ inBG)
            return base;

        bool inCombat = bot->IsInCombat();

        if (!inCombat)
            return base * 10.0f;

        else if (inCombat)
            return base * 2.5f;

        return base;
    }

    // Dynamic react delay calculation:

    if (HasRealPlayerMaster())
        return base;

    float multiplier = 1.0f;
    bool inBG = bot->InBattleground() || bot->InArena();

    /*if (inBG)
    {
        if (bot->IsInCombat() || _currentState == BOT_STATE_COMBAT)
        {
            multiplier = sPlayerbotAIConfig->fastReactInBG ? 2.5f : 5.0f;
            return base * multiplier;
        }
        else
        {
            multiplier = sPlayerbotAIConfig->fastReactInBG ? 1.0f : 10.0f;
            return base * multiplier;
        }
    }*/

    // When in combat, return 5 times the base
    if (bot->IsInCombat() || _currentState == BOT_STATE_COMBAT)
    {
        multiplier = 5.0f;
        return base * multiplier;
    }

    // When not resting, return 10-30 times the base
    if (!bot->HasFlag(PLAYER_FIELD_PLAYER_FLAGS, PLAYER_FLAGS_RESTING))
    {
        multiplier = urand(10, 30);
        return base * multiplier;
    }

    // In other cases, return 20-200 times the base
    multiplier = urand(20, 200);
    return base * multiplier;
}

void PlayerbotAI::UpdateAI(uint32 elapsed, bool minimal)
{
    // Handle the AI check delay
    if (nextAICheckDelay > elapsed)
        nextAICheckDelay -= elapsed;
    else
        nextAICheckDelay = 0;

    // Early return if bot is in invalid state
    if (!bot || !bot->IsInWorld() || !bot->GetSession() || bot->GetSession()->isLogingOut() ||
        bot->IsDuringRemoveFromWorld())
        return;

    // Playerbot-controlled pets must never acquire targets on their own. This
    // covers regular pets (hunter/warlock), permanent guardians (DK ghoul,
    // water elemental) and any other class guardian exposed through the same
    // owner slot. The combat strategy explicitly commands the pet only after
    // HasEngagedTarget confirms that its owner has started the attack.
    if (Guardian* pet = bot->GetGuardianPet())
    {
        pet->SetReactState(REACT_PASSIVE);
        if (Unit* petTarget = pet->GetVictim())
        {
            if (!HasEngagedTarget(petTarget))
            {
                pet->AttackStop();
                pet->SetTarget(ObjectGuid::Empty);
                if (CharmInfo* charmInfo = pet->GetCharmInfo())
                {
                    charmInfo->SetIsCommandAttack(false);
                    charmInfo->SetIsAtStay(false);
                    charmInfo->SetIsFollowing(false);
                    charmInfo->SetIsCommandFollow(true);
                    charmInfo->SetIsReturning(true);
                    charmInfo->SetCommandState(COMMAND_FOLLOW);
                }
                pet->GetMotionMaster()->Clear();
                pet->GetMotionMaster()->MoveFollow(
                    bot, PET_FOLLOW_DIST, pet->GetFollowAngle());
            }
        }
    }

    // Playerbot sessions are not driven through WorldSession's normal socket
    // receive queue. Process synthetic time-sync replies here, after the login
    // callback and the outgoing SendPacket stack have completely returned.
    while (!_pendingTimeSyncCounters.empty())
    {
        WorldPacket response(CMSG_TIME_SYNC_RESP, 8);
        response << _pendingTimeSyncCounters.front() << uint32(getMSTime());
        _pendingTimeSyncCounters.pop();
        bot->GetSession()->HandleTimeSyncResp(response);
    }

    // Instance navmeshes occasionally place a following bot on geometry
    // below a narrow ramp/platform (notably the Hollowed Out Tree in Siege of
    // Niuzao Temple). Recover only the unambiguous "directly below the real
    // player and separated by collision" case, after it persists for a full
    // second. The narrow 2D/vertical limits avoid skipping legitimate paths
    // between different dungeon floors.
    Player* followRecoveryMaster = GetMaster();
    bool canRecoverFollow = followRecoveryMaster &&
        !GET_PLAYERBOT_AI(followRecoveryMaster) &&
        followRecoveryMaster->IsInWorld() &&
        followRecoveryMaster->GetMap() == bot->GetMap() &&
        bot->GetMap() && bot->GetMap()->Instanceable() &&
        !bot->IsBeingTeleported() &&
        !followRecoveryMaster->IsBeingTeleported() &&
        !bot->GetVehicle() && !followRecoveryMaster->GetVehicle() &&
        !bot->GetTransport() && !followRecoveryMaster->GetTransport();
    bool invalidFollowPosition = canRecoverFollow &&
        followRecoveryMaster->GetPositionZ() - bot->GetPositionZ() > 5.0f &&
        bot->GetExactDist2d(followRecoveryMaster) < 12.0f &&
        !bot->IsWithinLOSInMap(followRecoveryMaster);

    if (invalidFollowPosition)
    {
        uint32 now = getMSTime();
        if (!_invalidFollowPositionSince)
            _invalidFollowPositionSince = now;
        else if (getMSTimeDiff(_invalidFollowPositionSince, now) >= 1000)
        {
            float oldZ = bot->GetPositionZ();
            float x, y, z;
            followRecoveryMaster->GetClosePoint(x, y, z,
                bot->GetObjectSize(), 1.5f,
                static_cast<float>(M_PI));
            z += 0.5f;
            bot->GetMotionMaster()->Clear();
            bot->NearTeleportTo(x, y, z,
                followRecoveryMaster->GetOrientation());

            if (Pet* pet = bot->GetPet())
            {
                float petX, petY, petZ;
                bot->GetClosePoint(petX, petY, petZ,
                    pet->GetObjectSize(), PET_FOLLOW_DIST,
                    pet->GetFollowAngle());
                petZ += 0.5f;
                pet->GetMotionMaster()->Clear();
                pet->NearTeleportTo(petX, petY, petZ,
                    bot->GetOrientation());
            }

            TC_LOG_WARN("server",
                "Playerbot recovered from invalid instance follow position bot=%s guid=%u map=%u old-z=%.2f master=%s master-z=%.2f",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                bot->GetMapId(), oldZ,
                followRecoveryMaster->GetName().c_str(),
                followRecoveryMaster->GetPositionZ());
            _invalidFollowPositionSince = 0;
        }
    }
    else
        _invalidFollowPositionSince = 0;

    // Strategy containers belong to this map update thread. The LFG
    // coordinator only posts an atomic request so actions cannot be destroyed
    // while Engine::DoNextAction is using them.
    if (_lfgAutoQueueInitializePending.exchange(false))
    {
        uint32 requesterGuid = _lfgAutoQueueRequesterGuid.load();
        Player* requester = requesterGuid ?
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(requesterGuid)) : nullptr;
        Group* botGroup = bot->GetGroup(GroupSlot::Instance);
        if (!botGroup)
            botGroup = bot->GetGroup();
        Group* requesterGroup = requester ?
            requester->GetGroup(GroupSlot::Instance) : nullptr;
        if (requester && !requesterGroup)
            requesterGroup = requester->GetGroup();

        if (requester && botGroup && requesterGroup == botGroup)
        {
            SetMaster(requester);
            Reset(false);
            ResetStrategies();
            ChangeStrategy("+follow,-stay,-lfg,-bg", BOT_STATE_NON_COMBAT);
        }
        else if (requesterGuid)
        {
            // Teleport/group visibility may lag by one map tick.
            _lfgAutoQueueInitializePending.store(true);
        }
    }

    // Buff maintenance is requested by the world coordinator but executed on
    // this bot's map thread. Never cast during a pull, teleport, cleanup, or
    // while any same-map party member is fighting. A later periodic request
    // retries naturally if the group was busy on this tick.
    if (_lfgPreparationBuffPending.exchange(false))
    {
        uint32 requesterGuid = _lfgAutoQueueRequesterGuid.load();
        Player* requester = requesterGuid ?
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(requesterGuid)) : nullptr;
        Group* group = bot->GetGroup(GroupSlot::Instance);
        if (!group)
            group = bot->GetGroup();
        Group* requesterGroup = requester ?
            requester->GetGroup(GroupSlot::Instance) : nullptr;
        if (requester && !requesterGroup)
            requesterGroup = requester->GetGroup();

        bool safe = requester && requester->IsInWorld() &&
            requester->GetMap() == bot->GetMap() && group &&
            requesterGroup == group && bot->IsAlive() &&
            !bot->IsBeingTeleported() && !requester->IsBeingTeleported() &&
            !bot->IsPlayerbotCleanupPending();
        if (safe)
        {
            for (GroupReference* ref = group->GetFirstMember(); ref;
                 ref = ref->next())
            {
                Player* member = ref->GetSource();
                if (member && member->GetMap() == bot->GetMap() &&
                    (member->IsInCombat() || member->GetVictim() ||
                     !member->getAttackers().empty()))
                {
                    safe = false;
                    break;
                }
            }
        }

        if (safe && CastAutomatedPvpPreparationBuff(bot))
            TC_LOG_INFO("server",
                "AutoQueue LFG map-thread preparation cast bot=%s guid=%u requester=%u map=%u",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                requesterGuid, bot->GetMapId());
    }

    // A bot logged in only to fill an LFG request must not wander, grind or
    // acquire an open-world target while the queue/proposal is being built.
    // Its equipment/session maintenance remains available to the manager.
    if (IsLfgAutoQueueReserved())
    {
        if (bot->IsInCombat())
            bot->CombatStopWithPets(true);
        bot->AttackStop();
        bot->SetTarget(ObjectGuid::Empty);
        SetNextCheckDelay(100);
        return;
    }

    // Native AI may reconsider its master after group/map transitions. A bot
    // owned by an active LFG request must remain attached to that real player
    // for the complete dungeon, not choose another bot or resume autonomous
    // roaming. Reapply the follow strategy only when repair is needed.
    uint32 const lfgRequesterGuid = _lfgAutoQueueRequesterGuid.load();
    if (lfgRequesterGuid)
    {
        Player* requester = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(lfgRequesterGuid));
        Group* botGroup = bot->GetGroup(GroupSlot::Instance);
        if (!botGroup)
            botGroup = bot->GetGroup();
        Group* requesterGroup = requester ?
            requester->GetGroup(GroupSlot::Instance) : nullptr;
        if (requester && !requesterGroup)
            requesterGroup = requester->GetGroup();

        if (requester && requester->IsInWorld() &&
            requester->GetMap() == bot->GetMap() && botGroup &&
            requesterGroup == botGroup && GetMaster() != requester)
        {
            SetMaster(requester);
            ResetStrategies();
            ChangeStrategy("+follow,-stay,-lfg,-bg",
                BOT_STATE_NON_COMBAT);
            TC_LOG_WARN("server",
                "AutoQueue LFG repaired requester master/follow bot=%s guid=%u requester=%s requester-guid=%u map=%u",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                requester->GetName().c_str(), lfgRequesterGuid,
                bot->GetMapId());
        }

        Value<Unit*>* currentTargetValue =
            _aiObjectContext->GetValue<Unit*>("current target");
        Unit* currentTarget = currentTargetValue ?
            currentTargetValue->Get() : nullptr;
        if (currentTarget && bot->IsValidAttackTarget(currentTarget) &&
            !CanLfgAutoQueueEngage(currentTarget))
        {
            currentTargetValue->Set(nullptr);
            bot->AttackStop();
            bot->SetTarget(ObjectGuid::Empty);
            bot->StopMoving();
            if (Pet* pet = bot->GetPet())
                pet->AttackStop();
        }
    }

    AllowActivity();

    if (!CanUpdateAI())
        return;

    // Handle the current spell
    Spell* currentSpell = bot->GetCurrentSpell(CURRENT_GENERIC_SPELL);
    if (!currentSpell)
        currentSpell = bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
    if (currentSpell)
    {
        const SpellInfo* spellInfo = currentSpell->GetSpellInfo();
        if (spellInfo && currentSpell->getState() == SPELL_STATE_PREPARING)
        {
            Unit* spellTarget = currentSpell->m_targets.GetUnitTarget();
            // Interrupt if target is dead or spell can't target dead units
            if (spellTarget && !spellTarget->IsAlive() && !spellInfo->IsAllowingDeadTarget())
            {
                InterruptSpell();
                YieldThread(GetReactDelay());
                return;
            }

            bool isHeal = false;
            bool isSingleTarget = true;

            for (uint8 i = 0; i < 3; ++i)
            {
                if (!spellInfo->Effects[i].Effect)
                    continue;

                // Check if spell is a heal
                if (spellInfo->Effects[i].Effect == SPELL_EFFECT_HEAL ||
                    spellInfo->Effects[i].Effect == SPELL_EFFECT_HEAL_MAX_HEALTH ||
                    spellInfo->Effects[i].Effect == SPELL_EFFECT_HEAL_MECHANICAL)
                    isHeal = true;

                // Check if spell is single-target
                if ((spellInfo->Effects[i].TargetA.GetTarget() &&
                    spellInfo->Effects[i].TargetA.GetTarget() != TARGET_UNIT_TARGET_ALLY) ||
                    (spellInfo->Effects[i].TargetB.GetTarget() &&
                        spellInfo->Effects[i].TargetB.GetTarget() != TARGET_UNIT_TARGET_ALLY))
                {
                    isSingleTarget = false;
                }
            }

            // Interrupt if target ally has full health (heal by other member)
            if (isHeal && isSingleTarget && spellTarget && spellTarget->IsFullHealth())
            {
                InterruptSpell();
                YieldThread(GetReactDelay());
                return;
            }

            // Ensure bot is facing target if necessary
            if (spellTarget && !bot->HasInArc(CAST_ANGLE_IN_FRONT, spellTarget) &&
                (spellInfo->FacingCasterFlags & SPELL_FACING_FLAG_INFRONT))
            {
                sServerFacade->SetFacingTo(bot, spellTarget);
            }

            // Wait for spell cast
            YieldThread(GetReactDelay());
            return;
        }
    }

    // Update internal AI
    UpdateAIInternal(elapsed, minimal);
    YieldThread();
}

void PlayerbotAI::UpdateAIInternal([[maybe_unused]] uint32 elapsed, bool minimal)
{
    if (bot->IsBeingTeleported() || !bot->IsInWorld())
        return;

    std::string const mapString = WorldPosition(bot).isOverworld() ? std::to_string(bot->GetMapId()) : "I";
    PerformanceMonitorOperation* pmo =
            sPerformanceMonitor->start(PERF_MON_TOTAL, "PlayerbotAI::UpdateAIInternal " + mapString);

    ExternalEventHelper helper(_aiObjectContext);

    // logout if logout timer is ready or if instant logout is possible
    if (bot->GetSession()->isLogingOut())
    {
        WorldSession* botWorldSessionPtr = bot->GetSession();
        bool logout = botWorldSessionPtr->ShouldLogOut(time(nullptr));
        if (!master || !master->GetSession()->GetPlayer())
            logout = true;

        if (bot->HasFlag(PLAYER_FIELD_PLAYER_FLAGS, PLAYER_FLAGS_RESTING) || bot->HasUnitState(UNIT_STATE_IN_FLIGHT) ||
            botWorldSessionPtr->GetSecurity() >= AccountTypes::SEC_PLAYER)
        {
            logout = true;
        }

        if (master &&
            (master->HasFlag(PLAYER_FIELD_PLAYER_FLAGS, PLAYER_FLAGS_RESTING) || master->HasUnitState(UNIT_STATE_IN_FLIGHT) ||
                (master->GetSession() &&
                    master->GetSession()->GetSecurity() >= AccountTypes::SEC_PLAYER)))
        {
            logout = true;
        }

        if (logout)
        {
        }

        SetNextCheckDelay(sPlayerbotAIConfig->reactDelay);
        return;
    }

    botOutgoingPacketHandlers.Handle(helper);
    masterIncomingPacketHandlers.Handle(helper);
    masterOutgoingPacketHandlers.Handle(helper);

    DoNextAction(minimal);

    if (pmo)
        pmo->finish();
}

bool PlayerbotAI::DoSpecificAction(std::string const name, Event event, bool silent, std::string const qualifier)
{
    // Preparation buffs and a few administrative commands call this entry
    // point from the world thread. It shares cached Action objects and the AI
    // context with DoNextAction, so both paths must use the same lifetime lock.
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    std::ostringstream out;

    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
    {
        ActionResult res = _engines[i]->ExecuteAction(name, event, qualifier);
        switch (res)
        {
        case ACTION_RESULT_UNKNOWN:
            continue;
        case ACTION_RESULT_OK:
            if (!silent)
            {
                //PlaySound(TEXT_EMOTE_NOD);
            }
            return true;
        case ACTION_RESULT_IMPOSSIBLE:
            out << name << ": impossible";
            if (!silent)
            {
                //TellError(out.str());
                //PlaySound(TEXT_EMOTE_NO);
            }
            return false;
        case ACTION_RESULT_USELESS:
            out << name << ": useless";
            if (!silent)
            {
                //TellError(out.str());
                //PlaySound(TEXT_EMOTE_NO);
            }
            return false;
        case ACTION_RESULT_FAILED:
            if (!silent)
            {
                //out << name << ": failed";
                //TellError(out.str());
            }
            return false;
        }
    }

    if (!silent)
    {
        //out << name << ": unknown action";
        //TellError(out.str());
    }

    return false;
}

bool PlayerbotAI::AllowActive(ActivityType activityType)
{
    return true;
    auto HasRealPlayers = ([](Map* map)
    {
        Map::PlayerList const& players = map->GetPlayers();
        if (players.isEmpty())
        {
            return false;
        }

        for (auto const& itr : players)
        {
            Player* player = itr.GetSource();
            if (!player || !player->IsVisible())
            {
                continue;
            }

            PlayerbotAI* botAI = GET_PLAYERBOT_AI(player);
            if (!botAI || botAI->IsRealPlayer() || botAI->HasRealPlayerMaster())
            {
                return true;
            }
        }

        return false;
    });

    auto ZoneHasRealPlayers = ([](Player * bot)
    {
        Map* map = bot->GetMap();
        if (!bot || !map)
        {
            return false;
        }

        for (Player* player : sRandomPlayerbotMgr->GetPlayers())
        {
            if (player->GetMapId() != bot->GetMapId())
                continue;

            if (player->IsGameMaster() && !player->IsVisible())
            {
                continue;
            }

            if (player->GetZoneId() == bot->GetZoneId())
            {
                PlayerbotAI* botAI = GET_PLAYERBOT_AI(player);
                if (!botAI || botAI->IsRealPlayer() || botAI->HasRealPlayerMaster())
                {
                    return true;
                }
            }
        }

        return false;
    });

    // when botActiveAlone is 100% and smartScale disabled
    //if (sPlayerbotAIConfig->botActiveAlone >= 100 && !sPlayerbotAIConfig->botActiveAloneSmartScale)
    {
        //return true;
    }

    // Is in combat. Always defend yourself.
    if (activityType != OUT_OF_PARTY_ACTIVITY && activityType != PACKET_ACTIVITY)
    {
        if (bot->IsInCombat())
        {
            return true;
        }
    }
    
    // only keep updating till initializing time has completed,
    // which prevents unneeded expensive GameTime calls.
    if (_isBotInitializing)
    {
        _isBotInitializing = sWorld->GetUptime() < sPlayerbotAIConfig->maxRandomBots * 0.11;

        // no activity allowed during bot initialization
        if (_isBotInitializing)
        {
            return false;
        }
    }

    // General exceptions
    if (activityType == PACKET_ACTIVITY)
    {
        return true;
    }

    // bg, raid, dungeon
    if (!WorldPosition(bot).isOverworld())
    {
        return true;
    }

    // bot map has active players.
    //if (sPlayerbotAIConfig->BotActiveAloneForceWhenInMap)
    {
        if (HasRealPlayers(bot->GetMap()))
        {
            return true;
        }
    }

    // bot zone has active players.
    //if (sPlayerbotAIConfig->BotActiveAloneForceWhenInZone)
    {
        if (ZoneHasRealPlayers(bot))
        {
            return true;
        }
    }

    // when in real guild
    /*if (sPlayerbotAIConfig->BotActiveAloneForceWhenInGuild)
    {
        if (IsInRealGuild())
        {
            return true;
        }
    }*/

    // Player is near. Always active.
    /*if (HasPlayerNearby(sPlayerbotAIConfig->BotActiveAloneForceWhenInRadius))
    {
        return true;
    }*/

    // Has player master. Always active.
    if (GetMaster())
    {
        PlayerbotAI* masterBotAI = GET_PLAYERBOT_AI(GetMaster());
        if (!masterBotAI || masterBotAI->IsRealPlayer())
        {
            return true;
        }
    }

    // if grouped up
    Group* group = bot->GetGroup();
    if (group)
    {
        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
        {
            Player* member = gref->GetSource();
            if (!member || !member->IsInWorld() && member->GetMapId() != bot->GetMapId())
            {
                continue;
            }

            if (member == bot)
            {
                continue;
            }

            PlayerbotAI* memberBotAI = GET_PLAYERBOT_AI(member);
            {
                if (!memberBotAI || memberBotAI->HasRealPlayerMaster())
                {
                    return true;
                }
            }

            if (group->IsLeader(member->GetGUID()))
            {
                if (!memberBotAI->AllowActivity(PARTY_ACTIVITY))
                {
                    return false;
                }
            }
        }
    }

    // In bg queue. Speed up bg queue/join.
    if (bot->InBattlegroundQueue())
    {
        return true;
    }

    //bool isLFG = false;
    //if (group)
    //{
    //    if (sLFGMgr->GetState(group->GetGUID()) != lfg::LFG_STATE_NONE)
    //    {
    //        isLFG = true;
    //    }
    //}
    //if (sLFGMgr->GetState(bot->GetGUID()) != lfg::LFG_STATE_NONE)
    //{
    //    isLFG = true;
    //}
    //if (isLFG)
    //{
    //    return true;
    //}

    //// HasFriend
    //if (sPlayerbotAIConfig->BotActiveAloneForceWhenIsFriend)
    //{
    //    for (auto& player : sRandomPlayerbotMgr->GetPlayers())
    //    {
    //        if (!player || !player->IsInWorld() || !player->GetSocial() || !bot->GetGUID())
    //        {
    //            continue;
    //        }

    //        if (player->GetSocial()->HasFriend(bot->GetGUID()))
    //        {
    //            return true;
    //        }
    //    }
    //}

    //// Force the bots to spread
    //if (activityType == OUT_OF_PARTY_ACTIVITY || activityType == GRIND_ACTIVITY)
    //{
    //    if (HasManyPlayersNearby(10, 40))
    //    {
    //        return true;
    //    }
    //}

    // Bots don't need to move using PathGenerator.
    if (activityType == DETAILED_MOVE_ACTIVITY)
    {
        return false;
    }

    /*if (sPlayerbotAIConfig->botActiveAlone <= 0)
    {
        return false;
    }*/

    // #######################################################################################
    // All mandatory conditations are checked to be active or not, from here the remaining
    // situations are usable for scaling when enabled.
    // #######################################################################################

    // Below is code to have a specified % of bots active at all times.
    // The default is 10%. With 0.1% of all bots going active or inactive each minute.
    /*uint32 mod = sPlayerbotAIConfig->botActiveAlone > 100 ? 100 : sPlayerbotAIConfig->botActiveAlone;
    if (sPlayerbotAIConfig->botActiveAloneSmartScale &&
        bot->GetLevel() >= sPlayerbotAIConfig->botActiveAloneSmartScaleWhenMinLevel &&
        bot->GetLevel() <= sPlayerbotAIConfig->botActiveAloneSmartScaleWhenMaxLevel)
    {
        mod = AutoScaleActivity(mod);
    }

    uint32 ActivityNumber =
        GetFixedBotNumer(BotTypeNumber::ACTIVITY_TYPE_NUMBER, 100,
            sPlayerbotAIConfig->botActiveAlone * static_cast<float>(mod) / 100 * 0.01f);

    return ActivityNumber <=
        (sPlayerbotAIConfig->botActiveAlone * mod) /
        100;  // The given percentage of bots should be active and rotate 1% of those active bots each minute.
    */

    return false;
}

bool PlayerbotAI::AllowActivity(ActivityType activityType, bool checkNow)
{
    if (!_allowActiveCheckTimer[activityType])
        _allowActiveCheckTimer[activityType] = time(nullptr);

    if (!checkNow && time(nullptr) < (_allowActiveCheckTimer[activityType] + 5))
        return _allowActive[activityType];

    bool allowed = AllowActive(activityType);
    _allowActive[activityType] = allowed;
    _allowActiveCheckTimer[activityType] = time(nullptr);
    return allowed;
}

void PlayerbotAI::Reset(bool full)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    if (bot->HasUnitState(UNIT_STATE_IN_FLIGHT))
        return;

    WorldSession* botWorldSessionPtr = bot->GetSession();
    bool logout = botWorldSessionPtr->ShouldLogOut(time(nullptr));

    // cancel logout
    if (!logout && bot->GetSession()->isLogingOut())
    {
        //WorldPackets::Character::LogoutCancel data = WorldPacket(CMSG_LOGOUT_CANCEL);
        //bot->GetSession()->HandleLogoutCancelOpcode(data);
        //TellMaster("Logout cancelled!");
    }

    _currentEngine = _engines[BOT_STATE_NON_COMBAT];
    _currentState = BOT_STATE_NON_COMBAT;
    nextAICheckDelay = 0;
    //whispers.clear();

    _aiObjectContext->GetValue<Unit*>("old target")->Set(nullptr);
    _aiObjectContext->GetValue<Unit*>("current target")->Set(nullptr);
    _aiObjectContext->GetValue<GuidVector>("prioritized targets")->Reset();
    _aiObjectContext->GetValue<ObjectGuid>("pull target")->Set(ObjectGuid::Empty);
    //_aiObjectContext->GetValue<GuidPosition>("rpg target")->Set(GuidPosition());
    //_aiObjectContext->GetValue<LootObject>("loot target")->Set(LootObject());
    //_aiObjectContext->GetValue<uint32>("lfg proposal")->Set(0);
    bot->SetTarget(ObjectGuid::Empty);

    LastSpellCast& lastSpell = _aiObjectContext->GetValue<LastSpellCast&>("last spell cast")->Get();
    lastSpell.Reset();

    if (full)
    {
        _aiObjectContext->GetValue<LastMovement&>("last movement")->Get().Set(nullptr);
        //_aiObjectContext->GetValue<LastMovement&>("last area trigger")->Get().Set(nullptr);
        //_aiObjectContext->GetValue<LastMovement&>("last taxi")->Get().Set(nullptr);
        //_aiObjectContext->GetValue<TravelTarget*>("travel target")->Get()->setTarget(sTravelMgr->nullTravelDestination, sTravelMgr->nullWorldPosition, true);
        //_aiObjectContext->GetValue<TravelTarget*>("travel target")->Get()->setStatus(TRAVEL_STATUS_EXPIRED);
        //_aiObjectContext->GetValue<TravelTarget*>("travel target")->Get()->setExpireIn(1000);
        _rpgInfo = NewRpgInfo();
    }

    //_aiObjectContext->GetValue<GuidSet&>("ignore rpg target")->Get().clear();

    bot->GetMotionMaster()->Clear();

    InterruptSpell();

    if (full)
    {
        for (uint8 i = 0; i < BOT_STATE_MAX; i++)
        {
            _engines[i]->Init();
        }
    }
}

void PlayerbotAI::ResetStrategies()
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
        _engines[i]->removeAllStrategies();

    AiFactory::AddDefaultCombatStrategies(bot, this, _engines[BOT_STATE_COMBAT]);
    AiFactory::AddDefaultNonCombatStrategies(bot, this, _engines[BOT_STATE_NON_COMBAT]);
    AiFactory::AddDefaultDeadStrategies(bot, this, _engines[BOT_STATE_DEAD]);
    //if (sPlayerbotAIConfig->applyInstanceStrategies)
        //ApplyInstanceStrategies(bot->GetMapId());

    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
        _engines[i]->Init();
}

void PlayerbotAI::ReInitCurrentEngine()
{
    // InterruptSpell();
    _currentEngine->Init();
}

void PlayerbotAI::ChangeEngine(BotState type)
{
    Engine* engine = _engines[type];

    if (_currentEngine != engine)
    {
        _currentEngine = engine;
        _currentState = type;
        ReInitCurrentEngine();

        switch (type)
        {
        case BOT_STATE_COMBAT:
            //TC_LOG_DEBUG("playerbots",  "=== %s COMBAT ===", bot->GetName().c_str());
            break;
        case BOT_STATE_NON_COMBAT:
            //TC_LOG_DEBUG("playerbots",  "=== %s NON-COMBAT ===", bot->GetName().c_str());
            break;
        case BOT_STATE_DEAD:
            //TC_LOG_DEBUG("playerbots",  "=== %s DEAD ===", bot->GetName().c_str());
            break;
        default:
            break;
        }
    }
}
void PlayerbotAI::ChangeStrategy(std::string const names, BotState type)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    Engine* e = _engines[type];
    if (!e)
        return;

    e->ChangeStrategy(names);
}

void PlayerbotAI::ClearStrategies(BotState type)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    Engine* e = _engines[type];
    if (!e)
        return;

    e->removeAllStrategies();
}

std::vector<std::string> PlayerbotAI::GetStrategies(BotState type)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    Engine* e = _engines[type];
    if (!e)
        return std::vector<std::string>();

    return e->GetStrategies();
}

void PlayerbotAI::DoNextAction(bool min)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    if (!bot->IsInWorld() || bot->IsBeingTeleported() || (GetMaster() && GetMaster()->IsBeingTeleported()))
    {
        SetNextCheckDelay(sPlayerbotAIConfig->globalCoolDown);
        return;
    }

    if (bot->HasUnitState(UNIT_STATE_IN_FLIGHT))
    {
        SetNextCheckDelay(sPlayerbotAIConfig->passiveDelay);
        return;
    }

    // Change engine if just died
    bool isBotAlive = bot->IsAlive();
    if (_currentEngine != _engines[BOT_STATE_DEAD] && !isBotAlive)
    {
        bot->StopMoving();
        bot->GetMotionMaster()->Clear();
        bot->GetMotionMaster()->MoveIdle();

        // Death Count to prevent skeleton piles
        Player* master = GetMaster();  // warning here - whipowill
        if (!HasActivePlayerMaster() && !bot->InBattleground())
        {
            uint32 dCount = _aiObjectContext->GetValue<uint32>("death count")->Get();
            _aiObjectContext->GetValue<uint32>("death count")->Set(++dCount);
        }

        _aiObjectContext->GetValue<Unit*>("current target")->Set(nullptr);
        //_aiObjectContext->GetValue<Unit*>("enemy player target")->Set(nullptr);
        //_aiObjectContext->GetValue<ObjectGuid>("pull target")->Set(ObjectGuid::Empty);
        //_aiObjectContext->GetValue<LootObject>("loot target")->Set(LootObject());

        ChangeEngine(BOT_STATE_DEAD);
        return;
    }

    // Change engine if just ressed
    if (_currentEngine == _engines[BOT_STATE_DEAD] && isBotAlive)
    {
        ChangeEngine(BOT_STATE_NON_COMBAT);
        return;
    }

    // Clear targets if in combat but sticking with old data
    if (_currentEngine == _engines[BOT_STATE_NON_COMBAT] && bot->IsInCombat())
    {
        Unit* currentTarget = _aiObjectContext->GetValue<Unit*>("current target")->Get();
        if (currentTarget != nullptr)
        {
            _aiObjectContext->GetValue<Unit*>("current target")->Set(nullptr);
        }
    }

    bool minimal = !AllowActivity();
    _currentEngine->DoNextAction(nullptr, 0, (minimal || min));

    if (minimal)
    {
        if (!bot->isAFK() && !bot->InBattleground() && !HasRealPlayerMaster())
            bot->ToggleAFK();

        SetNextCheckDelay(sPlayerbotAIConfig->passiveDelay);
        return;
    }
    else if (bot->isAFK())
        bot->ToggleAFK();

    Group* group = bot->GetGroup();
    PlayerbotAI* masterBotAI = nullptr;
    if (master)
        masterBotAI = GET_PLAYERBOT_AI(master);

    // Test BG master set
    if ((!master || (masterBotAI && !masterBotAI->IsRealPlayer())) && group)
    {
        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (!botAI)
        {
            return;
        }

        // Ideally we want to have the leader as master.
        Player* newMaster = botAI->GetGroupMaster();
        Player* playerMaster = nullptr;

        // Are there any non-bot players in the group?
        if (!newMaster || GET_PLAYERBOT_AI(newMaster))
        {
            for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
            {
                Player* member = gref->GetSource();
                if (!member || member == bot || member == newMaster || !member->IsInWorld() ||
                    !member->IsInSameRaidWith(bot))
                    continue;

                PlayerbotAI* memberBotAI = GET_PLAYERBOT_AI(member);
                if (memberBotAI)
                {
                    if (memberBotAI->IsRealPlayer() && !bot->InBattleground())
                        playerMaster = member;

                    continue;
                }

                // Same BG checks (optimize checking conditions here)
                //if (bot->InBattleground() && bot->GetBattleground() &&
                //    bot->GetBattleground()->GetBgTypeID() == BATTLEGROUND_AV && !GET_PLAYERBOT_AI(member) &&
                //    member->InBattleground() && bot->GetMapId() == member->GetMapId())
                //{
                //    // Skip if same BG but same subgroup or lower level
                //    if (!group->SameSubGroup(bot, member) || member->GetLevel() < bot->GetLevel())
                //        continue;

                //    // Follow real player only if higher honor points
                //    uint32 honorpts = member->GetHonorPoints();
                //    if (bot->GetHonorPoints() && honorpts < bot->GetHonorPoints())
                //        continue;

                //    playerMaster = member;
                //    continue;
                //}

                //if (bot->InBattleground())
                //    continue;

                newMaster = member;
                break;
            }
        }

        if (!newMaster && playerMaster)
            newMaster = playerMaster;

        if (newMaster && (!master || master != newMaster) && bot != newMaster)
        {
            master = newMaster;
            botAI->SetMaster(newMaster);
            botAI->ResetStrategies();
            botAI->ChangeStrategy("+follow", BOT_STATE_NON_COMBAT);

            if (botAI->GetMaster() == botAI->GetGroupMaster())
                botAI->TellMaster("Hello, I follow you!");
            else
                botAI->TellMaster(!urand(0, 2) ? "Hello!" : "Hi!");
        }
    }

    if (master && master->IsInWorld())
    {
        float distance = sServerFacade->GetDistance2d(bot, master);
        if (master->m_movementInfo.HasMovementFlag(MOVEMENTFLAG_WALKING) && distance < 20.0f)
            bot->m_movementInfo.AddMovementFlag(MOVEMENTFLAG_WALKING);
        else
            bot->m_movementInfo.RemoveMovementFlag(MOVEMENTFLAG_WALKING);

        if (master->IsSitState() && nextAICheckDelay < 1000)
        {
            if (!bot->isMoving() && distance < 10.0f)
                bot->SetStandState(UNIT_STAND_STATE_SIT);
        }
        else if (nextAICheckDelay < 1000)
            bot->SetStandState(UNIT_STAND_STATE_STAND);
    }
    else if (bot->m_movementInfo.HasMovementFlag(MOVEMENTFLAG_WALKING))
        bot->m_movementInfo.RemoveMovementFlag(MOVEMENTFLAG_WALKING);
    else if ((nextAICheckDelay < 1000) && bot->IsSitState())
        bot->SetStandState(UNIT_STAND_STATE_STAND);


    bool hasMountAura = bot->HasAuraType(SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED) ||
        bot->HasAuraType(SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED);
    if (hasMountAura && !bot->IsMounted())
    {
        bot->RemoveAurasByType(SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED);
        bot->RemoveAurasByType(SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED);
    }
}

void PlayerbotAI::HandleTeleportAck()
{
    if (IsRealPlayer())
        return;

    bot->GetMotionMaster()->Clear(true);
    bot->StopMoving();
    if (bot->IsBeingTeleportedNear())
    {
        // Temporary fix for instance can not enter
        if (!bot->IsInWorld())
        {
            bot->GetMap()->AddPlayerToMap(bot);
        }
        while (bot->IsInWorld() && bot->IsBeingTeleportedNear())
        {
            Player* plMover = bot->m_mover->ToPlayer();
            if (!plMover)
                return;

            ObjectGuid guid = plMover->GetGUID();
            WorldPacket p = WorldPacket(CMSG_MOVE_TELEPORT_ACK, 20);
            p << (uint32)0;  // supposed to be flags? not used currently
            p << (uint32)0;  // time - not currently used
            
            p.WriteBit(guid[0]);
            p.WriteBit(guid[7]);
            p.WriteBit(guid[3]);
            p.WriteBit(guid[5]);
            p.WriteBit(guid[4]);
            p.WriteBit(guid[6]);
            p.WriteBit(guid[1]);
            p.WriteBit(guid[2]);

            p.WriteByteSeq(guid[4]);
            p.WriteByteSeq(guid[1]);
            p.WriteByteSeq(guid[6]);
            p.WriteByteSeq(guid[7]);
            p.WriteByteSeq(guid[0]);
            p.WriteByteSeq(guid[2]);
            p.WriteByteSeq(guid[5]);
            p.WriteByteSeq(guid[3]);
            
            bot->GetSession()->HandleMoveTeleportAck(p);
        };
    }
    if (bot->IsBeingTeleportedFar())
    {
        while (bot->IsBeingTeleportedFar())
        {
            bot->GetSession()->HandleMoveWorldportAck();
        }
        // SetNextCheckDelay(urand(2000, 5000));
        //if (sPlayerbotAIConfig->applyInstanceStrategies)
            //ApplyInstanceStrategies(bot->GetMapId(), true);
        Reset(true);
    }
    SetNextCheckDelay(sPlayerbotAIConfig->globalCoolDown);
}

void PlayerbotAI::HandleBotOutgoingPacket(WorldPacket const& packet)
{
    if (packet.empty())
        return;
    if (!bot || !bot->IsInWorld() || bot->IsDuringRemoveFromWorld())
    {
        return;
    }

    //TC_LOG_INFO("playerbots", "Player: %s Received packet %s", bot->GetName().c_str(), GetOpcodeNameForLogging((OpcodeServer)packet->GetOpcode()).c_str());

    switch (packet.GetOpcode())
    {
    case SMSG_SPELL_FAILURE:
    {
        return;
    }
    case SMSG_SPELL_DELAYED:
    {
        return;
    }
    case SMSG_EMOTE:  // do not react to NPC emotes
    {
        return;
    }
    case SMSG_MESSAGECHAT:  // do not react to self or if not ready to reply
    {
        return;
    }
    case SMSG_MOVE_KNOCK_BACK:  // handle knockbacks
    {
        return;
    }
    case SMSG_TIME_SYNC_REQ:
    {
        WorldPacket p = packet;
        uint32 counter;
        p >> counter;

        // SendPacket invokes this hook while Player::SendTimeSync is still on
        // the stack. Handling the synthetic client reply synchronously here
        // re-enters the session during login and can invalidate the player
        // state when several offline bots are staged at once. Save only the
        // counter; UpdateAI handles it after the login stack has returned.
        _pendingTimeSyncCounters.push(counter);
        break;
    }
    default:
        botOutgoingPacketHandlers.AddPacket(packet);
        return;
    }
}

void PlayerbotAI::HandleMasterIncomingPacket(WorldPacket const& packet)
{
    masterIncomingPacketHandlers.AddPacket(packet);
}

void PlayerbotAI::HandleMasterOutgoingPacket(WorldPacket const& packet)
{
    masterOutgoingPacketHandlers.AddPacket(packet);
}

bool PlayerbotAI::HasRealPlayerMaster()
{
    if (master)
    {
        PlayerbotAI* masterBotAI = GET_PLAYERBOT_AI(master);
        return !masterBotAI || masterBotAI->IsRealPlayer();
    }

    return false;
}
bool PlayerbotAI::HasActivePlayerMaster()
{
    return master && !GET_PLAYERBOT_AI(master);
}

bool PlayerbotAI::HasPlayerNearby(WorldPosition* pos, float range)
{
    float sqRange = range * range;
    bool nearPlayer = false;
    for (auto& player : sRandomPlayerbotMgr->GetPlayers())
    {
        if (!player->IsGameMaster() || player->isGMVisible())
        {
            if (player->GetMapId() != bot->GetMapId())
                continue;

            if (pos->sqDistance(WorldPosition(player)) < sqRange)
                nearPlayer = true;

            // if player is far check farsight/cinematic camera
            WorldObject* viewObj = player->GetViewpoint();
            if (viewObj && viewObj != player)
            {
                if (pos->sqDistance(WorldPosition(viewObj)) < sqRange)
                    nearPlayer = true;
            }
        }
    }

    return nearPlayer;
}

bool PlayerbotAI::HasPlayerNearby(float range)
{
    WorldPosition botPos(bot);
    return HasPlayerNearby(&botPos, range);
};

bool PlayerbotAI::HasManyPlayersNearby(uint32 trigerrValue, float range)
{
    float sqRange = range * range;
    uint32 found = 0;

    for (auto& player : sRandomPlayerbotMgr->GetPlayers())
    {
        if ((!player->IsGameMaster() || player->isGMVisible()) && sServerFacade->GetDistance2d(player, bot) < sqRange)
        {
            found++;

            if (found >= trigerrValue)
                return true;
        }
    }

    return false;
}

bool PlayerbotAI::IsAlt()
{
    return HasRealPlayerMaster() && !sRandomPlayerbotMgr->IsRandomBot(bot);
}

bool PlayerbotAI::IsInVehicle(bool canControl, bool canCast, bool canAttack, bool canTurn, bool fixed)
{
    Vehicle* vehicle = bot->GetVehicle();
    if (!vehicle)
        return false;

    // get vehicle
    Unit* vehicleBase = vehicle->GetBase();
    if (!vehicleBase || !vehicleBase->IsAlive())
        return false;

    if (!vehicle->GetVehicleInfo())
        return false;

    // get seat
    VehicleSeatEntry const* seat = vehicle->GetSeatForPassenger(bot);
    if (!seat)
        return false;

    if (!(canControl || canCast || canAttack || canTurn || fixed))
        return true;

    if (canControl)
        return seat->CanControl() && !(vehicle->GetVehicleInfo()->m_flags & VEHICLE_FLAG_FIXED_POSITION);

    if (canCast)
        return (seat->m_flags & VEHICLE_SEAT_FLAG_CAN_CAST) != 0;

    if (canAttack)
        return (seat->m_flags & VEHICLE_SEAT_FLAG_CAN_ATTACK) != 0;

    if (canTurn)
        return (seat->m_flags & VEHICLE_SEAT_FLAG_ALLOW_TURNING) != 0;

    if (fixed)
        return (vehicle->GetVehicleInfo()->m_flags & VEHICLE_FLAG_FIXED_POSITION) != 0;

    return false;
}
bool PlayerbotAI::IsOpposing(Player* player)
{
    return IsOpposing(player->GetRace(), bot->GetRace());
}

bool PlayerbotAI::IsOpposing(uint8 race1, uint8 race2)
{
    return (IsAlliance(race1) && !IsAlliance(race2)) || (!IsAlliance(race1) && IsAlliance(race2));
}
bool PlayerbotAI::HasStrategy(std::string const name, BotState type)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    if (_engines[type])
        return _engines[type]->HasStrategy(name);
    return false;
}

bool PlayerbotAI::ContainsStrategy(StrategyType type)
{
    std::lock_guard<std::recursive_mutex> strategyLock(_strategyMutex);

    for (uint8 i = 0; i < BOT_STATE_MAX; i++)
    {
        if (_engines[i]->HasStrategyType(type))
            return true;
    }

    return false;
}

bool PlayerbotAI::CanMove()
{
    // do not allow if not vehicle driver
    //if (IsInVehicle() && !IsInVehicle(true))
        //return false;

    if (bot->isFrozen() || bot->IsPolymorphed() || (bot->isDead() && !bot->HasFlag(PLAYER_FIELD_PLAYER_FLAGS, PLAYER_FLAGS_GHOST)) ||
        bot->IsBeingTeleported() /* || bot->HasRootAura() || bot->HasSpiritOfRedemptionAura() || bot->HasConfuseAura()*/ ||
        bot->IsCharmed() /* || bot->HasStunAura()*/ || bot->IsInFlight() || bot->HasUnitState(UNIT_STATE_LOST_CONTROL))
        return false;

    return bot->GetMotionMaster()->GetCurrentMovementGeneratorType() != FLIGHT_MOTION_TYPE;
}

Unit* PlayerbotAI::GetUnit(ObjectGuid guid)
{
    if (!guid)
        return nullptr;

    return ObjectAccessor::GetUnit(*bot, guid);
}

Player* PlayerbotAI::GetPlayer(ObjectGuid guid)
{
    Unit* unit = GetUnit(guid);
    return unit ? unit->ToPlayer() : nullptr;
}

Player* PlayerbotAI::GetGroupMaster()
{
    if (!bot->InBattleground())
        if (Group* group = bot->GetGroup())
            if (Player* player = ObjectAccessor::FindPlayer(group->GetLeaderGUID()))
                return player;

    return master;
}

uint32 GetCreatureIdForCreatureTemplateId(uint32 creatureTemplateId)
{
    QueryResult results = WorldDatabase.PQuery("SELECT guid FROM `creature` WHERE id = %u LIMIT 1;", creatureTemplateId);
    if (results)
    {
        Field* fields = results->Fetch();
        return fields[0].GetUInt32();
    }
    return 0;
}

Unit* PlayerbotAI::GetUnit(CreatureData const* creatureData)
{
    if (!creatureData)
        return nullptr;

    Map* map = sMapMgr->FindMap(creatureData->mapId, 0);
    if (!map)
        return nullptr;

    uint32 spawnId = creatureData->spawnId;
    if (!spawnId)  // workaround for CreatureData with missing spawnId (this just uses first matching creatureId in DB,
        // but thats ok this method is only used for battlemasters and theres only 1 of each type)
        spawnId = GetCreatureIdForCreatureTemplateId(creatureData->id);
    auto creatureBounds = map->GetCreatureBySpawnIdStore().equal_range(spawnId);
    if (creatureBounds.first == creatureBounds.second)
        return nullptr;

    return creatureBounds.first->second;
}

Creature* PlayerbotAI::GetCreature(ObjectGuid guid)
{
    if (!guid)
        return nullptr;

    return ObjectAccessor::GetCreature(*bot, guid);
}

GameObject* PlayerbotAI::GetGameObject(ObjectGuid guid)
{
    if (!guid)
        return nullptr;

    return ObjectAccessor::GetGameObject(*bot, guid);
}
WorldObject* PlayerbotAI::GetWorldObject(ObjectGuid guid)
{
    if (!guid)
        return nullptr;

    return ObjectAccessor::GetWorldObject(*bot, guid);
}

bool PlayerbotAI::SayToParty(const std::string& msg)
{
    if (!bot->GetGroup())
        return false;

    /*WorldPacket data;
    ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, msg.c_str(), LANG_UNIVERSAL, CHAT_TAG_NONE, bot->GetGUID(),
        bot->GetName());

    for (auto reciever : GetPlayersInGroup())
    {
        sServerFacade->SendPacket(reciever, &data);
    }*/

    return true;
}

bool PlayerbotAI::SayToRaid(const std::string& msg)
{
    if (!bot->GetGroup() || bot->GetGroup()->isRaidGroup())
        return false;

    /*WorldPacket data;
    ChatHandler::BuildChatPacket(data, CHAT_MSG_RAID, msg.c_str(), LANG_UNIVERSAL, CHAT_TAG_NONE, bot->GetGUID(),
        bot->GetName());

    for (auto reciever : GetPlayersInGroup())
    {
        sServerFacade->SendPacket(reciever, &data);
    }*/

    return true;
}

bool PlayerbotAI::Yell(const std::string& msg)
{
    if (bot->GetTeamId() == TeamId::TEAM_ALLIANCE)
    {
        bot->Yell(msg, LANG_COMMON);
    }
    else
    {
        bot->Yell(msg, LANG_ORCISH);
    }

    return true;
}

bool PlayerbotAI::Say(const std::string& msg)
{
    if (bot->GetTeamId() == TeamId::TEAM_ALLIANCE)
    {
        bot->Say(msg, LANG_COMMON);
    }
    else
    {
        bot->Say(msg, LANG_ORCISH);
    }

    return true;
}

bool PlayerbotAI::Whisper(const std::string& msg, const std::string& receiverName)
{
    const auto receiver = ObjectAccessor::FindPlayerByName(receiverName);
    if (!receiver)
    {
        return false;
    }

    if (bot->GetTeamId() == TeamId::TEAM_ALLIANCE)
    {
        bot->Whisper(msg, LANG_COMMON, receiver);
    }
    else
    {
        bot->Whisper(msg, LANG_ORCISH, receiver);
    }

    return true;
}

bool PlayerbotAI::TellMaster(std::ostringstream& stream)
{
    return TellMaster(stream.str());
}

bool PlayerbotAI::TellMaster(std::string const text)
{
    if (!master || !TellMasterNoFacing(text))
        return false;

    if (!bot->isMoving() && !bot->IsInCombat() && bot->GetMapId() == master->GetMapId() &&
        !bot->HasUnitState(UNIT_STATE_IN_FLIGHT) && !bot->IsFlying())
    {
        if (!bot->HasInArc(EMOTE_ANGLE_IN_FRONT, master, sPlayerbotAIConfig->sightDistance))
            bot->SetFacingToObject(master);

        bot->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
    }

    return true;
}

bool PlayerbotAI::TellMasterNoFacing(std::ostringstream& stream)
{
    return TellMasterNoFacing(stream.str());
}

bool PlayerbotAI::TellMasterNoFacing(std::string const text)
{
    Player* master = GetMaster();
    PlayerbotAI* masterBotAI = nullptr;
    if (master)
        masterBotAI = GET_PLAYERBOT_AI(master);

    /*if ((!master || (masterBotAI && !masterBotAI->IsRealPlayer())) &&
        (sPlayerbotAIConfig->randomBotSayWithoutMaster || HasStrategy("debug", BOT_STATE_NON_COMBAT)))
    {
        bot->Say(text, (bot->GetTeamId() == TEAM_ALLIANCE ? LANG_COMMON : LANG_ORCISH));
        return true;
    }

    if (!IsTellAllowed(securityLevel))
        return false;

    time_t lastSaid = whispers[text];

    if (!lastSaid || (time(nullptr) - lastSaid) >= sPlayerbotAIConfig->repeatDelay / 1000)
    {
        whispers[text] = time(nullptr);

        ChatMsg type = CHAT_MSG_WHISPER;
        if (currentChat.second - time(nullptr) >= 1)
            type = currentChat.first;

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, type == CHAT_MSG_ADDON ? CHAT_MSG_PARTY : type,
            type == CHAT_MSG_ADDON ? LANG_ADDON : LANG_UNIVERSAL, bot, nullptr, text.c_str());
        master->SendDirectMessage(&data);
    }*/

    return true;
}
bool PlayerbotAI::TellError(std::string const text)
{
    Player* master = GetMaster();
    if (!master || GET_PLAYERBOT_AI(master))
        return false;

    if (PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(master))
        mgr->TellError(bot->GetName(), text);

    return false;
}

int32 PlayerbotAI::GetNearGroupMemberCount(float dis)
{
    int count = 1;  // yourself
    if (Group* group = bot->GetGroup())
    {
        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
        {
            Player* member = gref->GetSource();
            if (member == bot)  // calculated
                continue;

            if (!member || !member->IsInWorld())
                continue;

            if (member->GetMapId() != bot->GetMapId())
                continue;

            if (member->GetExactDist(bot) > dis)
                continue;

            count++;
        }
    }
    return count;
}

float PlayerbotAI::GetRange(std::string const type)
{
    float val = 0;
    if (_aiObjectContext)
        val = _aiObjectContext->GetValue<float>("range", type)->Get();

    if (abs(val) >= 0.1f)
        return val;

    if (type == "spell")
        return sPlayerbotAIConfig->spellDistance;

    if (type == "shoot")
        return sPlayerbotAIConfig->shootDistance;

    if (type == "flee")
        return sPlayerbotAIConfig->fleeDistance;

    if (type == "heal")
        return sPlayerbotAIConfig->healDistance;

    if (type == "melee")
        return sPlayerbotAIConfig->meleeDistance;

    return 0;
}

bool IsRealAura(Player* bot, AuraEffect const* aurEff, Unit const* unit)
{
    if (!aurEff)
        return false;

    if (!unit->IsHostileTo(bot))
        return true;

    SpellInfo const* spellInfo = aurEff->GetSpellInfo();

    uint32 stacks = aurEff->GetBase()->GetStackAmount();
    if (stacks >= spellInfo->StackAmount)
        return true;

    if (aurEff->GetCaster() == bot || spellInfo->IsPositive() ||
        spellInfo->Effects[aurEff->GetEffIndex()].IsAreaAuraEffect())
        return true;

    return false;
}

bool PlayerbotAI::canDispel(SpellInfo const* spellInfo, uint32 dispelType)
{
    static std::vector<std::string> dispel_whitelist =
    {
        "mutating injection",
        "frostbolt",
    };

    if (spellInfo->Dispel != dispelType)
        return false;

    if (!spellInfo->SpellName[0])
    {
        return true;
    }

    for (std::string& wl : dispel_whitelist)
    {
        if (caseInsensitiveEqual(spellInfo->SpellName[0], wl) == 0)
        {
            return false;
        }
    }

    return !spellInfo->SpellName[0] || (caseInsensitiveEqual(spellInfo->SpellName[0], "demon skin") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "mage armor") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "frost armor") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "wavering will") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "chilled") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "mana tap") &&
        caseInsensitiveEqual(spellInfo->SpellName[0], "ice armor"));
}

bool PlayerbotAI::HasAuraToDispel(Unit* target, uint32 dispelType)
{
    if (!target->IsInWorld())
    {
        return false;
    }
    bool isFriend = bot->IsFriendlyTo(target);
    Unit::VisibleAuraMap const* visibleAuras = target->GetVisibleAuras();
    for (Unit::VisibleAuraMap::const_iterator itr = visibleAuras->begin(); itr != visibleAuras->end(); ++itr)
    {
        Aura* aura = itr->second->GetBase();

        if (aura->IsPassive())
            continue;

        if (sPlayerbotAIConfig->dispelAuraDuration && aura->GetDuration() &&
            aura->GetDuration() < (int32)sPlayerbotAIConfig->dispelAuraDuration)
            continue;

        SpellInfo const* spellInfo = aura->GetSpellInfo();

        bool isPositiveSpell = spellInfo->IsPositive();
        if (isPositiveSpell && isFriend)
            continue;

        if (!isPositiveSpell && !isFriend)
            continue;

        if (canDispel(spellInfo, dispelType))
            return true;
    }
    return false;
}

bool PlayerbotAI::HasAura(std::string const name, Unit* unit, bool maxStack, bool checkIsOwner, int maxAuraAmount,
    bool checkDuration)
{
    if (!unit)
        return false;

    std::wstring wnamepart;
    if (!Utf8toWStr(name, wnamepart))
        return false;

    wstrToLower(wnamepart);

    int auraAmount = 0;

    // Iterate through all aura types
    for (uint32 auraType = SPELL_AURA_BIND_SIGHT; auraType < TOTAL_AURAS; auraType++)
    {
        Unit::AuraEffectList const& auras = unit->GetAuraEffectsByType((AuraType)auraType);
        if (auras.empty())
            continue;

        // Iterate through each aura effect
        for (AuraEffect const* aurEff : auras)
        {
            if (!aurEff)
                continue;

            SpellInfo const* spellInfo = aurEff->GetSpellInfo();
            if (!spellInfo)
                continue;

            // Check if the aura name matches
            std::string_view const auraName = spellInfo->SpellName[0];
            if (auraName.empty() || auraName.length() != wnamepart.length() || !Utf8FitTo(std::string(auraName), wnamepart))
                continue;

            // Check if this is a valid aura for the bot
            if (IsRealAura(bot, aurEff, unit))
            {
                // Check caster if necessary
                if (checkIsOwner && aurEff->GetCasterGUID() != bot->GetGUID())
                    continue;

                // Check aura duration if necessary
                if (checkDuration && aurEff->GetBase()->GetDuration() == -1)
                    continue;

                // Count stacks and charges
                uint32 maxStackAmount = spellInfo->StackAmount;
                uint32 maxProcCharges = spellInfo->ProcCharges;

                // Count the aura based on max stack and proc charges
                if (maxStack)
                {
                    if (maxStackAmount && aurEff->GetBase()->GetStackAmount() >= maxStackAmount)
                        auraAmount++;

                    if (maxProcCharges && aurEff->GetBase()->GetCharges() >= maxProcCharges)
                        auraAmount++;
                }
                else
                {
                    auraAmount++;
                }

                // Early exit if maxAuraAmount is reached
                if (maxAuraAmount < 0 && auraAmount > 0)
                    return true;
            }
        }
    }

    // Return based on the maximum aura amount conditions
    if (maxAuraAmount >= 0)
    {
        return auraAmount == maxAuraAmount || (auraAmount > 0 && auraAmount <= maxAuraAmount);
    }

    return false;
}

bool PlayerbotAI::HasAura(uint32 spellId, Unit const* unit)
{
    if (!spellId || !unit)
        return false;

    return unit->HasAura(spellId);
}

void PlayerbotAI::RemoveShapeshift()
{
    RemoveAura("bear form");
    RemoveAura("dire bear form");
    RemoveAura("moonkin form");
    RemoveAura("travel form");
    RemoveAura("cat form");
    RemoveAura("flight form");
    RemoveAura("swift flight form");
    RemoveAura("aquatic form");
    RemoveAura("ghost wolf");
    // RemoveAura("tree of life");
}

void PlayerbotAI::RemoveAura(std::string const name)
{
    uint32 spellid = _aiObjectContext->GetValue<uint32>("spell id", name)->Get();
    if (spellid && HasAura(spellid, bot))
        bot->RemoveAurasDueToSpell(spellid);
}

Aura* PlayerbotAI::GetAura(std::string const name, Unit* unit, bool checkIsOwner, bool checkDuration, int checkStack)
{
    if (!unit)
        return nullptr;

    std::wstring wnamepart;
    if (!Utf8toWStr(name, wnamepart))
        return nullptr;

    wstrToLower(wnamepart);

    for (uint32 auraType = SPELL_AURA_BIND_SIGHT; auraType < TOTAL_AURAS; ++auraType)
    {
        Unit::AuraEffectList const& auras = unit->GetAuraEffectsByType((AuraType)auraType);
        if (auras.empty())
            continue;

        for (AuraEffect const* aurEff : auras)
        {
            SpellInfo const* spellInfo = aurEff->GetSpellInfo();
            std::string const& auraName = spellInfo->SpellName[0];

            // Directly skip if name mismatch (both length and content)
            if (auraName.empty() || auraName.length() != wnamepart.length() || !Utf8FitTo(auraName, wnamepart))
                continue;

            if (!IsRealAura(bot, aurEff, unit))
                continue;

            // Check owner if necessary
            if (checkIsOwner && aurEff->GetCasterGUID() != bot->GetGUID())
                continue;

            // Check duration if necessary
            if (checkDuration && aurEff->GetBase()->GetDuration() == -1)
                continue;

            // Check stack if necessary
            if (checkStack != -1 && aurEff->GetBase()->GetStackAmount() < checkStack)
                continue;

            return aurEff->GetBase();
        }
    }

    return nullptr;
}

bool PlayerbotAI::HasAnyAuraOf(Unit* player, ...)
{
    if (!player)
        return false;

    va_list vl;
    va_start(vl, player);

    const char* cur;
    while ((cur = va_arg(vl, const char*)) != nullptr)
    {
        if (HasAura(cur, player))
        {
            va_end(vl);
            return true;
        }
    }

    va_end(vl);
    return false;
}

bool PlayerbotAI::IsInterruptableSpellCasting(Unit* target, std::string const spell)
{
    uint32 spellid = _aiObjectContext->GetValue<uint32>("spell id", spell)->Get();
    if (!spellid || !target->IsNonMeleeSpellCasted(true))
        return false;

    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellid);
    if (!spellInfo)
        return false;

    for (uint8 i = EFFECT_0; i <= EFFECT_2; i++)
    {
        if ((spellInfo->InterruptFlags & SPELL_INTERRUPT_FLAG_INTERRUPT) &&
            spellInfo->PreventionType == SPELL_PREVENTION_TYPE_SILENCE)
            return true;

        if (spellInfo->Effects[i].Effect == SPELL_EFFECT_INTERRUPT_CAST &&
            !target->IsImmunedToSpellEffect(spellInfo, i))
            return true;

        if ((spellInfo->Effects[i].Effect == SPELL_EFFECT_APPLY_AURA) &&
            spellInfo->Effects[i].ApplyAuraName == SPELL_AURA_MOD_SILENCE)
            return true;
    }

    return false;
}

void PlayerbotAI::SpellInterrupted(uint32 spellid)
{
    for (uint8 type = CURRENT_MELEE_SPELL; type <= CURRENT_CHANNELED_SPELL; type++)
    {
        Spell* spell = bot->GetCurrentSpell((CurrentSpellTypes)type);
        if (!spell)
            continue;
        if (spell->GetSpellInfo()->Id == spellid)
            bot->InterruptSpell((CurrentSpellTypes)type);
    }
}

void PlayerbotAI::InterruptSpell()
{
    for (uint8 type = CURRENT_MELEE_SPELL; type <= CURRENT_CHANNELED_SPELL; type++)
    {
        Spell* spell = bot->GetCurrentSpell((CurrentSpellTypes)type);
        if (!spell)
            continue;

        bot->InterruptSpell((CurrentSpellTypes)type);

        WorldPacket data(SMSG_SPELL_FAILURE, 8 + 1 + 4 + 1);
        data << bot->GetPackGUID();
        data << uint8(1);
        data << uint32(spell->m_spellInfo->Id);
        data << uint8(0);
        bot->SendMessageToSet(&data, true);

        data.Initialize(SMSG_SPELL_FAILED_OTHER, 8 + 1 + 4 + 1);
        data << bot->GetPackGUID();
        data << uint8(1);
        data << uint32(spell->m_spellInfo->Id);
        data << uint8(0);
        bot->SendMessageToSet(&data, true);

        SpellInterrupted(spell->m_spellInfo->Id);
    }
}

bool PlayerbotAI::CanCastSpell(std::string const name, Unit* target, Item* itemTarget)
{
    return CanCastSpell(_aiObjectContext->GetValue<uint32>("spell id", name)->Get(), target, true, itemTarget);
}

bool PlayerbotAI::CanCastSpell(uint32 spellid, Unit* target, bool checkHasSpell, Item* itemTarget, Item* castItem)
{
    if (!spellid)
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Can cast spell failed. No spellid. - spellid: %u, bot name: %s", spellid, bot->GetName().c_str());
        }
        return false;
    }

    if (bot->HasUnitState(UNIT_STATE_LOST_CONTROL))
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Can cast spell failed. Unit state lost control. - spellid: %u, bot name: %s", spellid, bot->GetName().c_str());
        }
        return false;
    }

    if (!target)
        target = bot;

    // if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
    //TC_LOG_DEBUG("playerbots", "Can cast spell? - target name: %s, spellid: %u, bot name: %s", target->GetName().c_str(), spellid, bot->GetName().c_str());

    if (Pet* pet = bot->GetPet())
        if (pet->HasSpell(spellid))
            return true;

    if (checkHasSpell && !bot->HasSpell(spellid))
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Can cast spell failed. Bot not has spell. - target name: %s, spellid: %u, bot name: %s", target->GetName().c_str(), spellid, bot->GetName().c_str());
        }
        return false;
    }

    if (bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr)
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "CanCastSpell() target name: %d, spellid: %u, bot name: %s, failed because has current channeled spell", target->GetName().c_str(), spellid, bot->GetName().c_str());
        }
        return false;
    }

    if (bot->HasSpellCooldown(spellid))
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Can cast spell failed. Spell not has cooldown. - target name: %s, spellid: %u, bot name: %s", target->GetName().c_str(), spellid, bot->GetName().c_str());
        }
        return false;
    }

    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellid);
    if (!spellInfo)
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Can cast spell failed. No spellInfo. - target name: %s, spellid: %u, bot name: %s", target->GetName().c_str(), spellid, bot->GetName().c_str());
        }
        return false;
    }

    uint32 CastingTime = !spellInfo->IsChanneled() ? spellInfo->CalcCastTime(bot->GetLevel()) : spellInfo->GetDuration();
    // bool interruptOnMove = spellInfo->InterruptFlags & SPELL_INTERRUPT_FLAG_MOVEMENT;
    if ((CastingTime || spellInfo->IsAutoRepeatRangedSpell()) && bot->isMoving())
    {
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        {
            //TC_LOG_DEBUG("playerbots", "Casting time and bot is moving - target name: %s, spellid: %u, bot name: %s", target->GetName().c_str(), spellid, bot->GetName().c_str());
        }
        return false;
    }

    if (!itemTarget)
    {
        bool positiveSpell = spellInfo->IsPositive();
        // if (positiveSpell && bot->IsHostileTo(target))
        //     return false;

        // if (!positiveSpell && bot->IsFriendlyTo(target))
        //     return false;

        // bool damage = false;
        // for (uint8 i = EFFECT_0; i <= EFFECT_2; i++)
        // {
        //     if (spellInfo->Effects[i].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
        //     {
        //         damage = true;
        //         break;
        //     }
        // }

        if (target->IsImmunedToSpell(spellInfo, spellInfo->GetAllEffectsMechanicMask()))
        {
            //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
            {
                //TC_LOG_DEBUG("playerbots", "target is immuned to spell - target name: %s, spellid: %u, bot name: %s", target->GetName(), spellid, bot->GetName());
            }
            return false;
        }

        // if (!damage)
        // {
        //     for (uint8 i = EFFECT_0; i <= EFFECT_2; i++)
        //     {
        //         if (target->IsImmunedToSpellEffect(spellInfo, i)) {
        //             if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster())) {
        //                 LOG_DEBUG("playerbots", "target is immuned to spell effect - target name: {}, spellid: {},
        //                 bot name: {}",
        //                     target->GetName(), spellid, bot->GetName());
        //             }
        //             return false;
        //         }
        //     }
        // }

        if (bot != target && sServerFacade->GetDistance2d(bot, target) > sPlayerbotAIConfig->sightDistance)
        {
            //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
            {
                //TC_LOG_DEBUG("playerbots", "target is out of sight distance - target name: %s, spellid: %u, bot name: %s", target->GetName(), spellid, bot->GetName());
            }
            return false;
        }
    }

    Unit* oldSel = bot->GetSelectedUnit();
    // TRIGGERED_IGNORE_POWER_AND_REAGENT_COST flag for not calling CheckPower in check
    // which avoids buff charge to be ineffectively reduced (e.g. dk freezing fog for howling blast)
    /// @TODO: Fix all calls to ApplySpellMod

    Spell* spell = new Spell(bot, spellInfo, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
    spell->m_targets.SetUnitTarget(target);
    spell->m_CastItem = castItem;
    if (itemTarget == nullptr)
    {
        //itemTarget = aiObjectContext->GetValue<Item*>("item for spell", spellid)->Get();
    }
    spell->m_targets.SetItemTarget(itemTarget);
    SpellCastResult result = spell->CheckCast(true);
    delete spell;

    if (oldSel)
        bot->SetSelection(oldSel->GetGUID());

    switch (result)
    {
    case SPELL_FAILED_NOT_INFRONT:
    case SPELL_FAILED_NOT_STANDING:
    case SPELL_FAILED_UNIT_NOT_INFRONT:
    case SPELL_FAILED_MOVING:
    case SPELL_FAILED_TRY_AGAIN:
    case SPELL_CAST_OK:
    case SPELL_FAILED_NOT_SHAPESHIFT:
    case SPELL_FAILED_OUT_OF_RANGE:
        return true;
    default:
        //if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster()))
        //{
            //if (result != SPELL_FAILED_NOT_READY && result != SPELL_CAST_OK)
                //TC_LOG_DEBUG("playerbots", "CanCastSpell Check Failed. - target name: %s, spellid: %u, bot name: %s, result: %u", target->GetName().c_str(), spellid, bot->GetName().c_str(), (uint32)result);
        //}
        return false;
    }
}

bool PlayerbotAI::CanCastSpell(uint32 spellid, GameObject* goTarget, uint8 effectMask, bool checkHasSpell)
{
    if (!spellid)
        return false;

    if (bot->HasUnitState(UNIT_STATE_LOST_CONTROL))
        return false;

    Pet* pet = bot->GetPet();
    if (pet && pet->HasSpell(spellid))
        return true;

    if (checkHasSpell && !bot->HasSpell(spellid))
        return false;

    if (bot->HasSpellCooldown(spellid))
        return false;

    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellid);
    if (!spellInfo)
        return false;

    int32 CastingTime = !spellInfo->IsChanneled() ? spellInfo->CalcCastTime(bot->GetLevel()) : spellInfo->GetDuration();
    if (CastingTime > 0 && bot->isMoving())
        return false;

    bool damage = false;
    for (int32 i = EFFECT_0; i <= EFFECT_2; i++)
    {
        if (spellInfo->Effects[i].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
        {
            damage = true;
            break;
        }
    }

    if (sServerFacade->GetDistance2d(bot, goTarget) > sPlayerbotAIConfig->sightDistance)
        return false;

    // ObjectGuid oldSel = bot->GetTarget();
    // bot->SetTarget(goTarget->GetGUID());
    Spell* spell = new Spell(bot, spellInfo, TRIGGERED_NONE);

    spell->m_targets.SetGOTarget(goTarget);
    //spell->m_CastItem = aiObjectContext->GetValue<Item*>("item for spell", spellid)->Get();
    //spell->m_targets.SetItemTarget(spell->m_CastItem);

    SpellCastResult result = spell->CheckCast(true);
    delete spell;
    // if (oldSel)
    //     bot->SetTarget(oldSel);

    switch (result)
    {
    case SPELL_FAILED_NOT_INFRONT:
    case SPELL_FAILED_NOT_STANDING:
    case SPELL_FAILED_UNIT_NOT_INFRONT:
    case SPELL_FAILED_MOVING:
    case SPELL_FAILED_TRY_AGAIN:
    case SPELL_CAST_OK:
        return true;
    default:
        break;
    }

    return false;
}

bool PlayerbotAI::CanCastSpell(uint32 spellid, float x, float y, float z, uint8 effectMask, bool checkHasSpell,
    Item* itemTarget)
{
    if (!spellid)
        return false;

    Pet* pet = bot->GetPet();
    if (pet && pet->HasSpell(spellid))
        return true;

    if (checkHasSpell && !bot->HasSpell(spellid))
        return false;

    if (bot->HasSpellCooldown(spellid))
        return false;

    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellid);
    if (!spellInfo)
        return false;

    if (!itemTarget)
    {
        if (bot->GetDistance(x, y, z) > sPlayerbotAIConfig->sightDistance)
            return false;
    }

    Spell* spell = new Spell(bot, spellInfo, TRIGGERED_NONE);

    spell->m_targets.SetDst(x, y, z, 0.f);
    //spell->m_CastItem = itemTarget ? itemTarget : aiObjectContext->GetValue<Item*>("item for spell", spellid)->Get();
    //spell->m_targets.SetItemTarget(spell->m_CastItem);

    SpellCastResult result = spell->CheckCast(true);
    delete spell;

    switch (result)
    {
    case SPELL_FAILED_NOT_INFRONT:
    case SPELL_FAILED_NOT_STANDING:
    case SPELL_FAILED_UNIT_NOT_INFRONT:
    case SPELL_FAILED_MOVING:
    case SPELL_FAILED_TRY_AGAIN:
    case SPELL_CAST_OK:
        return true;
    default:
        return false;
    }
}

bool PlayerbotAI::CastSpell(std::string const name, Unit* target, Item* itemTarget)
{
    TC_LOG_DEBUG("playerbots", "%s cast: %s", bot->GetName().c_str(), name.c_str());
    bool result = CastSpell(_aiObjectContext->GetValue<uint32>("spell id", name)->Get(), target, itemTarget);
    //const std::string res = result ? "success" : "failed";
    //TC_LOG_DEBUG("playerbots", "%s cast: %s => %s", bot->GetName().c_str(), name.c_str(), res.c_str());
    if (result)
    {
        _aiObjectContext->GetValue<time_t>("last spell cast time", name)->Set(time(nullptr));
    }

    return result;
}

bool PlayerbotAI::CastSpell(uint32 spellId, Unit* target, Item* itemTarget)
{
    if (!spellId)
    {
        return false;
    }

    if (!target)
        target = bot;

    // Apply the same real-player pull ownership to direct class spell
    // actions. Many rotations cast through this function without first
    // calling AttackAction, so guarding only the melee/target-selection path
    // would still allow an autonomous ranged pull.
    if (target != bot && bot->IsValidAttackTarget(target) &&
        !CanLfgAutoQueueEngage(target))
        return false;

    Pet* pet = bot->GetPet();
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (pet && pet->HasSpell(spellId))
    {
        bool autocast = false;
        for (unsigned int& m_autospell : pet->m_autospells)
        {
            if (m_autospell == spellId)
            {
                autocast = true;
                break;
            }
        }

        pet->ToggleAutocast(spellInfo, !autocast);
        //std::ostringstream out;
        //out << (autocast ? "|cffff0000|Disabling" : "|cFF00ff00|Enabling") << " pet auto-cast for ";
        //out << chatHelper.FormatSpell(spellInfo);
        //TellMaster(out);
        return true;
    }

    if (bot->IsFlying() || bot->HasUnitState(UNIT_STATE_IN_FLIGHT))
    {
        return false;
    }

    bool failWithDelay = false;
    if (!bot->IsStandState())
    {
        bot->SetStandState(UNIT_STAND_STATE_STAND);
        failWithDelay = true;
    }

    ObjectGuid oldSel = bot->GetSelectedUnit() ? bot->GetSelectedUnit()->GetGUID() : ObjectGuid();
    bot->SetSelection(target->GetGUID());
    WorldObject* faceTo = target;
    if (!bot->HasInArc(CAST_ANGLE_IN_FRONT, faceTo) && (spellInfo->FacingCasterFlags & SPELL_FACING_FLAG_INFRONT))
    {
        sServerFacade->SetFacingTo(bot, faceTo);
        // failWithDelay = true;
    }

    if (failWithDelay)
    {
        SetNextCheckDelay(sPlayerbotAIConfig->reactDelay);
        return false;
    }

    Spell* spell = new Spell(bot, spellInfo, TRIGGERED_NONE);
    spell->m_cast_count += 1;
    SpellCastTargets targets;
    if (spellInfo->Targets & TARGET_FLAG_ITEM)
    {
        //spell->m_CastItem = itemTarget ? itemTarget : aiObjectContext->GetValue<Item*>("item for spell", spellId)->Get();
        targets.SetItemTarget(spell->m_CastItem);

        if (bot->GetTradeData())
        {
            //bot->GetTradeData()->SetSpell(spellId);
            delete spell;
            return true;
        }
    }
    else if (spellInfo->Targets & TARGET_FLAG_DEST_LOCATION)
    {
        // WorldLocation aoe = aiObjectContext->GetValue<WorldLocation>("aoe position")->Get();
        // targets.SetDst(aoe);
        targets.SetDst(*target);
    }
    else if (spellInfo->Targets & TARGET_FLAG_SOURCE_LOCATION)
    {
        targets.SetDst(*bot);
    }
    else
    {
        targets.SetUnitTarget(target);
    }

    if (spellInfo->Effects[0].Effect == SPELL_EFFECT_OPEN_LOCK || spellInfo->Effects[0].Effect == SPELL_EFFECT_SKINNING)
    {
        /*LootObject loot = *aiObjectContext->GetValue<LootObject>("loot target");
        GameObject* go = GetGameObject(loot.guid);
        if (go && go->isSpawned())
        {
            WorldPacket packetgouse(CMSG_GAMEOBJ_USE, 8);
            packetgouse << loot.guid;
            bot->GetSession()->HandleGameObjectUseOpcode(packetgouse);
            targets.SetGOTarget(go);
            faceTo = go;
        }
        else
        {
            if (Unit* creature = GetUnit(loot.guid))
            {
                targets.SetUnitTarget(creature);
                faceTo = creature;
            }
        }*/
    }

    if (bot->isMoving() && spell->GetCastTime())
    {
        // bot->StopMoving();
        SetNextCheckDelay(sPlayerbotAIConfig->reactDelay);
        spell->cancel();
        delete spell;
        return false;
    }

    spell->prepare(&targets);
    SpellCastResult result = spell->CheckCast(false);
    if (result != SPELL_CAST_OK)
    {
        // if (!sPlayerbotAIConfig->logInGroupOnly || (bot->GetGroup() && HasRealPlayerMaster())) {
        TC_LOG_DEBUG("playerbots", "Spell cast failed. - target name: %s, spellid: %u, bot name: %s, result: %u", target->GetName().c_str(), spellId, bot->GetName().c_str(), result);
        // }
        return false;
    }
    
    _aiObjectContext->GetValue<LastSpellCast&>("last spell cast")->Get().Set(spellId, target->GetGUID(), time(nullptr));
    _aiObjectContext->GetValue<PositionMap&>("position")->Get()["random"].Reset();

    if (oldSel)
        bot->SetSelection(oldSel);

    /*if (HasStrategy("debug spell", BOT_STATE_NON_COMBAT))
    {
        std::ostringstream out;
        out << "Casting " << ChatHelper::FormatSpell(spellInfo);
        TellMasterNoFacing(out);
    }*/

    return true;
}

bool PlayerbotAI::CastSpell(uint32 spellId, float x, float y, float z, Item* itemTarget)
{
    if (!spellId)
        return false;

    Pet* pet = bot->GetPet();
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (pet && pet->HasSpell(spellId))
    {
        bool autocast = false;
        for (unsigned int& m_autospell : pet->m_autospells)
        {
            if (m_autospell == spellId)
            {
                autocast = true;
                break;
            }
        }

        pet->ToggleAutocast(spellInfo, !autocast);
        return true;
    }

    MotionMaster& mm = *bot->GetMotionMaster();

    if (bot->IsFlying() || bot->HasUnitState(UNIT_STATE_IN_FLIGHT))
        return false;

    bool failWithDelay = false;
    if (!bot->IsStandState())
    {
        bot->SetStandState(UNIT_STAND_STATE_STAND);
        failWithDelay = true;
    }

    ObjectGuid oldSel = bot->GetSelectedUnit() ? bot->GetSelectedUnit()->GetGUID() : ObjectGuid();

    if (!bot->isMoving())
        bot->SetFacingTo(bot->GetAngle(x, y));

    if (failWithDelay)
    {
        SetNextCheckDelay(sPlayerbotAIConfig->globalCoolDown);
        return false;
    }

    Spell* spell = new Spell(bot, spellInfo, TRIGGERED_NONE);

    SpellCastTargets targets;
    if (spellInfo->Targets & TARGET_FLAG_ITEM)
    {
        /*spell->m_CastItem =
            itemTarget ? itemTarget : aiObjectContext->GetValue<Item*>("item for spell", spellId)->Get();
        targets.SetItemTarget(spell->m_CastItem);

        if (bot->GetTradeData())
        {
            bot->GetTradeData()->SetSpell(spellId);
            delete spell;
            return true;
        }*/
    }
    else if (spellInfo->Targets & TARGET_FLAG_DEST_LOCATION)
    {
        //WorldLocation aoe = aiObjectContext->GetValue<WorldLocation>("aoe position")->Get();
        targets.SetDst(x, y, z, 0.f);
    }
    else if (spellInfo->Targets & TARGET_FLAG_SOURCE_LOCATION)
    {
        targets.SetDst(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), 0.f);
    }
    else
    {
        return false;
    }

    if (spellInfo->Effects[0].Effect == SPELL_EFFECT_OPEN_LOCK || spellInfo->Effects[0].Effect == SPELL_EFFECT_SKINNING)
    {
        return false;
    }

    spell->prepare(&targets);

    if (bot->isMoving() && spell->GetCastTime())
    {
        // bot->StopMoving();
        SetNextCheckDelay(sPlayerbotAIConfig->reactDelay);
        spell->cancel();
        delete spell;
        return false;
    }

    if (spellInfo->Effects[0].Effect == SPELL_EFFECT_OPEN_LOCK || spellInfo->Effects[0].Effect == SPELL_EFFECT_SKINNING)
    {
        /*LootObject loot = *aiObjectContext->GetValue<LootObject>("loot target");
        if (!loot.IsLootPossible(bot))
        {
            spell->cancel();
            delete spell;
            return false;
        }*/
    }

    _aiObjectContext->GetValue<LastSpellCast&>("last spell cast")->Get().Set(spellId, bot->GetGUID(), time(nullptr));
    _aiObjectContext->GetValue<PositionMap&>("position")->Get()["random"].Reset();

    if (oldSel)
        bot->SetSelection(oldSel);

    /*if (HasStrategy("debug spell", BOT_STATE_NON_COMBAT))
    {
        std::ostringstream out;
        out << "Casting " << ChatHelper::FormatSpell(spellInfo);
        TellMasterNoFacing(out);
    }*/

    return true;
}

float PlayerbotAI::GetItemScoreMultiplier(ItemQualities quality)
{
    switch (quality)
    {
        // each quality increase 1.1x
        case ITEM_QUALITY_POOR:
            return 1.0f;
            break;
        case ITEM_QUALITY_NORMAL:
            return 1.1f;
            break;
        case ITEM_QUALITY_UNCOMMON:
            return 1.21f;
            break;
        case ITEM_QUALITY_RARE:
            return 1.331f;
            break;
        case ITEM_QUALITY_EPIC:
            return 1.4641f;
            break;
        case ITEM_QUALITY_LEGENDARY:
            return 1.61051f;
            break;
        default:
            break;
    }
    return 1.0f;
}

void PlayerbotAI::_fillGearScoreData(Player* player, Item* item, std::vector<uint32>* gearScore, uint32& twoHandScore,
    bool mixed)
{
    if (!item)
        return;

    ItemTemplate const* proto = item->GetTemplate();
    if (player->CanUseItem(proto) != EQUIP_ERR_OK)
        return;

    uint8 type = proto->InventoryType;
    uint32 level = mixed ? proto->ItemLevel * PlayerbotAI::GetItemScoreMultiplier(ItemQualities(proto->Quality))
        : proto->ItemLevel;

    switch (type)
    {
    case INVTYPE_2HWEAPON:
        twoHandScore = std::max(twoHandScore, level);
        break;
    case INVTYPE_WEAPON:
    case INVTYPE_WEAPONMAINHAND:
        (*gearScore)[SLOT_MAIN_HAND] = std::max((*gearScore)[SLOT_MAIN_HAND], level);
        break;
    case INVTYPE_SHIELD:
    case INVTYPE_WEAPONOFFHAND:
        (*gearScore)[EQUIPMENT_SLOT_OFFHAND] = std::max((*gearScore)[EQUIPMENT_SLOT_OFFHAND], level);
        break;
    case INVTYPE_THROWN:
    case INVTYPE_RANGEDRIGHT:
    case INVTYPE_RANGED:
    case INVTYPE_QUIVER:
    case INVTYPE_RELIC:
        (*gearScore)[EQUIPMENT_SLOT_RANGED] = std::max((*gearScore)[EQUIPMENT_SLOT_RANGED], level);
        break;
    case INVTYPE_HEAD:
        (*gearScore)[EQUIPMENT_SLOT_HEAD] = std::max((*gearScore)[EQUIPMENT_SLOT_HEAD], level);
        break;
    case INVTYPE_NECK:
        (*gearScore)[EQUIPMENT_SLOT_NECK] = std::max((*gearScore)[EQUIPMENT_SLOT_NECK], level);
        break;
    case INVTYPE_SHOULDERS:
        (*gearScore)[EQUIPMENT_SLOT_SHOULDERS] = std::max((*gearScore)[EQUIPMENT_SLOT_SHOULDERS], level);
        break;
    case INVTYPE_BODY:
        (*gearScore)[EQUIPMENT_SLOT_BODY] = std::max((*gearScore)[EQUIPMENT_SLOT_BODY], level);
        break;
    case INVTYPE_CHEST:
        (*gearScore)[EQUIPMENT_SLOT_CHEST] = std::max((*gearScore)[EQUIPMENT_SLOT_CHEST], level);
        break;
    case INVTYPE_WAIST:
        (*gearScore)[EQUIPMENT_SLOT_WAIST] = std::max((*gearScore)[EQUIPMENT_SLOT_WAIST], level);
        break;
    case INVTYPE_LEGS:
        (*gearScore)[EQUIPMENT_SLOT_LEGS] = std::max((*gearScore)[EQUIPMENT_SLOT_LEGS], level);
        break;
    case INVTYPE_FEET:
        (*gearScore)[EQUIPMENT_SLOT_FEET] = std::max((*gearScore)[EQUIPMENT_SLOT_FEET], level);
        break;
    case INVTYPE_WRISTS:
        (*gearScore)[EQUIPMENT_SLOT_WRISTS] = std::max((*gearScore)[EQUIPMENT_SLOT_WRISTS], level);
        break;
    case INVTYPE_HANDS:
        (*gearScore)[EQUIPMENT_SLOT_HEAD] = std::max((*gearScore)[EQUIPMENT_SLOT_HEAD], level);
        break;
        // equipped gear score check uses both rings and trinkets for calculation, assume that for bags/banks it is the
        // same with keeping second highest score at second slot
    case INVTYPE_FINGER:
    {
        if ((*gearScore)[EQUIPMENT_SLOT_FINGER1] < level)
        {
            (*gearScore)[EQUIPMENT_SLOT_FINGER2] = (*gearScore)[EQUIPMENT_SLOT_FINGER1];
            (*gearScore)[EQUIPMENT_SLOT_FINGER1] = level;
        }
        else if ((*gearScore)[EQUIPMENT_SLOT_FINGER2] < level)
            (*gearScore)[EQUIPMENT_SLOT_FINGER2] = level;
        break;
    }
    case INVTYPE_TRINKET:
    {
        if ((*gearScore)[EQUIPMENT_SLOT_TRINKET1] < level)
        {
            (*gearScore)[EQUIPMENT_SLOT_TRINKET2] = (*gearScore)[EQUIPMENT_SLOT_TRINKET1];
            (*gearScore)[EQUIPMENT_SLOT_TRINKET1] = level;
        }
        else if ((*gearScore)[EQUIPMENT_SLOT_TRINKET2] < level)
            (*gearScore)[EQUIPMENT_SLOT_TRINKET2] = level;
        break;
    }
    case INVTYPE_CLOAK:
        (*gearScore)[EQUIPMENT_SLOT_BACK] = std::max((*gearScore)[EQUIPMENT_SLOT_BACK], level);
        break;
    default:
        break;
    }
}

bool PlayerbotAI::IsSafe(Player* player)
{
    return player && player->GetMapId() == bot->GetMapId() && player->GetInstanceId() == bot->GetInstanceId() &&
        !player->IsBeingTeleported();
}
bool PlayerbotAI::IsSafe(WorldObject* obj)
{
    return obj && obj->GetMapId() == bot->GetMapId() && obj->GetInstanceId() == bot->GetInstanceId() &&
        (!obj->IsPlayer() || !((Player*)obj)->IsBeingTeleported());
}

uint32 PlayerbotAI::GetMixedGearScore(Player* player, bool withBags, bool withBank, uint32 topN)
{
    std::vector<uint32> gearScore(EQUIPMENT_SLOT_END);
    uint32 twoHandScore = 0;

    for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END; ++i)
    {
        if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
            _fillGearScoreData(player, item, &gearScore, twoHandScore, true);
    }

    if (withBags)
    {
        // check inventory
        for (uint8 i = INVENTORY_SLOT_ITEM_START; i < INVENTORY_SLOT_ITEM_END; ++i)
        {
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
                _fillGearScoreData(player, item, &gearScore, twoHandScore, true);
        }

        // check bags
        for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        {
            if (Bag* pBag = (Bag*)player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
            {
                for (uint32 j = 0; j < pBag->GetBagSize(); ++j)
                {
                    if (Item* item2 = pBag->GetItemByPos(j))
                        _fillGearScoreData(player, item2, &gearScore, twoHandScore, true);
                }
            }
        }
    }

    if (withBank)
    {
        for (uint8 i = BANK_SLOT_ITEM_START; i < BANK_SLOT_ITEM_END; ++i)
        {
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
                _fillGearScoreData(player, item, &gearScore, twoHandScore, true);
        }

        for (uint8 i = BANK_SLOT_BAG_START; i < BANK_SLOT_BAG_END; ++i)
        {
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
            {
                if (item->IsBag())
                {
                    Bag* bag = (Bag*)item;
                    for (uint8 j = 0; j < bag->GetBagSize(); ++j)
                    {
                        if (Item* item2 = bag->GetItemByPos(j))
                            _fillGearScoreData(player, item2, &gearScore, twoHandScore, true);
                    }
                }
            }
        }
    }
    if (!topN)
    {
        uint8 count = EQUIPMENT_SLOT_END - 2;  // ignore body and tabard slots
        uint32 sum = 0;

        // check if 2h hand is higher level than main hand + off hand
        if (gearScore[EQUIPMENT_SLOT_MAINHAND] + gearScore[EQUIPMENT_SLOT_OFFHAND] < twoHandScore * 2)
        {
            gearScore[EQUIPMENT_SLOT_OFFHAND] = 0;  // off hand is ignored in calculations if 2h weapon has higher score
            --count;
            gearScore[EQUIPMENT_SLOT_MAINHAND] = twoHandScore;
        }

        for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END; ++i)
        {
            sum += gearScore[i];
        }

        if (count)
        {
            uint32 res = uint32(sum / count);
            return res;
        }

        return 0;
    }
    // topN != 0
    if (gearScore[EQUIPMENT_SLOT_MAINHAND] + gearScore[EQUIPMENT_SLOT_OFFHAND] < twoHandScore * 2)
    {
        gearScore[EQUIPMENT_SLOT_OFFHAND] = twoHandScore;
        gearScore[EQUIPMENT_SLOT_MAINHAND] = twoHandScore;
    }
    std::vector<uint32> topGearScore;
    for (uint8 i = EQUIPMENT_SLOT_START; i < EQUIPMENT_SLOT_END; ++i)
    {
        topGearScore.push_back(gearScore[i]);
    }
    std::sort(topGearScore.begin(), topGearScore.end(), [&](const uint32 lhs, const uint32 rhs) { return lhs > rhs; });
    uint32 sum = 0;
    for (int i = 0; i < std::min((uint32)topGearScore.size(), topN); i++)
    {
        sum += topGearScore[i];
    }
    return sum / topN;
}

// A custom CanEquipItem (remove AutoUnequipOffhand in FindEquipSlot to prevent unequip on `item usage` calculation)
InventoryResult PlayerbotAI::CanEquipItem(uint8 slot, uint16& dest, Item* pItem, bool swap, bool not_loading) const
{
    dest = 0;
    if (pItem)
    {
        //TC_LOG_DEBUG("playerbots", "STORAGE: CanEquipItem slot = %u, item = %u, count = %u", slot, pItem->GetEntry(), pItem->GetCount());
        ItemTemplate const* pProto = pItem->GetTemplate();
        if (pProto)
        {
            // item used
            if (pItem->m_lootGenerated)
                return InventoryResult::EQUIP_ERR_LOOT_GONE;

            if (pItem->IsBindedNotWith(bot))
                return InventoryResult::EQUIP_ERR_NOT_OWNER;

            InventoryResult res = bot->CanTakeMoreSimilarItems(pItem);
            if (res != EQUIP_ERR_OK)
                return res;

            ScalingStatDistributionEntry const* ssd =
                pProto->ScalingStatDistribution
                ? sScalingStatDistributionStore.LookupEntry(pProto->ScalingStatDistribution)
                : 0;
            // check allowed level (extend range to upper values if MaxLevel more or equal max player level, this let GM
            // set high level with 1...max range items)
            if (ssd && ssd->MaxLevel < DEFAULT_MAX_LEVEL && ssd->MaxLevel < bot->GetLevel())
                return InventoryResult::EQUIP_ERR_CANT_EQUIP_EVER;

            uint8 eslot = FindEquipSlot(pProto, slot, swap);
            if (eslot == NULL_SLOT)
                return InventoryResult::EQUIP_ERR_CANT_EQUIP_EVER;

            // Xinef: dont allow to equip items on disarmed slot
            if (!bot->CanUseAttackType(bot->GetAttackBySlot(eslot)))
                return EQUIP_ERR_NOT_WHILE_DISARMED;

            res = bot->CanUseItem(pItem, not_loading);
            if (res != EQUIP_ERR_OK)
                return res;

            if (!swap && bot->GetItemByPos(INVENTORY_SLOT_BAG_0, eslot))
                return InventoryResult::EQUIP_ERR_NO_SLOT_AVAILABLE;

            // if we are swapping 2 equiped items, CanEquipUniqueItem check
            // should ignore the item we are trying to swap, and not the
            // destination item. CanEquipUniqueItem should ignore destination
            // item only when we are swapping weapon from bag
            uint8 ignore = uint8(NULL_SLOT);
            switch (eslot)
            {
            case EQUIPMENT_SLOT_MAINHAND:
                ignore = EQUIPMENT_SLOT_OFFHAND;
                break;
            case EQUIPMENT_SLOT_OFFHAND:
                ignore = EQUIPMENT_SLOT_MAINHAND;
                break;
            case EQUIPMENT_SLOT_FINGER1:
                ignore = EQUIPMENT_SLOT_FINGER2;
                break;
            case EQUIPMENT_SLOT_FINGER2:
                ignore = EQUIPMENT_SLOT_FINGER1;
                break;
            case EQUIPMENT_SLOT_TRINKET1:
                ignore = EQUIPMENT_SLOT_TRINKET2;
                break;
            case EQUIPMENT_SLOT_TRINKET2:
                ignore = EQUIPMENT_SLOT_TRINKET1;
                break;
            }

            if (ignore == uint8(NULL_SLOT) || pItem != bot->GetItemByPos(INVENTORY_SLOT_BAG_0, ignore))
                ignore = eslot;

            InventoryResult res2 = bot->CanEquipUniqueItem(pItem, swap ? ignore : uint8(NULL_SLOT));
            if (res2 != EQUIP_ERR_OK)
                return res2;

            // check unique-equipped special item classes
            if (pProto->Class == ITEM_CLASS_QUIVER)
                for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
                    if (Item* pBag = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
                        if (pBag != pItem)
                            if (ItemTemplate const* pBagProto = pBag->GetTemplate())
                                if (pBagProto->Class == pProto->Class && (!swap || pBag->GetSlot() != eslot))
                                    return (pBagProto->SubClass == ITEM_SUBCLASS_AMMO_POUCH)
                                    ? InventoryResult::EQUIP_ERR_AMMO_ONLY
                                    : InventoryResult::EQUIP_ERR_ONLY_ONE_QUIVER;

            uint32 type = pProto->InventoryType;

            if (eslot == EQUIPMENT_SLOT_OFFHAND)
            {
                // Do not allow polearm to be equipped in the offhand (rare case for the only 1h polearm 41750)
                // xinef: same for fishing poles
                if (type == INVTYPE_WEAPON && (pProto->SubClass == ITEM_SUBCLASS_WEAPON_POLEARM ||
                    pProto->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE))
                    return InventoryResult::EQUIP_ERR_WRONG_SLOT;

                else if (type == INVTYPE_WEAPON || type == INVTYPE_WEAPONOFFHAND)
                {
                    if (!bot->CanDualWield())
                        return InventoryResult::EQUIP_ERR_2HANDED_EQUIPPED;
                }
                else if (type == INVTYPE_2HWEAPON)
                {
                    if (!bot->CanDualWield() || !bot->CanTitanGrip())
                        return InventoryResult::EQUIP_ERR_2HANDED_EQUIPPED;
                }

                if (bot->IsTwoHandUsed())
                    return InventoryResult::EQUIP_ERR_2HANDED_EQUIPPED;
            }

            // equip two-hand weapon case (with possible unequip 2 items)
            if (type == INVTYPE_2HWEAPON)
            {
                if (eslot == EQUIPMENT_SLOT_OFFHAND)
                {
                    if (!bot->CanTitanGrip())
                        return InventoryResult::EQUIP_ERR_CANT_EQUIP_EVER;
                }
                else if (eslot != EQUIPMENT_SLOT_MAINHAND)
                    return InventoryResult::EQUIP_ERR_CANT_EQUIP_EVER;

                if (!bot->CanTitanGrip())
                {
                    // offhand item must can be stored in inventory for offhand item and it also must be unequipped
                    Item* offItem = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
                    ItemPosCountVec off_dest;
                    if (offItem && (!not_loading ||
                        bot->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0) << 8 | EQUIPMENT_SLOT_OFFHAND,
                            false) != EQUIP_ERR_OK ||
                        bot->CanStoreItem(NULL_BAG, NULL_SLOT, off_dest, offItem, false) != EQUIP_ERR_OK))
                        return swap ? InventoryResult::EQUIP_ERR_CANT_SWAP : InventoryResult::EQUIP_ERR_INV_FULL;
                }
            }
            dest = ((INVENTORY_SLOT_BAG_0 << 8) | eslot);
            return EQUIP_ERR_OK;
        }
    }

    return !swap ? EQUIP_ERR_ITEM_NOT_FOUND : InventoryResult::EQUIP_ERR_CANT_SWAP;
}

uint8 PlayerbotAI::FindEquipSlot(ItemTemplate const* proto, uint32 slot, bool swap) const
{
    uint8 slots[4];
    slots[0] = NULL_SLOT;
    slots[1] = NULL_SLOT;
    slots[2] = NULL_SLOT;
    slots[3] = NULL_SLOT;
    switch (proto->InventoryType)
    {
    case INVTYPE_HEAD:
        slots[0] = EQUIPMENT_SLOT_HEAD;
        break;
    case INVTYPE_NECK:
        slots[0] = EQUIPMENT_SLOT_NECK;
        break;
    case INVTYPE_SHOULDERS:
        slots[0] = EQUIPMENT_SLOT_SHOULDERS;
        break;
    case INVTYPE_BODY:
        slots[0] = EQUIPMENT_SLOT_BODY;
        break;
    case INVTYPE_CHEST:
    case INVTYPE_ROBE:
        slots[0] = EQUIPMENT_SLOT_CHEST;
        break;
    case INVTYPE_WAIST:
        slots[0] = EQUIPMENT_SLOT_WAIST;
        break;
    case INVTYPE_LEGS:
        slots[0] = EQUIPMENT_SLOT_LEGS;
        break;
    case INVTYPE_FEET:
        slots[0] = EQUIPMENT_SLOT_FEET;
        break;
    case INVTYPE_WRISTS:
        slots[0] = EQUIPMENT_SLOT_WRISTS;
        break;
    case INVTYPE_HANDS:
        slots[0] = EQUIPMENT_SLOT_HANDS;
        break;
    case INVTYPE_FINGER:
        slots[0] = EQUIPMENT_SLOT_FINGER1;
        slots[1] = EQUIPMENT_SLOT_FINGER2;
        break;
    case INVTYPE_TRINKET:
        slots[0] = EQUIPMENT_SLOT_TRINKET1;
        slots[1] = EQUIPMENT_SLOT_TRINKET2;
        break;
    case INVTYPE_CLOAK:
        slots[0] = EQUIPMENT_SLOT_BACK;
        break;
    case INVTYPE_RANGED:
    case INVTYPE_WEAPON:
    {
        slots[0] = EQUIPMENT_SLOT_MAINHAND;

        // suggest offhand slot only if know dual wielding
        // (this will be replace mainhand weapon at auto equip instead unwonted "you don't known dual wielding" ...
        if (bot->CanDualWield())
            slots[1] = EQUIPMENT_SLOT_OFFHAND;
        break;
    }
    case INVTYPE_SHIELD:
    case INVTYPE_WEAPONOFFHAND:
    case INVTYPE_HOLDABLE:
        slots[0] = EQUIPMENT_SLOT_OFFHAND;
        break;
    case INVTYPE_2HWEAPON:
        slots[0] = EQUIPMENT_SLOT_MAINHAND;
        if (Item* mhWeapon = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND))
        {
            if (ItemTemplate const* mhWeaponProto = mhWeapon->GetTemplate())
            {
                if (mhWeaponProto->SubClass == ITEM_SUBCLASS_WEAPON_POLEARM ||
                    mhWeaponProto->SubClass == ITEM_SUBCLASS_WEAPON_STAFF)
                {
                    bot->AutoUnequipOffhandIfNeed(true);
                    break;
                }
            }
        }

        if (bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
        {
            if (proto->SubClass == ITEM_SUBCLASS_WEAPON_POLEARM || proto->SubClass == ITEM_SUBCLASS_WEAPON_STAFF)
            {
                break;
            }
        }
        if (bot->CanDualWield() && bot->CanTitanGrip() && proto->SubClass != ITEM_SUBCLASS_WEAPON_POLEARM &&
            proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF && proto->SubClass != ITEM_SUBCLASS_WEAPON_FISHING_POLE)
            slots[1] = EQUIPMENT_SLOT_OFFHAND;
        break;
    case INVTYPE_TABARD:
        slots[0] = EQUIPMENT_SLOT_TABARD;
        break;
    case INVTYPE_WEAPONMAINHAND:
        slots[0] = EQUIPMENT_SLOT_MAINHAND;
        break;
    case INVTYPE_BAG:
        slots[0] = INVENTORY_SLOT_BAG_START + 0;
        slots[1] = INVENTORY_SLOT_BAG_START + 1;
        slots[2] = INVENTORY_SLOT_BAG_START + 2;
        slots[3] = INVENTORY_SLOT_BAG_START + 3;
        break;
    default:
        return NULL_SLOT;
    }

    if (slot != NULL_SLOT)
    {
        if (swap || !bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            for (uint8 i = 0; i < 4; ++i)
                if (slots[i] == slot)
                    return slot;
    }
    else
    {
        // search free slot at first
        for (uint8 i = 0; i < 4; ++i)
            if (slots[i] != NULL_SLOT && !bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slots[i]))
                // in case 2hand equipped weapon (without titan grip) offhand slot empty but not free
                if (slots[i] != EQUIPMENT_SLOT_OFFHAND || !bot->IsTwoHandUsed())
                    return slots[i];

        // if not found free and can swap return first appropriate from used
        for (uint8 i = 0; i < 4; ++i)
            if (slots[i] != NULL_SLOT && swap)
                return slots[i];
    }

    // no free position
    return NULL_SLOT;
}
bool PlayerbotAI::HasAggro(Unit* unit)
{
    if (!unit)
    {
        return false;
    }
    bool isMT = PlayerBotSpec::IsMainTank(bot);
    Unit* victim = unit->GetVictim();
    if (victim && (victim->GetGUID() == bot->GetGUID() || (!isMT && victim->ToPlayer() && PlayerBotSpec::IsTank(victim->ToPlayer()))))
    {
        return true;
    }
    return false;
}

bool PlayerbotAI::HasEngagedTarget(Unit* target) const
{
    if (!bot || !target || !bot->IsValidAttackTarget(target))
        return false;

    // Do not let a pet continue on an old target after its owner switches or
    // clears targets. Threat from an earlier hit alone is not a current order.
    Unit* ownerTarget = _aiObjectContext ?
        _aiObjectContext->GetValue<Unit*>("current target")->Get() : nullptr;
    if (ownerTarget != target)
        return false;

    // Melee and explicit auto-attacks establish a victim immediately.
    if (bot->GetVictim() == target)
        return true;

    // Ranged and caster owners may not have a melee victim yet. Recognize a
    // harmful cast aimed at this exact unit so their pet can assist as the
    // owner's attack begins, rather than after an arbitrary party member pulls.
    for (uint8 type = CURRENT_MELEE_SPELL; type < CURRENT_MAX_SPELL; ++type)
    {
        Spell* spell = bot->GetCurrentSpell(CurrentSpellTypes(type));
        if (!spell || spell->m_targets.GetUnitTargetGUID() != target->GetGUID())
            continue;

        SpellInfo const* spellInfo = spell->GetSpellInfo();
        if (spellInfo && spellInfo->DmgClass != SPELL_DAMAGE_CLASS_NONE &&
            !bot->IsFriendlyTo(target))
            return true;
    }

    // Instant attacks may already have finished by the next AI update. A
    // positive threat entry proves that this owner actually engaged the PvE
    // target; target combat caused solely by another group member does not.
    return target->CanHaveThreatList() &&
        target->GetThreatManager().getThreat(bot) > 0.0f;
}
