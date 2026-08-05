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
#include "ItemPrototype.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotMgr.h"
#include "PerformanceMonitor.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <sstream>
#include <vector>

namespace
{
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
        if (!args || strcmp(args, "preview"))
        {
            handler->SendSysMessage("Usage: .soloarena preview");
            return true;
        }

        Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (!sPlayerbotAIConfig->autoQueueEnabled || !sPlayerbotAIConfig->autoQueueArena ||
            !sPlayerbotAIConfig->autoQueueDryRun)
        {
            handler->SendSysMessage("Solo Arena preview requires AutoQueue.Enabled=1, Arena=1 and DryRun=1.");
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

        handler->PSendSysMessage(
            "Dry-run only: teammate %s; opponents %s and %s. No bot was logged in, changed, grouped or queued.",
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
