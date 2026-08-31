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

#include "RandomPlayerbotMgr.h"

#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <chrono>
#include <iomanip>
#include <map>
#include <random>
#include <set>
#include <sstream>

#include "AccountMgr.h"
#include "AiFactory.h"
#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "BotFactory.h"
#include "CharacterCache.h"
#include "CellImpl.h"
#include "ChannelMgr.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "DatabaseEnv.h"
#include "Define.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "GuildMgr.h"
#include "LFGMgr.h"
#include "MapManager.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "PerformanceMonitor.h"
#include "Playerbots.h"
#include "RandomItemManager.h"
#include "RandomPlayerbotBracketMgr.h"
#include "SharedDefines.h"
#include "Unit.h"
#include "World.h"

namespace
{
    struct LfgAutoQueueDemand
    {
        uint8 Team = 0;
        uint32 RequesterGuid = 0;
        lfg::LfgDungeonSet Dungeons;
        uint32 RandomDungeon = 0;
        std::set<uint32> BucketPlayers;
        uint32 NeededTanks = 0;
        uint32 NeededHealers = 0;
        uint32 NeededDamage = 0;
    };

    struct LfgAutoQueueStagedLogin
    {
        uint8 Team = 0;
        uint32 RequesterGuid = 0;
        lfg::LfgDungeonSet Dungeons;
        uint32 RandomDungeon = 0;
        lfg::LfgRoles Role = lfg::PLAYER_ROLE_NONE;
    };

    struct LfgAutoQueueManagedBot
    {
        uint32 RequesterGuid = 0;
        lfg::LfgRoles Role = lfg::PLAYER_ROLE_NONE;
        bool EnteredDungeon = false;
        bool PreparationBuffed = false;
        bool GroupLeadershipEnsured = false;
        bool CleanupRequested = false;
    };

    std::map<uint32, LfgAutoQueueStagedLogin> LfgAutoQueueStagedLogins;
    std::map<uint32, LfgAutoQueueManagedBot> LfgAutoQueueManagedBots;
    std::set<uint32> LfgAutoQueueIneligibleBots;

    lfg::LfgRoles GetLfgRole(Player* player)
    {
        if (!player)
            return lfg::PLAYER_ROLE_NONE;

        switch (AiFactory::GetPlayerRoles(player))
        {
            case BOT_ROLE_TANK:
                return lfg::PLAYER_ROLE_TANK;
            case BOT_ROLE_HEALER:
                return lfg::PLAYER_ROLE_HEALER;
            case BOT_ROLE_DPS:
                return lfg::PLAYER_ROLE_DAMAGE;
            default:
                return lfg::PLAYER_ROLE_NONE;
        }
    }

    lfg::LfgRoles GetLfgRole(Specializations specialization)
    {
        switch (specialization)
        {
            case SPEC_WARRIOR_PROTECTION:
            case SPEC_PALADIN_PROTECTION:
            case SPEC_DEATH_KNIGHT_BLOOD:
            case SPEC_DRUID_GUARDIAN:
            case SPEC_MONK_BREWMASTER:
                return lfg::PLAYER_ROLE_TANK;
            case SPEC_PALADIN_HOLY:
            case SPEC_DRUID_RESTORATION:
            case SPEC_PRIEST_DISCIPLINE:
            case SPEC_PRIEST_HOLY:
            case SPEC_SHAMAN_RESTORATION:
            case SPEC_MONK_MISTWEAVER:
                return lfg::PLAYER_ROLE_HEALER;
            case SPEC_NONE:
                return lfg::PLAYER_ROLE_NONE;
            default:
                return lfg::PLAYER_ROLE_DAMAGE;
        }
    }

    bool CanAutoQueueLfgBot(Player* bot, uint8 team,
                            std::string* rejectionReason = nullptr)
    {
        auto reject = [rejectionReason](char const* reason)
        {
            if (rejectionReason)
                *rejectionReason = reason;
            return false;
        };

        if (!bot)
            return reject("missing-player");
        if (IsSoloArenaAutomationBusy())
            return reject("solo-arena-automation-busy");
        if (IsSoloArenaManagedPlayer(bot->GetGUID().GetCounter()))
            return reject("solo-arena-managed");
        if (LfgAutoQueueManagedBots.count(bot->GetGUID().GetCounter()))
            return reject("already-lfg-managed");
        if (!bot->IsInWorld())
            return reject("not-in-world");
        if (uint8(bot->GetTeam()) != team)
            return reject("wrong-team");
        if (GetLfgRole(bot) == lfg::PLAYER_ROLE_NONE)
            return reject("unsupported-specialization");
        if (bot->GetGroup())
            return reject("already-grouped");
        if (bot->IsUsingLfg())
            return reject("already-using-lfg");
        if (bot->InBattleground() || bot->InBattlegroundQueue())
            return reject("using-pvp");
        if (bot->IsInCombat())
            return reject("in-combat");
        if (bot->IsInFlight())
            return reject("in-flight");
        if (!bot->GetMap() || bot->GetMap()->Instanceable())
            return reject("instance-map");

        if (rejectionReason)
            rejectionReason->clear();
        return true;
    }

    struct BgAutoQueueDemand
    {
        BattlegroundTypeId Type = BATTLEGROUND_TYPE_NONE;
        uint32 MapId = 0;
        BattlegroundBracketId Bracket = BG_BRACKET_ID_FIRST;
        uint32 RealPlayers[2] = { 0, 0 };
        uint32 BotPlayers[2] = { 0, 0 };
        uint32 Healers[2] = { 0, 0 };
        uint32 RequesterGuid[2] = { 0, 0 };
    };

    struct BgAutoQueueManagedBot
    {
        BattlegroundQueueTypeId QueueType = BATTLEGROUND_QUEUE_NONE;
        BattlegroundTypeId Type = BATTLEGROUND_TYPE_NONE;
        BattlegroundBracketId Bracket = BG_BRACKET_ID_FIRST;
        uint32 RequesterGuid = 0;
        bool Entered = false;
        bool LoadoutApplied = false;
        bool PreparationBuffed = false;
        bool StrategyInitialized = false;
    };

    struct BgAutoQueueStagedLogin
    {
        BattlegroundQueueTypeId QueueType = BATTLEGROUND_QUEUE_NONE;
        BattlegroundTypeId Type = BATTLEGROUND_TYPE_NONE;
        uint32 MapId = 0;
        BattlegroundBracketId Bracket = BG_BRACKET_ID_FIRST;
        TeamId Team = TEAM_NEUTRAL;
        uint32 RequesterGuid = 0;
        bool Healer = false;
    };

    std::map<uint32, BgAutoQueueManagedBot> BgAutoQueueManagedBots;
    std::map<uint32, BgAutoQueueStagedLogin> BgAutoQueueStagedLogins;
    // Do not repeatedly wake the same character after it failed the runtime
    // eligibility check. The set is intentionally process-local: a clean
    // restart retries the character after any transient state has cleared.
    std::set<uint32> BgAutoQueueIneligibleBots;

    bool IsBgHealerSpecialization(Specializations specialization)
    {
        switch (specialization)
        {
            case SPEC_PALADIN_HOLY:
            case SPEC_DRUID_RESTORATION:
            case SPEC_PRIEST_DISCIPLINE:
            case SPEC_PRIEST_HOLY:
            case SPEC_SHAMAN_RESTORATION:
            case SPEC_MONK_MISTWEAVER:
                return true;
            default:
                return false;
        }
    }

    bool CanAutoQueueBgBot(Player* bot, TeamId team, uint32 mapId,
                           BattlegroundBracketId bracket,
                           std::string* rejectionReason = nullptr)
    {
        auto reject = [rejectionReason](char const* reason)
        {
            if (rejectionReason)
                *rejectionReason = reason;
            return false;
        };

        if (!bot)
            return reject("missing-player");
        if (IsSoloArenaAutomationBusy())
            return reject("solo-arena-automation-busy");
        if (IsSoloArenaManagedPlayer(bot->GetGUID().GetCounter()))
            return reject("solo-arena-managed");
        if (BgAutoQueueManagedBots.count(bot->GetGUID().GetCounter()))
            return reject("already-bg-managed");
        if (!bot->IsInWorld())
            return reject("not-in-world");
        if (!HasAutomatedPvpBotLoadout(bot->GetSpecialization()))
            return reject("unsupported-specialization");
        if (bot->GetTeamId() != team)
            return reject("wrong-team");
        if (bot->GetGroup())
            return reject("already-grouped");
        if (bot->IsUsingLfg())
            return reject("using-lfg");
        if (bot->InBattleground())
            return reject("already-in-battleground");
        if (bot->InBattlegroundQueue())
            return reject("already-in-pvp-queue");
        if (bot->IsInCombat())
            return reject("in-combat");
        if (bot->IsInFlight())
            return reject("in-flight");
        if (!bot->GetMap() || bot->GetMap()->Instanceable())
            return reject("instance-map");

        PvPDifficultyEntry const* botBracket =
            GetBattlegroundBracketByLevel(mapId, bot->GetLevel());
        if (!botBracket || botBracket->GetBracketId() != bracket)
            return reject("wrong-level-bracket");

        if (rejectionReason)
            rejectionReason->clear();
        return true;
    }
}

RandomPlayerbotMgr::RandomPlayerbotMgr()
    : PlayerbotHolder(),
    _autoQueueElapsed(0),
    _processTicks(0)
{
    _playersLevel = 1;// sPlayerbotAIConfig->randombotStartingLevel;
    _playersCheckTimer = 0;
}

RandomPlayerbotMgr::~RandomPlayerbotMgr() {}

bool RandomPlayerbotMgr::IsLfgAutoQueueReserved(Player const* bot) const
{
    if (!bot)
        return false;

    uint32 guid = bot->GetGUID().GetCounter();
    if (LfgAutoQueueStagedLogins.count(guid))
        return true;

    auto managed = LfgAutoQueueManagedBots.find(guid);
    return managed != LfgAutoQueueManagedBots.end() &&
        (!bot->GetMap() || !bot->GetMap()->Instanceable());
}

bool RandomPlayerbotMgr::CanLfgAutoQueueBotEngage(
    Player const* bot, Unit const* target) const
{
    if (!bot)
        return false;

    auto managed = LfgAutoQueueManagedBots.find(bot->GetGUID().GetCounter());
    if (managed == LfgAutoQueueManagedBots.end())
        return LfgAutoQueueStagedLogins.count(bot->GetGUID().GetCounter()) == 0;

    Player* requester = ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(managed->second.RequesterGuid));
    if (!requester || !requester->IsInWorld())
        return false;

    // The real player owns the pull. Once the player has attacked or is being
    // attacked, normal tank/healer/DPS behavior is allowed for the whole
    // server-controlled party.
    if (requester->IsInCombat() || requester->GetVictim() ||
        requester->HasUnitState(UNIT_STATE_MELEE_ATTACKING) ||
        !requester->getAttackers().empty())
        return true;

    return target && target->GetVictim() == requester;
}

void RandomPlayerbotMgr::Reserve(const uint32 size)
{
    _currentBots.reserve(size);
}

uint32 RandomPlayerbotMgr::GetMaxAllowedBotCount()
{
    return GetEventValue(0, "bot_count");
}

void RandomPlayerbotMgr::ScheduleRandomize(uint32 bot, uint32 time)
{
    SetEventValue(bot, "randomize", 1, time);
}

void RandomPlayerbotMgr::ScheduleTeleport(uint32 bot, uint32 time)
{
    if (!time)
        time = 60 + urand(sPlayerbotAIConfig->randomBotUpdateInterval, sPlayerbotAIConfig->randomBotUpdateInterval * 3);

    SetEventValue(bot, "teleport", 1, time);
}

void RandomPlayerbotMgr::UpdateAIInternal(uint32 elapsed, bool /*minimal*/)
{
    if (totalPmo)
        totalPmo->finish();

    totalPmo = sPerformanceMonitor->start(PERF_MON_TOTAL, "RandomPlayerbotMgr::FullTick");

    UpdateAutoQueueObserver(elapsed);

    if (!sPlayerbotAIConfig->randomBotAutologin || !sPlayerbotAIConfig->enabled)
        return;

    uint32 maxAllowedBotCount = GetEventValue(0, "bot_count");
    if (!maxAllowedBotCount || (maxAllowedBotCount < sPlayerbotAIConfig->minRandomBots ||
        maxAllowedBotCount > sPlayerbotAIConfig->maxRandomBots))
    {
        maxAllowedBotCount = sPlayerbotAIConfig->minRandomBots + (std::rand() % (sPlayerbotAIConfig->maxRandomBots - sPlayerbotAIConfig->minRandomBots + 1));
        auto randomInterval = sPlayerbotAIConfig->randomBotCountChangeMinInterval +
            (std::rand() % (sPlayerbotAIConfig->randomBotCountChangeMaxInterval - sPlayerbotAIConfig->randomBotCountChangeMinInterval + 1));
        SetEventValue(0, "bot_count", maxAllowedBotCount, randomInterval);
    }

    GetBots();
    std::vector<uint32> availableBots = _currentBots;
    uint32 availableBotCount = _currentBots.size();
    uint32 onlineBotCount = playerBots.size();

    uint32 onlineBotFocus = 75;
    if (onlineBotCount < (uint32)(sPlayerbotAIConfig->minRandomBots * 90 / 100))
        onlineBotFocus = 25;

    // only keep updating till initializing time has completed,
    // which prevents unneeded expensive GameTime calls.
    if (_isBotInitializing)
    {
        _isBotInitializing = sWorld->GetUptime() < sPlayerbotAIConfig->maxRandomBots * (0.11 + 0.4);
    }

    uint32 updateIntervalTurboBoost = _isBotInitializing ? 1 : sPlayerbotAIConfig->randomBotUpdateInterval;
    SetNextCheckDelay(updateIntervalTurboBoost * (onlineBotFocus + 25) * 10);

    PerformanceMonitorOperation* pmo = sPerformanceMonitor->start(
            PERF_MON_TOTAL,
            onlineBotCount < maxAllowedBotCount ? "RandomPlayerbotMgr::Login" : "RandomPlayerbotMgr::UpdateAIInternal");

    if (availableBotCount < maxAllowedBotCount)
    {
        AddRandomBots();
    }

    uint32 updateBots = sPlayerbotAIConfig->randomBotsPerInterval * onlineBotFocus / 100;
    uint32 maxNewBots = onlineBotCount < maxAllowedBotCount ? maxAllowedBotCount - onlineBotCount : 0;
    uint32 loginBots = std::min(sPlayerbotAIConfig->randomBotsPerInterval - updateBots, maxNewBots);

    if (!availableBots.empty())
    {
        // Update bots
        for (auto bot : availableBots)
        {
            if (!GetPlayerBot(bot))
                continue;

            if (ProcessBot(bot))
            {
                updateBots--;
            }

            if (!updateBots)
                break;
        }

        if (loginBots && botLoading.empty())
        {
            loginBots += updateBots;
            loginBots = std::min(loginBots, maxNewBots);

            TC_LOG_INFO("playerbots", "%d new bots", loginBots);

            // Log in bots
            for (auto bot : availableBots)
            {
                if (GetPlayerBot(bot))
                    continue;

                if (ProcessBot(bot))
                {
                    loginBots--;
                }

                if (!loginBots)
                    break;
            }
        }
    }

    if (pmo)
        pmo->finish();
}

void RandomPlayerbotMgr::UpdateAutoQueueObserver(uint32 elapsed)
{
    if (!sPlayerbotAIConfig->autoQueueEnabled)
        return;

    _autoQueueElapsed += elapsed;
    if (_autoQueueElapsed < sPlayerbotAIConfig->autoQueueCheckInterval)
        return;

    _autoQueueElapsed = 0;

    uint32 realLfg = 0;
    uint32 botLfg = 0;
    // One demand record per real requester.  Several real players may queue
    // for the same dungeon at once but still belong to different matchmaking
    // buckets; merging them by team+dungeon would fill the wrong party.
    std::map<uint32, LfgAutoQueueDemand> lfgDemands;
    if (sPlayerbotAIConfig->autoQueueLfg)
    {
        for (auto const& managerPair : sLFGMgr->GetQueueManagers())
        {
            for (auto const& queuePair : managerPair.second.GetQueuerData())
            {
                bool hasRealPlayer = false;
                bool hasRandomBot = false;
                for (ObjectGuid const& guid : queuePair.second.Players)
                {
                    Player* player = ObjectAccessor::FindConnectedPlayer(guid);
                    if (!player)
                        continue;

                    // Bots explicitly logged in for this request are owned by
                    // PlayerbotHolder but do not necessarily carry the older
                    // persistent random-bot event. Treat every holder-owned or
                    // lifecycle-owned character as a bot, otherwise fillers
                    // become new "real" requesters and recursively create more
                    // demand (the same class of bug previously fixed for BG).
                    uint32 lowGuid = guid.GetCounter();
                    if (IsRandomBot(player) || GetPlayerBot(guid) ||
                        LfgAutoQueueStagedLogins.count(lowGuid) ||
                        LfgAutoQueueManagedBots.count(lowGuid))
                        hasRandomBot = true;
                    else
                        hasRealPlayer = true;
                }

                if (hasRealPlayer)
                {
                    ++realLfg;
                    if (!queuePair.second.Dungeons.empty())
                    {
                        uint32 requesterGuid = 0;
                        for (ObjectGuid const& playerGuid : queuePair.second.Players)
                        {
                            Player* queued = ObjectAccessor::FindConnectedPlayer(playerGuid);
                            if (queued && !GetPlayerBot(playerGuid))
                            {
                                requesterGuid = playerGuid.GetCounter();
                                break;
                            }
                        }

                        if (requesterGuid)
                        {
                            uint32 dungeonId = *queuePair.second.Dungeons.begin();
                            lfg::DungeonQueue const& dungeonQueue =
                                managerPair.second.GetQueue(dungeonId);
                            lfg::Queuer queuer(queuePair.second.GUID,
                                queuePair.second.QueueId);

                            for (lfg::Bucket const& bucket : dungeonQueue.GetBuckets())
                            {
                                if (!bucket.Contains(queuer))
                                    continue;

                                LfgAutoQueueDemand& demand = lfgDemands[requesterGuid];
                                demand.Team = managerPair.first;
                                demand.RequesterGuid = requesterGuid;
                                demand.Dungeons = queuePair.second.Dungeons;
                                demand.RandomDungeon = sLFGMgr->GetRandomDungeon(
                                    ObjectGuid::Create<HighGuid::Player>(requesterGuid),
                                    queuePair.second.QueueId);
                                demand.BucketPlayers.clear();
                                for (lfg::Queuer const& bucketQueuer :
                                     bucket.GetQueuers())
                                {
                                    if (bucketQueuer.IsPlayer())
                                        demand.BucketPlayers.insert(
                                            bucketQueuer.GetGUID().GetCounter());
                                    else
                                        for (ObjectGuid const& member :
                                             bucketQueuer.GetGroupPlayers())
                                            demand.BucketPlayers.insert(
                                                member.GetCounter());
                                }
                                demand.NeededTanks = bucket.GetRemainingSlots(
                                    lfg::PLAYER_ROLE_TANK);
                                demand.NeededHealers = bucket.GetRemainingSlots(
                                    lfg::PLAYER_ROLE_HEALER);
                                demand.NeededDamage = bucket.GetRemainingSlots(
                                    lfg::PLAYER_ROLE_DAMAGE);
                                break;
                            }
                        }
                    }
                }
                if (hasRandomBot)
                    ++botLfg;
            }
        }
    }

    // A staged login already reserves one of the requester's missing role
    // slots. Native LFG does not see that character until login completes, so
    // subtract these reservations now to prevent duplicate staging on the
    // following five-second observer tick.
    for (auto const& stagedPair : LfgAutoQueueStagedLogins)
    {
        LfgAutoQueueStagedLogin const& staged = stagedPair.second;
        if (staged.Dungeons.empty())
            continue;
        auto demandItr = lfgDemands.find(staged.RequesterGuid);
        if (demandItr == lfgDemands.end() ||
            demandItr->second.RequesterGuid != staged.RequesterGuid)
            continue;

        uint32* needed = nullptr;
        if (staged.Role == lfg::PLAYER_ROLE_TANK)
            needed = &demandItr->second.NeededTanks;
        else if (staged.Role == lfg::PLAYER_ROLE_HEALER)
            needed = &demandItr->second.NeededHealers;
        else if (staged.Role == lfg::PLAYER_ROLE_DAMAGE)
            needed = &demandItr->second.NeededDamage;
        if (needed && *needed)
            --*needed;
    }

    // Once a complete bucket becomes an LFG proposal, native matchmaking
    // temporarily removes all of its queuers from the dungeon buckets. The
    // real requester can immediately appear alone again even though this
    // lifecycle still owns the exact healer/DPS fillers waiting in that
    // proposal. Reserve only managed bots which are absent from the current
    // requester bucket; bots still present there are already reflected in the
    // bucket's remaining-slot counts.
    for (auto const& managedPair : LfgAutoQueueManagedBots)
    {
        LfgAutoQueueManagedBot const& managed = managedPair.second;
        auto demandItr = lfgDemands.find(managed.RequesterGuid);
        if (demandItr == lfgDemands.end() ||
            demandItr->second.BucketPlayers.count(managedPair.first))
            continue;

        uint32* needed = nullptr;
        if (managed.Role == lfg::PLAYER_ROLE_TANK)
            needed = &demandItr->second.NeededTanks;
        else if (managed.Role == lfg::PLAYER_ROLE_HEALER)
            needed = &demandItr->second.NeededHealers;
        else if (managed.Role == lfg::PLAYER_ROLE_DAMAGE)
            needed = &demandItr->second.NeededDamage;
        if (needed && *needed)
            --*needed;
    }

    uint32 lfgBotsStaged = 0;
    uint32 lfgBotsJoined = 0;
    uint32 lfgProposalsAccepted = 0;
    if (sPlayerbotAIConfig->autoQueueLfg &&
        sPlayerbotAIConfig->autoQueueLfgAutomatic)
    {
        // Finish only the logins that were explicitly requested by a real LFG
        // queue. Bots retain their existing PvE equipment; the PvP loadout
        // journal is deliberately not used by this path.
        for (auto itr = LfgAutoQueueStagedLogins.begin();
             itr != LfgAutoQueueStagedLogins.end();)
        {
            uint32 botGuid = itr->first;
            LfgAutoQueueStagedLogin const staged = itr->second;
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(botGuid);
            Player* requester = ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(staged.RequesterGuid));
            Player* bot = GetPlayerBot(guid);
            bool requesterActive = requester && requester->IsInWorld() &&
                requester->IsUsingLfg();

            if (!requesterActive)
            {
                if (bot && !bot->IsUsingLfg() && !bot->GetGroup() &&
                    !bot->GetMap()->Instanceable())
                    LogoutPlayerBot(guid);
                if (IsBotLoading(guid))
                {
                    ++itr;
                    continue;
                }
                TC_LOG_INFO("server",
                    "AutoQueue LFG canceled staged login guid=%u requester=%u",
                    botGuid, staged.RequesterGuid);
                itr = LfgAutoQueueStagedLogins.erase(itr);
                continue;
            }

            if (!bot || !bot->IsInWorld() || IsBotLoading(guid) ||
                bot->IsBeingTeleported())
            {
                ++itr;
                continue;
            }

            std::string rejectionReason;
            if (!CanAutoQueueLfgBot(bot, staged.Team, &rejectionReason) ||
                GetLfgRole(bot) != staged.Role)
            {
                // A bot loaded specifically for LFG may resume an old taxi or
                // let its normal open-world AI acquire an NPC before this
                // observer sees it. Neither state makes the character an
                // invalid dungeon filler. Stop it locally and validate all
                // eligibility rules again.
                if (rejectionReason == "in-combat")
                {
                    bot->CombatStopWithPets(true);
                    bot->AttackStop();
                    bot->SetTarget(ObjectGuid::Empty);
                    rejectionReason.clear();
                    CanAutoQueueLfgBot(bot, staged.Team, &rejectionReason);
                }
                else if (rejectionReason == "in-flight")
                {
                    bot->GetMotionMaster()->MovementExpired();
                    bot->CleanupAfterTaxiFlight();
                    rejectionReason.clear();
                    CanAutoQueueLfgBot(bot, staged.Team, &rejectionReason);
                }

                if (!rejectionReason.empty() || GetLfgRole(bot) != staged.Role)
                {
                    // Combat/flight can be re-applied by the world during the
                    // same update. Keep this reserved candidate passive and
                    // retry next tick instead of blacklisting it.
                    if (rejectionReason == "in-combat" ||
                        rejectionReason == "in-flight")
                    {
                        ++itr;
                        continue;
                    }

                    LfgAutoQueueIneligibleBots.insert(botGuid);
                    TC_LOG_ERROR("server",
                        "AutoQueue LFG staged bot ineligible name=%s guid=%u role=%u reason=%s",
                        bot->GetName().c_str(), botGuid, uint32(staged.Role),
                        rejectionReason.empty() ? "wrong-role" : rejectionReason.c_str());
                    if (!bot->IsUsingLfg() && !bot->GetGroup())
                        LogoutPlayerBot(guid);
                    itr = LfgAutoQueueStagedLogins.erase(itr);
                    continue;
                }

                TC_LOG_INFO("server",
                    "AutoQueue LFG cleared transient open-world state name=%s guid=%u role=%u",
                    bot->GetName().c_str(), botGuid, uint32(staged.Role));
            }

            if (!bot->IsAlive())
            {
                Revive(bot);
                bot->SetHealth(bot->GetMaxHealth());
            }

            // A character row having a valid specialization does not imply a
            // usable dungeon build. Fill missing equipment, repair pieces
            // which do not match the active specialization, and initialize
            // talents, glyphs and pets before exposing the bot to native LFG.
            BotFactory factory(bot, bot->GetLevel());
            factory.InitEquipmentForSpec();
            factory.InitTalentsTree(false);
            factory.InitGlyphs();
            factory.InitPet();

            Item* mainHand = bot->GetItemByPos(
                INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
            uint32 glyphCount = 0;
            for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
                if (bot->GetGlyph(bot->GetActiveSpec(), slot))
                    ++glyphCount;

            uint32 expectedTalents = std::min<uint32>(6,
                bot->GetLevel() / 15);
            uint32 expectedGlyphs = bot->GetLevel() >= 75 ? 6 :
                (bot->GetLevel() >= 50 ? 4 :
                    (bot->GetLevel() >= 25 ? 2 : 0));
            std::string equipmentFailure;
            char const* buildFailure = !factory.HasRequiredWeaponSetForSpec(
                    &equipmentFailure) ? equipmentFailure.c_str() :
                (bot->GetUsedTalentCount() < expectedTalents ?
                    "incomplete-talents" :
                    (glyphCount < expectedGlyphs ?
                        "incomplete-glyphs" : nullptr));
            if (buildFailure)
            {
                LfgAutoQueueIneligibleBots.insert(botGuid);
                TC_LOG_ERROR("server",
                    "AutoQueue LFG build rejected name=%s guid=%u role=%u reason=%s talents=%u/%u glyphs=%u/%u",
                    bot->GetName().c_str(), botGuid, uint32(staged.Role),
                    buildFailure, bot->GetUsedTalentCount(), expectedTalents,
                    glyphCount, expectedGlyphs);
                LogoutPlayerBot(guid);
                itr = LfgAutoQueueStagedLogins.erase(itr);
                continue;
            }

            TC_LOG_INFO("server",
                "AutoQueue LFG PvE build ready name=%s guid=%u role=%u specialization=%u main-hand=%u off-hand=%u talents=%u glyphs=%u pet=%u",
                bot->GetName().c_str(), botGuid, uint32(staged.Role),
                uint32(bot->GetSpecialization()), mainHand->GetEntry(),
                bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
                    EQUIPMENT_SLOT_OFFHAND) ?
                    bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
                        EQUIPMENT_SLOT_OFFHAND)->GetEntry() : 0,
                bot->GetUsedTalentCount(), glyphCount,
                bot->GetGuardianPet() ? bot->GetGuardianPet()->GetEntry() : 0);

            lfg::LfgDungeonSet dungeons = staged.Dungeons;
            // Preserve the requester's original random-dungeon category for
            // the bot's client/LFG state. JoinLfg expands it internally for
            // compatibility matching, just as it did for the real requester.
            if (staged.RandomDungeon)
            {
                dungeons.clear();
                dungeons.insert(staged.RandomDungeon);
            }
            // Register before JoinLfg: adding the final required role can
            // create a proposal synchronously.
            sLFGMgr->SetProposalAutoAccept(bot->GetGUID(), true);
            sLFGMgr->JoinLfg(bot, staged.Role, dungeons,
                "request-driven playerbot LFG fill");
            if (!bot->IsUsingLfg())
            {
                sLFGMgr->SetProposalAutoAccept(bot->GetGUID(), false);
                LfgAutoQueueIneligibleBots.insert(botGuid);
                TC_LOG_ERROR("server",
                    "AutoQueue LFG join refused name=%s guid=%u role=%u requester=%u",
                    bot->GetName().c_str(), botGuid, uint32(staged.Role),
                    staged.RequesterGuid);
                LogoutPlayerBot(guid);
                itr = LfgAutoQueueStagedLogins.erase(itr);
                continue;
            }

            LfgAutoQueueManagedBots[botGuid] =
                { staged.RequesterGuid, staged.Role, false, false, false,
                  false };
            ++lfgBotsJoined;
            TC_LOG_INFO("server",
                "AutoQueue LFG joined staged bot name=%s guid=%u role=%u requester=%u compatible-dungeons=%u random-dungeon=%u",
                bot->GetName().c_str(), botGuid, uint32(staged.Role),
                staged.RequesterGuid, uint32(dungeons.size()),
                staged.RandomDungeon);
            itr = LfgAutoQueueStagedLogins.erase(itr);
        }

        // A real client answers its own proposal. Server-controlled bots have
        // no client packet, therefore accept only proposals for bots owned by
        // this request-driven lifecycle.
        for (auto& managedPair : LfgAutoQueueManagedBots)
        {
            ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(
                managedPair.first);
            Player* bot = GetPlayerBot(botGuid);

            // Proposal acceptance is GUID-based and does not require the bot
            // to be in the world at this exact instant. A headless bot can be
            // between maps while the proposal is created; gating acceptance
            // on IsInWorld made the proposal stall and eventually time out.
            if (sLFGMgr->AnswerProposalForPlayer(botGuid, true))
            {
                ++lfgProposalsAccepted;
                TC_LOG_INFO("server",
                    "AutoQueue LFG accepted proposal bot=%s guid=%u role=%u",
                    bot ? bot->GetName().c_str() : "<loading>",
                    managedPair.first,
                    uint32(managedPair.second.Role));
            }

            if (!bot || !bot->IsInWorld())
                continue;

            if (bot->GetMap() && bot->GetMap()->Instanceable())
            {
                managedPair.second.EnteredDungeon = true;
                if (!bot->IsAlive())
                {
                    Revive(bot);
                    bot->SetHealth(bot->GetMaxHealth());
                }

                // Native matchmaking may randomly choose any solo queuer as
                // leader.  For a request-driven bot party the real requester
                // must remain the navigation master; otherwise all fillers can
                // follow an arbitrary bot and leave the player behind.
                if (!managedPair.second.GroupLeadershipEnsured)
                {
                    Player* requester = ObjectAccessor::FindConnectedPlayer(
                        ObjectGuid::Create<HighGuid::Player>(
                            managedPair.second.RequesterGuid));
                    Group* group = bot->GetGroup(GroupSlot::Instance);
                    if (!group)
                        group = bot->GetGroup();
                    Group* requesterGroup = nullptr;
                    if (requester)
                    {
                        requesterGroup = requester->GetGroup(GroupSlot::Instance);
                        if (!requesterGroup)
                            requesterGroup = requester->GetGroup();
                    }
                    if (requester && group && requesterGroup == group)
                    {
                        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                        {
                            botAI->SetMaster(requester);
                            // Do not carry an open-world target or pending
                            // cast across the LFG teleport.
                            botAI->Reset(false);
                            botAI->ResetStrategies();
                            // Native LFG group creation does not emit the
                            // normal playerbot invitation action which usually
                            // enables follow. Make the dungeon navigation
                            // contract explicit for every LFG filler.
                            botAI->ChangeStrategy(
                                "+follow,-stay,-lfg,-bg",
                                BOT_STATE_NON_COMBAT);
                        }
                        if (group->GetLeaderGUID() != requester->GetGUID())
                            group->ChangeLeader(requester->GetGUID());
                        managedPair.second.GroupLeadershipEnsured =
                            group->GetLeaderGUID() == requester->GetGUID();
                        if (managedPair.second.GroupLeadershipEnsured)
                            TC_LOG_INFO("server",
                                "AutoQueue LFG real requester is group leader requester=%s guid=%u group=%u",
                                requester->GetName().c_str(),
                                managedPair.second.RequesterGuid,
                                group->GetGUID().GetCounter());
                    }
                }

                // Use only real class-supported party buffs. DoSpecificAction
                // first checks whether the aura is useful, so duplicate class
                // auras are not blindly recast. Revisit on later ticks until a
                // cast succeeds, which covers teleport/GCD timing.
                if (!managedPair.second.PreparationBuffed &&
                    CastAutomatedPvpPreparationBuff(bot))
                {
                    managedPair.second.PreparationBuffed = true;
                    TC_LOG_INFO("server",
                        "AutoQueue LFG preparation buff cast bot=%s guid=%u role=%u map=%u",
                        bot->GetName().c_str(), managedPair.first,
                        uint32(managedPair.second.Role), bot->GetMapId());
                }
            }
        }

        // Release only bots owned by this automation after the native LFG
        // lifecycle has fully ended. Never tear down an active dungeon group,
        // an active queue/proposal or a teleport in progress.
        for (auto itr = LfgAutoQueueManagedBots.begin();
             itr != LfgAutoQueueManagedBots.end();)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(itr->first);
            Player* bot = GetPlayerBot(guid);
            Player* requester = ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(itr->second.RequesterGuid));
            Group* botGroup = bot ? bot->GetGroup(GroupSlot::Instance) : nullptr;
            if (bot && !botGroup)
                botGroup = bot->GetGroup();
            Group* requesterGroup = requester ?
                requester->GetGroup(GroupSlot::Instance) : nullptr;
            if (requester && !requesterGroup)
                requesterGroup = requester->GetGroup();
            bool requesterSharesGroup = botGroup &&
                requesterGroup == botGroup;
            bool requesterActive = requester &&
                (requester->IsUsingLfg() || requester->GetGroup() ||
                 requester->IsBeingTeleported() ||
                 (requester->IsInWorld() && requester->GetMap() &&
                  requester->GetMap()->Instanceable()));

            if (!bot)
            {
                if (!IsBotLoading(guid))
                {
                    sLFGMgr->SetProposalAutoAccept(guid, false);
                    itr = LfgAutoQueueManagedBots.erase(itr);
                }
                else
                    ++itr;
                continue;
            }

            // Leaving an LFG instance removes only the real requester from the
            // native group. The four headless fillers would otherwise remain
            // in the dungeon indefinitely and receive a continue offer which
            // they cannot answer. Once an entered filler no longer shares the
            // requester's group, unwind that filler through the native LFG
            // leave path, wait for its return teleport, then log it out.
            if (itr->second.EnteredDungeon && !requesterSharesGroup &&
                !itr->second.CleanupRequested)
            {
                itr->second.CleanupRequested = true;
                TC_LOG_INFO("server",
                    "AutoQueue LFG cleanup requested bot=%s guid=%u requester=%u requester-online=%u",
                    bot->GetName().c_str(), itr->first,
                    itr->second.RequesterGuid, requester ? 1u : 0u);
            }

            if (itr->second.CleanupRequested)
            {
                if (!bot->IsInWorld() || bot->IsBeingTeleported() ||
                    IsBotLoading(guid))
                {
                    ++itr;
                    continue;
                }

                if (!bot->IsAlive())
                {
                    Revive(bot);
                    bot->SetHealth(bot->GetMaxHealth());
                }

                botGroup = bot->GetGroup(GroupSlot::Instance);
                if (!botGroup)
                    botGroup = bot->GetGroup();
                if (botGroup)
                {
                    TC_LOG_INFO("server",
                        "AutoQueue LFG removing filler from instance group bot=%s guid=%u group=%u",
                        bot->GetName().c_str(), itr->first,
                        botGroup->GetGUID().GetCounter());
                    Player::RemoveFromGroup(botGroup, bot->GetGUID(),
                        GROUP_REMOVEMETHOD_LEAVE);
                    ++itr;
                    continue;
                }

                if (bot->GetMap() && bot->GetMap()->Instanceable())
                {
                    if (bot->TeleportToBGEntryPoint())
                    {
                        TC_LOG_INFO("server",
                            "AutoQueue LFG returning filler to entry point bot=%s guid=%u map=%u",
                            bot->GetName().c_str(), itr->first,
                            bot->GetMapId());
                        ++itr;
                        continue;
                    }

                    // A missing entry point must not strand an ownerless bot
                    // in a dungeon forever. Persist its current safe state and
                    // let the normal login/homebind validation recover it.
                    TC_LOG_ERROR("server",
                        "AutoQueue LFG filler has no return entry point; logging out bot=%s guid=%u map=%u",
                        bot->GetName().c_str(), itr->first,
                        bot->GetMapId());
                }

                if (bot->IsUsingLfg())
                    sLFGMgr->RemovePlayerQueues(bot->GetGUID());
                sLFGMgr->SetProposalAutoAccept(bot->GetGUID(), false);
                TC_LOG_INFO("server",
                    "AutoQueue LFG cleanup complete bot=%s guid=%u requester=%u",
                    bot->GetName().c_str(), itr->first,
                    itr->second.RequesterGuid);
                LogoutPlayerBot(guid);
                itr = LfgAutoQueueManagedBots.erase(itr);
                continue;
            }

            // TeleportPlayer temporarily removes a playerbot from the world.
            // Keep ownership across that transition so the following observer
            // tick can assign the real requester as master and enable follow.
            if (!bot->IsInWorld())
            {
                if (requesterActive || bot->IsUsingLfg() || bot->GetGroup() ||
                    bot->IsBeingTeleported() || IsBotLoading(guid))
                    ++itr;
                else
                {
                    sLFGMgr->SetProposalAutoAccept(guid, false);
                    itr = LfgAutoQueueManagedBots.erase(itr);
                }
                continue;
            }

            bool botActive = bot->IsUsingLfg() || bot->GetGroup() ||
                bot->IsBeingTeleported() ||
                (bot->GetMap() && bot->GetMap()->Instanceable());

            // If the real requester abandons the queue before a proposal or a
            // dungeon group exists, a server-controlled filler has no client
            // which can press Leave Queue.  Remove only this automation-owned
            // bot's native LFG queue entries.  Never do this after it joined a
            // group, started teleporting, or entered an instance.
            if (!requesterActive && bot->IsUsingLfg() && !bot->GetGroup() &&
                !bot->IsBeingTeleported() &&
                (!bot->GetMap() || !bot->GetMap()->Instanceable()))
            {
                sLFGMgr->RemovePlayerQueues(bot->GetGUID());
                botActive = bot->IsUsingLfg();
                TC_LOG_INFO("server",
                    "AutoQueue LFG removed abandoned bot queue name=%s guid=%u requester=%u",
                    bot->GetName().c_str(), itr->first,
                    itr->second.RequesterGuid);
            }

            if (!requesterActive && !botActive)
            {
                if (!bot->IsAlive())
                {
                    Revive(bot);
                    bot->SetHealth(bot->GetMaxHealth());
                }
                TC_LOG_INFO("server",
                    "AutoQueue LFG lifecycle complete bot=%s guid=%u requester=%u entered=%u",
                    bot->GetName().c_str(), itr->first,
                    itr->second.RequesterGuid,
                    itr->second.EnteredDungeon ? 1u : 0u);
                sLFGMgr->SetProposalAutoAccept(bot->GetGUID(), false);
                LogoutPlayerBot(guid);
                itr = LfgAutoQueueManagedBots.erase(itr);
                continue;
            }

            ++itr;
        }

        // Stage exactly the roles that the native dungeon queue reports as
        // missing. This supports normal 1/1/3 dungeons as well as LFR queue
        // definitions without hard-coding a group size.
        for (auto& demandPair : lfgDemands)
        {
            LfgAutoQueueDemand& demand = demandPair.second;
            Player* requester = demand.RequesterGuid ?
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(demand.RequesterGuid)) : nullptr;
            if (!requester || !requester->IsUsingLfg() ||
                sPlayerbotAIConfig->randomBotAccounts.empty())
                continue;

            auto stageRole = [&](lfg::LfgRoles role, uint32& needed)
            {
                while (needed && lfgBotsStaged <
                    sPlayerbotAIConfig->autoQueueMaxBotsPerCycle)
                {
                    uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
                    uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
                    QueryResult candidates = CharacterDatabase.PQuery(
                        "SELECT guid,name,race,class,talentTree,activespec "
                        "FROM characters WHERE account >= %u AND account <= %u "
                        "AND level=%u AND online=0 AND instance_id=0 "
                        "AND guid NOT IN (SELECT guid FROM guild_member) "
                        "AND guid NOT IN (SELECT memberGuid FROM group_member) "
                        "AND guid NOT IN (SELECT owner_guid FROM solo_arena_loadout_backup) "
                        "ORDER BY RAND()",
                        minAccount, maxAccount, requester->GetLevel());
                    if (!candidates)
                        break;

                    uint32 selectedGuid = 0;
                    std::string selectedName;
                    do
                    {
                        Field* fields = candidates->Fetch();
                        uint32 candidateGuid = fields[0].GetUInt32();
                        ObjectGuid candidateObjectGuid =
                            ObjectGuid::Create<HighGuid::Player>(candidateGuid);
                        uint8 race = fields[2].GetUInt8();
                        if (uint8(Player::TeamForRace(race)) != demand.Team ||
                            LfgAutoQueueIneligibleBots.count(candidateGuid) ||
                            LfgAutoQueueStagedLogins.count(candidateGuid) ||
                            LfgAutoQueueManagedBots.count(candidateGuid) ||
                            BgAutoQueueStagedLogins.count(candidateGuid) ||
                            BgAutoQueueManagedBots.count(candidateGuid) ||
                            ObjectAccessor::FindPlayer(candidateObjectGuid) ||
                            GetPlayerBot(candidateObjectGuid) || IsBotLoading(candidateObjectGuid))
                            continue;

                        uint32 specs[MAX_TALENT_SPECS] = { 0, 0 };
                        std::istringstream talentTrees(fields[4].GetString());
                        for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
                            talentTrees >> specs[spec];
                        uint8 activeSpec = fields[5].GetUInt8();
                        if (activeSpec >= MAX_TALENT_SPECS)
                            activeSpec = 0;
                        if (GetLfgRole(Specializations(specs[activeSpec])) != role)
                            continue;

                        selectedGuid = candidateGuid;
                        selectedName = fields[1].GetString();
                        break;
                    }
                    while (candidates->NextRow());

                    if (!selectedGuid)
                        break;

                    ObjectGuid selectedObjectGuid =
                        ObjectGuid::Create<HighGuid::Player>(selectedGuid);
                    LfgAutoQueueStagedLogins[selectedGuid] =
                        { demand.Team, demand.RequesterGuid, demand.Dungeons,
                          demand.RandomDungeon, role };
                    AddPlayerBot(selectedObjectGuid, 0);
                    --needed;
                    ++lfgBotsStaged;
                    TC_LOG_INFO("server",
                        "AutoQueue LFG staged login name=%s guid=%u role=%u requester=%u dungeons=%u",
                        selectedName.c_str(), selectedGuid, uint32(role),
                        demand.RequesterGuid, uint32(demand.Dungeons.size()));
                }
            };

            stageRole(lfg::PLAYER_ROLE_TANK, demand.NeededTanks);
            stageRole(lfg::PLAYER_ROLE_HEALER, demand.NeededHealers);
            stageRole(lfg::PLAYER_ROLE_DAMAGE, demand.NeededDamage);
        }
    }

    uint32 realBg = 0;
    uint32 realArena = 0;
    uint32 botBg = 0;
    uint32 botArena = 0;
    std::map<std::pair<BattlegroundQueueTypeId, BattlegroundBracketId>,
        BgAutoQueueDemand> bgDemands;
    auto countPvpQueues = [](Player* player, uint32& bgCount, uint32& arenaCount)
    {
        if (!player || !player->IsInWorld())
            return;

        for (uint8 slot = 0; slot < PLAYER_MAX_BATTLEGROUND_QUEUES; ++slot)
        {
            BattlegroundQueueTypeId queueType = player->GetBattlegroundQueueTypeId(slot);
            if (queueType == BATTLEGROUND_QUEUE_NONE)
                continue;

            if (BattlegroundMgr::BGArenaType(queueType))
                ++arenaCount;
            else
                ++bgCount;
        }
    };

    if (sPlayerbotAIConfig->autoQueueBattleground || sPlayerbotAIConfig->autoQueueArena)
    {
        for (Player* player : _players)
        {
            if (!player || !player->IsInWorld())
                continue;

            uint32 playerGuid = player->GetGUID().GetCounter();
            // Request-driven bots are intentionally logged in through the
            // normal playerbot holder and may also appear in _players. Never
            // count them as real requesters or the observer starts building a
            // bot-only queue after the actual player has left.
            if (GetPlayerBot(player->GetGUID()) ||
                BgAutoQueueManagedBots.count(playerGuid) ||
                BgAutoQueueStagedLogins.count(playerGuid))
                continue;

            countPvpQueues(player, realBg, realArena);
            for (uint8 slot = 0; slot < PLAYER_MAX_BATTLEGROUND_QUEUES; ++slot)
            {
                BattlegroundQueueTypeId queueType = player->GetBattlegroundQueueTypeId(slot);
                if (queueType == BATTLEGROUND_QUEUE_NONE ||
                    BattlegroundMgr::BGArenaType(queueType))
                    continue;

                BattlegroundTypeId bgType = BattlegroundMgr::BGTemplateId(queueType);
                Battleground* bg = sBattlegroundMgr->GetBattlegroundTemplate(bgType);
                PvPDifficultyEntry const* bracket = bg ?
                    GetBattlegroundBracketByLevel(bg->GetMapId(), player->GetLevel()) : nullptr;
                if (!bg || !bracket || player->GetTeamId() > TEAM_HORDE)
                    continue;

                BgAutoQueueDemand& demand = bgDemands[{ queueType, bracket->GetBracketId() }];
                demand.Type = bgType;
                demand.MapId = bg->GetMapId();
                demand.Bracket = bracket->GetBracketId();
                ++demand.RealPlayers[player->GetTeamId()];
                if (PlayerBotSpec::IsHeal(player, true))
                    ++demand.Healers[player->GetTeamId()];
                if (!demand.RequesterGuid[player->GetTeamId()])
                    demand.RequesterGuid[player->GetTeamId()] =
                        player->GetGUID().GetCounter();
            }
        }

        for (auto const& botPair : playerBots)
        {
            Player* bot = botPair.second;
            if (bot && (IsRandomBot(bot) ||
                BgAutoQueueManagedBots.count(bot->GetGUID().GetCounter())))
            {
                countPvpQueues(bot, botBg, botArena);

                for (uint8 slot = 0; slot < PLAYER_MAX_BATTLEGROUND_QUEUES; ++slot)
                {
                    BattlegroundQueueTypeId queueType = bot->GetBattlegroundQueueTypeId(slot);
                    if (queueType == BATTLEGROUND_QUEUE_NONE ||
                        BattlegroundMgr::BGArenaType(queueType))
                        continue;

                    BattlegroundTypeId bgType = BattlegroundMgr::BGTemplateId(queueType);
                    Battleground* bg = sBattlegroundMgr->GetBattlegroundTemplate(bgType);
                    PvPDifficultyEntry const* bracket = bg ?
                        GetBattlegroundBracketByLevel(bg->GetMapId(), bot->GetLevel()) : nullptr;
                    if (!bg || !bracket || bot->GetTeamId() > TEAM_HORDE)
                        continue;

                    BgAutoQueueDemand& demand = bgDemands[{ queueType, bracket->GetBracketId() }];
                    demand.Type = bgType;
                    demand.MapId = bg->GetMapId();
                    demand.Bracket = bracket->GetBracketId();
                    ++demand.BotPlayers[bot->GetTeamId()];
                    if (PlayerBotSpec::IsHeal(bot, true))
                        ++demand.Healers[bot->GetTeamId()];
                }
            }
        }

        // A bot whose login was requested for this BG already owns a future
        // team slot. Count it now so the five-second observer cannot request
        // duplicate logins while the character is still entering the world.
        for (auto const& stagedPair : BgAutoQueueStagedLogins)
        {
            BgAutoQueueStagedLogin const& staged = stagedPair.second;
            auto demandItr = bgDemands.find({ staged.QueueType, staged.Bracket });
            if (demandItr == bgDemands.end() || staged.Team > TEAM_HORDE)
                continue;
            ++demandItr->second.BotPlayers[staged.Team];
            if (staged.Healer)
                ++demandItr->second.Healers[staged.Team];
        }
    }

    uint32 bgInvitesAccepted = 0;
    uint32 bgBotsJoined = 0;
    uint32 bgBotsStaged = 0;
    if (sPlayerbotAIConfig->autoQueueBattleground &&
        sPlayerbotAIConfig->autoQueueBattlegroundAutomatic)
    {
        // Complete request-driven offline logins before examining already
        // managed queue members. This keeps RandomBotAutologin optional: a
        // real BG request can wake only the characters it actually needs.
        for (auto itr = BgAutoQueueStagedLogins.begin();
             itr != BgAutoQueueStagedLogins.end();)
        {
            uint32 botGuid = itr->first;
            BgAutoQueueStagedLogin const staged = itr->second;
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(botGuid);
            Player* requester = staged.RequesterGuid ?
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(staged.RequesterGuid)) : nullptr;
            bool requesterActive = requester && requester->IsInWorld() &&
                requester->InBattlegroundQueueForBattlegroundQueueType(staged.QueueType);
            Player* bot = GetPlayerBot(guid);

            if (!requesterActive)
            {
                if (bot && !bot->InBattleground() && !bot->InBattlegroundQueue())
                    LogoutPlayerBot(guid);
                if (IsBotLoading(guid))
                {
                    ++itr;
                    continue;
                }
                TC_LOG_INFO("server",
                    "AutoQueue BG canceled staged login guid=%u requester=%u type=%u",
                    botGuid, staged.RequesterGuid, uint32(staged.Type));
                itr = BgAutoQueueStagedLogins.erase(itr);
                continue;
            }

            if (!bot || !bot->IsInWorld() || IsBotLoading(guid) ||
                bot->IsBeingTeleported())
            {
                ++itr;
                continue;
            }

            std::string rejectionReason;
            if (!CanAutoQueueBgBot(bot, staged.Team, staged.MapId,
                staged.Bracket, &rejectionReason))
            {
                // Offline random bots can retain a stale open-world combat
                // state while they are being loaded specifically for this
                // queue.  It is transient and safe to clear before the bot
                // has joined a group, PvP queue or battleground.  Re-run the
                // complete eligibility test afterwards so no other rejection
                // is accidentally bypassed.
                if (rejectionReason == "in-combat")
                {
                    bot->CombatStopWithPets(true);
                    rejectionReason.clear();
                    if (CanAutoQueueBgBot(bot, staged.Team, staged.MapId,
                        staged.Bracket, &rejectionReason))
                    {
                        TC_LOG_INFO("server",
                            "AutoQueue BG cleared transient combat state name=%s guid=%u type=%u",
                            bot->GetName().c_str(), botGuid, uint32(staged.Type));
                    }
                }

                if (rejectionReason.empty())
                {
                    // The retry succeeded; continue with the normal staged
                    // loadout and queue path below.
                }
                else
                {
                    BgAutoQueueIneligibleBots.insert(botGuid);
                    TC_LOG_WARN("server",
                        "AutoQueue BG staged bot became ineligible name=%s guid=%u type=%u reason=%s team=%u expected-team=%u spec=%u level=%u map=%u",
                        bot->GetName().c_str(), botGuid, uint32(staged.Type),
                        rejectionReason.c_str(), uint32(bot->GetTeamId()),
                        uint32(staged.Team), uint32(bot->GetSpecialization()),
                        uint32(bot->GetLevel()), bot->GetMapId());
                    if (!bot->InBattleground() && !bot->InBattlegroundQueue())
                        LogoutPlayerBot(guid);
                    itr = BgAutoQueueStagedLogins.erase(itr);
                    continue;
                }
            }

            if (!bot->IsAlive())
            {
                Revive(bot);
                bot->SetHealth(bot->GetMaxHealth());
            }

            bool loadoutApplied = false;
            if (sPlayerbotAIConfig->autoQueueBattlegroundLoadout)
            {
                uint32 changed = 0;
                std::string loadoutError;
                if (!ApplyAutomatedPvpBotLoadout(bot, staged.RequesterGuid,
                    changed, loadoutError))
                {
                    TC_LOG_ERROR("server",
                        "AutoQueue BG staged loadout refused name=%s guid=%u requester=%u error=%s",
                        bot->GetName().c_str(), botGuid, staged.RequesterGuid,
                        loadoutError.c_str());
                    LogoutPlayerBot(guid);
                    itr = BgAutoQueueStagedLogins.erase(itr);
                    continue;
                }
                loadoutApplied = true;
            }

            if (!sBattlegroundMgr->QueuePlayer(bot, staged.Type))
            {
                if (loadoutApplied)
                {
                    uint32 restored = 0;
                    uint32 remaining = 0;
                    std::string restoreError;
                    RestoreAutomatedPvpBotLoadout(bot, "battleground-staged-queue-failed",
                        restored, remaining, restoreError);
                }
                LogoutPlayerBot(guid);
                itr = BgAutoQueueStagedLogins.erase(itr);
                continue;
            }

            BgAutoQueueManagedBots[botGuid] =
                { staged.QueueType, staged.Type, staged.Bracket,
                  staged.RequesterGuid, false, loadoutApplied, false, false };
            ++bgBotsJoined;
            TC_LOG_INFO("server",
                "AutoQueue BG staged bot joined name=%s guid=%u team=%u type=%u bracket=%u requester=%u",
                bot->GetName().c_str(), botGuid, uint32(staged.Team),
                uint32(staged.Type), uint32(staged.Bracket), staged.RequesterGuid);
            itr = BgAutoQueueStagedLogins.erase(itr);
        }

        // Reconcile only bots claimed by this feature.  If the real requester
        // abandons the queue before entry, remove our bot rather than leaving
        // behind an autonomous bot-only queue.  Once either side has entered
        // the match, normal battleground lifecycle owns it until exit.
        for (auto itr = BgAutoQueueManagedBots.begin();
             itr != BgAutoQueueManagedBots.end();)
        {
            uint32 botGuid = itr->first;
            BgAutoQueueManagedBot& managed = itr->second;
            Player* bot = GetPlayerBot(
                ObjectGuid::Create<HighGuid::Player>(botGuid));
            if (!bot || !bot->IsInWorld())
            {
                TC_LOG_WARN("server",
                    "AutoQueue BG released unavailable managed bot guid=%u type=%u",
                    botGuid, uint32(managed.Type));
                itr = BgAutoQueueManagedBots.erase(itr);
                continue;
            }

            bool inManagedQueue = bot->InBattlegroundQueueForBattlegroundQueueType(
                managed.QueueType);
            if (bot->InBattleground())
            {
                managed.Entered = true;
                Battleground* activeBg = bot->GetBattleground();
                if (activeBg && activeBg->IsBattleground() &&
                    !managed.StrategyInitialized)
                {
                    if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                    {
                        botAI->ResetStrategies();
                        managed.StrategyInitialized = true;
                        TC_LOG_INFO("server",
                            "AutoQueue BG objective strategy initialized name=%s guid=%u instance=%u type=%u",
                            bot->GetName().c_str(), botGuid, activeBg->GetInstanceID(),
                            uint32(managed.Type));
                    }
                }
                if (activeBg && activeBg->GetStatus() == STATUS_WAIT_JOIN &&
                    sPlayerbotAIConfig->autoQueueBattlegroundPreparationBuffs &&
                    !managed.PreparationBuffed &&
                    CastAutomatedPvpPreparationBuff(bot))
                {
                    managed.PreparationBuffed = true;
                    TC_LOG_INFO("server",
                        "AutoQueue BG preparation buff name=%s guid=%u instance=%u type=%u",
                        bot->GetName().c_str(), botGuid, activeBg->GetInstanceID(),
                        uint32(managed.Type));
                }
            }

            Player* requester = managed.RequesterGuid ?
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(managed.RequesterGuid)) : nullptr;
            bool requesterActive = requester && requester->IsInWorld() &&
                (requester->InBattlegroundQueueForBattlegroundQueueType(
                    managed.QueueType) || requester->InBattleground() ||
                    requester->IsBeingTeleported());

            if (!managed.Entered && inManagedQueue && !requesterActive)
            {
                sBattlegroundMgr->RemovePlayerFromQueue(bot, managed.QueueType);
                if (managed.LoadoutApplied)
                {
                    uint32 restored = 0;
                    uint32 remaining = 0;
                    std::string restoreError;
                    if (!RestoreAutomatedPvpBotLoadout(bot,
                        "battleground-requester-left", restored, remaining,
                        restoreError))
                    {
                        TC_LOG_ERROR("server",
                            "AutoQueue BG requester-left restore pending name=%s guid=%u restored=%u remaining=%u error=%s",
                            bot->GetName().c_str(), botGuid, restored, remaining,
                            restoreError.c_str());
                        ++itr;
                        continue;
                    }
                }
                TC_LOG_INFO("server",
                    "AutoQueue BG removed bot name=%s guid=%u because requester=%u left type=%u",
                    bot->GetName().c_str(), botGuid, managed.RequesterGuid,
                    uint32(managed.Type));
                itr = BgAutoQueueManagedBots.erase(itr);
                continue;
            }

            if (!bot->InBattleground() && !inManagedQueue &&
                !bot->IsBeingTeleported())
            {
                if (managed.LoadoutApplied)
                {
                    if (!bot->IsAlive())
                        Revive(bot);
                    bot->SetHealth(bot->GetMaxHealth());
                    uint32 restored = 0;
                    uint32 remaining = 0;
                    std::string restoreError;
                    if (!RestoreAutomatedPvpBotLoadout(bot, "battleground-exit",
                        restored, remaining, restoreError))
                    {
                        TC_LOG_ERROR("server",
                            "AutoQueue BG loadout restore pending name=%s guid=%u restored=%u remaining=%u error=%s",
                            bot->GetName().c_str(), botGuid, restored, remaining,
                            restoreError.c_str());
                        ++itr;
                        continue;
                    }
                }
                TC_LOG_INFO("server",
                    "AutoQueue BG lifecycle completed bot name=%s guid=%u type=%u entered=%u",
                    bot->GetName().c_str(), botGuid, uint32(managed.Type),
                    managed.Entered ? 1 : 0);
                if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                    botAI->ResetStrategies();
                itr = BgAutoQueueManagedBots.erase(itr);
                continue;
            }

            ++itr;
        }

        // Accept only non-Arena invitations owned by this automation.  Other
        // playerbot queue systems remain untouched.
        for (auto const& managedPair : BgAutoQueueManagedBots)
        {
            Player* bot = GetPlayerBot(ObjectGuid::Create<HighGuid::Player>(
                managedPair.first));
            // Membership in BgAutoQueueManagedBots is the ownership boundary.
            // Request-driven offline bots are not necessarily marked as
            // random bots, but their invitations still have to be accepted.
            if (!bot || !bot->IsInWorld())
                continue;

            for (uint8 slot = 0; slot < PLAYER_MAX_BATTLEGROUND_QUEUES; ++slot)
            {
                BattlegroundQueueTypeId queueType = bot->GetBattlegroundQueueTypeId(slot);
                if (queueType == managedPair.second.QueueType &&
                    sBattlegroundMgr->AcceptQueueInvite(bot, slot))
                {
                    ++bgInvitesAccepted;
                    break;
                }
            }
        }

        for (auto& demandPair : bgDemands)
        {
            BgAutoQueueDemand& demand = demandPair.second;
            // Never manufacture a bot-only battleground.
            if (!demand.RealPlayers[TEAM_ALLIANCE] && !demand.RealPlayers[TEAM_HORDE])
                continue;

            Battleground* bg = sBattlegroundMgr->GetBattlegroundTemplate(demand.Type);
            // MinPlayersPerTeam is only the threshold at which the core may
            // start a match (WSG is 5). Automation should fill the playable
            // roster, whose real WSG size is 10 per faction.
            uint32 targetPerTeam = bg ? bg->GetMaxPlayersPerTeam() : 0;
            if (!targetPerTeam)
                continue;

            for (TeamId team : { TEAM_ALLIANCE, TEAM_HORDE })
            {
                uint32 requesterGuid = demand.RequesterGuid[team] ?
                    demand.RequesterGuid[team] :
                    demand.RequesterGuid[team == TEAM_ALLIANCE ?
                        TEAM_HORDE : TEAM_ALLIANCE];
                while (demand.RealPlayers[team] + demand.BotPlayers[team] < targetPerTeam &&
                    bgBotsJoined + bgBotsStaged <
                        sPlayerbotAIConfig->autoQueueBattlegroundMaxBotsPerCycle)
                {
                    Player* selectedBot = nullptr;
                    uint32 desiredHealers = std::max<uint32>(1, targetPerTeam / 5);
                    bool needHealer = demand.Healers[team] < desiredHealers;
                    std::vector<Player*> eligibleBots;
                    std::vector<Player*> eligibleHealers;
                    for (auto const& botPair : playerBots)
                    {
                        Player* bot = botPair.second;
                        if (!IsRandomBot(bot) || !CanAutoQueueBgBot(
                            bot, team, demand.MapId, demand.Bracket))
                            continue;

                        eligibleBots.push_back(bot);
                        if (PlayerBotSpec::IsHeal(bot, true))
                            eligibleHealers.push_back(bot);
                    }

                    std::vector<Player*> const& selectionPool =
                        needHealer && !eligibleHealers.empty() ?
                            eligibleHealers : eligibleBots;
                    if (!selectionPool.empty())
                        selectedBot = selectionPool[
                            urand(0, uint32(selectionPool.size() - 1))];

                    if (!selectedBot)
                    {
                        // No suitable random bot is online. Select an unused
                        // offline character from the configured random-bot
                        // accounts and stage its login. The next observer tick
                        // applies the protected loadout and queues it.
                        if (sPlayerbotAIConfig->randomBotAccounts.empty())
                            break;

                        Player* requester = requesterGuid ?
                            ObjectAccessor::FindConnectedPlayer(
                                ObjectGuid::Create<HighGuid::Player>(requesterGuid)) : nullptr;
                        if (!requester)
                            break;

                        uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
                        uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
                        QueryResult candidates = CharacterDatabase.PQuery(
                            "SELECT guid,name,race,class,talentTree,activespec "
                            "FROM characters WHERE account >= %u AND account <= %u "
                            "AND level=%u AND online=0 AND instance_id=0 "
                            "AND guid NOT IN (SELECT guid FROM guild_member) "
                            "AND guid NOT IN (SELECT memberGuid FROM group_member) "
                            "AND guid NOT IN (SELECT owner_guid FROM solo_arena_loadout_backup) "
                            "ORDER BY RAND()",
                            minAccount, maxAccount, requester->GetLevel());
                        if (!candidates)
                            break;

                        uint32 selectedGuid = 0;
                        std::string selectedName;
                        bool selectedHealer = false;
                        uint32 fallbackGuid = 0;
                        std::string fallbackName;
                        bool fallbackHealer = false;
                        do
                        {
                            Field* fields = candidates->Fetch();
                            uint32 candidateGuid = fields[0].GetUInt32();
                            ObjectGuid candidateObjectGuid =
                                ObjectGuid::Create<HighGuid::Player>(candidateGuid);
                            uint8 race = fields[2].GetUInt8();
                            uint32 candidateTeam = Player::TeamForRace(race);
                            if (candidateTeam == PANDAREN_NEUTRAL ||
                                TeamId(candidateTeam == ALLIANCE ? TEAM_ALLIANCE : TEAM_HORDE) != team ||
                                BgAutoQueueIneligibleBots.count(candidateGuid) ||
                                BgAutoQueueStagedLogins.count(candidateGuid) ||
                                BgAutoQueueManagedBots.count(candidateGuid) ||
                                ObjectAccessor::FindPlayer(candidateObjectGuid) ||
                                GetPlayerBot(candidateObjectGuid) || IsBotLoading(candidateObjectGuid))
                                continue;

                            uint32 specs[MAX_TALENT_SPECS] = { 0, 0 };
                            std::istringstream talentTrees(fields[4].GetString());
                            for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
                                talentTrees >> specs[spec];
                            uint8 activeSpec = fields[5].GetUInt8();
                            if (activeSpec >= MAX_TALENT_SPECS)
                                activeSpec = 0;
                            bool healer = IsBgHealerSpecialization(
                                Specializations(specs[activeSpec]));
                            if (!HasAutomatedPvpBotLoadout(
                                Specializations(specs[activeSpec])))
                                continue;
                            if (needHealer && !healer)
                            {
                                if (!fallbackGuid)
                                {
                                    fallbackGuid = candidateGuid;
                                    fallbackName = fields[1].GetString();
                                    fallbackHealer = false;
                                }
                                continue;
                            }

                            selectedGuid = candidateGuid;
                            selectedName = fields[1].GetString();
                            selectedHealer = healer;
                            break;
                        }
                        while (candidates->NextRow());

                        // If this team has no unused healer, allow a DPS bot
                        // rather than leaving the entire battleground stalled.
                        if (!selectedGuid && fallbackGuid)
                        {
                            selectedGuid = fallbackGuid;
                            selectedName = fallbackName;
                            selectedHealer = fallbackHealer;
                        }
                        if (!selectedGuid)
                            break;

                        ObjectGuid selectedObjectGuid =
                            ObjectGuid::Create<HighGuid::Player>(selectedGuid);
                        BgAutoQueueStagedLogins[selectedGuid] =
                            { demandPair.first.first, demand.Type, demand.MapId,
                              demand.Bracket, team, requesterGuid, selectedHealer };
                        AddPlayerBot(selectedObjectGuid, 0);
                        ++demand.BotPlayers[team];
                        if (selectedHealer)
                            ++demand.Healers[team];
                        ++bgBotsStaged;
                        TC_LOG_INFO("server",
                            "AutoQueue BG staged login name=%s guid=%u team=%u type=%u bracket=%u healer=%u requester=%u",
                            selectedName.c_str(), selectedGuid, uint32(team),
                            uint32(demand.Type), uint32(demand.Bracket),
                            selectedHealer ? 1u : 0u, requesterGuid);
                        continue;
                    }

                    // A random bot may have died in the open world before it
                    // was selected. Restore it through the existing bot
                    // lifecycle before queueing; never apply this to the real
                    // requester.
                    if (!selectedBot->IsAlive())
                    {
                        Revive(selectedBot);
                        if (!selectedBot->IsAlive())
                        {
                            TC_LOG_ERROR("server",
                                "AutoQueue BG could not revive selected bot name=%s guid=%u",
                                selectedBot->GetName().c_str(),
                                selectedBot->GetGUID().GetCounter());
                            break;
                        }
                        selectedBot->SetHealth(selectedBot->GetMaxHealth());
                        TC_LOG_INFO("server",
                            "AutoQueue BG revived selected bot name=%s guid=%u before queue",
                            selectedBot->GetName().c_str(),
                            selectedBot->GetGUID().GetCounter());
                    }

                    bool loadoutApplied = false;
                    if (sPlayerbotAIConfig->autoQueueBattlegroundLoadout)
                    {
                        uint32 changed = 0;
                        std::string loadoutError;
                        if (!ApplyAutomatedPvpBotLoadout(selectedBot,
                            requesterGuid, changed, loadoutError))
                        {
                            TC_LOG_ERROR("server",
                                "AutoQueue BG skipped bot loadout name=%s guid=%u requester=%u error=%s",
                                selectedBot->GetName().c_str(),
                                selectedBot->GetGUID().GetCounter(), requesterGuid,
                                loadoutError.c_str());
                            break;
                        }
                        loadoutApplied = true;
                    }

                    if (!sBattlegroundMgr->QueuePlayer(selectedBot, demand.Type))
                    {
                        if (loadoutApplied)
                        {
                            uint32 restored = 0;
                            uint32 remaining = 0;
                            std::string restoreError;
                            RestoreAutomatedPvpBotLoadout(selectedBot,
                                "battleground-queue-failed", restored, remaining,
                                restoreError);
                        }
                        break;
                    }

                    ++demand.BotPlayers[team];
                    if (PlayerBotSpec::IsHeal(selectedBot, true))
                        ++demand.Healers[team];
                    ++bgBotsJoined;
                    BgAutoQueueManagedBots[selectedBot->GetGUID().GetCounter()] =
                        { demandPair.first.first, demand.Type, demand.Bracket,
                          requesterGuid, false, loadoutApplied, false, false };
                    TC_LOG_INFO("server",
                        "AutoQueue BG joined bot name=%s guid=%u team=%u type=%u bracket=%u target-per-team=%u healers=%u/%u requester=%u",
                        selectedBot->GetName().c_str(), selectedBot->GetGUID().GetCounter(),
                        uint32(team), uint32(demand.Type), uint32(demand.Bracket),
                        targetPerTeam, demand.Healers[team], desiredHealers,
                        requesterGuid);
                }
            }
        }
    }

    TC_LOG_INFO("server",
        "AutoQueue observer (dry-run=%u, max-bots=%u, bg-max-bots=%u): LFG real/bot=%u/%u staged=%u joined=%u accepted=%u demands=%u pending=%u managed=%u, BG real/bot=%u/%u staged=%u joined=%u accepted=%u demands=%u pending=%u managed=%u, Arena real/bot=%u/%u",
        sPlayerbotAIConfig->autoQueueDryRun ? 1 : 0, sPlayerbotAIConfig->autoQueueMaxBotsPerCycle,
        sPlayerbotAIConfig->autoQueueBattlegroundMaxBotsPerCycle,
        realLfg, botLfg, lfgBotsStaged, lfgBotsJoined, lfgProposalsAccepted,
        uint32(lfgDemands.size()), uint32(LfgAutoQueueStagedLogins.size()),
        uint32(LfgAutoQueueManagedBots.size()),
        realBg, botBg, bgBotsStaged, bgBotsJoined, bgInvitesAccepted,
        uint32(bgDemands.size()), uint32(BgAutoQueueStagedLogins.size()),
        uint32(BgAutoQueueManagedBots.size()),
        realArena, botArena);
}

uint32 RandomPlayerbotMgr::AddRandomBots()
{
    uint32 maxAllowedBotCount = GetEventValue(0, "bot_count");

    if (_currentBots.size() < maxAllowedBotCount)
    {
        maxAllowedBotCount -= _currentBots.size();
        maxAllowedBotCount = std::min(sPlayerbotAIConfig->randomBotsPerInterval, maxAllowedBotCount);

        for (std::vector<uint32>::iterator i = sPlayerbotAIConfig->randomBotAccounts.begin();
            i != sPlayerbotAIConfig->randomBotAccounts.end(); i++)
        {
            uint32 accountId = *i;

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARS_BY_ACCOUNT_ID);
            stmt->setUInt32(0, accountId);
            PreparedQueryResult result = CharacterDatabase.Query(stmt);
            if (!result)
                continue;
            std::vector<uint32> guids;
            do
            {
                Field* fields = result->Fetch();
                uint64 guid = fields[0].GetInt64();
                if (GetEventValue(guid, "add"))
                    continue;

                if (GetEventValue(guid, "logout"))
                    continue;

                if (GetPlayerBot(guid))
                    continue;

                if (std::find(_currentBots.begin(), _currentBots.end(), guid) != _currentBots.end())
                    continue;

                guids.push_back(guid);
            } while (result->NextRow());

            std::mt19937 rnd(time(0));
            std::shuffle(guids.begin(), guids.end(), rnd);

            for (uint32& guid : guids)
            {
                uint32 add_time = 31104000;

                SetEventValue(guid, "add", 1, add_time);
                SetEventValue(guid, "logout", 0, 0);
                SetEventValue(guid, "randomize", 1, add_time * 2);
                SetEventValue(guid, "teleport", 1, add_time * 2);
                _currentBots.push_back(guid);

                maxAllowedBotCount--;
                if (!maxAllowedBotCount)
                    break;
            }

            if (!maxAllowedBotCount)
                break;
        }

        if (maxAllowedBotCount)
            TC_LOG_ERROR("playerbots", "Not enough random bot accounts available. Try to increase RandomBotAccountCount in your conf file");
    }

    return _currentBots.size();
}

void RandomPlayerbotMgr::Remove(Player* bot)
{
    ObjectGuid owner = bot->GetGUID();

    PlayerbotsPreparedStatement* stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_DEL_RANDOM_BOTS_BY_OWNER);
    stmt->setUInt32(0, 0);
    stmt->setUInt32(1, owner.GetCounter());
    PlayerbotsDatabase.Execute(stmt);

    _eventCache[owner.GetCounter()].clear();

    LogoutPlayerBot(owner);
}

void RandomPlayerbotMgr::CheckPlayers()
{
}

bool RandomPlayerbotMgr::ProcessBot(uint32 bot)
{
    Player* player = GetPlayerBot(bot);
    PlayerbotAI* botAI = player ? GET_PLAYERBOT_AI(player) : nullptr;
    ObjectGuid botGUID = ObjectGuid::Create<HighGuid::Player>(bot);

    uint32 isValid = GetEventValue(bot, "add");
    if (!isValid)
    {
        if (!player || !player->GetGroup())
        {
            if (player)
            {
                auto side = (player->GetTeamId() == TeamId::TEAM_ALLIANCE ? "A" : "H");
                TC_LOG_INFO("playerbots", "Bot #%u %s:%u <%s>: log out", bot, side, player->GetLevel(), player->GetName().c_str());
            }
            else
                TC_LOG_INFO("playerbots", "Bot #%u: log out", bot);

            SetEventValue(bot, "add", 0, 0);
            _currentBots.erase(std::remove(_currentBots.begin(), _currentBots.end(), bot), _currentBots.end());

            if (player)
                LogoutPlayerBot(botGUID);
        }

        return false;
    }

    uint32 randomTime;
    if (!player)
    {
        AddPlayerBot(botGUID, 0);
        randomTime = 1 + (std::rand() % 2);

        uint32 randomBotUpdateInterval = _isBotInitializing ? 1 : sPlayerbotAIConfig->randomBotUpdateInterval;
        int minValue = std::max(5, static_cast<int>(randomBotUpdateInterval * 0.5));
        int maxValue = std::max(12, static_cast<int>(randomBotUpdateInterval * 2));
        randomTime = minValue + (std::rand() % (maxValue - minValue + 1));
        
        SetEventValue(bot, "update", 1, randomTime);

        // do not randomize or teleport immediately after server start (prevent lagging)
        if (!GetEventValue(bot, "randomize"))
        {
            int minValue = std::max(7, static_cast<int>(randomBotUpdateInterval * 0.7));
            int maxValue = std::max(14, static_cast<int>(randomBotUpdateInterval * 1.4));
            randomTime = minValue + (std::rand() % (maxValue - minValue + 1));

            ScheduleRandomize(bot, randomTime);
        }
        if (!GetEventValue(bot, "teleport"))
        {
            int minValue = std::max(7, static_cast<int>(randomBotUpdateInterval * 0.7));
            int maxValue = std::max(14, static_cast<int>(randomBotUpdateInterval * 1.4));
            randomTime = minValue + (std::rand() % (maxValue - minValue + 1));

            ScheduleTeleport(bot, randomTime);
        }

        return true;
    }

    if (!player->IsInWorld())
        return false;

    if (player->GetGroup() || player->HasUnitState(UNIT_STATE_IN_FLIGHT))
        return false;

    uint32 update = GetEventValue(bot, "update");
    if (!update)
    {
        if (botAI)
            botAI->GetAiObjectContext()->GetValue<bool>("random bot update")->Set(true);

        bool update = true;
        if (botAI)
        {
            botAI->GetAiObjectContext()->GetValue<bool>("random bot update")->Set(true);
            if (!sRandomPlayerbotMgr->IsRandomBot(player))
                update = false;

            if (player->GetGroup() && botAI->GetGroupMaster())
            {
                PlayerbotAI* groupMasterBotAI = GET_PLAYERBOT_AI(botAI->GetGroupMaster());
                if (!groupMasterBotAI || groupMasterBotAI->IsRealPlayer())
                {
                    update = false;
                }
            }
        }

        if (update)
            ProcessBot(player);

        randomTime = urand(60/*sPlayerbotAIConfig->minRandomBotReviveTime*/, 300/*sPlayerbotAIConfig->maxRandomBotReviveTime*/);
        SetEventValue(bot, "update", 1, randomTime);

        return true;
    }

    /*uint32 logout = GetEventValue(bot, "logout");
    if (player && !logout && !isValid)
    {
        auto side = (player->GetTeamId() == TeamId::TEAM_ALLIANCE ? "A" : "H");
        TC_LOG_INFO("playerbots", "Bot #%u %s:%u <%s>: log out", bot, side, player->GetLevel(), player->GetName().c_str());
        LogoutPlayerBot(botGUID);
        for (auto it = _currentBots.begin(); it != _currentBots.end();)
        {
            if (*it == bot)
            {
                it = _currentBots.erase(it);
                break;
            }
            else
                ++it;
        }
        SetEventValue(bot, "logout", 1, urand(sPlayerbotAIConfig->minRandomBotInWorldTime, sPlayerbotAIConfig->maxRandomBotInWorldTime));
        return true;
    }*/

    return false;
}

bool RandomPlayerbotMgr::ProcessBot(Player* player)
{
    ObjectGuid bot = player->GetGUID();

    if (player->InBattleground())
        return false;

    if (player->InBattlegroundQueue())
        return false;

    

    // if death revive
    if (player->isDead())
    {
        if (!GetEventValue(bot, "dead"))
        {
            uint32 randomTime = urand(60/*sPlayerbotAIConfig->minRandomBotReviveTime*/, 300/*sPlayerbotAIConfig->maxRandomBotReviveTime*/);
            TC_LOG_DEBUG("playerbots", "Mark bot %s as dead, will be revived in %us.", player->GetName().c_str(), randomTime);
            SetEventValue(bot, "dead", 1, sPlayerbotAIConfig->maxRandomBotInWorldTime);
            SetEventValue(bot, "revive", 1, randomTime);
            return false;
        }

        if (!GetEventValue(bot, "revive"))
        {
            Revive(player);
            return true;
        }

        return false;
    }

    // only randomize and teleport idle bots
    bool idleBot = false;
    PlayerbotAI* botAI = GET_PLAYERBOT_AI(player);
    if (botAI)
    {
        /*if (TravelTarget* target = botAI->GetAiObjectContext()->GetValue<TravelTarget*>("travel target")->Get())
        {
            if (target->getTravelState() == TravelState::TRAVEL_STATE_IDLE)
            {
                idleBot = true;
            }
        }
        else*/
        //{
            idleBot = true;
        //}
    }
    if (idleBot)
    {
        if (player->GetInstanceId() || player->GetGroup() || player->InArena() || player->inRandomLfgDungeon() || player->IsInFlight() || player->IsInCombat() || !player->IsAlive())
            return false;

        // randomize
        uint32 randomize = GetEventValue(bot, "randomize");
        if (!randomize)
        {
            PerformanceMonitorOperation* pmo = sPerformanceMonitor->start(PERF_MON_RNDBOT, "Randomize");
            Randomize(player);
            TC_LOG_DEBUG("playerbots", "Bot #%u %s:%u <%s>: randomized", bot.GetCounter(), player->GetTeamId() == TEAM_ALLIANCE ? "A" : "H", player->GetLevel(), player->GetName().c_str());
            if (pmo)
                pmo->finish();
            return true;
        }

        uint32 teleport = GetEventValue(bot, "teleport");
        if (!teleport)
        {
            PerformanceMonitorOperation* pmo = sPerformanceMonitor->start(PERF_MON_RNDBOT, "RandomTeleportByLocations");
            TC_LOG_DEBUG("playerbots", "Bot #%u <%s>: teleport for level and refresh", bot.GetCounter(), player->GetName().c_str());
            Refresh(player);
            RandomTeleportForLevel(player);
            uint32 time = urand(sPlayerbotAIConfig->minRandomBotTeleportInterval, sPlayerbotAIConfig->maxRandomBotTeleportInterval);
            ScheduleTeleport(bot, time);
            if (pmo)
                pmo->finish();
            return true;
        }
    }

    return false;
}

void RandomPlayerbotMgr::TagForRandomize(Player* bot, uint32 level)
{
    ObjectGuid::LowType guid = bot->GetGUID().GetCounter();

    SetValue(bot, "level", level);
    ScheduleRandomize(guid, 0);
}

void RandomPlayerbotMgr::Revive(Player* player)
{
    uint64 bot = player->GetGUID();

    SetEventValue(bot, "dead", 0, 0);
    SetEventValue(bot, "revive", 0, 0);

    Refresh(player);
}

void RandomPlayerbotMgr::Clear(Player* bot)
{
    //PlayerbotFactory factory(bot, bot->GetLevel());
    //factory.ClearEverything();
}

void RandomPlayerbotMgr::RandomizeFirst(Player* bot)
{
    uint32 maxLevel = sPlayerbotAIConfig->randomBotMaxLevel;
    maxLevel = std::min(maxLevel, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));

    // if lvl sync is enabled, max level is limited by online players lvl
    /*if (sPlayerbotAIConfig->syncLevelWithPlayers)
        maxLevel = std::max(sPlayerbotAIConfig->randomBotMinLevel,
            std::min(playersLevel, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)));*/

    //PerformanceMonitorOperation* pmo = sPerformanceMonitor->start(PERF_MON_RNDBOT, "RandomizeFirst");

    
    uint32 level = urand(sPlayerbotAIConfig->randomBotMinLevel, maxLevel);
    uint32 chance = std::clamp<uint32>(sPlayerbotAIConfig->randomBotMaxLevelChance * 100, 0, 100);
    if (urand(1, 100) <= chance)
        level = maxLevel;

    if (bot->GetClass() == CLASS_DEATH_KNIGHT)
        level = urand(std::max(sPlayerbotAIConfig->randomBotMinLevel, sWorld->getIntConfig(CONFIG_START_HEROIC_PLAYER_LEVEL)), std::max(sWorld->getIntConfig(CONFIG_START_HEROIC_PLAYER_LEVEL), maxLevel));

    if (sPlayerbotAIConfig->disableRandomLevels)
    {
        level = bot->GetClass() == CLASS_DEATH_KNIGHT ? std::max(uint32(55), sWorld->getIntConfig(CONFIG_START_HEROIC_PLAYER_LEVEL)) : uint32(55);
    }

    SetValue(bot, "level", level);
    BotFactory factory(bot, level);
    factory.Randomize(false);

    uint32 randomTime   = urand(sPlayerbotAIConfig->minRandomBotRandomizeTime, sPlayerbotAIConfig->maxRandomBotRandomizeTime);
    uint32 inworldTime  = urand(sPlayerbotAIConfig->minRandomBotInWorldTime, sPlayerbotAIConfig->maxRandomBotInWorldTime);

    PlayerbotsPreparedStatement* stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_UPD_RANDOM_BOTS);
    stmt->setUInt32(0, randomTime);
    stmt->setString(1, "bot_delete");
    stmt->setUInt32(2, bot->GetGUID().GetCounter());
    PlayerbotsDatabase.Execute(stmt);

    stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_UPD_RANDOM_BOTS);
    stmt->setUInt32(0, inworldTime);
    stmt->setString(1, "logout");
    stmt->setUInt32(2, bot->GetGUID().GetCounter());
    PlayerbotsDatabase.Execute(stmt);

    // teleport to a random inn for bot level
    if (GET_PLAYERBOT_AI(bot))
        GET_PLAYERBOT_AI(bot)->Reset(true);

    if (bot->GetGroup())
        bot->RemoveFromGroup();

    //if (pmo)
        //pmo->finish();

    //for (int i = 1; i < MAX_INVTYPE; ++i)
    //{
        //sRandomItemMgr->FindBestItemForLevelAndEquip(bot, InventoryType(i));
    //}

    RandomTeleportForLevel(bot);
}

void RandomPlayerbotMgr::Randomize(Player* bot)
{
    if (GET_PLAYERBOT_AI(bot))
            GET_PLAYERBOT_AI(bot)->Reset(true);

    uint8 level = GetValue(bot, "level");
    BotFactory factory(bot, level);
    factory.Randomize(false);

    // rez / clean cd / etc
    Refresh(bot);
    RandomTeleportForLevel(bot);

    // -- safe
    ScheduleRandomize(bot->GetGUID().GetCounter(), 62208000);
}

void RandomPlayerbotMgr::Refresh(Player* bot)
{
    PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
    if (!botAI)
        return;

    if (bot->isDead())
    {
        bot->ResurrectPlayer(1.0f);
        bot->SpawnCorpseBones();
        botAI->ResetStrategies();
    }

    // if (sPlayerbotAIConfig->disableRandomLevels)
    //     return;

    if (bot->InBattleground())
        return;

    TC_LOG_INFO("playerbots", "Refreshing bot #%u <%s>", bot->GetGUID().GetCounter(), bot->GetName().c_str());
    PerformanceMonitorOperation* pmo = sPerformanceMonitor->start(PERF_MON_RNDBOT, "Refresh");

    botAI->Reset();
    bot->DurabilityRepairAll(false, 1.0f, false);
    bot->SetFullHealth();
    //bot->SetPvP(true);
    BotFactory factory(bot, bot->GetLevel());
    factory.Refresh();

    if (bot->GetMaxPower(POWER_MANA) > 0)
        bot->SetPower(POWER_MANA, bot->GetMaxPower(POWER_MANA));

    if (bot->GetMaxPower(POWER_ENERGY) > 0)
        bot->SetPower(POWER_ENERGY, bot->GetMaxPower(POWER_ENERGY));

    uint32 money = bot->GetMoney();
    bot->SetMoney(money + 500 * sqrt(urand(1, bot->GetLevel() * 5)));

    //if (bot->GetGroup())
        //bot->RemoveFromGroup();

    if (pmo)
        pmo->finish();
}

bool RandomPlayerbotMgr::IsRandomBot(Player* bot)
{
    if (bot && GET_PLAYERBOT_AI(bot))
    {
        if (GET_PLAYERBOT_AI(bot)->IsRealPlayer())
        {
            return false;
        }
    }
    if (bot)
    {
        return IsRandomBot(bot->GetGUID().GetCounter());
    }

    return false;
}

bool RandomPlayerbotMgr::IsRandomBot(ObjectGuid::LowType bot)
{
    ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(bot);
    if (!sPlayerbotAIConfig->IsInRandomAccountList(sCharacterCache->GetCharacterAccountIdByGuid(guid)))
        return false;
    if (std::find(_currentBots.begin(), _currentBots.end(), bot) != _currentBots.end())
        return true;
    return false;
}

void RandomPlayerbotMgr::GetBots()
{
    if (!_currentBots.empty())
        return;

    PlayerbotsPreparedStatement* stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_SEL_RANDOM_BOTS_BY_OWNER_AND_EVENT);
    stmt->setUInt32(0, 0);
    stmt->setString(1, "add");
    uint32 maxAllowedBotCount = GetEventValue(0, "bot_count");
    if (PreparedQueryResult result = PlayerbotsDatabase.Query(stmt))
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 bot = fields[0].GetUInt32();
            if (GetEventValue(bot, "add"))
                _currentBots.push_back(bot);

            if (_currentBots.size() >= maxAllowedBotCount)
                break;
        } while (result->NextRow());
    }
}

uint32 RandomPlayerbotMgr::GetEventValue(uint32 bot, std::string const event)
{
    // load all events at once on first event load
    if (_eventCache[bot].empty())
    {
        PlayerbotsPreparedStatement* stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_SEL_RANDOM_BOTS_BY_OWNER_AND_BOT);
        stmt->setUInt32(0, 0);
        stmt->setUInt64(1, bot);
        if (PreparedQueryResult result = PlayerbotsDatabase.Query(stmt))
        {
            do
            {
                Field* fields = result->Fetch();
                std::string const eventName = fields[0].GetString();

                CachedEvent e;
                e.value = fields[1].GetUInt32();
                e.lastChangeTime = fields[2].GetUInt32();
                e.validIn = fields[3].GetUInt32();
                e.data = fields[4].GetString();
                _eventCache[bot][eventName] = std::move(e);
            } while (result->NextRow());
        }
    }

    CachedEvent& e = _eventCache[bot][event];
    if ((time(0) - e.lastChangeTime) >= e.validIn && event != "specNo" && event != "specLink")
        e.value = 0;

    return e.value;
}

std::string const RandomPlayerbotMgr::GetEventData(uint32 bot, std::string const event)
{
    std::string data = "";
    if (GetEventValue(bot, event))
    {
        CachedEvent e = _eventCache[bot][event];
        data = e.data;
    }

    return data;
}

uint32 RandomPlayerbotMgr::SetEventValue(uint32 bot, std::string const event, uint32 value, uint32 validIn,
    std::string const data)
{
    PlayerbotsDatabaseTransaction trans = PlayerbotsDatabase.BeginTransaction();

    PlayerbotsPreparedStatement* stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_DEL_RANDOM_BOTS_BY_OWNER_AND_EVENT);
    stmt->setUInt32(0, 0);
    stmt->setUInt64(1, bot);
    stmt->setString(2, event);
    trans->Append(stmt);

    if (value)
    {
        stmt = PlayerbotsDatabase.GetPreparedStatement(PLAYERBOTS_INS_RANDOM_BOTS);
        stmt->setUInt32(0, 0);
        stmt->setUInt64(1, bot);
        auto time = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
        stmt->setInt64(2, time);
        stmt->setUInt32(3, validIn);
        stmt->setString(4, event);
        stmt->setUInt32(5, value);
        if (data != "")
        {
            stmt->setString(6, data);
        }
        else
        {
            stmt->setString(6, "");
        }
        trans->Append(stmt);
    }

    PlayerbotsDatabase.CommitTransaction(trans);

    CachedEvent e(value, (uint32)time(nullptr), validIn, data);
    _eventCache[bot][event] = std::move(e);
    return value;
}

uint32 RandomPlayerbotMgr::GetValue(uint32 bot, std::string const type) { return GetEventValue(bot, type); }

uint32 RandomPlayerbotMgr::GetValue(Player* bot, std::string const type)
{
    return GetValue(bot->GetGUID().GetCounter(), type);
}

std::string const RandomPlayerbotMgr::GetData(uint32 bot, std::string const type) { return GetEventData(bot, type); }

void RandomPlayerbotMgr::SetValue(uint32 bot, std::string const type, uint32 value, std::string const data)
{
    SetEventValue(bot, type, value, sPlayerbotAIConfig->maxRandomBotInWorldTime, data);
}

void RandomPlayerbotMgr::SetValue(Player* bot, std::string const type, uint32 value, std::string const data)
{
    SetValue(bot->GetGUID().GetCounter(), type, value, data);
}

void RandomPlayerbotMgr::OnPlayerLogout(Player* player)
{
    if (!player)
        return;

    DisablePlayerBot(player->GetGUID());

    for (PlayerBotMap::const_iterator it = GetPlayerBotsBegin(); it != GetPlayerBotsEnd(); ++it)
    {
        Player* const bot = it->second;
        PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
        if (botAI && player == botAI->GetMaster())
        {
            botAI->SetMaster(nullptr);
            if (!bot->InBattleground())
            {
                //botAI->ResetStrategies();
            }
        }
    }

    _players.erase(std::remove(_players.begin(), _players.end(), player), _players.end());
}

void RandomPlayerbotMgr::OnBotLoginInternal(Player* const bot)
{
    auto maxAllowed = sRandomPlayerbotMgr->GetMaxAllowedBotCount();
    TC_LOG_INFO("playerbots", "%u/%u Bot %s logged in - Active spec tab: %u Spec: %u", playerBots.size(), maxAllowed, bot->GetName().c_str(), (uint32)bot->GetActiveSpec(), (uint32)bot->GetSpecialization());

    // Inventory capacity must exist before Caller, arena or specialization
    // preparation can preserve replaced equipment in the bot's bags.
    BotFactory factory(bot, bot->GetLevel());
    if (bot->GetSpecialization() != SPEC_NONE)
    {
        std::string previousEquipmentIssue;
        bool neededRepair = !factory.HasRequiredEquipmentForSpec(
            &previousEquipmentIssue);
        factory.InitEquipmentForSpec();
        std::string remainingWeaponIssue;
        if (!factory.HasRequiredWeaponSetForSpec(&remainingWeaponIssue))
            TC_LOG_ERROR("playerbots",
                "Bot equipment repair incomplete name=%s guid=%u specialization=%u reason=%s",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                uint32(bot->GetSpecialization()),
                remainingWeaponIssue.c_str());
        else if (neededRepair && factory.HasRequiredEquipmentForSpec())
            TC_LOG_INFO("playerbots",
                "Bot equipment repaired name=%s guid=%u specialization=%u previous-issue=%s main-hand=%u off-hand=%u",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                uint32(bot->GetSpecialization()),
                previousEquipmentIssue.c_str(),
                bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
                    EQUIPMENT_SLOT_MAINHAND)->GetEntry(),
                bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
                    EQUIPMENT_SLOT_OFFHAND) ?
                    bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
                        EQUIPMENT_SLOT_OFFHAND)->GetEntry() : 0);
    }
    else
        factory.InitBags();

    // If this player has been created recently and is not assign horde / alliance as pandaren
    if (bot->GetRace() == RACE_PANDAREN_NEUTRAL)
    {
        // Allow player to get fully logged
        bot->AddDelayedEvent(5000, [bot]()
        {
            static const uint32 JOIN_THE_ALLIANCE = 1;
            static const uint32 JOIN_THE_HORDE = 0;

            WorldPacket packet(CMSG_SELECT_FACTION);
            packet << (std::rand() % 2 ? JOIN_THE_HORDE : JOIN_THE_ALLIANCE);

            WorldSession* session = bot->GetSession();
            session->HandleSelectFactionOpcode(packet);

            TC_LOG_INFO("playerbots", "%s Assigned to faction: %s", bot->GetName().c_str(), (bot->GetTeamId() ? "Alliance" : "Horde"));
        });        
    }
    if (bot->GetRace() == RACE_GOBLIN && bot->GetLevel() == 1)
    {
        bot->AddDelayedEvent(5000, [bot]()
        {
            // -- force finish quest
            auto it = bot->getRewardedQuests().find(25265);
            if (it == bot->getRewardedQuests().end())
            {
                bot->CompleteQuest(25265, true, true);
                bot->CompleteQuest(25266, true, true);
                bot->CompleteQuest(25267, true, true);
                bot->CompleteQuest(25268, true, true);
            }
        });
    }
    if (bot->GetRace() == RACE_WORGEN && bot->GetLevel() == 1)
    {
        bot->AddDelayedEvent(5000, [bot]()
        {
            // -- force finish quest
            auto it = bot->getRewardedQuests().find(26706);
            if (it == bot->getRewardedQuests().end())
            {
                bot->CompleteQuest(26706, true, true);
                bot->CompleteQuest(14434, true, true);
            }
        });
    }

    if (bot->GetClass() == CLASS_DEATH_KNIGHT && bot->GetLevel() == 55)
    {
        bot->AddDelayedEvent(5000, [bot]()
        {
            // -- force finish quest
            auto it = bot->getRewardedQuests().find(13188);
            if (it == bot->getRewardedQuests().end() && bot->GetTeam() == Team::ALLIANCE)
                bot->CompleteQuest(13188, true, true);
            it = bot->getRewardedQuests().find(13189);
            if (it == bot->getRewardedQuests().end() && bot->GetTeam() == Team::HORDE)
                bot->CompleteQuest(13189, true, true);
        });
    }

    /*if (sPlayerbotAIConfig->randomBotFixedLevel)
    {
        bot->SetPlayerFlag(PLAYER_FLAGS_NO_XP_GAIN);
    }
    else
    {
        bot->RemovePlayerFlag(PLAYER_FLAGS_NO_XP_GAIN);
    }*/
}

void RandomPlayerbotMgr::OnPlayerLogin(Player* player)
{
    uint32 botsNearby = 0;

    for (PlayerBotMap::const_iterator it = GetPlayerBotsBegin(); it != GetPlayerBotsEnd(); ++it)
    {
        Player* const bot = it->second;
        if (player == bot /* || GET_PLAYERBOT_AI(player)*/)  // TEST
            continue;

        Cell playerCell(player->GetPositionX(), player->GetPositionY());
        Cell botCell(bot->GetPositionX(), bot->GetPositionY());

        // if (playerCell == botCell)
        // botsNearby++;

        Group* group = bot->GetGroup();
        if (!group)
            continue;

        for (GroupReference* gref = group->GetFirstMember(); gref; gref = gref->next())
        {
            Player* member = gref->GetSource();
            PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot);
            if (botAI && member == player && (!botAI->GetMaster() || GET_PLAYERBOT_AI(botAI->GetMaster())))
            {
                if (!bot->InBattleground())
                {
                    botAI->SetMaster(player);
                    botAI->ResetStrategies();
                    botAI->TellMaster("Hello");
                }

                break;
            }
        }
    }

    if (botsNearby > 100 && false)
    {
        WorldPosition botPos(player);

        if (!player->GetFactionTemplateEntry())
        {
            botPos.GetReachableRandomPointOnGround(player, sPlayerbotAIConfig->reactDistance * 2, true);
            player->TeleportTo(botPos);
        }
        else
        {
            /*std::vector<TravelDestination*> dests = sTravelMgr->getRpgTravelDestinations(player, true, true, 200000.0f);

            do
            {
                RpgTravelDestination* dest = (RpgTravelDestination*)dests[urand(0, dests.size() - 1)];
                CreatureTemplate const* cInfo = dest->GetCreatureTemplate();
                if (!cInfo)
                    continue;

                FactionTemplateEntry const* factionEntry = sFactionTemplateStore.LookupEntry(cInfo->faction);
                ReputationRank reaction = Unit::GetFactionReactionTo(player->GetFactionTemplateEntry(), factionEntry);

                if (reaction > REP_NEUTRAL && dest->nearestPoint(&botPos)->m_mapId == player->GetMapId())
                {
                    botPos = *dest->nearestPoint(&botPos);
                    break;
                }
            } while (true);*/
        }

        //player->TeleportTo(botPos);
    }

    if (!IsRandomBot(player))
    {
        if (std::find(_players.begin(), _players.end(), player) == _players.end())
        {
            _players.push_back(player);
            TC_LOG_DEBUG("playerbots", "Including non-random bot player %s into random bot update", player->GetName().c_str());
        }
    }
}

void RandomPlayerbotMgr::OnPlayerLoginError(uint32 bot)
{
    SetEventValue(bot, "add", 0, 0);
    _currentBots.erase(std::remove(_currentBots.begin(), _currentBots.end(), bot), _currentBots.end());
}

Player* RandomPlayerbotMgr::GetRandomPlayer()
{
    if (_players.empty())
        return nullptr;

    uint32 index = std::rand() % _players.size();
    return _players[index];
}

void RandomPlayerbotMgr::PrepareAddclassCache()
{
    if (sPlayerbotAIConfig->randomBotAccounts.empty())
    {
        TC_LOG_WARN("playerbots", "Unable to prepare add class cache as accounts are empty");
        return;
    }
    int32 maxAccountId = sPlayerbotAIConfig->randomBotAccounts.back();
    int32 minIdx = 0;
    int32 minAccountId = sPlayerbotAIConfig->randomBotAccounts[minIdx];
    if (minAccountId < 0)
    {
        TC_LOG_ERROR("playerbots", "No available account for add class!");
    }
    int32 collected = 0;
    for (uint8 claz = CLASS_WARRIOR; claz <= CLASS_DRUID; claz++)
    {
        if (claz == 10)
            continue;
        QueryResult results = CharacterDatabase.PQuery(
            "SELECT guid, race FROM characters "
            "WHERE account >= %u AND account <= %u AND class = '%u' AND online = 0 AND "
            "guid NOT IN ( SELECT guid FROM guild_member ) "
            "ORDER BY account DESC",
            minAccountId, maxAccountId, claz);
        if (results)
        {
            do
            {
                Field* fields = results->Fetch();
                ObjectGuid guid = ObjectGuid(HighGuid::Player, fields[0].GetUInt32());
                uint8 race = fields[1].GetUInt8();
                uint32 team = Player::TeamForRace(race);

                // Neutral pandaren do not belong in either faction-specific
                // addclass cache until their faction has been selected.
                if (team == PANDAREN_NEUTRAL)
                    continue;

                bool isAlliance = team == ALLIANCE;
                AddclassCache()[GetTeamClassIdx(isAlliance, claz)].push_back(guid);
                collected++;
            } while (results->NextRow());
        }
    }
    TC_LOG_INFO("playerbots", ">> %u characters collected for addclass command.", collected);
}

void RandomPlayerbotMgr::PrepareTeleportCache()
{
    uint32 zone_count = 0, farm_spot_count = 0, city_count = 0;
    QueryResult results = PlayerbotsDatabase.PQuery("SELECT ZoneId, ZoneTyp, MinLevel, MaxLevel, TeamsDisabled, MapId, MinPlayers, MaxPlayers FROM playerbot_farming_zone");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();

            uint32 zoneId = fields[0].GetUInt32();
            uint32 zoneType = fields[1].GetUInt32();
            uint32 minLevel = fields[2].GetUInt32();
            uint32 maxLevel = fields[3].GetUInt32();
            Team disabled = (Team)fields[4].GetUInt32();
            uint32 mapid = fields[5].GetUInt32();
            uint32 minPlayer = fields[6].GetUInt32();
            uint32 maxPlayer = fields[7].GetUInt32();

            farm_zone new_zone
            {
                zoneId,     /* ZoneId */
                zoneType,   /* ZoneType */
                minLevel,   /* MinLevel */
                maxLevel,   /* MaxLevel */
                disabled,   /* TeamDisabled */
                mapid,      /* MapId */
                minPlayer,  /* MinPlayer */
                maxPlayer   /* MaxPlayer */
            };

            _farm_cache_data.emplace_back(std::move(new_zone));
            zone_count++;
        } while (results->NextRow());
    }

    results = PlayerbotsDatabase.PQuery("SELECT ZoneId, Id, MinLevel, MaxLevel, TeamsDisabled, X, Y, Z, Radius FROM playerbot_farming_spot");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();

            uint32 zoneid = fields[0].GetUInt32();
            uint32 id = fields[1].GetUInt32();
            uint32 minLevel = fields[2].GetUInt32();
            uint32 maxLevel = fields[3].GetUInt32();
            Team disabled = (Team)fields[4].GetUInt32();
            float x = fields[5].GetFloat();
            float y = fields[6].GetFloat();
            float z = fields[7].GetFloat();
            uint32 radius = fields[8].GetUInt32();

            farm_spot new_spot
            {
                minLevel,   /* MinLevel */
                maxLevel,   /* MaxLevel */
                0,          /* MapId */
                x,          /* X */
                y,          /* Y */
                z           /* Z */
            };

            for (auto& zone_data : _farm_cache_data)
            {
                if (zone_data.zone_id == zoneid)
                {
                    new_spot.map_id = zone_data.map_id;
                    zone_data.spots.emplace_back(std::move(new_spot));
                    break;
                }
            }

            farm_spot_count++;
        } while (results->NextRow());
    }

    results = PlayerbotsDatabase.PQuery("SELECT ZoneId, CityId, MinLevel, MaxLevel, TeamsDisabled, X, Y, Z, Radius FROM playerbot_city");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();

            uint32 ZoneId = fields[0].GetUInt32();
            uint32 city_id = fields[1].GetUInt32();
            uint32 minLevel = fields[2].GetUInt32();
            uint32 maxLevel = fields[3].GetUInt32();
            Team disabled = (Team)fields[4].GetUInt32();
            float x = fields[5].GetFloat();
            float y = fields[6].GetFloat();
            float z = fields[7].GetFloat();
            uint32 radius = fields[8].GetUInt32();
            uint32 map_id = UINT32_MAX;

            for (auto& zone_data : _farm_cache_data)
            {
                if (zone_data.zone_id == ZoneId)
                {
                    map_id = zone_data.map_id;
                    break;
                }
            }

            if (map_id == UINT32_MAX)
            {
                TC_LOG_ERROR("server.loading", "City {%u} in ZoneId {%u} is not found in zone cache", city_id, ZoneId);
                continue;
            }

            city new_city
            {
                ZoneId,     /* ZoneId */
                city_id,    /* CityId */
                map_id,     /* map_id */
                minLevel,   /* MinLevel */
                maxLevel,   /* MaxLevel */
                disabled,   /* TeamDisabled */
                x,          /* X */
                y,          /* Y */
                z,          /* Z */
            };

            _city_cache_data.emplace_back(std::move(new_city));
            city_count++;
        } while (results->NextRow());
    }
    results = PlayerbotsDatabase.PQuery("SELECT Zone, PathId, PointId, X, Y, Z FROM playerbot_zone_path");
    if (results)
    {
        do
        {
            Field* fields = results->Fetch();

            uint32 ZoneId = fields[0].GetUInt32();
            uint32 PathId = fields[1].GetUInt32();
            uint32 PointId = fields[2].GetUInt32();
            float x = fields[3].GetFloat();
            float y = fields[4].GetFloat();
            float z = fields[5].GetFloat();

            farm_spot new_path
            {
                0,          /* MinLevel */
                0,          /* MaxLevel */
                0,          /* MapId */
                x,          /* X */
                y,          /* Y */
                z           /* Z */
            };

            for (auto& zone_data : _farm_cache_data)
            {
                if (zone_data.zone_id == ZoneId)
                {
                    new_path.map_id = zone_data.map_id;
                    new_path.min_level = zone_data.min_level;
                    new_path.max_level = zone_data.max_level;
                    zone_data.spots.emplace_back(std::move(new_path));
                    break;
                }
            }
        } while (results->NextRow());
    }

    TC_LOG_INFO("server.loading", ">> Loaded %u cache zone for %u farm spot", zone_count, farm_spot_count);
    TC_LOG_INFO("server.loading", ">> Loaded %u city zone", city_count);
}

void RandomPlayerbotMgr::RandomTeleportForLevel(Player* bot)
{
    if (!bot) return;

    // Teleport to city
    if (bot->GetLevel() >= 10 && urand(0, 100) < 0.25 * 100)
    {
        if (const auto city_data = GetCityForPlayer(bot))
        {
            Map* map = sMapMgr->FindMap(city_data->map_id, 0);

            bot->TeleportTo(city_data->map_id, city_data->x, city_data->y, city_data->z, 0.0f, 0);
            TC_LOG_INFO("playerbots", "Bot #%u <%s> teleported to City: map{%u} %f:%f:%f", bot->GetGUID().GetCounter(), bot->GetName().c_str(), city_data->map_id, city_data->x, city_data->y, city_data->z);
        }
        else if (const auto farm_spot = GetFarmZoneForPlayer(bot))
        {
            Map* map = sMapMgr->FindMap(farm_spot->map_id, 0);

            bot->TeleportTo(farm_spot->map_id, farm_spot->x, farm_spot->y, farm_spot->z, 0.0f, 0);
            TC_LOG_INFO("playerbots", "Bot #%u <%s> teleported to FarmSpot: map{%u} %f:%f:%f", bot->GetGUID().GetCounter(), bot->GetName().c_str(), farm_spot->map_id, farm_spot->x, farm_spot->y, farm_spot->z);
        }
    }
    else
    {
        if (const auto farm_zone = GetFarmZoneForPlayer(bot))
        {
            Map* map = sMapMgr->FindMap(farm_zone->map_id, 0);

            bot->TeleportTo(farm_zone->map_id, farm_zone->x, farm_zone->y, farm_zone->z, 0.0f, 0);
            TC_LOG_INFO("playerbots", "Bot #%u <%s> teleported to FarmZone: map{%u} %f:%f:%f", bot->GetGUID().GetCounter(), bot->GetName().c_str(), farm_zone->map_id, farm_zone->x, farm_zone->y, farm_zone->z);
        }
    }
}

const RandomPlayerbotMgr::city* RandomPlayerbotMgr::GetCityForPlayer(Player* player)
{
    if (_city_cache_data.empty()) return nullptr;

    std::mt19937 gen(std::chrono::system_clock::now().time_since_epoch().count());
    std::shuffle(_city_cache_data.begin(), _city_cache_data.end(), gen);

    for (const auto& city_data : _city_cache_data)
    {
        if (player->GetLevel() < city_data.min_level || player->GetLevel() > city_data.max_level || city_data.team_disabled == player->GetTeam())
            continue;
        return &city_data;
    }

    return nullptr;
}

const RandomPlayerbotMgr::farm_spot* RandomPlayerbotMgr::GetFarmZoneForPlayer(Player* player)
{
    if (_farm_cache_data.empty()) return nullptr;

    std::mt19937 gen(std::chrono::system_clock::now().time_since_epoch().count());
    std::shuffle(_farm_cache_data.begin(), _farm_cache_data.end(), gen);

    for (auto& zone : _farm_cache_data)
    {
        if (player->GetLevel() < zone.min_level || player->GetLevel() > zone.max_level || zone.team_disabled == player->GetTeam())
            continue;

        if (zone.max_player != 0)
        {
            uint32 playercount = 0;
            for (const auto& _internal_player : _players)
            {
                if (_internal_player && _internal_player->IsInWorld() && !_internal_player->IsBeingTeleported() && _internal_player->GetZoneId() == zone.zone_id && _internal_player != player)
                    ++playercount;
            }

            for (PlayerBotMap::const_iterator itr = GetPlayerBotsBegin(); itr != GetPlayerBotsEnd(); ++itr)
            {
                Player* const bot = itr->second;
                if (!bot || bot == player || !bot->IsInWorld() || bot->IsBeingTeleported()
                    || bot->GetZoneId() != zone.zone_id) continue;

                ++playercount;
            }

            if (zone.max_player <= playercount)
            {
                TC_LOG_DEBUG("playerbots", "Zone {%u} has too many players for: %s {%u} : %u/%u", zone.zone_id, player->GetName().c_str(), player->GetLevel(), playercount, zone.max_player);

                continue;
            }
        }

        auto& spots = zone.spots;
        std::shuffle(spots.begin(), spots.end(), gen);
        for (auto& spot : spots)
        {
            if (player->GetLevel() >= spot.min_level && player->GetLevel() <= spot.max_level)
            {
                // -- 
                TC_LOG_DEBUG("playerbots", "Farm spot found for : %s - level: %u", player->GetName().c_str(), player->GetLevel());
                return &spot;
            }
        }
    }

    TC_LOG_WARN("playerbots", "No valid zone farm found for %s level: %u", player->GetName().c_str(), player->GetLevel());
    return nullptr;
}
