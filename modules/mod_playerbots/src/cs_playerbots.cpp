/*
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

#include "Chat.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "GroupMgr.h"
#include "ItemPrototype.h"
#include "LFGMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotMgr.h"
#include "PerformanceMonitor.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <map>
#include <sstream>
#include <vector>

namespace
{
std::map<uint32, std::string> SoloArenaStagedBots;
uint32 SoloArenaStagedRequester = 0;
uint32 SoloArenaStagedTeammate = 0;
uint32 SoloArenaStagedOpponentHealer = 0;
uint32 SoloArenaStagedOpponentDamage = 0;
uint32 SoloArenaRequesterGroup = 0;
uint32 SoloArenaOpponentGroup = 0;

enum class SoloArenaPreviewRole : uint8
{
    None,
    Melee,
    Ranged,
    Healer
};

struct SoloArenaPreviewCandidate
{
    uint32 Guid = 0;
    std::string Name;
    uint8 Race = 0;
    uint8 Class = 0;
    uint8 Level = 0;
    uint32 Team = 0;
    Specializations Specialization = SPEC_NONE;
    SoloArenaPreviewRole Role = SoloArenaPreviewRole::None;
    uint32 EquippedItems = 0;
    uint32 AverageItemLevel = 0;
    uint32 PvpItems = 0;
    uint32 PvpPower = 0;
    uint32 Resilience = 0;

    uint32 GearScore() const
    {
        return PvpItems * 100000 + PvpPower + AverageItemLevel;
    }
};

SoloArenaPreviewRole GetSoloArenaPreviewRole(Specializations specialization)
{
    switch (specialization)
    {
        case SPEC_PALADIN_RETRIBUTION:
        case SPEC_WARRIOR_ARMS:
        case SPEC_WARRIOR_FURY:
        case SPEC_DRUID_FERAL:
        case SPEC_DEATH_KNIGHT_FROST:
        case SPEC_DEATH_KNIGHT_UNHOLY:
        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_ROGUE_COMBAT:
        case SPEC_ROGUE_SUBTLETY:
        case SPEC_SHAMAN_ENHANCEMENT:
        case SPEC_MONK_WINDWALKER:
            return SoloArenaPreviewRole::Melee;
        case SPEC_MAGE_ARCANE:
        case SPEC_MAGE_FIRE:
        case SPEC_MAGE_FROST:
        case SPEC_DRUID_BALANCE:
        case SPEC_HUNTER_BEAST_MASTERY:
        case SPEC_HUNTER_MARKSMANSHIP:
        case SPEC_HUNTER_SURVIVAL:
        case SPEC_PRIEST_SHADOW:
        case SPEC_SHAMAN_ELEMENTAL:
        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_WARLOCK_DESTRUCTION:
            return SoloArenaPreviewRole::Ranged;
        case SPEC_PALADIN_HOLY:
        case SPEC_DRUID_RESTORATION:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
        case SPEC_SHAMAN_RESTORATION:
        case SPEC_MONK_MISTWEAVER:
            return SoloArenaPreviewRole::Healer;
        default:
            return SoloArenaPreviewRole::None;
    }
}

bool IsSoloArenaDamage(SoloArenaPreviewRole role)
{
    return role == SoloArenaPreviewRole::Melee || role == SoloArenaPreviewRole::Ranged;
}

char const* SoloArenaRoleName(SoloArenaPreviewRole role)
{
    switch (role)
    {
        case SoloArenaPreviewRole::Melee:  return "melee";
        case SoloArenaPreviewRole::Ranged: return "ranged";
        case SoloArenaPreviewRole::Healer: return "healer";
        default:                           return "none";
    }
}

char const* SoloArenaTeamName(uint32 team)
{
    return team == ALLIANCE ? "Alliance" : "Horde";
}

void ReadSoloArenaGear(std::string const& cache, SoloArenaPreviewCandidate& candidate)
{
    std::istringstream stream(cache);
    uint32 itemEntry = 0;
    uint32 visibleValue = 0;
    uint32 itemLevelTotal = 0;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (!(stream >> itemEntry >> visibleValue))
            break;

        if (!itemEntry || slot == EQUIPMENT_SLOT_BODY || slot == EQUIPMENT_SLOT_TABARD)
            continue;

        ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemEntry);
        if (!item)
            continue;

        ++candidate.EquippedItems;
        itemLevelTotal += item->ItemLevel;

        bool pvpItem = false;
        for (uint8 stat = 0; stat < MAX_ITEM_PROTO_STATS; ++stat)
        {
            int32 value = std::max<int32>(0, item->ItemStat[stat].ItemStatValue);
            switch (item->ItemStat[stat].ItemStatType)
            {
                case ITEM_MOD_PVP_POWER:
                    candidate.PvpPower += value;
                    pvpItem = true;
                    break;
                case ITEM_MOD_RESILIENCE_RATING:
                    candidate.Resilience += value;
                    pvpItem = true;
                    break;
                default:
                    break;
            }
        }

        if (pvpItem)
            ++candidate.PvpItems;
    }

    if (candidate.EquippedItems)
        candidate.AverageItemLevel = itemLevelTotal / candidate.EquippedItems;
}

SoloArenaPreviewCandidate const* FindSoloArenaCandidate(
    std::vector<SoloArenaPreviewCandidate> const& candidates, SoloArenaPreviewRole wantedRole,
    uint32 wantedTeam, bool requireTeam, uint8 forbiddenClass,
    std::vector<uint32> const& excluded)
{
    for (SoloArenaPreviewCandidate const& candidate : candidates)
    {
        if (candidate.Role != wantedRole &&
            !(wantedRole == SoloArenaPreviewRole::Melee && IsSoloArenaDamage(candidate.Role)))
            continue;
        if (requireTeam && candidate.Team != wantedTeam)
            continue;
        if (forbiddenClass && candidate.Class == forbiddenClass)
            continue;
        if (std::find(excluded.begin(), excluded.end(), candidate.Guid) != excluded.end())
            continue;
        return &candidate;
    }

    return nullptr;
}
}

class playerbots_commandscript : public CommandScript
{
public:
    playerbots_commandscript() : CommandScript("playerbots_commandscript") {}

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> commandTable =
        {
            { "npcbot",         SEC_ADMINISTRATOR,          true,           &HandlePlayerbotCommand},
            { "pmon",           SEC_GAMEMASTER,             true,           &HandlePerfMonCommand},
            { "soloarena",      SEC_ADMINISTRATOR,          false,          &HandleSoloArenaCommand},
        };
        return commandTable;
    }

    static bool HandlePlayerbotCommand(ChatHandler* handler, char const* args)
    {
        return PlayerbotMgr::HandlePlayerbotMgrCommand(handler, args);
    }

    static bool HandleSoloArenaCommand(ChatHandler* handler, char const* args)
    {
        bool preview = args && !strcmp(args, "preview");
        bool login = args && !strcmp(args, "login");
        bool status = args && !strcmp(args, "status");
        bool logout = args && !strcmp(args, "logout");
        bool formGroups = args && !strcmp(args, "group");
        bool ungroup = args && !strcmp(args, "ungroup");
        if (!preview && !login && !status && !logout && !formGroups && !ungroup)
        {
            handler->SendSysMessage("Usage: .soloarena preview|login|status|group|ungroup|logout");
            return true;
        }

        Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (status)
        {
            if (SoloArenaStagedBots.empty())
            {
                handler->SendSysMessage("Solo Arena has no staged bots in this WorldServer process.");
                return true;
            }

            uint32 loadingCount = 0;
            uint32 onlineCount = 0;
            uint32 offlineCount = 0;
            for (auto const& staged : SoloArenaStagedBots)
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
                bool loadingBot = sRandomPlayerbotMgr->IsBotLoading(guid);
                Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
                char const* state = loadingBot ? "loading" : (bot ? "online" : "offline");
                loadingCount += loadingBot ? 1 : 0;
                onlineCount += bot ? 1 : 0;
                offlineCount += (!loadingBot && !bot) ? 1 : 0;
                handler->PSendSysMessage("Solo Arena staged bot %s (guid %u): %s, group=%s, queue=%s.",
                    staged.second.c_str(), staged.first, state,
                    bot && bot->GetGroup() ? "yes" : "no",
                    bot && (bot->InBattlegroundQueue() || bot->InBattleground()) ? "yes" : "no");
            }

            Group* requesterGroup = SoloArenaRequesterGroup ? sGroupMgr->GetGroupByGUID(SoloArenaRequesterGroup) : nullptr;
            Group* opponentGroup = SoloArenaOpponentGroup ? sGroupMgr->GetGroupByGUID(SoloArenaOpponentGroup) : nullptr;
            handler->PSendSysMessage(
                "Solo Arena staged status: total=%u, loading=%u, online=%u, offline=%u, "
                "requester-group=%u/%u, opponent-group=%u/%u.",
                uint32(SoloArenaStagedBots.size()), loadingCount, onlineCount, offlineCount,
                SoloArenaRequesterGroup, requesterGroup ? requesterGroup->GetMembersCount() : 0,
                SoloArenaOpponentGroup, opponentGroup ? opponentGroup->GetMembersCount() : 0);
            return true;
        }

        if (ungroup)
        {
            if (!SoloArenaRequesterGroup && !SoloArenaOpponentGroup)
            {
                handler->SendSysMessage("Solo Arena has no tracked staged groups to remove.");
                return true;
            }

            auto disbandTrackedGroup = [handler](uint32& groupId, uint32 firstGuid, uint32 secondGuid,
                                                 char const* label) -> bool
            {
                if (!groupId)
                    return true;

                Group* stagedGroup = sGroupMgr->GetGroupByGUID(groupId);
                if (!stagedGroup)
                {
                    handler->PSendSysMessage("Solo Arena %s group %u no longer exists; clearing its tracker.",
                        label, groupId);
                    groupId = 0;
                    return true;
                }

                ObjectGuid first = ObjectGuid::Create<HighGuid::Player>(firstGuid);
                ObjectGuid second = ObjectGuid::Create<HighGuid::Player>(secondGuid);
                if (!firstGuid || !secondGuid || stagedGroup->GetMembersCount() != 2 ||
                    !stagedGroup->IsMember(first) || !stagedGroup->IsMember(second))
                {
                    handler->PSendSysMessage(
                        "Refusing to disband Solo Arena %s group %u: its membership changed.", label, groupId);
                    return false;
                }

                uint32 removedGroupId = groupId;
                stagedGroup->Disband();
                groupId = 0;
                TC_LOG_INFO("server", "SoloArena staged %s group disbanded group=%u", label, removedGroupId);
                return true;
            };

            bool opponentRemoved = disbandTrackedGroup(SoloArenaOpponentGroup,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage, "opponent");
            bool requesterRemoved = disbandTrackedGroup(SoloArenaRequesterGroup,
                SoloArenaStagedRequester, SoloArenaStagedTeammate, "requester");
            handler->PSendSysMessage(
                "Solo Arena staged ungroup: requester=%s, opponent=%s, remaining-groups=%u.",
                requesterRemoved ? "removed" : "protected", opponentRemoved ? "removed" : "protected",
                uint32((SoloArenaRequesterGroup ? 1 : 0) + (SoloArenaOpponentGroup ? 1 : 0)));
            return true;
        }

        if (logout)
        {
            if (SoloArenaStagedBots.empty())
            {
                handler->SendSysMessage("Solo Arena has no staged bots to log out.");
                return true;
            }

            if (SoloArenaRequesterGroup || SoloArenaOpponentGroup)
            {
                handler->SendSysMessage(
                    "Solo Arena staged groups still exist. Use .soloarena ungroup before logout.");
                return true;
            }

            uint32 loggedOut = 0;
            uint32 removedOffline = 0;
            uint32 stillLoading = 0;
            uint32 protectedBots = 0;
            for (auto itr = SoloArenaStagedBots.begin(); itr != SoloArenaStagedBots.end();)
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(itr->first);
                if (sRandomPlayerbotMgr->IsBotLoading(guid))
                {
                    ++stillLoading;
                    ++itr;
                    continue;
                }

                Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
                if (bot && (bot->GetGroup() || bot->InBattlegroundQueue() || bot->InBattleground()))
                {
                    ++protectedBots;
                    handler->PSendSysMessage(
                        "Refusing to log out staged bot %s: it is grouped or in a battleground/queue.",
                        itr->second.c_str());
                    ++itr;
                    continue;
                }

                std::string name = itr->second;
                bool wasOnline = bot != nullptr;
                if (bot)
                {
                    sRandomPlayerbotMgr->LogoutPlayerBot(guid);
                    ++loggedOut;
                }
                else
                    ++removedOffline;

                TC_LOG_INFO("server", "SoloArena staged logout name=%s guid=%u state=%s",
                    name.c_str(), guid.GetCounter(), wasOnline ? "logged-out" : "already-offline");
                itr = SoloArenaStagedBots.erase(itr);
            }

            if (SoloArenaStagedBots.empty())
            {
                SoloArenaStagedRequester = 0;
                SoloArenaStagedTeammate = 0;
                SoloArenaStagedOpponentHealer = 0;
                SoloArenaStagedOpponentDamage = 0;
            }

            handler->PSendSysMessage(
                "Solo Arena staged cleanup: logged-out=%u, removed-offline=%u, still-loading=%u, protected=%u, remaining=%u.",
                loggedOut, removedOffline, stillLoading, protectedBots, uint32(SoloArenaStagedBots.size()));
            return true;
        }

        if (!sPlayerbotAIConfig->autoQueueEnabled || !sPlayerbotAIConfig->autoQueueArena ||
            !sPlayerbotAIConfig->autoQueueDryRun)
        {
            handler->SendSysMessage("Solo Arena preview requires AutoQueue.Enabled=1, Arena=1 and DryRun=1.");
            return true;
        }

        if (formGroups && (!sPlayerbotAIConfig->autoQueueArenaStageLogin ||
            !sPlayerbotAIConfig->autoQueueArenaStageGroup))
        {
            handler->SendSysMessage(
                "Solo Arena staged grouping is disabled. StageLogin=1 and StageGroup=1 are both required.");
            return true;
        }

        if (formGroups)
        {
            if (SoloArenaStagedBots.size() != 3 || !SoloArenaStagedRequester || !SoloArenaStagedTeammate ||
                !SoloArenaStagedOpponentHealer || !SoloArenaStagedOpponentDamage)
            {
                handler->SendSysMessage(
                    "Solo Arena needs one complete staged-login set before grouping. Use .soloarena login first.");
                return true;
            }

            if (player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Only the administrator character that created this staged set may form its groups.");
                return true;
            }

            if (SoloArenaRequesterGroup || SoloArenaOpponentGroup)
            {
                handler->SendSysMessage(
                    "Solo Arena staged groups already exist. Use .soloarena status or .soloarena ungroup.");
                return true;
            }

            auto hasQueueState = [](Player* stagedPlayer) -> bool
            {
                return stagedPlayer->InBattlegroundQueue() || stagedPlayer->InBattleground() ||
                    sLFGMgr->GetActiveState(stagedPlayer->GetGUID()) != lfg::LFG_STATE_NONE;
            };

            if (player->GetGroup() || hasQueueState(player))
            {
                handler->SendSysMessage(
                    "Solo Arena grouping refused: the requester already has a group or queue state.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);

            Player* stagedPlayers[] = { teammate, opponentHealer, opponentDamage };
            char const* stagedLabels[] = { "teammate", "opponent healer", "opponent damage" };
            for (uint8 index = 0; index < 3; ++index)
            {
                Player* stagedPlayer = stagedPlayers[index];
                if (!stagedPlayer || stagedPlayer->GetGroup() || hasQueueState(stagedPlayer))
                {
                    handler->PSendSysMessage(
                        "Solo Arena grouping refused: %s is offline or already has a group/queue state.",
                        stagedLabels[index]);
                    return true;
                }
            }

            Group* requesterGroup = new Group();
            if (!requesterGroup->Create(player))
            {
                delete requesterGroup;
                handler->SendSysMessage("Solo Arena could not create the requester group.");
                return true;
            }

            if (!requesterGroup->AddMember(teammate))
            {
                requesterGroup->Disband();
                handler->SendSysMessage(
                    "Solo Arena could not add the teammate; the requester group was rolled back.");
                return true;
            }

            Group* opponentGroup = new Group();
            if (!opponentGroup->Create(opponentHealer))
            {
                delete opponentGroup;
                requesterGroup->Disband();
                handler->SendSysMessage(
                    "Solo Arena could not create the opponent group; the requester group was rolled back.");
                return true;
            }

            if (!opponentGroup->AddMember(opponentDamage))
            {
                opponentGroup->Disband();
                requesterGroup->Disband();
                handler->SendSysMessage(
                    "Solo Arena could not add the opponent damage bot; both groups were rolled back.");
                return true;
            }

            SoloArenaRequesterGroup = requesterGroup->GetLowGUID();
            SoloArenaOpponentGroup = opponentGroup->GetLowGUID();
            TC_LOG_INFO("server",
                "SoloArena staged groups created requester-group=%u members=%s/%s opponent-group=%u members=%s/%s; no teleport or queue requested",
                SoloArenaRequesterGroup, player->GetName().c_str(), teammate->GetName().c_str(),
                SoloArenaOpponentGroup, opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str());
            handler->PSendSysMessage(
                "Solo Arena created requester group %u and opponent group %u. No teleport or queue was requested. "
                "Use .soloarena status, then .soloarena ungroup before logout.",
                SoloArenaRequesterGroup, SoloArenaOpponentGroup);
            return true;
        }

        if (login && !sPlayerbotAIConfig->autoQueueArenaStageLogin)
        {
            handler->SendSysMessage(
                "Solo Arena staged login is disabled. Set AiPlayerbot.AutoQueue.Arena.StageLogin=1 and restart.");
            return true;
        }

        if (login && !SoloArenaStagedBots.empty())
        {
            handler->SendSysMessage(
                "Solo Arena already has staged bots. Use .soloarena status and .soloarena logout first.");
            return true;
        }

        if (player->GetLevel() != DEFAULT_MAX_LEVEL)
        {
            handler->PSendSysMessage("Solo Arena preview currently supports level %u only.", DEFAULT_MAX_LEVEL);
            return true;
        }

        SoloArenaPreviewRole playerRole = GetSoloArenaPreviewRole(player->GetSpecialization());
        if (!IsSoloArenaDamage(playerRole) && playerRole != SoloArenaPreviewRole::Healer)
        {
            handler->SendSysMessage("Solo Arena preview requires an active damage or healer specialization.");
            return true;
        }

        if (sPlayerbotAIConfig->randomBotAccounts.empty())
        {
            handler->SendSysMessage("Solo Arena preview found no configured random-bot accounts.");
            return true;
        }

        uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
        uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
        QueryResult result = CharacterDatabase.PQuery(
            "SELECT guid, name, race, class, level, talentTree, activespec, equipmentCache "
            "FROM characters WHERE account >= %u AND account <= %u AND level = %u AND online = 0 "
            "AND guid NOT IN (SELECT guid FROM guild_member) "
            "AND guid NOT IN (SELECT memberGuid FROM group_member)",
            minAccount, maxAccount, player->GetLevel());

        if (!result)
        {
            handler->SendSysMessage("Solo Arena preview found no unused offline random-bot characters.");
            return true;
        }

        std::vector<SoloArenaPreviewCandidate> candidates;
        uint32 rejectedNeutral = 0;
        uint32 rejectedSpec = 0;
        uint32 rejectedGear = 0;

        do
        {
            Field* fields = result->Fetch();
            SoloArenaPreviewCandidate candidate;
            candidate.Guid = fields[0].GetUInt32();
            candidate.Name = fields[1].GetString();
            candidate.Race = fields[2].GetUInt8();
            candidate.Class = fields[3].GetUInt8();
            candidate.Level = fields[4].GetUInt8();
            candidate.Team = Player::TeamForRace(candidate.Race);

            if (candidate.Team == PANDAREN_NEUTRAL)
            {
                ++rejectedNeutral;
                continue;
            }

            uint32 specs[MAX_TALENT_SPECS] = { 0, 0 };
            std::istringstream talentTrees(fields[5].GetString());
            for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
                talentTrees >> specs[spec];

            uint8 activeSpec = fields[6].GetUInt8();
            if (activeSpec >= MAX_TALENT_SPECS)
                activeSpec = 0;
            candidate.Specialization = Specializations(specs[activeSpec]);
            candidate.Role = GetSoloArenaPreviewRole(candidate.Specialization);
            if (!IsSoloArenaDamage(candidate.Role) && candidate.Role != SoloArenaPreviewRole::Healer)
            {
                ++rejectedSpec;
                continue;
            }

            ReadSoloArenaGear(fields[7].GetString(), candidate);
            if (candidate.EquippedItems < sPlayerbotAIConfig->autoQueueArenaMinEquippedItems ||
                candidate.AverageItemLevel < sPlayerbotAIConfig->autoQueueArenaMinAverageItemLevel ||
                candidate.PvpItems < sPlayerbotAIConfig->autoQueueArenaMinPvpItems)
            {
                ++rejectedGear;
                continue;
            }

            candidates.push_back(candidate);
        }
        while (result->NextRow());

        std::sort(candidates.begin(), candidates.end(),
            [](SoloArenaPreviewCandidate const& left, SoloArenaPreviewCandidate const& right)
            {
                return left.GearScore() > right.GearScore();
            });

        std::vector<uint32> selected;
        SoloArenaPreviewRole teammateRole = playerRole == SoloArenaPreviewRole::Healer ? SoloArenaPreviewRole::Melee : SoloArenaPreviewRole::Healer;
        SoloArenaPreviewCandidate const* teammate = FindSoloArenaCandidate(
            candidates, teammateRole, player->GetTeam(), true, player->GetClass(), selected);
        if (teammate)
            selected.push_back(teammate->Guid);

        SoloArenaPreviewCandidate const* opponentHealer = FindSoloArenaCandidate(
            candidates, SoloArenaPreviewRole::Healer, 0, false, 0, selected);
        if (opponentHealer)
            selected.push_back(opponentHealer->Guid);

        SoloArenaPreviewCandidate const* opponentDamage = FindSoloArenaCandidate(
            candidates, SoloArenaPreviewRole::Melee,
            opponentHealer ? opponentHealer->Team : 0, opponentHealer != nullptr,
            opponentHealer ? opponentHealer->Class : 0, selected);

        TC_LOG_INFO("server",
            "SoloArena 2v2 preview requester=%s role=%s faction=%s eligible=%u rejected(neutral/spec/gear)=%u/%u/%u",
            player->GetName().c_str(), SoloArenaRoleName(playerRole), SoloArenaTeamName(player->GetTeam()),
            uint32(candidates.size()), rejectedNeutral, rejectedSpec, rejectedGear);

        if (!teammate || !opponentHealer || !opponentDamage)
        {
            handler->PSendSysMessage(
                "Solo Arena preview could not form 2v2: teammate=%s, opponent healer=%s, opponent damage=%s. "
                "Eligible=%u; rejected neutral/spec/gear=%u/%u/%u.",
                teammate ? "yes" : "no", opponentHealer ? "yes" : "no", opponentDamage ? "yes" : "no",
                uint32(candidates.size()), rejectedNeutral, rejectedSpec, rejectedGear);
            return true;
        }

        auto report = [](char const* position, SoloArenaPreviewCandidate const* candidate)
        {
            TC_LOG_INFO("server",
                "SoloArena 2v2 preview %s=%s guid=%u faction=%s class=%u spec=%u role=%s gear=%u avg-ilvl=%u pvp-items=%u pvp-power=%u resilience=%u",
                position, candidate->Name.c_str(), candidate->Guid, SoloArenaTeamName(candidate->Team),
                candidate->Class, uint32(candidate->Specialization), SoloArenaRoleName(candidate->Role),
                candidate->EquippedItems, candidate->AverageItemLevel, candidate->PvpItems,
                candidate->PvpPower, candidate->Resilience);
        };

        report("teammate", teammate);
        report("opponent-healer", opponentHealer);
        report("opponent-damage", opponentDamage);

        if (preview)
        {
            handler->PSendSysMessage(
                "Dry-run only: teammate %s; opponents %s and %s. No bot was logged in, changed, grouped or queued.",
                teammate->Name.c_str(), opponentHealer->Name.c_str(), opponentDamage->Name.c_str());
            return true;
        }

        SoloArenaPreviewCandidate const* stagedCandidates[] = { teammate, opponentHealer, opponentDamage };
        for (SoloArenaPreviewCandidate const* candidate : stagedCandidates)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(candidate->Guid);
            if (ObjectAccessor::FindPlayer(guid) || sRandomPlayerbotMgr->GetPlayerBot(guid) ||
                sRandomPlayerbotMgr->IsBotLoading(guid))
            {
                handler->PSendSysMessage(
                    "Solo Arena staged login aborted: candidate %s is already online or loading. No new login was requested.",
                    candidate->Name.c_str());
                return true;
            }
        }

        SoloArenaStagedRequester = player->GetGUID().GetCounter();
        SoloArenaStagedTeammate = teammate->Guid;
        SoloArenaStagedOpponentHealer = opponentHealer->Guid;
        SoloArenaStagedOpponentDamage = opponentDamage->Guid;

        for (SoloArenaPreviewCandidate const* candidate : stagedCandidates)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(candidate->Guid);
            SoloArenaStagedBots[candidate->Guid] = candidate->Name;
            sRandomPlayerbotMgr->AddPlayerBot(guid, 0);
            TC_LOG_INFO("server",
                "SoloArena staged login requested name=%s guid=%u faction=%s role=%s; no group, teleport or queue requested",
                candidate->Name.c_str(), candidate->Guid, SoloArenaTeamName(candidate->Team),
                SoloArenaRoleName(candidate->Role));
        }

        handler->PSendSysMessage(
            "Staged login requested for %s, %s and %s. Wait a few seconds, then use .soloarena status. "
            "No group, teleport or queue was requested. Finish with .soloarena logout.",
            teammate->Name.c_str(), opponentHealer->Name.c_str(), opponentDamage->Name.c_str());
        return true;
    }

    static bool HandlePerfMonCommand(ChatHandler* handler, char const* args)
    {
        if (!strcmp(args, "reset"))
        {
            sPerformanceMonitor->Reset();
            return true;
        }

        if (!strcmp(args, "tick"))
        {
            sPerformanceMonitor->PrintStats(true, false);
            return true;
        }

        if (!strcmp(args, "stack"))
        {
            sPerformanceMonitor->PrintStats(false, true);
            return true;
        }

        if (!strcmp(args, "toggle"))
        {
            sPlayerbotAIConfig->perfMonEnabled = !sPlayerbotAIConfig->perfMonEnabled;
            if (sPlayerbotAIConfig->perfMonEnabled)
                TC_LOG_INFO("playerbots", "Performance monitor enabled");
            else
                TC_LOG_INFO("playerbots", "Performance monitor disabled");
            return true;
        }

        sPerformanceMonitor->PrintStats();
        return true;
    }
};

void AddSC_playerbots_commandscript() { new playerbots_commandscript(); }
