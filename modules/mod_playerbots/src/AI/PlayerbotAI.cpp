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

#include <algorithm>
#include <atomic>
#include <array>
#include <cctype>
#include <cmath>
#include <limits>
#include <mutex>
#include <sstream>
#include <string>
#include <tuple>
#include <unordered_map>
#include <vector>

#include "AiFactory.h"
#include "Channel.h"
#include "ChannelMgr.h"
#include "CreatureAIImpl.h"
#include "DBCStores.h"
#include "Engine.h"
#include "ExternalEventHelper.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Helper.h"
#include "LastMovementValue.h"
#include "LastSpellCastValue.h"
#include "LFGMgr.h"
#include "MapManager.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PositionValue.h"
#include "PointMovementGenerator.h"
#include "Playerbots.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "PlayerbotTextMgr.h"
#include "PerformanceMonitor.h"
#include "RandomPlayerbotMgr.h"
#include "ServerFacade.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SocialMgr.h"
#include "SpellAuraEffects.h"
#include "SpellHistory.h"
#include "SpellInfo.h"
#include "Transport.h"
#include "TradeData.h"
#include "Unit.h"
#include "Vehicle.h"
#include "UpdateFields.h"

// True when the text still contains an unresolved placeholder (a %name token or
// a <name> token) that PlayerbotTextMgr::Format could not substitute. Used to
// re-roll random ambient texts so no raw placeholders reach chat.
static bool HasUnresolvedPlaceholders(std::string const& text)
{
    for (size_t i = 0; i + 1 < text.size(); ++i)
    {
        if (text[i] == '%' && (std::isalpha(static_cast<unsigned char>(text[i + 1])) || text[i + 1] == '_'))
            return true;
        if (text[i] == '<' && text.find('>', i + 1) != std::string::npos)
            return true;
    }
    return false;
}

namespace
{
// The custom chat channel the ambient chatter is posted to. Bots join it
// automatically when they log in (JoinBotToWorldChannel in PlayerbotMgr.cpp).
char const* const BOT_WORLD_CHANNEL_NAME = "World";
// How often one bot may roll for the server-wide ambient speech slot (the
// custom "World" chat channel). TalkRandom also has to win the global
// TryReserveAmbientSpeech CAS, so in practice only one bot speaks per window.
constexpr uint32 AMBIENT_SPEECH_INTERVAL_SEC = 20;
// Extra random delay (0..AMBIENT_SPEECH_JITTER_SEC) added to the per-bot
// timer. A fixed interval makes every bot wake up on the same second, so the
// bot that just used the slot wakes up exactly when it reopens and wins it
// again -- the same few bots would speak in World forever.
// A random offset spreads the wake-ups across the window.
constexpr uint32 AMBIENT_SPEECH_JITTER_SEC = 20;
// A bot that has already used the slot has to wait this long before it may
// take it again, which rotates the chatter over the whole bot population.
// It must exceed AMBIENT_SPEECH_INTERVAL_SEC so that after a bot speaks there
// is still at least one eligible bot left while the slot is locked.
constexpr uint32 AMBIENT_SPEECH_COOLDOWN_SEC = 40;
// Every eligible bot first draws a random moment inside this window and only
// competes for the slot once that moment has passed. The bot with the shortest
// drawn delay is the one that reaches the global TryReserveAmbientSpeech CAS,
// so the winner is a uniformly random member of the eligible set instead of
// the bot whose AI tick happens to run first.
// Milliseconds are used on purpose: time_t only resolves whole seconds, so at
// that resolution several bots would draw the same instant and the tie would
// be decided by update order again.
constexpr uint32 AMBIENT_SPEECH_RACE_MS = 3000;
} // namespace

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

BotActivityMode PlayerbotAI::GetActivityMode() const
{
    if (!bot)
        return BotActivityMode::OpenWorldPve;

    // Arenas are battleground maps too, so the more specific check must win.
    if (bot->InArena())
        return BotActivityMode::ArenaPvp;
    if (bot->InBattleground())
        return BotActivityMode::BattlegroundPvp;

    // Boss Caller raids are deliberately staged in the outdoor world.  The
    // access flag has exactly the same lifecycle as that managed raid and is
    // therefore a stronger signal than the map type.
    if (bot->HasWorldBossStagingAccess())
        return BotActivityMode::WorldBossPve;

    Map* map = bot->GetMap();
    if (map && map->IsRaid())
        return BotActivityMode::RaidPve;
    if (map && map->IsDungeon())
        return BotActivityMode::DungeonPve;

    return BotActivityMode::OpenWorldPve;
}

bool PlayerbotAI::IsGroupPveActivity() const
{
    BotActivityMode const mode = GetActivityMode();
    return mode == BotActivityMode::DungeonPve ||
        mode == BotActivityMode::RaidPve ||
        mode == BotActivityMode::WorldBossPve;
}

bool PlayerbotAI::IsPvpActivity() const
{
    BotActivityMode const mode = GetActivityMode();
    return mode == BotActivityMode::BattlegroundPvp ||
        mode == BotActivityMode::ArenaPvp;
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
        Unit* petTarget = pet->GetVictim();
        CharmInfo* charmInfo = pet->GetCharmInfo();
        bool const ownerStillEngaged = petTarget &&
            HasEngagedTarget(petTarget);
        bool const staleAttackCommand = charmInfo &&
            charmInfo->IsCommandAttack() && !ownerStillEngaged;
        if ((petTarget && !ownerStillEngaged) || staleAttackCommand)
        {
            pet->AttackStop();
            pet->SetTarget(ObjectGuid::Empty);
            if (charmInfo)
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

        // Establish the specialization's personal stance/presence/form first.
        // Unlike arenas, LFG has no preparation countdown and combat can begin
        // immediately after loading. If the mode is already correct, continue
        // with one normal raid buff from the same request.
        bool cast = safe && CastAutomatedRoleMode(bot);
        if (safe && !cast)
            cast = CastAutomatedPvpPreparationBuff(bot);
        if (cast)
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

    // Interrupts are checked before the ordinary "wait for current cast"
    // path. This lets the one bot selected by the LFG group coordinator stop
    // its own heal/damage cast and answer a short enemy cast immediately.
    if (TryGroupPveCoordinatedInterrupt())
    {
        YieldThread(GetReactDelay());
        return;
    }

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

    UpdateRandomSpeech(elapsed);

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
    case SMSG_ITEM_PUSH_RESULT:  // bot looted/received an item -> loot broadcast
    {
        if (!sPlayerbotAIConfig->enableBroadcasts)
            break;

        WorldPacket p = packet;
        ObjectGuid itemGuid, playerGuid;
        bool displayInChat = false, received = false, bonusLoot = false, created = false;

        itemGuid[2] = p.ReadBit();
        playerGuid[4] = p.ReadBit();
        itemGuid[5] = p.ReadBit();
        displayInChat = p.ReadBit();
        playerGuid[1] = p.ReadBit();
        received = p.ReadBit();   // 0 = looted, 1 = npc
        itemGuid[4] = p.ReadBit();
        playerGuid[6] = p.ReadBit();
        playerGuid[5] = p.ReadBit();
        playerGuid[7] = p.ReadBit();
        playerGuid[0] = p.ReadBit();
        itemGuid[0] = p.ReadBit();
        itemGuid[7] = p.ReadBit();
        playerGuid[2] = p.ReadBit();
        itemGuid[6] = p.ReadBit();
        bonusLoot = p.ReadBit();
        playerGuid[3] = p.ReadBit();
        itemGuid[1] = p.ReadBit();
        created = p.ReadBit();    // 0 = received, 1 = created
        itemGuid[3] = p.ReadBit();
        p.FlushBits();

        p.ReadByteSeq(playerGuid[1]);
        p.ReadByteSeq(itemGuid[1]);
        uint32 battlePetSpecies = 0;
        p >> battlePetSpecies;
        p.ReadByteSeq(itemGuid[0]);
        p.ReadByteSeq(playerGuid[5]);
        p.ReadByteSeq(playerGuid[2]);
        uint32 suffixFactor = 0;
        p >> suffixFactor;
        p.ReadByteSeq(itemGuid[7]);
        uint32 quality = 0;
        p >> quality;
        uint32 itemId = 0;
        p >> itemId;
        int32 randomPropertyId = 0;
        p >> randomPropertyId;
        p.ReadByteSeq(itemGuid[6]);
        uint32 breed = 0;
        p >> breed;
        uint32 inventoryCount = 0;
        p >> inventoryCount;
        p.ReadByteSeq(itemGuid[2]);
        p.ReadByteSeq(playerGuid[0]);
        uint32 count = 0;
        p >> count;
        p.ReadByteSeq(playerGuid[7]);
        p.ReadByteSeq(itemGuid[5]);
        p.ReadByteSeq(playerGuid[4]);
        uint32 itemSlot = 0;
        p >> itemSlot;

        // Only react to items that were looted from the world (not NPC/quest/craft).
        if (!received && !created)
        {
            uint32 chance = 0;
            std::string category;
            switch (quality)
            {
                case 0: chance = sPlayerbotAIConfig->broadcastChanceLootingItemPoor; category = "broadcast_looting_item_poor"; break;
                case 1: chance = sPlayerbotAIConfig->broadcastChanceLootingItemNormal; category = "broadcast_looting_item_normal"; break;
                case 2: chance = sPlayerbotAIConfig->broadcastChanceLootingItemUncommon; category = "broadcast_looting_item_uncommon"; break;
                case 3: chance = sPlayerbotAIConfig->broadcastChanceLootingItemRare; category = "broadcast_looting_item_rare"; break;
                case 4: chance = sPlayerbotAIConfig->broadcastChanceLootingItemEpic; category = "broadcast_looting_item_epic"; break;
                case 5: chance = sPlayerbotAIConfig->broadcastChanceLootingItemLegendary; category = "broadcast_looting_item_legendary"; break;
                default: chance = sPlayerbotAIConfig->broadcastChanceLootingItemArtifact; category = "broadcast_looting_item_artifact"; break;
            }

            ItemTemplate const* itemProto = itemId ? sObjectMgr->GetItemTemplate(itemId) : nullptr;
            if (chance)
                TryBroadcast(category, chance, nullptr, itemProto);
        }
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

    // If there is no real player master, the bot announces its message in /say
    // instead of whispering it (e.g. random bots speaking in the world).
    if (!master || (masterBotAI && !masterBotAI->IsRealPlayer()))
    {
        bot->Say(text, (bot->GetTeamId() == TEAM_ALLIANCE ? LANG_COMMON : LANG_ORCISH));
        return true;
    }

    if (!master->GetSession())
        return false;

    // Avoid spamming the master with the exact same message too often.
    time_t lastSaid = whispers[text];

    if (lastSaid && (time(nullptr) - lastSaid) < sPlayerbotAIConfig->repeatDelay / 1000)
        return true;

    whispers[text] = time(nullptr);

    WorldPacket data;
    ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, LANG_UNIVERSAL, bot, master, text.c_str());
    master->GetSession()->SendPacket(&data);

    return true;
}

bool PlayerbotAI::HandleCommand(uint32 /*type*/, std::string const text, Player* owner)
{
    if (!owner)
        owner = GetMaster();
    if (!owner)
        return false;

    std::string msg = text;
    // Trim surrounding whitespace
    size_t first = msg.find_first_not_of(" \t");
    if (first == std::string::npos)
        return false;
    msg = msg.substr(first);
    size_t last = msg.find_last_not_of(" \t");
    if (last != std::string::npos)
        msg = msg.substr(0, last + 1);

    if (msg.empty())
        return false;

    // Trivial social chatter is not treated as a command.
    if (msg == "hi" || msg == "hello" || msg == "hey" || msg == "yo")
        return false;

    // Strategy toggle commands ("follow", "stay", ...). If the message names a
    // known strategy, toggle it on the appropriate engine so the master can
    // command the bot by typing the strategy name.
    if (msg == "follow" || msg == "stay" || msg == "runaway" || msg == "guard" ||
        msg == "ranged" || msg == "close" || msg == "save mana" || msg == "group" ||
        msg == "dead" || msg == "formation" || msg == "move from group" ||
        msg == "flee from adds" || msg == "dps assist" || msg == "tank assist")
    {
        // Toggle the strategy. "+name" enables it; if already enabled it is
        // toggled off, matching the classic playerbots behaviour.
        ChangeStrategy("+" + msg, BOT_STATE_NON_COMBAT);
        return true;
    }

    ExternalEventHelper helper(_aiObjectContext);
    return helper.ParseChatCommand(msg, owner);
}

bool PlayerbotAI::Talk(std::string const name, Unit* target, ItemTemplate const* item, Quest const* quest)
{
    if (!sPlayerbotAIConfig->randomBotTalk)
        return false;
    if (!bot || !bot->IsInWorld() || bot->IsDuringRemoveFromWorld())
        return false;
    if (bot->IsInCombat() && _currentState != BOT_STATE_COMBAT)
        return false;

    LocaleConstant locale = DEFAULT_LOCALE;
    if (Player* m = GetMaster())
        locale = m->GetSession()->GetSessionDbcLocale();
    else
        locale = bot->GetSession()->GetSessionDbcLocale();

    uint32 sayType = 0;
    std::string text = sPlayerbotTextMgr->GetText(name, locale, &sayType);
    if (text.empty())
        text = sPlayerbotTextMgr->GetSpeech(name, target ? target->GetName() : "");
    if (text.empty())
        return false;

    text = sPlayerbotTextMgr->Format(std::move(text), bot, target, item, quest);

    if (sayType == 1)
        return Yell(text);

    return Say(text);
}

bool PlayerbotAI::TalkRandom()
{
    if (!sPlayerbotAIConfig->randomBotTalk)
        return false;
    if (!bot || !bot->IsInWorld() || bot->IsDuringRemoveFromWorld())
        return false;
    if (bot->IsInCombat() && _currentState != BOT_STATE_COMBAT)
        return false;

    LocaleConstant locale = DEFAULT_LOCALE;
    if (Player* m = GetMaster())
        locale = m->GetSession()->GetSessionDbcLocale();
    else
        locale = bot->GetSession()->GetSessionDbcLocale();

    // Server-wide ambient speech slot: no matter how many bots are online,
    // only one wins a slot per window, so the World channel never floods with
    // simultaneous bot chatter.
    if (!sPlayerbotTextMgr->TryReserveAmbientSpeech(AMBIENT_SPEECH_INTERVAL_SEC))
        return false;

    // Pick a random text from the whole table. Some rows are templates whose
    // placeholders (e.g. %quest_link, %category, %faction) Format() cannot fill
    // without extra context, so re-roll a few times until the formatted text is
    // clean (no raw placeholders) before sending it to chat.
    for (uint32 attempt = 0; attempt < 10; ++attempt)
    {
        uint32 sayType = 0;
        std::string text = sPlayerbotTextMgr->GetRandomText(locale, &sayType);
        if (text.empty())
        {
            // An empty text pool means ambient chat can never produce anything,
            // so the World channel would go silent with no trace left. Report
            // it once instead of every time a bot tries.
            static std::atomic<bool> emptyTextPoolWarned{false};
            bool expected = false;
            if (emptyTextPoolWarned.compare_exchange_strong(expected, true))
                TC_LOG_WARN("playerbots",
                    "Bot %s cannot speak in the \"%s\" channel: the ai_playerbot_texts table is empty, so ambient chatter is disabled",
                    bot->GetName().c_str(), BOT_WORLD_CHANNEL_NAME);
            return false;
        }

        text = sPlayerbotTextMgr->Format(std::move(text), bot);
        if (HasUnresolvedPlaceholders(text))
            continue;

        // Prefer speaking in the World channel (the bot joins it at login so
        // other players can see the ambient chatter).
        //
        // With AllowTwoSide.Interaction.Channel disabled (the default) there is
        // one ChannelMgr per faction, so the same channel name lives in two
        // separate pools; with it enabled both calls return the same ChannelMgr
        // and the duplicate is skipped. The message is then sent to every
        // distinct channel the bot is in, so players of both factions hear the
        // chatter instead of only their own bots.
        //
        // Membership is only ever *read* here, never created or refreshed.
        // Channel creation (GetJoinChannel) and a real join (JoinChannel) both
        // read or write the character database when PreserveCustomChannels is on,
        // and this function runs on a map worker thread -- the world thread owns
        // that connection. So creation and joining stay in JoinBotToWorldChannel,
        // which runs from OnBotLogin on the world thread. A custom channel is
        // only deleted once it runs empty, so with bots in it the entry is
        // stable for the whole uptime.
        std::vector<Channel*> worldChannels;
        ChannelMgr* seenChannelMgr = nullptr;
        for (uint32 faction : { ALLIANCE, HORDE })
        {
            ChannelMgr* cMgr = ChannelMgr::forTeam(faction);
            if (!cMgr || cMgr == seenChannelMgr)
                continue;
            seenChannelMgr = cMgr;

            Channel* channel = cMgr->GetChannel(BOT_WORLD_CHANNEL_NAME, bot, false);
            if (channel && channel->IsOn(bot->GetGUID()))
                worldChannels.push_back(channel);
        }

        if (!worldChannels.empty())
        {
            for (Channel* channel : worldChannels)
                channel->Say(bot->GetGUID(), text, LANG_UNIVERSAL);

            // Hand the slot to someone else: UpdateRandomSpeech keeps a bot
            // that just spoke off the next windows.
            _lastAmbientSpeechSec = time(nullptr);
            return true;
        }

        // The bot is not a member of the World channel in any pool, so the
        // message would reach no player in it. Speak locally instead, and say so
        // once a minute -- this distinguishes "no text data" from "bots have
        // text but are not in the channel" (e.g. the channel has a password).
        static std::atomic<time_t> lastNoMembershipWarn{0};
        time_t nowWarn = time(nullptr);
        time_t expected = lastNoMembershipWarn.load(std::memory_order_relaxed);
        if (nowWarn - expected >= 60 &&
            lastNoMembershipWarn.compare_exchange_strong(expected, nowWarn,
                std::memory_order_relaxed, std::memory_order_relaxed))
            TC_LOG_WARN("playerbots",
                "Bot %s could not speak in the \"%s\" channel: it is not a member, so the text was said locally instead. Check that the channel has no password and is not banning bots",
                bot->GetName().c_str(), BOT_WORLD_CHANNEL_NAME);

        if (sayType == 1)
            return Yell(text);
        return Say(text);
    }

    return false;
}

bool PlayerbotAI::TryTalk(std::string const name, uint32 chance, Unit* target, ItemTemplate const* item, Quest const* quest)
{
    if (chance == 0)
        return false;
    if (chance < 30000 && urand(0, 29999) >= chance)
        return false;

    return Talk(name, target, item, quest);
}

bool PlayerbotAI::Broadcast(std::string const name, Unit* target, ItemTemplate const* item, Quest const* quest)
{
    if (!sPlayerbotAIConfig->randomBotTalk || !sPlayerbotAIConfig->enableBroadcasts)
        return false;
    if (!bot || !bot->IsInWorld() || bot->IsDuringRemoveFromWorld())
        return false;
    if (bot->IsInCombat() && _currentState != BOT_STATE_COMBAT)
        return false;

    LocaleConstant locale = DEFAULT_LOCALE;
    if (Player* m = GetMaster())
        locale = m->GetSession()->GetSessionDbcLocale();
    else
        locale = bot->GetSession()->GetSessionDbcLocale();

    uint32 sayType = 0;
    std::string text = sPlayerbotTextMgr->GetText(name, locale, &sayType);
    if (text.empty())
        text = sPlayerbotTextMgr->GetSpeech(name, target ? target->GetName() : "");
    if (text.empty())
        return false;

    text = sPlayerbotTextMgr->Format(std::move(text), bot, target, item, quest);

    // 1) Guild chat (most reliable - no channel membership needed)
    if (Guild* guild = bot->GetGuild())
    {
        if (urand(0, 29999) < sPlayerbotAIConfig->broadcastToGuildGlobalChance)
        {
            guild->BroadcastToGuild(bot->GetSession(), false, text);
            return true;
        }
    }

    // 2) Chat channels, gated by their per-channel global chances.
    //    Channel names are built from the DBC pattern so they match the real
    //    localized channels other players can see. Standard ChatChannels.dbc
    //    ids: 1=General, 2=Trade, 22=LocalDefense, 25=GuildRecruitment,
    //    26=LookingForGroup.
    ChannelMgr* cMgr = ChannelMgr::forTeam(bot->GetTeamId());
    if (cMgr)
    {
        auto channelName = [&](uint32 channelId, std::string const& sub) -> std::string
        {
            for (uint32 i = 0; i < sChatChannelsStore.GetNumRows(); ++i)
            {
                ChatChannelsEntry const* ch = sChatChannelsStore.LookupEntry(i);
                if (!ch || ch->ChannelID != channelId || !ch->pattern[locale])
                    continue;
                char buf[120];
                snprintf(buf, 120, ch->pattern[locale], sub.c_str());
                return std::string(buf);
            }
            return "";
        };

        AreaTableEntry const* zone = sAreaTableStore.LookupEntry(bot->GetZoneId());
        std::string zoneName = zone && zone->area_name[0] ? zone->area_name[0] : "";
        std::string cityName = "";
        if (AreaTableEntry const* city = sAreaTableStore.LookupEntry(3459))
            cityName = city->area_name[0] ? city->area_name[0] : "";

        struct ChannelCandidate
        {
            uint32 id;
            std::string name;
            uint32 chance;
        };

        std::vector<ChannelCandidate> candidates;
        if (!zoneName.empty())
        {
            candidates.push_back({ 1, channelName(1, zoneName), sPlayerbotAIConfig->broadcastToGeneralGlobalChance });
            candidates.push_back({ 22, channelName(22, zoneName), sPlayerbotAIConfig->broadcastToLocalDefenseGlobalChance });
        }
        if (!cityName.empty())
        {
            candidates.push_back({ 2, channelName(2, cityName), sPlayerbotAIConfig->broadcastToTradeGlobalChance });
            candidates.push_back({ 25, channelName(25, cityName), sPlayerbotAIConfig->broadcastToGuildRecruitmentGlobalChance });
        }
        candidates.push_back({ 26, channelName(26, ""), sPlayerbotAIConfig->broadcastToLFGGlobalChance });
        candidates.push_back({ 0, BOT_WORLD_CHANNEL_NAME, sPlayerbotAIConfig->broadcastToWorldGlobalChance });

        for (auto const& candidate : candidates)
        {
            if (!candidate.chance || candidate.name.empty())
                continue;
            if (urand(0, 29999) >= candidate.chance)
                continue;

            Channel* channel = cMgr->GetChannel(candidate.name, bot, false);
            if (!channel)
                channel = cMgr->GetJoinChannel(candidate.name, candidate.id);
            if (!channel)
                continue;

            // JoinChannel is a no-op for players that are already members.
            // Bots are server-side NPCs, so the join must stay silent.
            channel->JoinChannel(bot, "", false);
            if (!channel->IsOn(bot->GetGUID()))
                continue;                 // Say() would silently drop the text

            channel->Say(bot->GetGUID(), text, LANG_UNIVERSAL);

            // A World-channel broadcast counts as ambient chatter, so this bot
            // yields the next windows to other World channel members.
            if (candidate.id == 0)
                _lastAmbientSpeechSec = time(nullptr);

            return true;
        }
    }

    // 3) Fall back to a local say/yell.
    if (sayType == 1)
        return Yell(text);

    return Say(text);
}

bool PlayerbotAI::TryBroadcast(std::string const name, uint32 chance, Unit* target, ItemTemplate const* item, Quest const* quest)
{
    if (chance == 0)
        return false;
    if (chance < 30000 && urand(0, 29999) >= chance)
        return false;

    return Broadcast(name, target, item, quest);
}

void PlayerbotAI::UpdateRandomSpeech(uint32 /*elapsed*/)
{
    if (!sPlayerbotAIConfig->randomBotTalk)
        return;

    // Resolve the ambient speech race. The instant is drawn on the 20-40 s
    // check cadence further down, but the deadline itself has to be polled on
    // every AI tick -- UpdateRandomSpeech() is called from UpdateAIInternal()
    // -- otherwise the random delay would never shift the moment of the
    // attempt and the bot with the fastest tick would still win the slot.
    if (_ambientRaceDeadlineMs)
    {
        // Plain unsigned comparison. Do NOT use getMSTimeDiff(now, deadline)
        // here: once the deadline has passed, getMSTimeDiff treats now as a
        // uint32 wrap-around of the deadline and returns a huge positive
        // number, so the check below would stay true forever and TalkRandom()
        // would never run -- no bot would ever speak again.
        if (getMSTime() < _ambientRaceDeadlineMs)
            return;                  // the drawn instant has not arrived yet

        _ambientRaceDeadlineMs = 0;
        TalkRandom();
        return;
    }

    time_t now = time(nullptr);
    if (now < _speechCheckTimer)
        return;

    // Anti-spam: a bot checks the ambient slot at most once per window.
    //
    // The random offset is what keeps the whole population from locking onto a
    // single speaker: with a fixed interval every bot wakes up on the same
    // second, so the bot that just took the global slot wakes up exactly when
    // the slot reopens and wins it again -- the same few bots would keep
    // speaking in the World channel forever. The jitter spreads the wake-ups
    // across the window, so a random bot is the one that reaches the slot.
    _speechCheckTimer = now + AMBIENT_SPEECH_INTERVAL_SEC + urand(0, AMBIENT_SPEECH_JITTER_SEC);

    if (bot->IsInCombat())
    {
        // taunt speech while the bot has aggro (the victim is attacking the bot)
        if (Unit* victim = bot->GetVictim())
        {
            if (victim->GetVictim() == bot)
            {
                uint32 tauntChance = sPlayerbotTextMgr->GetSpeechProbability("taunt");
                if (tauntChance && urand(1, 100) <= tauntChance)
                    Talk("taunt", victim);
            }
        }

        // aoe speech when the bot is surrounded by multiple attackers
        if (bot->getAttackers().size() >= 2)
        {
            uint32 aoeChance = sPlayerbotTextMgr->GetSpeechProbability("aoe");
            if (aoeChance && urand(1, 100) <= aoeChance)
                Talk("aoe", bot->GetVictim());
        }
    }
    else
    {
        // random emotes when enabled (AiPlayerbot.RandomBotEmote)
        if (sPlayerbotAIConfig->randomBotEmote && urand(1, 100) <= 10)
        {
            static std::array<Emote, 10> const emotes = {
                EMOTE_ONESHOT_WAVE, EMOTE_ONESHOT_BOW, EMOTE_ONESHOT_APPLAUD, EMOTE_ONESHOT_CHEER,
                EMOTE_ONESHOT_KNEEL, EMOTE_ONESHOT_CRY, EMOTE_ONESHOT_ROAR, EMOTE_ONESHOT_SALUTE,
                EMOTE_ONESHOT_DANCE, EMOTE_ONESHOT_LAUGH
            };
            bot->HandleEmoteCommand(emotes[urand(0, uint32(emotes.size() - 1))]);
            return;
        }

        // ambient chatter for masterless random bots (or when explicitly enabled).
        // Low frequency so a bot speaks at most every ~20s.
        if (!HasRealPlayerMaster() || sPlayerbotAIConfig->randomBotSayWithoutMaster)
        {
            if (!sPlayerbotAIConfig->enableBroadcasts)
                return;

            // dungeon suggestion (broadcast to channels)
            if (sPlayerbotAIConfig->randomBotSuggestDungeons &&
                sPlayerbotAIConfig->broadcastChanceSuggestInstance &&
                urand(0, 29999) < sPlayerbotAIConfig->broadcastChanceSuggestInstance)
            {
                Broadcast("suggest_instance");
                return;
            }

            // Rotate the slot. TalkRandom() releases only one server-wide
            // speech slot per window, so without this the bot that happens to
            // wake up first would keep taking it and the World channel would
            // be filled by the same few bots. A bot that already used a recent
            // window stays silent and hands the slot to another member.
            //
            // A negative value means the wall clock moved backwards since this
            // bot last spoke; treat that as "not recently spoken" so the bot
            // can still talk instead of going silent for the rest of the uptime.
            time_t const sinceLastSpeech = now - _lastAmbientSpeechSec;
            if (sinceLastSpeech >= 0 && sinceLastSpeech < AMBIENT_SPEECH_COOLDOWN_SEC)
                return;

            // Pick the speaker by a randomized race instead of by update order:
            // draw one instant inside the race window, and only compete for the
            // global slot once that instant has passed (see the poll at the top
            // of this function). The bot with the shortest drawn delay wins, so
            // the speaker is a uniformly random member of the eligible set
            // instead of the bot whose AI tick runs first.
            _ambientRaceDeadlineMs = getMSTime() + urand(0, AMBIENT_SPEECH_RACE_MS);
            return;                     // TalkRandom() fires once the instant passes
        }
    }
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

namespace
{
std::mutex GroupPveInterruptReservationMutex;
std::unordered_map<uint64, uint32> GroupPveInterruptReservations;

uint64 GetGroupPveInterruptReservationKey(Unit* target)
{
    if (!target)
        return 0;
    return (uint64(target->GetInstanceId()) << 32) |
        target->GetGUID().GetCounter();
}

bool IsGroupPveInterruptReserved(Unit* target)
{
    uint64 key = GetGroupPveInterruptReservationKey(target);
    if (!key)
        return false;

    std::lock_guard<std::mutex> lock(GroupPveInterruptReservationMutex);
    auto itr = GroupPveInterruptReservations.find(key);
    if (itr == GroupPveInterruptReservations.end())
        return false;
    if (int32(itr->second - getMSTime()) > 0)
        return true;
    GroupPveInterruptReservations.erase(itr);
    return false;
}

void ReserveGroupPveInterrupt(Unit* target)
{
    uint64 key = GetGroupPveInterruptReservationKey(target);
    if (!key)
        return;

    // Keep projectile/destination stuns from prompting another bot to spend
    // its cooldown before the first effect reaches the trash caster.
    std::lock_guard<std::mutex> lock(GroupPveInterruptReservationMutex);
    uint32 now = getMSTime();
    for (auto itr = GroupPveInterruptReservations.begin();
         itr != GroupPveInterruptReservations.end();)
    {
        if (int32(itr->second - now) <= 0)
            itr = GroupPveInterruptReservations.erase(itr);
        else
            ++itr;
    }
    GroupPveInterruptReservations[key] = now + 750;
}

std::vector<char const*> GetLfgInterruptActions(Player* player)
{
    if (!player)
        return {};

    switch (player->GetClass())
    {
        case CLASS_WARRIOR:      return { "pummel", "disrupting shout" };
        case CLASS_PALADIN:      return { "rebuke" };
        case CLASS_HUNTER:       return { "counter shot", "silencing shot" };
        case CLASS_ROGUE:        return { "kick" };
        case CLASS_PRIEST:       return { "silence" };
        case CLASS_DEATH_KNIGHT: return { "mind freeze", "strangulate" };
        case CLASS_SHAMAN:       return { "wind shear" };
        case CLASS_MAGE:         return { "counterspell" };
        case CLASS_WARLOCK:      return { "spell lock", "optical blast" };
        case CLASS_MONK:         return { "spear hand strike" };
        case CLASS_DRUID:
            // Skull Bash requires a melee form; caster druids should try
            // their ranged interrupt first instead of cancelling a heal only
            // to fail the shapeshift requirement.
            return player->GetSpecialization() == SPEC_DRUID_FERAL ||
                   player->GetSpecialization() == SPEC_DRUID_GUARDIAN ?
                std::vector<char const*> { "skull bash", "solar beam" } :
                std::vector<char const*> { "solar beam", "skull bash" };
        default:                 return {};
    }
}

std::vector<char const*> GetLfgStunActions(Player* player)
{
    if (!player)
        return {};

    switch (player->GetClass())
    {
        case CLASS_WARRIOR: return { "storm bolt", "shockwave" };
        case CLASS_PALADIN: return { "hammer of justice" };
        case CLASS_HUNTER:  return { "intimidation", "binding shot" };
        case CLASS_ROGUE:   return { "kidney shot" };
        case CLASS_PRIEST:  return { "psychic horror" };
        case CLASS_DEATH_KNIGHT: return { "asphyxiate", "gnaw" };
        case CLASS_MAGE:    return { "deep freeze" };
        case CLASS_WARLOCK: return { "shadowfury" };
        case CLASS_MONK:    return { "leg sweep" };
        case CLASS_DRUID:   return { "mighty bash", "bash" };
        // Capacitor Totem is delayed and therefore is not a dependable cast
        // stop. Shaman already has the much better Wind Shear above.
        default:            return {};
    }
}

Spell const* GetInterruptibleCurrentSpell(Unit* target)
{
    if (!target || !target->IsNonMeleeSpellCasted(false))
        return nullptr;

    for (uint8 type = CURRENT_GENERIC_SPELL;
         type <= CURRENT_CHANNELED_SPELL; ++type)
    {
        Spell const* spell = target->GetCurrentSpell(CurrentSpellTypes(type));
        SpellInfo const* info = spell ? spell->GetSpellInfo() : nullptr;
        if (info &&
            (info->InterruptFlags & SPELL_INTERRUPT_FLAG_INTERRUPT) &&
            info->PreventionType == SPELL_PREVENTION_TYPE_SILENCE)
            return spell;
    }

    return nullptr;
}

bool IsCastingNonMeleeSpell(Player* player)
{
    return player &&
        (player->GetCurrentSpell(CURRENT_GENERIC_SPELL) ||
         player->GetCurrentSpell(CURRENT_CHANNELED_SPELL));
}

uint8 GetInterruptRolePriority(Player* player)
{
    if (!player)
        return 3;
    if (PlayerBotSpec::IsHeal(player))
        return 2;
    if (PlayerBotSpec::IsTank(player))
        return 1;
    return 0;
}

bool CanPrepareLfgInterrupt(Unit* caster, Unit* target,
    SpellInfo const* spellInfo)
{
    if (!caster || !target || !spellInfo)
        return false;

    // CheckCast() is normally reached through Spell::prepare(), which fills
    // m_powerType and m_powerCost first.  This is only a disposable probe, so
    // calling CheckCast() directly with TRIGGERED_NONE can read the
    // uninitialised power fields and eventually assert in Unit::GetPowerIndex.
    // The real cast still performs its normal power/reagent checks below; the
    // probe only needs to validate target, range, LOS and caster state.
    Spell probe(caster, spellInfo,
        TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
    if (spellInfo->Targets & TARGET_FLAG_DEST_LOCATION)
        probe.m_targets.SetDst(*target);
    else if (spellInfo->Targets & TARGET_FLAG_SOURCE_LOCATION)
        probe.m_targets.SetDst(*caster);
    else
        probe.m_targets.SetUnitTarget(target);

    SpellCastResult result = caster->ToPet() ?
        probe.CheckPetCast(target) : probe.CheckCast(true);
    return result == SPELL_CAST_OK ||
        result == SPELL_FAILED_NOT_INFRONT ||
        result == SPELL_FAILED_UNIT_NOT_INFRONT ||
        result == SPELL_FAILED_NOT_STANDING;
}

bool IsLfgBoss(Unit* target)
{
    Creature* creature = target ? target->ToCreature() : nullptr;
    CreatureTemplate const* creatureTemplate = creature ?
        creature->GetCreatureTemplate() : nullptr;
    return creature && (creature->IsDungeonBoss() ||
        creature->isWorldBoss() || (creatureTemplate &&
        creatureTemplate->rank == CREATURE_ELITE_WORLDBOSS));
}

bool CanStunLfgTrash(Unit* target, SpellInfo const* spellInfo)
{
    if (!target || !spellInfo || IsLfgBoss(target))
        return false;

    bool hasUsableStunEffect = false;
    for (uint8 effect = EFFECT_0; effect < MAX_SPELL_EFFECTS; ++effect)
    {
        SpellEffectInfo const& effectInfo = spellInfo->Effects[effect];
        bool isStun = effectInfo.ApplyAuraName == SPELL_AURA_MOD_STUN ||
            effectInfo.Mechanic == MECHANIC_STUN ||
            spellInfo->Mechanic == MECHANIC_STUN;
        if (effectInfo.IsEffect() && isStun &&
            !target->IsImmunedToSpellEffect(spellInfo, effect))
            hasUsableStunEffect = true;
    }

    return hasUsableStunEffect &&
        !target->IsImmunedToSpell(spellInfo,
            spellInfo->NegativeEffectMask);
}

bool ShouldDelayGroupPveAoe(PlayerbotAI* botAI, Player* bot,
    Unit* spellTarget, SpellInfo const* spellInfo)
{
    if (!botAI || !bot || !spellTarget || !spellInfo ||
        !botAI->IsGroupPveActivity() || PlayerBotSpec::IsTank(bot, true))
        return false;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group)
        group = bot->GetGroup();
    if (!group)
        return false;

    bool hasLivingTank = false;
    for (GroupReference* ref = group->GetFirstMember(); ref;
         ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member->IsAlive() &&
            member->GetMap() == bot->GetMap() &&
            PlayerBotSpec::IsTank(member, true))
        {
            hasLivingTank = true;
            break;
        }
    }
    if (!hasLivingTank)
        return false;

    bool harmfulAreaEffect = false;
    float effectRadius = 0.0f;
    for (uint8 effectIndex = EFFECT_0;
         effectIndex < MAX_SPELL_EFFECTS; ++effectIndex)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[effectIndex];
        if (!effect.IsEffect() || spellInfo->IsPositiveEffect(effectIndex))
            continue;

        bool const affectsSeveralTargets = effect.IsTargetingArea() ||
            effect.IsAreaAuraEffect() || effect.ChainTarget > 1;
        if (!affectsSeveralTargets)
            continue;

        harmfulAreaEffect = true;
        effectRadius = std::max(effectRadius, effect.CalcRadius(bot));
        if (effect.ChainTarget > 1)
            effectRadius = std::max(effectRadius, 12.0f);
    }
    if (!harmfulAreaEffect)
        return false;

    // Client data leaves the radius empty for some cones, cleaves and
    // triggered area effects. Eight yards matches the smallest AoE trigger.
    effectRadius = std::max(effectRadius, 8.0f);

    Unit* center = bot->IsValidAttackTarget(spellTarget) ? spellTarget :
        botAI->GetAiObjectContext()->GetValue<Unit*>("current target")->Get();
    if (!center)
        return false;

    uint32 affectedAttackers = 0;
    bool packHeldByTank = true;
    GuidVector const attackers = botAI->GetAiObjectContext()
        ->GetValue<GuidVector>("attackers")->Get();
    for (ObjectGuid const& guid : attackers)
    {
        Unit* unit = botAI->GetUnit(guid);
        if (!unit || !unit->IsAlive() || unit->GetMap() != bot->GetMap() ||
            !bot->IsValidAttackTarget(unit))
            continue;

        if (center->GetDistance2d(unit) > effectRadius &&
            bot->GetDistance2d(unit) > effectRadius)
            continue;

        ++affectedAttackers;
        Unit* victim = unit->GetVictim();
        Player* victimPlayer = victim ?
            victim->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!victimPlayer || !victimPlayer->IsAlive() ||
            victimPlayer->GetMap() != bot->GetMap() ||
            !group->IsMember(victimPlayer->GetGUID()) ||
            !PlayerBotSpec::IsTank(victimPlayer, true))
            packHeldByTank = false;
    }

    // Single-target use of a spell with an area-capable effect remains valid.
    // Once two or more engaged enemies can be hit, wait for tank ownership.
    return affectedAttackers >= 2 && !packHeldByTank;
}
}

bool PlayerbotAI::TryGroupPveCoordinatedInterrupt()
{
    uint32 requesterGuid = _lfgAutoQueueRequesterGuid.load();
    if (!bot || !bot->IsAlive() || !IsGroupPveActivity())
        return false;

    bool const worldBossRaid =
        GetActivityMode() == BotActivityMode::WorldBossPve;
    if (!requesterGuid && !worldBossRaid)
        return false;

    Group* group = bot->GetGroup(GroupSlot::Instance);
    if (!group)
        group = bot->GetGroup();
    if (!group)
        return false;

    Player* requester = requesterGuid ? ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(requesterGuid)) :
        ObjectAccessor::FindConnectedPlayer(group->GetLeaderGUID());
    if (!requesterGuid && requester)
        requesterGuid = requester->GetGUID().GetCounter();
    Group* requesterGroup = requester ?
        requester->GetGroup(GroupSlot::Instance) : nullptr;
    if (requester && !requesterGroup)
        requesterGroup = requester->GetGroup();
    if (!requester || requesterGroup != group ||
        requester->GetMap() != bot->GetMap())
        return false;

    // Build a group-wide view. A caster may not be this bot's current target,
    // but it can still be attacking another party member or be that member's
    // selected rotation target.
    std::vector<Unit*> castingTargets;
    auto addCastingTarget = [&](Unit* target)
    {
        if (!target || target->GetMap() != bot->GetMap() ||
            !target->IsAlive() || !bot->IsValidAttackTarget(target) ||
            !GetInterruptibleCurrentSpell(target))
            return;
        if (std::find(castingTargets.begin(), castingTargets.end(), target) ==
            castingTargets.end())
            castingTargets.push_back(target);
    };

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || member->GetMap() != bot->GetMap())
            continue;

        addCastingTarget(member->GetVictim());
        addCastingTarget(member->GetSelectedUnit());
        for (Unit* attacker : member->getAttackers())
            addCastingTarget(attacker);

        if (PlayerbotAI* memberAI = GET_PLAYERBOT_AI(member))
            addCastingTarget(memberAI->GetAiObjectContext()->
                GetValue<Unit*>("current target")->Get());
    }

    if (castingTargets.empty())
        return false;

    // Every bot computes the same ordering, so only one provider wins without
    // a cross-thread reservation. Handle the cast closest to completion first.
    std::sort(castingTargets.begin(), castingTargets.end(),
        [](Unit* left, Unit* right)
        {
            Spell const* leftSpell = GetInterruptibleCurrentSpell(left);
            Spell const* rightSpell = GetInterruptibleCurrentSpell(right);
            int32 leftTimer = leftSpell ? leftSpell->GetCurrentCastTimer() :
                std::numeric_limits<int32>::max();
            int32 rightTimer = rightSpell ? rightSpell->GetCurrentCastTimer() :
                std::numeric_limits<int32>::max();
            return std::make_tuple(leftTimer,
                       left->GetGUID().GetCounter()) <
                std::make_tuple(rightTimer,
                    right->GetGUID().GetCounter());
        });

    struct InterruptChoice
    {
        Player* player = nullptr;
        Unit* caster = nullptr;
        uint32 spellId = 0;
        char const* action = nullptr;
        bool stunFallback = false;
        std::tuple<uint8, uint8, uint8, uint32, uint8, float, uint32> rank;
    };

    for (Unit* target : castingTargets)
    {
        if (IsGroupPveInterruptReserved(target))
            continue;

        InterruptChoice best;
        bool found = false;

        for (GroupReference* ref = group->GetFirstMember(); ref;
             ref = ref->next())
        {
            Player* candidate = ref->GetSource();
            PlayerbotAI* candidateAI = candidate ?
                GET_PLAYERBOT_AI(candidate) : nullptr;
            if (!candidate || !candidateAI || candidateAI->IsRealPlayer() ||
                !candidate->IsAlive() || candidate->GetMap() != bot->GetMap() ||
                candidate->HasUnitState(UNIT_STATE_LOST_CONTROL))
                continue;

            if (worldBossRaid)
            {
                if (!candidate->HasWorldBossStagingAccess())
                    continue;
            }
            else if (candidateAI->_lfgAutoQueueRequesterGuid.load() !=
                requesterGuid)
                continue;

            std::vector<std::pair<char const*, bool>> actions;
            for (char const* action : GetLfgInterruptActions(candidate))
                actions.emplace_back(action, false);
            if (!IsLfgBoss(target))
                for (char const* action : GetLfgStunActions(candidate))
                    actions.emplace_back(action, true);

            bool candidateHasInterrupt = false;
            for (auto const& actionEntry : actions)
            {
                char const* action = actionEntry.first;
                bool stunFallback = actionEntry.second;
                // Once this candidate has a real interrupt, do not replace it
                // with one of the candidate's own stun fallbacks.
                if (stunFallback && candidateHasInterrupt)
                    break;

                uint32 spellId = candidateAI->GetAiObjectContext()->
                    GetValue<uint32>("spell id", action)->Get();
                SpellInfo const* spellInfo = spellId ?
                    sSpellMgr->GetSpellInfo(spellId) : nullptr;
                if (!spellInfo)
                    continue;
                if (stunFallback ?
                    !CanStunLfgTrash(target, spellInfo) :
                    !candidateAI->IsInterruptableSpellCasting(target, action))
                    continue;

                Pet* pet = candidate->GetPet();
                Unit* caster = nullptr;
                if (candidate->HasSpell(spellId))
                    caster = candidate;
                else if (pet && pet->IsAlive() && pet->HasSpell(spellId))
                    caster = pet;
                if (!caster || !caster->GetSpellHistory()->IsReady(spellId) ||
                    !caster->IsWithinLOSInMap(target))
                    continue;

                uint32 castTime = spellInfo->IsChanneled() ?
                    spellInfo->GetDuration() :
                    spellInfo->CalcCastTime(caster->GetLevel());
                // Damage pushback can make a cast-time interrupt arrive too
                // late. An attacked provider remains eligible for instant
                // Pummel/Kick/Rebuke/etc., but not for a cast-time answer.
                if (castTime > 0 && !caster->getAttackers().empty())
                    continue;

                float maxRange = caster->GetSpellMaxRangeForTarget(
                    target, spellInfo);
                if (maxRange <= 0.0f)
                    maxRange = 5.0f;
                if (!caster->IsWithinCombatRange(target, maxRange))
                    continue;
                if (!CanPrepareLfgInterrupt(caster, target, spellInfo))
                    continue;

                bool focused = candidate->GetVictim() == target ||
                    candidateAI->GetAiObjectContext()->
                        GetValue<Unit*>("current target")->Get() == target;
                uint32 cooldown = std::max(spellInfo->RecoveryTime,
                    spellInfo->CategoryRecoveryTime);
                auto rank = std::make_tuple(
                    uint8(stunFallback ? 1 : 0),
                    uint8(focused ? 0 : 1),
                    uint8(caster == candidate &&
                        IsCastingNonMeleeSpell(candidate) ? 1 : 0),
                    cooldown, GetInterruptRolePriority(candidate),
                    candidate->GetDistance(target),
                    candidate->GetGUID().GetCounter());

                if (!found || rank < best.rank)
                {
                    found = true;
                    best = { candidate, caster, spellId, action,
                             stunFallback, rank };
                }
                // Use this class's first ready interrupt. Its action order
                // keeps the normal short cooldown before longer silences.
                if (!stunFallback)
                {
                    candidateHasInterrupt = true;
                    break;
                }
                break;
            }
        }

        if (!found || best.player != bot)
            continue;

        bool success = false;
        if (best.caster == bot)
        {
            // Interrupts must pre-empt a long heal or damage cast. Spell::
            // cancel also removes the GCD started by that cancelled cast.
            InterruptSpell();
            success = CastSpell(best.spellId, target);
        }
        else if (Pet* pet = best.caster->ToPet())
        {
            pet->CastSpell(target, best.spellId, false);
            success = true;
        }

        if (success)
        {
            ReserveGroupPveInterrupt(target);
            Spell const* enemySpell = GetInterruptibleCurrentSpell(target);
            TC_LOG_INFO("server",
                "Managed PvE coordinated interrupt mode=%u bot=%s guid=%u role=%u action=%s spell=%u fallback=%s target=%s target-guid=%u enemy-spell=%u",
                uint32(GetActivityMode()),
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                uint32(GetInterruptRolePriority(bot)), best.action,
                best.spellId, best.stunFallback ? "stun" : "none",
                target->GetName().c_str(),
                target->GetGUID().GetCounter(),
                enemySpell ? enemySpell->GetSpellInfo()->Id : 0);
            return true;
        }
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

    // PvP displacement and control make dungeon trash scatter out of the
    // tank's control and may aggro neighbouring packs. Keep those tools for
    // PvP, but suppress them at the final cast boundary in PvE instances.
    // Also prevent non-tanks from taunting merely because an old class
    // strategy still contains a threat action.
    if (spellInfo && bot->GetMap() &&
        (bot->GetMap()->IsDungeon() || bot->GetMap()->IsRaid()) &&
        !bot->InBattleground() && !bot->InArena())
    {
        uint32 const scatterMechanics = (1u << MECHANIC_FEAR) |
            (1u << MECHANIC_TURN) |
            (1u << MECHANIC_HORROR) |
            (1u << MECHANIC_DISORIENTED);
        bool scattersTarget =
            (spellInfo->GetAllEffectsMechanicMask() & scatterMechanics) != 0;
        bool knocksTargetBack = false;
        bool tauntsTarget = false;
        for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
        {
            uint32 const aura = spellInfo->Effects[effect].ApplyAuraName;
            uint32 const spellEffect = spellInfo->Effects[effect].Effect;
            scattersTarget = scattersTarget || aura == SPELL_AURA_MOD_FEAR ||
                aura == SPELL_AURA_MOD_FEAR_2 || aura == SPELL_AURA_MOD_CONFUSE;
            knocksTargetBack = knocksTargetBack ||
                spellEffect == SPELL_EFFECT_KNOCK_BACK ||
                spellEffect == SPELL_EFFECT_KNOCK_BACK_DEST;
            tauntsTarget = tauntsTarget || spellEffect == SPELL_EFFECT_ATTACK_ME ||
                aura == SPELL_AURA_MOD_TAUNT;
        }

        bool const hostileTarget = target != bot && bot->IsValidAttackTarget(target);
        if (hostileTarget && (scattersTarget || knocksTargetBack ||
            (tauntsTarget && !PlayerBotSpec::IsTank(bot, true))))
            return false;
    }

    // Some rotations expose AoE as their default action instead of only
    // through an "aoe" strategy trigger. Enforce tank ownership at the final
    // cast boundary too, so those class-specific spells cannot open a pull.
    if (ShouldDelayGroupPveAoe(this, bot, target, spellInfo))
        return false;

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
