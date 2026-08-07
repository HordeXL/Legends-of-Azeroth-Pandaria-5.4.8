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
#include "BattlegroundMgr.h"
#include "BattlegroundQueue.h"
#include "DatabaseEnv.h"
#include "DisableMgr.h"
#include "Group.h"
#include "GroupMgr.h"
#include "ItemPrototype.h"
#include "LFGMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotMgr.h"
#include "PerformanceMonitor.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <map>
#include <set>
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
bool SoloArenaQueuesStaged = false;
bool SoloArenaMatchScheduled = false;
uint32 SoloArenaEnteredInstance = 0;
uint32 SoloArenaAutomaticExitTimer = 0;
std::set<uint32> SoloArenaAutomaticHealthRestoreScheduled;

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

struct SoloArenaLoadoutPlan
{
    Specializations Specialization;
    uint32 ItemSet;
    std::array<uint32, 5> AllianceItems;
    std::array<uint32, 5> HordeItems;
};

SoloArenaLoadoutPlan const* GetSoloArenaLoadoutPlan(Specializations specialization)
{
    // Season 15 Prideful five-piece sets. Item order is head, shoulders,
    // chest/robe, legs and hands. Alliance and Horde entries share the same
    // ItemSet but retain their faction-specific appearances.
    static SoloArenaLoadoutPlan const plans[] =
    {
        { SPEC_DEATH_KNIGHT_FROST, 1104, {{ 102713, 102652, 102676, 102651, 102650 }}, {{ 103378, 103380, 103376, 103379, 103377 }} },
        { SPEC_DEATH_KNIGHT_UNHOLY, 1104, {{ 102713, 102652, 102676, 102651, 102650 }}, {{ 103378, 103380, 103376, 103379, 103377 }} },
        { SPEC_DRUID_RESTORATION, 1105, {{ 102776, 102658, 102721, 102761, 102657 }}, {{ 103390, 103393, 103392, 103391, 103389 }} },
        { SPEC_DRUID_FERAL, 1106, {{ 102653, 102741, 102740, 102654, 102739 }}, {{ 103382, 103385, 103384, 103383, 103381 }} },
        { SPEC_DRUID_BALANCE, 1107, {{ 102634, 102700, 102614, 102767, 102696 }}, {{ 103399, 103402, 103401, 103400, 103398 }} },
        { SPEC_HUNTER_BEAST_MASTERY, 1108, {{ 102690, 102734, 102689, 102670, 102737 }}, {{ 103418, 103420, 103416, 103419, 103417 }} },
        { SPEC_HUNTER_MARKSMANSHIP, 1108, {{ 102690, 102734, 102689, 102670, 102737 }}, {{ 103418, 103420, 103416, 103419, 103417 }} },
        { SPEC_HUNTER_SURVIVAL, 1108, {{ 102690, 102734, 102689, 102670, 102737 }}, {{ 103418, 103420, 103416, 103419, 103417 }} },
        { SPEC_MAGE_ARCANE, 1109, {{ 102667, 102673, 102715, 102648, 102735 }}, {{ 103422, 103425, 103424, 103423, 103421 }} },
        { SPEC_MAGE_FIRE, 1109, {{ 102667, 102673, 102715, 102648, 102735 }}, {{ 103422, 103425, 103424, 103423, 103421 }} },
        { SPEC_MAGE_FROST, 1109, {{ 102667, 102673, 102715, 102648, 102735 }}, {{ 103422, 103425, 103424, 103423, 103421 }} },
        { SPEC_PALADIN_HOLY, 1110, {{ 102635, 102697, 102632, 102768, 102722 }}, {{ 103452, 103454, 103450, 103453, 103451 }} },
        { SPEC_PALADIN_RETRIBUTION, 1111, {{ 102779, 102744, 102747, 102780, 102630 }}, {{ 103441, 103443, 103439, 103442, 103440 }} },
        { SPEC_PRIEST_DISCIPLINE, 1112, {{ 102703, 102750, 102681, 102704, 102615 }}, {{ 103463, 103466, 103465, 103464, 103462 }} },
        { SPEC_PRIEST_HOLY, 1112, {{ 102703, 102750, 102681, 102704, 102615 }}, {{ 103463, 103466, 103465, 103464, 103462 }} },
        { SPEC_ROGUE_ASSASSINATION, 1113, {{ 102710, 102731, 102727, 102730, 102663 }}, {{ 103477, 103479, 103475, 103478, 103476 }} },
        { SPEC_ROGUE_COMBAT, 1113, {{ 102710, 102731, 102727, 102730, 102663 }}, {{ 103477, 103479, 103475, 103478, 103476 }} },
        { SPEC_ROGUE_SUBTLETY, 1113, {{ 102710, 102731, 102727, 102730, 102663 }}, {{ 103477, 103479, 103475, 103478, 103476 }} },
        { SPEC_SHAMAN_RESTORATION, 1114, {{ 102718, 102655, 102717, 102719, 102774 }}, {{ 103487, 103489, 103485, 103488, 103486 }} },
        { SPEC_SHAMAN_ENHANCEMENT, 1115, {{ 102714, 102629, 102759, 102778, 102742 }}, {{ 103492, 103494, 103490, 103493, 103491 }} },
        { SPEC_SHAMAN_ELEMENTAL, 1116, {{ 102693, 102637, 102743, 102781, 102692 }}, {{ 103498, 103500, 103496, 103499, 103497 }} },
        { SPEC_WARLOCK_AFFLICTION, 1117, {{ 102726, 102682, 102661, 102755, 102725 }}, {{ 103521, 103524, 103523, 103522, 103520 }} },
        { SPEC_WARLOCK_DEMONOLOGY, 1117, {{ 102726, 102682, 102661, 102755, 102725 }}, {{ 103521, 103524, 103523, 103522, 103520 }} },
        { SPEC_WARLOCK_DESTRUCTION, 1117, {{ 102726, 102682, 102661, 102755, 102725 }}, {{ 103521, 103524, 103523, 103522, 103520 }} },
        { SPEC_WARRIOR_ARMS, 1118, {{ 102619, 102685, 102728, 102732, 102618 }}, {{ 103527, 103529, 103525, 103528, 103526 }} },
        { SPEC_WARRIOR_FURY, 1118, {{ 102619, 102685, 102728, 102732, 102618 }}, {{ 103527, 103529, 103525, 103528, 103526 }} },
        { SPEC_MONK_MISTWEAVER, 1119, {{ 102628, 102777, 102763, 102762, 102627 }}, {{ 103435, 103437, 103438, 103436, 103434 }} },
        { SPEC_MONK_WINDWALKER, 1120, {{ 102712, 102626, 102720, 102656, 102675 }}, {{ 103430, 103432, 103433, 103431, 103429 }} },
        { SPEC_PRIEST_SHADOW, 1146, {{ 102751, 102671, 102622, 102621, 102707 }}, {{ 103468, 103471, 103470, 103469, 103467 }} }
    };

    for (SoloArenaLoadoutPlan const& plan : plans)
        if (plan.Specialization == specialization)
            return &plan;

    return nullptr;
}

bool IsSoloArenaLoadoutInventoryType(uint8 index, uint32 inventoryType)
{
    static uint32 const expected[] =
    {
        INVTYPE_HEAD, INVTYPE_SHOULDERS, INVTYPE_CHEST, INVTYPE_LEGS, INVTYPE_HANDS
    };

    return index == 2 ? (inventoryType == INVTYPE_CHEST || inventoryType == INVTYPE_ROBE) :
        inventoryType == expected[index];
}

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

char const* SoloArenaBattlegroundStatusName(BattlegroundStatus status)
{
    switch (status)
    {
        case STATUS_NONE:        return "NONE";
        case STATUS_WAIT_QUEUE:  return "WAIT_QUEUE";
        case STATUS_WAIT_JOIN:   return "WAIT_JOIN";
        case STATUS_IN_PROGRESS: return "IN_PROGRESS";
        case STATUS_WAIT_LEAVE:  return "WAIT_LEAVE";
        default:                 return "UNKNOWN";
    }
}

char const* SoloArenaBotStateName(PlayerbotAI* botAI)
{
    if (!botAI)
        return "real-player";

    switch (botAI->GetState())
    {
        case BOT_STATE_COMBAT:     return "combat";
        case BOT_STATE_NON_COMBAT: return "non-combat";
        case BOT_STATE_DEAD:       return "dead";
        default:                   return "unknown";
    }
}

bool IsSoloArenaTrackedParticipant(uint32 guid)
{
    return guid && (guid == SoloArenaStagedRequester || guid == SoloArenaStagedTeammate ||
        guid == SoloArenaStagedOpponentHealer || guid == SoloArenaStagedOpponentDamage);
}

bool ScheduleSoloArenaAutomaticHealthRestore(Player* participant, char const* reason)
{
    if (!participant || !IsSoloArenaTrackedParticipant(participant->GetGUID().GetCounter()) ||
        !SoloArenaEnteredInstance || participant->GetBattlegroundId() != SoloArenaEnteredInstance)
        return false;

    uint32 guid = participant->GetGUID().GetCounter();
    if (!SoloArenaAutomaticHealthRestoreScheduled.insert(guid).second)
        return false;

    participant->ScheduleBattlegroundHealthRestore();
    TC_LOG_INFO("server",
        "SoloArena automatic post-match health restore scheduled instance=%u name=%s guid=%u reason=%s",
        SoloArenaEnteredInstance, participant->GetName().c_str(), guid, reason);
    return true;
}

bool HasExactSoloArenaQueueGroup(BattlegroundQueue& queue, uint32 firstGuid, uint32 secondGuid,
                                 uint32& invitedInstance)
{
    GroupQueueInfo firstInfo;
    GroupQueueInfo secondInfo;
    ObjectGuid first = ObjectGuid::Create<HighGuid::Player>(firstGuid);
    ObjectGuid second = ObjectGuid::Create<HighGuid::Player>(secondGuid);
    if (!queue.GetPlayerGroupInfoData(first, &firstInfo) ||
        !queue.GetPlayerGroupInfoData(second, &secondInfo))
        return false;

    auto isExact = [first, second](GroupQueueInfo const& info) -> bool
    {
        return info.BgTypeId == BATTLEGROUND_AA && info.ArenaType == ARENA_TYPE_2v2 &&
            !info.IsRated && info.Players.size() == 2 &&
            info.Players.find(first) != info.Players.end() &&
            info.Players.find(second) != info.Players.end();
    };

    if (!isExact(firstInfo) || !isExact(secondInfo) || firstInfo.JoinTime != secondInfo.JoinTime ||
        firstInfo.IsInvitedToBGInstanceGUID != secondInfo.IsInvitedToBGInstanceGUID)
        return false;

    invitedInstance = firstInfo.IsInvitedToBGInstanceGUID;
    return true;
}

bool AcceptSoloArenaInvite(Player* participant, uint32 invitedInstance)
{
    if (!participant || !participant->GetSession() || !invitedInstance ||
        participant->InBattleground() || participant->IsBeingTeleported() ||
        !participant->IsInvitedForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
        return false;

    uint32 queueSlot = participant->GetBattlegroundQueueIndex(BATTLEGROUND_QUEUE_2v2);
    if (queueSlot >= PLAYER_MAX_BATTLEGROUND_QUEUES)
        return false;

    ObjectGuid guid = participant->GetGUID();
    WorldPacket packet(CMSG_BATTLEFIELD_PORT, 32);
    packet << uint8(1) << uint32(queueSlot) << uint32(0) << uint32(0);

    packet.WriteBit(guid[6]);
    packet.WriteBit(guid[4]);
    packet.WriteBit(guid[2]);
    packet.WriteBit(guid[5]);
    packet.WriteBit(guid[0]);
    packet.WriteBit(guid[1]);
    packet.WriteBit(guid[7]);
    packet.WriteBit(guid[3]);
    packet.FlushBits();

    packet.WriteByteSeq(guid[2]);
    packet.WriteByteSeq(guid[5]);
    packet.WriteByteSeq(guid[3]);
    packet.WriteByteSeq(guid[0]);
    packet.WriteByteSeq(guid[7]);
    packet.WriteByteSeq(guid[4]);
    packet.WriteByteSeq(guid[6]);
    packet.WriteByteSeq(guid[1]);

    participant->GetSession()->HandleBattleFieldPortOpcode(packet);
    return participant->GetBattlegroundId() == invitedInstance && participant->IsBeingTeleported();
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

void HandleSoloArenaClientLeave(Player* player)
{
    if (!sPlayerbotAIConfig->autoQueueArenaStageAutomaticExit || !player ||
        !SoloArenaEnteredInstance || !IsSoloArenaTrackedParticipant(player->GetGUID().GetCounter()))
        return;

    Battleground* arena = player->GetBattleground();
    if (!arena || !arena->IsArena() || arena->GetInstanceID() != SoloArenaEnteredInstance ||
        arena->GetStatus() != STATUS_WAIT_LEAVE)
        return;

    ScheduleSoloArenaAutomaticHealthRestore(player, "client-leave");
}

void UpdateSoloArenaAutomaticExit(uint32 diff)
{
    if (!sPlayerbotAIConfig->autoQueueArenaStageAutomaticExit || !SoloArenaEnteredInstance)
    {
        SoloArenaAutomaticExitTimer = 0;
        return;
    }

    if (SoloArenaAutomaticExitTimer > diff)
    {
        SoloArenaAutomaticExitTimer -= diff;
        return;
    }
    SoloArenaAutomaticExitTimer = 250;

    uint32 instanceId = SoloArenaEnteredInstance;
    Battleground* arena = sBattlegroundMgr->GetBattleground(instanceId, BATTLEGROUND_TYPE_NONE);
    if (arena && arena->IsArena() && arena->GetStatus() == STATUS_WAIT_LEAVE)
    {
        uint32 participantGuids[] = { SoloArenaStagedRequester, SoloArenaStagedTeammate,
            SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage };
        for (uint32 guid : participantGuids)
        {
            Player* participant = guid ? ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
            ScheduleSoloArenaAutomaticHealthRestore(participant, "wait-leave");

            // The real requester keeps the normal client Leave Arena button. Playerbot
            // sessions do not send that packet and can remain in the completed Arena
            // after the core auto-close timer, so remove only the three exact staged
            // bots through the same Player::LeaveBattleground path used by the command.
            if (participant && guid != SoloArenaStagedRequester &&
                participant->GetBattlegroundId() == instanceId)
            {
                participant->LeaveBattleground(true);
                TC_LOG_INFO("server",
                    "SoloArena automatic staged-bot exit requested instance=%u name=%s guid=%u",
                    instanceId, participant->GetName().c_str(), guid);
            }
        }
    }

    bool pendingExit = false;
    uint32 participantGuids[] = { SoloArenaStagedRequester, SoloArenaStagedTeammate,
        SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage };
    for (uint32 guid : participantGuids)
    {
        Player* participant = guid ? ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
        if (participant && (participant->GetBattlegroundId() == instanceId ||
            participant->IsBeingTeleported() ||
            participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2)))
        {
            pendingExit = true;
            break;
        }
    }

    if (pendingExit)
        return;

    TC_LOG_INFO("server",
        "SoloArena automatic post-match exit finalized instance=%u health-restore-scheduled=%u; groups and staged logins remain for explicit cleanup",
        instanceId, uint32(SoloArenaAutomaticHealthRestoreScheduled.size()));
    SoloArenaEnteredInstance = 0;
    SoloArenaQueuesStaged = false;
    SoloArenaMatchScheduled = false;
    SoloArenaAutomaticHealthRestoreScheduled.clear();
    SoloArenaAutomaticExitTimer = 0;
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
        bool loadoutAudit = args && !strcmp(args, "loadout");
        bool logout = args && !strcmp(args, "logout");
        bool formGroups = args && !strcmp(args, "group");
        bool ungroup = args && !strcmp(args, "ungroup");
        bool stageQueue = args && !strcmp(args, "queue");
        bool forceTolviron = args && !strcmp(args, "match tolviron");
        bool stageMatch = (args && !strcmp(args, "match")) || forceTolviron;
        bool stageEnter = args && !strcmp(args, "enter");
        bool combatStatus = args && !strcmp(args, "combatstatus");
        bool leaveArena = args && !strcmp(args, "leave");
        bool unstageQueue = args && !strcmp(args, "unqueue");
        if (!preview && !login && !status && !loadoutAudit && !logout && !formGroups && !ungroup &&
            !stageQueue && !stageMatch && !stageEnter && !combatStatus && !leaveArena && !unstageQueue)
        {
            handler->SendSysMessage(
                "Usage: .soloarena preview|login|status|loadout|group|queue|match [tolviron]|enter|combatstatus|leave|unqueue|ungroup|logout");
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
            bool requesterQueued = player->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2);
            uint32 requesterInvite = 0;
            uint32 opponentInvite = 0;
            bool requesterExact = false;
            bool opponentExact = false;
            if (SoloArenaQueuesStaged)
            {
                BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(BATTLEGROUND_QUEUE_2v2);
                requesterExact = HasExactSoloArenaQueueGroup(arenaQueue,
                    SoloArenaStagedRequester, SoloArenaStagedTeammate, requesterInvite);
                opponentExact = HasExactSoloArenaQueueGroup(arenaQueue,
                    SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage, opponentInvite);
            }

            uint32 insideCount = 0;
            uint32 teleportingCount = 0;
            uint32 otherInstanceCount = 0;
            uint32 participantGuids[] = { SoloArenaStagedRequester, SoloArenaStagedTeammate,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage };
            for (uint32 participantGuid : participantGuids)
            {
                Player* participant = participantGuid ? ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(participantGuid)) : nullptr;
                if (!participant)
                    continue;

                if (participant->IsBeingTeleported())
                    ++teleportingCount;
                if (SoloArenaEnteredInstance && participant->GetBattlegroundId() == SoloArenaEnteredInstance)
                    ++insideCount;
                else if (participant->GetBattlegroundId())
                    ++otherInstanceCount;
            }
            handler->PSendSysMessage(
                "Solo Arena staged status: total=%u, loading=%u, online=%u, offline=%u, "
                "requester-group=%u/%u, opponent-group=%u/%u, staged-queue=%s, requester-2v2=%s, "
                "match-scheduled=%s, exact-queues=%s/%s, invite-instances=%u/%u, "
                "entered-instance=%u, inside=%u, teleporting=%u, other-instance=%u.",
                uint32(SoloArenaStagedBots.size()), loadingCount, onlineCount, offlineCount,
                SoloArenaRequesterGroup, requesterGroup ? requesterGroup->GetMembersCount() : 0,
                SoloArenaOpponentGroup, opponentGroup ? opponentGroup->GetMembersCount() : 0,
                SoloArenaQueuesStaged ? "yes" : "no", requesterQueued ? "yes" : "no",
                SoloArenaMatchScheduled ? "yes" : "no", requesterExact ? "yes" : "no",
                opponentExact ? "yes" : "no", requesterInvite, opponentInvite,
                SoloArenaEnteredInstance, insideCount, teleportingCount, otherInstanceCount);
            return true;
        }

        if (loadoutAudit)
        {
            if (SoloArenaStagedBots.size() != 3 || !SoloArenaStagedRequester ||
                player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Solo Arena loadout audit requires this requester's complete staged-login set. Use .soloarena login first.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* participants[] =
            {
                player,
                sRandomPlayerbotMgr->GetPlayerBot(teammateGuid),
                sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid),
                sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid)
            };
            char const* labels[] = { "requester", "teammate", "opponent-healer", "opponent-damage" };
            uint8 const equipmentSlots[] =
            {
                EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_SHOULDERS, EQUIPMENT_SLOT_CHEST,
                EQUIPMENT_SLOT_LEGS, EQUIPMENT_SLOT_HANDS
            };

            uint32 completePlans = 0;
            for (uint8 participantIndex = 0; participantIndex < 4; ++participantIndex)
            {
                Player* participant = participants[participantIndex];
                if (!participant)
                {
                    handler->PSendSysMessage("Solo Arena loadout %s: offline.", labels[participantIndex]);
                    continue;
                }

                SoloArenaLoadoutPlan const* plan = GetSoloArenaLoadoutPlan(participant->GetSpecialization());
                if (!plan)
                {
                    handler->PSendSysMessage(
                        "Solo Arena loadout %s %s: no mapped set for class=%u spec=%u.",
                        labels[participantIndex], participant->GetName().c_str(), participant->GetClass(),
                        uint32(participant->GetSpecialization()));
                    continue;
                }

                std::array<uint32, 5> const& plannedItems = participant->GetTeam() == ALLIANCE ?
                    plan->AllianceItems : plan->HordeItems;
                uint32 currentPieces = 0;
                uint32 validPlannedItems = 0;
                std::ostringstream entries;
                for (uint8 itemIndex = 0; itemIndex < plannedItems.size(); ++itemIndex)
                {
                    if (itemIndex)
                        entries << '/';
                    entries << plannedItems[itemIndex];

                    if (Item* equipped = participant->GetItemByPos(
                        INVENTORY_SLOT_BAG_0, equipmentSlots[itemIndex]))
                        if (equipped->GetTemplate()->ItemSet == plan->ItemSet)
                            ++currentPieces;

                    ItemTemplate const* item = sObjectMgr->GetItemTemplate(plannedItems[itemIndex]);
                    if (!item || item->ItemSet != plan->ItemSet ||
                        !IsSoloArenaLoadoutInventoryType(itemIndex, item->InventoryType) ||
                        !(uint32(item->AllowableClass) & (1u << (participant->GetClass() - 1))) ||
                        participant->CanUseItem(item) != EQUIP_ERR_OK)
                        continue;

                    ++validPlannedItems;
                }

                if (validPlannedItems == plannedItems.size())
                    ++completePlans;

                handler->PSendSysMessage(
                    "Solo Arena loadout %s %s: faction=%s class=%u spec=%u target-set=%u current=%u/5 valid=%u/5 entries=%s.",
                    labels[participantIndex], participant->GetName().c_str(),
                    SoloArenaTeamName(participant->GetTeam()), participant->GetClass(),
                    uint32(participant->GetSpecialization()), plan->ItemSet, currentPieces,
                    validPlannedItems, entries.str().c_str());
                TC_LOG_INFO("server",
                    "SoloArena loadout audit label=%s name=%s guid=%u faction=%s class=%u spec=%u target-set=%u current=%u/5 valid=%u/5 entries=%s",
                    labels[participantIndex], participant->GetName().c_str(),
                    participant->GetGUID().GetCounter(), SoloArenaTeamName(participant->GetTeam()),
                    participant->GetClass(), uint32(participant->GetSpecialization()), plan->ItemSet,
                    currentPieces, validPlannedItems, entries.str().c_str());
            }

            handler->PSendSysMessage(
                "Dry-run only: %u/4 complete five-piece plans validated. No item was created, moved, equipped, saved or deleted.",
                completePlans);
            return true;
        }

        if (combatStatus)
        {
            if (!sPlayerbotAIConfig->autoQueueArenaStageCombatStatus)
            {
                handler->SendSysMessage(
                    "Solo Arena combat-status diagnostic is disabled by AiPlayerbot.AutoQueue.Arena.StageCombatStatus.");
                return true;
            }
            if (!SoloArenaEnteredInstance)
            {
                handler->SendSysMessage("Solo Arena has no tracked entered Arena instance to inspect.");
                return true;
            }
            if (player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Only the administrator character that entered this staged Arena may inspect it.");
                return true;
            }

            Battleground* arena = sBattlegroundMgr->GetBattleground(
                SoloArenaEnteredInstance, BATTLEGROUND_TYPE_NONE);
            if (!arena || !arena->IsArena())
            {
                handler->PSendSysMessage(
                    "Solo Arena combat-status diagnostic refused: tracked instance %u is unavailable or no longer an Arena.",
                    SoloArenaEnteredInstance);
                return true;
            }

            BattlegroundStatus arenaStatus = arena->GetStatus();
            handler->PSendSysMessage(
                "Solo Arena combat status: instance=%u, map=%u, status=%s(%u), start-delay-ms=%d, elapsed-ms=%u, "
                "players Alliance/Horde=%u/%u, alive Alliance/Horde=%u/%u.",
                arena->GetInstanceID(), arena->GetMapId(), SoloArenaBattlegroundStatusName(arenaStatus),
                uint32(arenaStatus), arena->GetStartDelayTime(), arena->GetElapsedTime(),
                arena->GetPlayersCountByTeam(ALLIANCE), arena->GetPlayersCountByTeam(HORDE),
                arena->GetAlivePlayersCountByTeam(ALLIANCE), arena->GetAlivePlayersCountByTeam(HORDE));
            TC_LOG_INFO("server",
                "SoloArena combat status instance=%u map=%u status=%s(%u) start-delay-ms=%d elapsed-ms=%u players=%u/%u alive=%u/%u",
                arena->GetInstanceID(), arena->GetMapId(), SoloArenaBattlegroundStatusName(arenaStatus),
                uint32(arenaStatus), arena->GetStartDelayTime(), arena->GetElapsedTime(),
                arena->GetPlayersCountByTeam(ALLIANCE), arena->GetPlayersCountByTeam(HORDE),
                arena->GetAlivePlayersCountByTeam(ALLIANCE), arena->GetAlivePlayersCountByTeam(HORDE));

            uint32 participantGuids[] = { SoloArenaStagedRequester, SoloArenaStagedTeammate,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage };
            char const* labels[] = { "requester", "teammate", "opponent-healer", "opponent-damage" };
            for (uint8 index = 0; index < 4; ++index)
            {
                Player* participant = participantGuids[index] ? ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(participantGuids[index])) : nullptr;
                if (!participant)
                {
                    handler->PSendSysMessage("Solo Arena combat participant %s: offline.", labels[index]);
                    TC_LOG_INFO("server", "SoloArena combat participant label=%s guid=%u state=offline",
                        labels[index], participantGuids[index]);
                    continue;
                }

                Unit* victim = participant->GetVictim();
                PlayerbotAI* botAI = GET_PLAYERBOT_AI(participant);
                bool inTrackedArena = participant->GetBattlegroundId() == SoloArenaEnteredInstance;
                handler->PSendSysMessage(
                    "Solo Arena combat participant %s: name=%s, guid=%u, present=%s, team=%s, alive=%s, "
                    "combat=%s, moving=%s, preparation=%s, ai=%s, victim=%s, position=%.2f/%.2f/%.2f.",
                    labels[index], participant->GetName().c_str(), participant->GetGUID().GetCounter(),
                    inTrackedArena ? "yes" : "no", SoloArenaTeamName(participant->GetBGTeam()),
                    participant->IsAlive() ? "yes" : "no", participant->IsInCombat() ? "yes" : "no",
                    participant->isMoving() ? "yes" : "no",
                    participant->HasAura(SPELL_ARENA_PREPARATION) ? "yes" : "no",
                    SoloArenaBotStateName(botAI), victim ? victim->GetName().c_str() : "none",
                    participant->GetPositionX(), participant->GetPositionY(), participant->GetPositionZ());
                TC_LOG_INFO("server",
                    "SoloArena combat participant label=%s name=%s guid=%u present=%u team=%s alive=%u combat=%u moving=%u preparation=%u ai=%s victim=%s position=%.2f/%.2f/%.2f",
                    labels[index], participant->GetName().c_str(), participant->GetGUID().GetCounter(),
                    inTrackedArena ? 1 : 0, SoloArenaTeamName(participant->GetBGTeam()),
                    participant->IsAlive() ? 1 : 0, participant->IsInCombat() ? 1 : 0,
                    participant->isMoving() ? 1 : 0,
                    participant->HasAura(SPELL_ARENA_PREPARATION) ? 1 : 0,
                    SoloArenaBotStateName(botAI), victim ? victim->GetName().c_str() : "none",
                    participant->GetPositionX(), participant->GetPositionY(), participant->GetPositionZ());
            }

            handler->SendSysMessage(
                "Solo Arena combat-status diagnostic made no queue, movement, combat, result, reward, or rating change.");
            return true;
        }

        if (leaveArena)
        {
            if (!SoloArenaEnteredInstance)
            {
                handler->SendSysMessage("Solo Arena has no tracked entered Arena instance to leave.");
                return true;
            }

            if (player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Only the administrator character that entered this staged Arena may leave it.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);
            Player* participants[] = { player, teammate, opponentHealer, opponentDamage };
            char const* labels[] = { "requester", "teammate", "opponent healer", "opponent damage" };

            Battleground* arena = sBattlegroundMgr->GetBattleground(
                SoloArenaEnteredInstance, BATTLEGROUND_TYPE_NONE);
            if (!arena || !arena->IsArena())
            {
                handler->PSendSysMessage(
                    "Solo Arena leave refused: tracked Arena instance %u is unavailable or no longer an Arena.",
                    SoloArenaEnteredInstance);
                return true;
            }

            for (uint8 index = 0; index < 4; ++index)
            {
                Player* participant = participants[index];
                if (!participant)
                {
                    handler->PSendSysMessage("Solo Arena leave refused: %s is offline.", labels[index]);
                    return true;
                }
                if (participant->IsBeingTeleported())
                {
                    handler->PSendSysMessage(
                        "Solo Arena leave refused: %s is still teleporting; wait and retry.", labels[index]);
                    return true;
                }
                if (participant->GetBattlegroundId() &&
                    participant->GetBattlegroundId() != SoloArenaEnteredInstance)
                {
                    handler->PSendSysMessage(
                        "Solo Arena leave refused: %s is in a different battleground instance %u.",
                        labels[index], participant->GetBattlegroundId());
                    return true;
                }
            }

            uint32 leftArena = 0;
            uint32 removedQueue = 0;
            uint32 alreadyOutside = 0;
            uint32 healthRestoreScheduled = 0;
            for (Player* participant : participants)
            {
                if (participant->GetBattlegroundId() == SoloArenaEnteredInstance)
                {
                    participant->LeaveBattleground(true);
                    if (sPlayerbotAIConfig->autoQueueArenaStageHealthRestore)
                    {
                        if (participant->IsBeingTeleportedFar())
                        {
                            participant->ScheduleBattlegroundHealthRestore();
                            ++healthRestoreScheduled;
                        }
                        else
                            TC_LOG_WARN("server",
                                "SoloArena post-return health restore not scheduled name=%s guid=%u: far teleport did not start",
                                participant->GetName().c_str(), participant->GetGUID().GetCounter());
                    }
                    ++leftArena;
                }
                else if (participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                {
                    sBattlegroundMgr->RemovePlayerFromQueue(participant, BATTLEGROUND_QUEUE_2v2);
                    ++removedQueue;
                }
                else
                    ++alreadyOutside;
            }

            uint32 remaining = 0;
            for (Player* participant : participants)
                if (participant->GetBattlegroundId() ||
                    participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                    ++remaining;

            if (remaining)
            {
                handler->PSendSysMessage(
                    "Solo Arena leave incomplete: %u tracked participants still have Arena/queue state.", remaining);
                return true;
            }

            uint32 exitedInstance = SoloArenaEnteredInstance;
            SoloArenaEnteredInstance = 0;
            SoloArenaQueuesStaged = false;
            SoloArenaMatchScheduled = false;
            SoloArenaAutomaticHealthRestoreScheduled.clear();
            SoloArenaAutomaticExitTimer = 0;
            TC_LOG_INFO("server",
                "SoloArena staged Arena left instance=%u participants=%s/%s versus %s/%s left=%u queue-removed=%u already-outside=%u health-restore-scheduled=%u",
                exitedInstance, player->GetName().c_str(), teammate->GetName().c_str(),
                opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str(),
                leftArena, removedQueue, alreadyOutside, healthRestoreScheduled);
            handler->SendSysMessage(
                "Solo Arena removed every tracked participant from the staged Arena/queue. "
                "Wait for return teleports and optional health restoration, then use "
                ".soloarena status and .soloarena ungroup.");
            return true;
        }

        if (unstageQueue)
        {
            if (SoloArenaEnteredInstance)
            {
                handler->SendSysMessage(
                    "Solo Arena has entered participants. Use .soloarena leave before unqueue.");
                return true;
            }
            if (!SoloArenaQueuesStaged)
            {
                handler->SendSysMessage("Solo Arena has no tracked staged 2v2 queue to remove.");
                return true;
            }

            if (player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Only the administrator character that staged this queue may remove it.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);
            Player* participants[] = { player, teammate, opponentHealer, opponentDamage };
            char const* labels[] = { "requester", "teammate", "opponent healer", "opponent damage" };

            uint32 onlineQueueSlots = 0;
            for (uint8 index = 0; index < 4; ++index)
            {
                if (!participants[index])
                {
                    handler->PSendSysMessage(
                        "Solo Arena unqueue refused: %s is offline.", labels[index]);
                    return true;
                }
                if (participants[index]->InBattleground())
                {
                    handler->PSendSysMessage(
                        "Solo Arena unqueue refused: %s has already entered a battleground/Arena.", labels[index]);
                    return true;
                }
                if (participants[index]->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                    ++onlineQueueSlots;
            }

            BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(BATTLEGROUND_QUEUE_2v2);
            uint32 requesterInvite = 0;
            uint32 opponentInvite = 0;
            bool requesterExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedRequester, SoloArenaStagedTeammate, requesterInvite);
            bool opponentExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage, opponentInvite);

            if (!onlineQueueSlots && !requesterExact && !opponentExact)
            {
                arenaQueue.SetForcedArenaType(BATTLEGROUND_TYPE_NONE);
                SoloArenaQueuesStaged = false;
                SoloArenaMatchScheduled = false;
                handler->SendSysMessage(
                    "Solo Arena staged 2v2 queue had already been removed; its tracker is now clear.");
                return true;
            }

            if (onlineQueueSlots != 4 || !requesterExact || !opponentExact)
            {
                handler->PSendSysMessage(
                    "Solo Arena unqueue refused: expected four exact staged queue members, found %u queue slots "
                    "(requester-exact=%s, opponent-exact=%s).",
                    onlineQueueSlots, requesterExact ? "yes" : "no", opponentExact ? "yes" : "no");
                return true;
            }

            Player* removalOrder[] = { teammate, player, opponentDamage, opponentHealer };
            arenaQueue.SetForcedArenaType(BATTLEGROUND_TYPE_NONE);
            for (Player* participant : removalOrder)
                sBattlegroundMgr->RemovePlayerFromQueue(participant, BATTLEGROUND_QUEUE_2v2);

            uint32 remainingQueueSlots = 0;
            for (Player* participant : participants)
                if (participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                    ++remainingQueueSlots;

            if (remainingQueueSlots)
            {
                handler->PSendSysMessage(
                    "Solo Arena staged unqueue incomplete: %u tracked 2v2 queue slots remain.",
                    remainingQueueSlots);
                return true;
            }

            SoloArenaQueuesStaged = false;
            SoloArenaMatchScheduled = false;
            TC_LOG_INFO("server",
                "SoloArena staged 2v2 queue removed members=%s/%s versus %s/%s invite-instances-before-cleanup=%u/%u",
                player->GetName().c_str(), teammate->GetName().c_str(),
                opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str(),
                requesterInvite, opponentInvite);
            handler->SendSysMessage(
                "Solo Arena removed all four staged 2v2 queue slots. Groups remain tracked; use .soloarena ungroup next.");
            return true;
        }

        if (ungroup)
        {
            if (SoloArenaEnteredInstance)
            {
                handler->SendSysMessage(
                    "Solo Arena entered instance still exists. Use .soloarena leave before ungroup.");
                return true;
            }
            if (SoloArenaQueuesStaged)
            {
                handler->SendSysMessage(
                    "Solo Arena staged queue still exists. Use .soloarena unqueue before ungroup.");
                return true;
            }
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

                Player* firstPlayer = ObjectAccessor::FindConnectedPlayer(first);
                Player* secondPlayer = ObjectAccessor::FindConnectedPlayer(second);
                if (!firstPlayer || !secondPlayer || firstPlayer->InBattlegroundQueue() ||
                    secondPlayer->InBattlegroundQueue() || firstPlayer->InBattleground() ||
                    secondPlayer->InBattleground())
                {
                    handler->PSendSysMessage(
                        "Refusing to disband Solo Arena %s group %u: a member is offline or has queue/Arena state.",
                        label, groupId);
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

            if (SoloArenaQueuesStaged)
            {
                handler->SendSysMessage(
                    "Solo Arena staged queue still exists. Use .soloarena unqueue before logout.");
                return true;
            }

            if (SoloArenaEnteredInstance)
            {
                handler->SendSysMessage(
                    "Solo Arena entered instance still exists. Use .soloarena leave before logout.");
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

        if (stageEnter && (!sPlayerbotAIConfig->autoQueueArenaStageLogin ||
            !sPlayerbotAIConfig->autoQueueArenaStageGroup ||
            !sPlayerbotAIConfig->autoQueueArenaStageQueue ||
            !sPlayerbotAIConfig->autoQueueArenaStageMatch ||
            !sPlayerbotAIConfig->autoQueueArenaStageEnter))
        {
            handler->SendSysMessage(
                "Solo Arena staged entry is disabled. StageLogin=1, StageGroup=1, StageQueue=1, "
                "StageMatch=1 and StageEnter=1 are required.");
            return true;
        }

        if (stageEnter)
        {
            if (SoloArenaEnteredInstance)
            {
                handler->PSendSysMessage(
                    "Solo Arena already tracks entered instance %u. Use .soloarena status or .soloarena leave.",
                    SoloArenaEnteredInstance);
                return true;
            }

            if (!SoloArenaQueuesStaged || !SoloArenaMatchScheduled ||
                player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Solo Arena entry requires this requester's exact tracked queue and scheduled matchmaking.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);
            Player* participants[] = { player, teammate, opponentHealer, opponentDamage };
            char const* labels[] = { "requester", "teammate", "opponent healer", "opponent damage" };

            BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(BATTLEGROUND_QUEUE_2v2);
            uint32 requesterInvite = 0;
            uint32 opponentInvite = 0;
            bool requesterExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedRequester, SoloArenaStagedTeammate, requesterInvite);
            bool opponentExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage, opponentInvite);
            if (!requesterExact || !opponentExact || arenaQueue.m_QueuedPlayers.size() != 4 ||
                !requesterInvite || requesterInvite != opponentInvite)
            {
                handler->PSendSysMessage(
                    "Solo Arena entry refused: expected two exact groups, four queued players, and one shared "
                    "nonzero invitation (exact=%s/%s, queued=%u, invites=%u/%u).",
                    requesterExact ? "yes" : "no", opponentExact ? "yes" : "no",
                    uint32(arenaQueue.m_QueuedPlayers.size()), requesterInvite, opponentInvite);
                return true;
            }

            Battleground* arena = sBattlegroundMgr->GetBattleground(requesterInvite, BATTLEGROUND_TYPE_NONE);
            if (!arena || !arena->IsArena() || arena->GetArenaType() != ARENA_TYPE_2v2 ||
                arena->GetStatus() != STATUS_WAIT_JOIN)
            {
                handler->PSendSysMessage(
                    "Solo Arena entry refused: invited instance %u is missing, not 2v2 Arena, or no longer waiting to join.",
                    requesterInvite);
                return true;
            }

            for (uint8 index = 0; index < 4; ++index)
            {
                Player* participant = participants[index];
                if (!participant || participant->InBattleground() || participant->IsBeingTeleported() ||
                    !participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2) ||
                    !participant->IsInvitedForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                {
                    handler->PSendSysMessage(
                        "Solo Arena entry refused: %s is offline, already inside/teleporting, or lacks the exact invitation.",
                        labels[index]);
                    return true;
                }
            }

            SoloArenaEnteredInstance = requesterInvite;
            uint32 accepted = 0;
            Player* acceptanceOrder[] = { opponentDamage, opponentHealer, teammate, player };
            for (Player* participant : acceptanceOrder)
            {
                if (!AcceptSoloArenaInvite(participant, requesterInvite))
                {
                    TC_LOG_ERROR("server",
                        "SoloArena staged entry stopped instance=%u accepted=%u failed=%s; use .soloarena status then .soloarena leave",
                        requesterInvite, accepted, participant->GetName().c_str());
                    handler->PSendSysMessage(
                        "Solo Arena entry stopped after %u accepts because %s did not enter. "
                        "Wait for teleports, then use .soloarena status and .soloarena leave.",
                        accepted, participant->GetName().c_str());
                    return true;
                }

                ++accepted;
                TC_LOG_INFO("server", "SoloArena staged enter accepted instance=%u name=%s guid=%u",
                    requesterInvite, participant->GetName().c_str(), participant->GetGUID().GetCounter());
            }

            SoloArenaQueuesStaged = false;
            SoloArenaMatchScheduled = false;
            TC_LOG_INFO("server",
                "SoloArena staged 2v2 entry requested instance=%u members=%s/%s versus %s/%s accepted=%u; leave before countdown ends",
                requesterInvite, player->GetName().c_str(), teammate->GetName().c_str(),
                opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str(), accepted);
            handler->SendSysMessage(
                "Solo Arena accepted the shared invitation for all four tracked participants. "
                "Wait for all teleports, use .soloarena status, then .soloarena leave before the countdown ends.");
            return true;
        }

        if (stageMatch && (!sPlayerbotAIConfig->autoQueueArenaStageLogin ||
            !sPlayerbotAIConfig->autoQueueArenaStageGroup ||
            !sPlayerbotAIConfig->autoQueueArenaStageQueue ||
            !sPlayerbotAIConfig->autoQueueArenaStageMatch))
        {
            handler->SendSysMessage(
                "Solo Arena staged matchmaking is disabled. StageLogin=1, StageGroup=1, StageQueue=1 and StageMatch=1 are required.");
            return true;
        }

        if (stageMatch)
        {
            if (!SoloArenaQueuesStaged || player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Solo Arena matchmaking requires this requester's exact tracked staged queue.");
                return true;
            }

            if (SoloArenaMatchScheduled)
            {
                handler->SendSysMessage(
                    "Solo Arena matchmaking was already scheduled. Use .soloarena status, then .soloarena unqueue.");
                return true;
            }

            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);
            Player* participants[] = { player, teammate, opponentHealer, opponentDamage };
            for (Player* participant : participants)
            {
                if (!participant || participant->InBattleground() ||
                    !participant->InBattlegroundQueueForBattlegroundQueueType(BATTLEGROUND_QUEUE_2v2))
                {
                    handler->SendSysMessage(
                        "Solo Arena matchmaking refused: an exact participant is offline, already inside, or no longer queued.");
                    return true;
                }
            }

            BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(BATTLEGROUND_QUEUE_2v2);
            uint32 requesterInvite = 0;
            uint32 opponentInvite = 0;
            bool requesterExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedRequester, SoloArenaStagedTeammate, requesterInvite);
            bool opponentExact = HasExactSoloArenaQueueGroup(arenaQueue,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage, opponentInvite);
            if (!requesterExact || !opponentExact || arenaQueue.m_QueuedPlayers.size() != 4)
            {
                handler->PSendSysMessage(
                    "Solo Arena matchmaking refused: expected only the two exact tracked groups and four queued players (exact=%s/%s, queued=%u).",
                    requesterExact ? "yes" : "no", opponentExact ? "yes" : "no",
                    uint32(arenaQueue.m_QueuedPlayers.size()));
                return true;
            }

            if (requesterInvite || opponentInvite)
            {
                handler->PSendSysMessage(
                    "Solo Arena matchmaking refused: an invitation already exists (%u/%u). Use .soloarena unqueue.",
                    requesterInvite, opponentInvite);
                return true;
            }

            Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
            PvPDifficultyEntry const* bracket = arenaTemplate ?
                GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), player->GetLevel()) : nullptr;
            if (!arenaTemplate || !bracket)
            {
                handler->SendSysMessage("Solo Arena matchmaking refused: Arena template or bracket is unavailable.");
                return true;
            }

            arenaQueue.SetForcedArenaType(forceTolviron ? BATTLEGROUND_TV : BATTLEGROUND_TYPE_NONE);
            sBattlegroundMgr->ScheduleQueueUpdate(0, ARENA_TYPE_2v2,
                BATTLEGROUND_QUEUE_2v2, BATTLEGROUND_AA, bracket->GetBracketId());
            SoloArenaMatchScheduled = true;
            TC_LOG_INFO("server",
                "SoloArena invite-only 2v2 matchmaking scheduled arena=%s members=%s/%s versus %s/%s; no acceptance or teleport requested",
                forceTolviron ? "Tol'viron" : "random",
                player->GetName().c_str(), teammate->GetName().c_str(),
                opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str());
            handler->PSendSysMessage(
                "Solo Arena scheduled one invite-only 2v2 queue update for %s. Do not click Enter. "
                "Use .soloarena status, then .soloarena unqueue promptly.",
                forceTolviron ? "Tol'viron" : "a random Arena");
            return true;
        }

        if (stageQueue && (!sPlayerbotAIConfig->autoQueueArenaStageLogin ||
            !sPlayerbotAIConfig->autoQueueArenaStageGroup ||
            !sPlayerbotAIConfig->autoQueueArenaStageQueue))
        {
            handler->SendSysMessage(
                "Solo Arena staged queue is disabled. StageLogin=1, StageGroup=1 and StageQueue=1 are required.");
            return true;
        }

        if (stageQueue)
        {
            if (SoloArenaQueuesStaged)
            {
                handler->SendSysMessage(
                    "Solo Arena staged 2v2 queue already exists. Use .soloarena status or .soloarena unqueue.");
                return true;
            }

            if (player->GetGUID().GetCounter() != SoloArenaStagedRequester ||
                SoloArenaStagedBots.size() != 3 || !SoloArenaRequesterGroup || !SoloArenaOpponentGroup)
            {
                handler->SendSysMessage(
                    "Solo Arena needs the complete tracked login and both tracked groups before queueing.");
                return true;
            }

            Group* requesterGroup = sGroupMgr->GetGroupByGUID(SoloArenaRequesterGroup);
            Group* opponentGroup = sGroupMgr->GetGroupByGUID(SoloArenaOpponentGroup);
            ObjectGuid teammateGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate);
            ObjectGuid opponentHealerGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer);
            ObjectGuid opponentDamageGuid = ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage);
            Player* teammate = sRandomPlayerbotMgr->GetPlayerBot(teammateGuid);
            Player* opponentHealer = sRandomPlayerbotMgr->GetPlayerBot(opponentHealerGuid);
            Player* opponentDamage = sRandomPlayerbotMgr->GetPlayerBot(opponentDamageGuid);

            auto exactGroup = [](Group* group, Player* leader, ObjectGuid first, ObjectGuid second) -> bool
            {
                return group && leader && group->GetMembersCount() == 2 &&
                    group->GetLeaderGUID() == leader->GetGUID() &&
                    group->IsMember(first) && group->IsMember(second);
            };

            if (!exactGroup(requesterGroup, player, player->GetGUID(), teammateGuid) ||
                !exactGroup(opponentGroup, opponentHealer, opponentHealerGuid, opponentDamageGuid) ||
                !teammate || !opponentHealer || !opponentDamage)
            {
                handler->SendSysMessage(
                    "Solo Arena queueing refused: a tracked group, leader, member, or online bot changed.");
                return true;
            }

            Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
            if (!arenaTemplate || DisableMgr::IsDisabledFor(DISABLE_TYPE_BATTLEGROUND, BATTLEGROUND_AA, nullptr))
            {
                handler->SendSysMessage("Solo Arena queueing refused: the all-Arena template is absent or disabled.");
                return true;
            }

            PvPDifficultyEntry const* requesterBracket =
                GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), player->GetLevel());
            PvPDifficultyEntry const* opponentBracket =
                GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), opponentHealer->GetLevel());
            if (!requesterBracket || requesterBracket != opponentBracket)
            {
                handler->SendSysMessage("Solo Arena queueing refused: the two groups are not in one Arena bracket.");
                return true;
            }

            GroupJoinBattlegroundResult requesterError = requesterGroup->CanJoinBattlegroundQueue(
                arenaTemplate, BATTLEGROUND_QUEUE_2v2, 2, 2, false, 0);
            GroupJoinBattlegroundResult opponentError = opponentGroup->CanJoinBattlegroundQueue(
                arenaTemplate, BATTLEGROUND_QUEUE_2v2, 2, 2, false, 0);
            if (requesterError != ERR_BATTLEGROUND_NONE || opponentError != ERR_BATTLEGROUND_NONE)
            {
                handler->PSendSysMessage(
                    "Solo Arena queueing refused by core validation: requester=%u, opponent=%u.",
                    uint32(requesterError), uint32(opponentError));
                return true;
            }

            BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(BATTLEGROUND_QUEUE_2v2);
            GroupQueueInfo* requesterInfo = arenaQueue.AddGroup(player, requesterGroup,
                BATTLEGROUND_AA, requesterBracket, ARENA_TYPE_2v2, false, false, 0, 0);
            GroupQueueInfo* opponentInfo = arenaQueue.AddGroup(opponentHealer, opponentGroup,
                BATTLEGROUND_AA, opponentBracket, ARENA_TYPE_2v2, false, false, 0, 0);

            BattlegroundBracketId bracketId = requesterBracket->GetBracketId();
            auto sendQueuedStatus = [&arenaQueue, arenaTemplate, bracketId](Group* group, GroupQueueInfo* info)
            {
                uint32 averageWait = arenaQueue.GetAverageQueueWaitTime(info, bracketId);
                for (auto&& member : *group)
                {
                    uint32 queueSlot = member->AddBattlegroundQueueId(BATTLEGROUND_QUEUE_2v2);
                    member->AddBattlegroundQueueJoinTime(BATTLEGROUND_AA, info->JoinTime);
                    WorldPacket data;
                    sBattlegroundMgr->BuildBattlegroundStatusPacket(&data, arenaTemplate, member,
                        queueSlot, STATUS_WAIT_QUEUE, averageWait, info->JoinTime, ARENA_TYPE_2v2);
                    member->GetSession()->SendPacket(&data);
                }
            };

            sendQueuedStatus(requesterGroup, requesterInfo);
            sendQueuedStatus(opponentGroup, opponentInfo);
            SoloArenaQueuesStaged = true;
            SoloArenaMatchScheduled = false;

            TC_LOG_INFO("server",
                "SoloArena staged non-rated 2v2 queue added members=%s/%s versus %s/%s; matchmaking not scheduled, no invite or teleport requested",
                player->GetName().c_str(), teammate->GetName().c_str(),
                opponentHealer->GetName().c_str(), opponentDamage->GetName().c_str());
            handler->SendSysMessage(
                "Solo Arena placed both exact groups in the non-rated 2v2 queue without scheduling matchmaking. "
                "Use .soloarena status, then .soloarena unqueue before ungroup.");
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
        SoloArenaAutomaticHealthRestoreScheduled.clear();
        SoloArenaAutomaticExitTimer = 0;

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
