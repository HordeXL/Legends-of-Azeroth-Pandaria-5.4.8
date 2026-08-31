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
#include "BotFactory.h"
#include "DatabaseEnv.h"
#include "DisableMgr.h"
#include "GameObject.h"
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
#include "PlayerbotSpec.h"
#include "PerformanceMonitor.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "RatedPvp.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"
#include "World.h"

#include <algorithm>
#include <array>
#include <limits>
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
std::vector<uint32> SoloArenaAutomaticRequesterTeam;
std::vector<uint32> SoloArenaAutomaticOpponentTeam;
uint8 SoloArenaAutomaticTeamSize = ARENA_TYPE_2v2;
BattlegroundQueueTypeId SoloArenaAutomaticQueueType = BATTLEGROUND_QUEUE_2v2;
uint32 SoloArenaRequesterGroup = 0;
uint32 SoloArenaOpponentGroup = 0;
bool SoloArenaQueuesStaged = false;
bool SoloArenaMatchScheduled = false;
uint32 SoloArenaEnteredInstance = 0;
bool SoloArenaAutomaticRewardProcessed = false;
uint32 SoloArenaAutomaticExitTimer = 0;
std::set<uint32> SoloArenaAutomaticHealthRestoreScheduled;
std::set<uint32> SoloArenaLoadoutRecoveryBots;
uint32 AutomatedPvpLoadoutRecoveryTimer = 0;
std::set<uint32> SoloArenaAutomaticPreparationBuffedBots;
std::set<uint32> SoloArenaAutomaticCombatActivatedBots;
bool SoloArenaAutomaticPreparationFacingApplied = false;

enum class SoloArenaAutomaticState : uint8
{
    Idle,
    Login,
    WaitForBots,
    ApplyLoadout,
    Group,
    Queue,
    Match,
    WaitForInvite,
    Enter,
    WaitForEntry,
    Active,
    Cleanup
};

SoloArenaAutomaticState SoloArenaAutomaticQueueState = SoloArenaAutomaticState::Idle;
uint32 SoloArenaAutomaticRequester = 0;
uint32 SoloArenaAutomaticUpdateTimer = 0;
uint32 SoloArenaAutomaticElapsed = 0;
std::string SoloArenaAutomaticCleanupReason;

uint8 const SoloArenaLoadoutEquipmentSlots[] =
{
    EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_SHOULDERS, EQUIPMENT_SLOT_CHEST,
    EQUIPMENT_SLOT_LEGS, EQUIPMENT_SLOT_HANDS
};

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

struct WorldBossPveLoadoutPlan
{
    Specializations Specialization;
    uint32 ItemSet;
    std::array<uint32, 5> Items;
};

enum class WorldBossPreviewRole : uint8
{
    None,
    Tank,
    Healer,
    Damage
};

enum WorldBossRaidBuff : uint8
{
    WORLD_BOSS_BUFF_STATS        = 1 << 0,
    WORLD_BOSS_BUFF_STAMINA      = 1 << 1,
    WORLD_BOSS_BUFF_ATTACK_POWER = 1 << 2,
    WORLD_BOSS_BUFF_ATTACK_SPEED = 1 << 3,
    WORLD_BOSS_BUFF_SPELL_POWER  = 1 << 4,
    WORLD_BOSS_BUFF_SPELL_HASTE  = 1 << 5,
    WORLD_BOSS_BUFF_CRITICAL     = 1 << 6,
    WORLD_BOSS_BUFF_MASTERY      = 1 << 7
};

uint8 GetWorldBossRaidBuffMask(Specializations specialization)
{
    // Mists of Pandaria 5.4.8 raid-buff equivalence categories shown by the
    // default raid UI. The mask describes what a specialization can maintain
    // through its normal PlayerbotAI actions, passives, forms, pets or totems.
    switch (specialization)
    {
        case SPEC_DRUID_BALANCE:
            return WORLD_BOSS_BUFF_STATS | WORLD_BOSS_BUFF_SPELL_HASTE;
        case SPEC_DRUID_FERAL:
        case SPEC_DRUID_GUARDIAN:
            return WORLD_BOSS_BUFF_STATS | WORLD_BOSS_BUFF_CRITICAL;
        case SPEC_DRUID_RESTORATION:
            return WORLD_BOSS_BUFF_STATS;

        case SPEC_PALADIN_HOLY:
        case SPEC_PALADIN_PROTECTION:
        case SPEC_PALADIN_RETRIBUTION:
            return WORLD_BOSS_BUFF_STATS | WORLD_BOSS_BUFF_MASTERY;

        case SPEC_MONK_WINDWALKER:
            return WORLD_BOSS_BUFF_STATS | WORLD_BOSS_BUFF_CRITICAL;
        case SPEC_MONK_BREWMASTER:
        case SPEC_MONK_MISTWEAVER:
            return WORLD_BOSS_BUFF_STATS;

        case SPEC_PRIEST_SHADOW:
            return WORLD_BOSS_BUFF_STAMINA | WORLD_BOSS_BUFF_SPELL_HASTE;
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
            return WORLD_BOSS_BUFF_STAMINA;

        case SPEC_WARRIOR_ARMS:
        case SPEC_WARRIOR_FURY:
            return WORLD_BOSS_BUFF_ATTACK_POWER;
        case SPEC_WARRIOR_PROTECTION:
            return WORLD_BOSS_BUFF_STAMINA;

        case SPEC_DEATH_KNIGHT_FROST:
        case SPEC_DEATH_KNIGHT_UNHOLY:
            return WORLD_BOSS_BUFF_ATTACK_POWER | WORLD_BOSS_BUFF_ATTACK_SPEED;
        case SPEC_DEATH_KNIGHT_BLOOD:
            return WORLD_BOSS_BUFF_ATTACK_POWER;

        case SPEC_HUNTER_BEAST_MASTERY:
            return WORLD_BOSS_BUFF_ATTACK_POWER | WORLD_BOSS_BUFF_ATTACK_SPEED;
        case SPEC_HUNTER_MARKSMANSHIP:
        case SPEC_HUNTER_SURVIVAL:
            return WORLD_BOSS_BUFF_ATTACK_POWER;

        case SPEC_MAGE_ARCANE:
        case SPEC_MAGE_FIRE:
        case SPEC_MAGE_FROST:
            return WORLD_BOSS_BUFF_SPELL_POWER | WORLD_BOSS_BUFF_CRITICAL;

        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_WARLOCK_DESTRUCTION:
            return WORLD_BOSS_BUFF_STAMINA | WORLD_BOSS_BUFF_SPELL_POWER;

        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_ROGUE_COMBAT:
        case SPEC_ROGUE_SUBTLETY:
            return WORLD_BOSS_BUFF_ATTACK_SPEED;

        case SPEC_SHAMAN_ELEMENTAL:
            return WORLD_BOSS_BUFF_SPELL_POWER | WORLD_BOSS_BUFF_SPELL_HASTE |
                WORLD_BOSS_BUFF_MASTERY;
        case SPEC_SHAMAN_ENHANCEMENT:
            return WORLD_BOSS_BUFF_ATTACK_SPEED | WORLD_BOSS_BUFF_SPELL_POWER |
                WORLD_BOSS_BUFF_MASTERY;
        case SPEC_SHAMAN_RESTORATION:
            return WORLD_BOSS_BUFF_SPELL_POWER | WORLD_BOSS_BUFF_MASTERY;

        default:
            return 0;
    }
}

uint8 CountWorldBossRaidBuffs(uint8 mask)
{
    uint8 count = 0;
    while (mask)
    {
        count += mask & 1;
        mask >>= 1;
    }
    return count;
}

std::string DescribeWorldBossRaidBuffs(uint8 mask)
{
    static char const* const names[] =
    {
        "stats", "stamina", "attack-power", "attack-speed", "spell-power",
        "spell-haste", "critical-strike", "mastery"
    };
    std::ostringstream description;
    for (uint8 index = 0; index < 8; ++index)
    {
        if (!(mask & (1 << index)))
            continue;
        if (description.tellp() > 0)
            description << ',';
        description << names[index];
    }
    return description.str();
}

struct WorldBossStagedCandidate
{
    uint32 Guid = 0;
    std::string Name;
    uint8 Class = 0;
    WorldBossPreviewRole Role = WorldBossPreviewRole::None;
    Specializations Specialization = SPEC_NONE;
    uint32 PvpItems = 0;
    uint32 AverageItemLevel = 0;
    uint32 OriginalMap = 0;
    float OriginalX = 0.0f;
    float OriginalY = 0.0f;
    float OriginalZ = 0.0f;
    float OriginalO = 0.0f;
    bool ReturnRequested = false;
    uint32 CleanupReadyAt = 0;
};

uint16 GetWorldBossClassBit(uint8 playerClass)
{
    return playerClass < 16 ? uint16(1u << playerClass) : 0;
}

uint8 CountWorldBossClasses(uint16 mask)
{
    uint8 count = 0;
    while (mask)
    {
        count += mask & 1;
        mask >>= 1;
    }
    return count;
}

bool SelectWorldBossDiverseRole(
    std::vector<WorldBossStagedCandidate> const& candidates, uint32 wanted,
    uint8 requesterClass, bool requesterHasRole, uint8& coveredBuffs,
    std::vector<uint32>& selected, uint16& selectedClasses)
{
    selected.clear();
    if (wanted > candidates.size())
        return false;

    std::set<uint32> selectedSet;
    uint16 usedClasses = requesterHasRole ?
        GetWorldBossClassBit(requesterClass) : 0;

    auto select = [&](uint32 index)
    {
        selected.push_back(index);
        selectedSet.insert(index);
        usedClasses |= GetWorldBossClassBit(candidates[index].Class);
        coveredBuffs |= GetWorldBossRaidBuffMask(
            candidates[index].Specialization);
    };

    // Candidates have already been ordered by PvE suitability. Take the best
    // representative of every available class before permitting a duplicate.
    // In a 25-player raid this yields all five healer classes and every DPS
    // class (counting the requester when they fill that role).
    for (uint32 index = 0; index < candidates.size() &&
        selected.size() < wanted; ++index)
    {
        uint16 classBit = GetWorldBossClassBit(candidates[index].Class);
        if (!classBit || usedClasses & classBit)
            continue;
        select(index);
    }

    // Fill the remaining role slots. Preserve complete raid-buff coverage
    // first, then prefer fewer PvP pieces and the highest item level. Exact
    // gear ties are randomized so repeated Calls need not use the same bots.
    while (selected.size() < wanted)
    {
        uint8 bestNewBuffs = 0;
        uint32 bestPvpItems = std::numeric_limits<uint32>::max();
        uint32 bestItemLevel = 0;
        std::vector<uint32> tied;
        for (uint32 index = 0; index < candidates.size(); ++index)
        {
            if (selectedSet.count(index))
                continue;

            uint8 newBuffs = CountWorldBossRaidBuffs(uint8(
                GetWorldBossRaidBuffMask(candidates[index].Specialization) &
                ~coveredBuffs));
            if (tied.empty() || newBuffs > bestNewBuffs ||
                (newBuffs == bestNewBuffs &&
                    candidates[index].PvpItems < bestPvpItems) ||
                (newBuffs == bestNewBuffs &&
                    candidates[index].PvpItems == bestPvpItems &&
                    candidates[index].AverageItemLevel > bestItemLevel))
            {
                bestNewBuffs = newBuffs;
                bestPvpItems = candidates[index].PvpItems;
                bestItemLevel = candidates[index].AverageItemLevel;
                tied.clear();
                tied.push_back(index);
            }
            else if (newBuffs == bestNewBuffs &&
                candidates[index].PvpItems == bestPvpItems &&
                candidates[index].AverageItemLevel == bestItemLevel)
                tied.push_back(index);
        }

        if (tied.empty())
            return false;
        select(tied[urand(0, uint32(tied.size() - 1))]);
    }
    selectedClasses = usedClasses;
    return true;
}

enum class WorldBossStagedState : uint8
{
    Idle,
    WaitForBots,
    WaitForTeleport,
    Grouped,
    Cleanup
};

WorldBossStagedState WorldBossStageState = WorldBossStagedState::Idle;
uint32 WorldBossStageRequester = 0;
uint32 WorldBossStageCaller = 0;
uint32 WorldBossStageBoss = 0;
uint32 WorldBossStageBossEntry = 0;
uint32 WorldBossStageGroup = 0;
uint32 WorldBossStageRaidSize = 0;
uint32 WorldBossStageElapsed = 0;
uint32 WorldBossStageUpdateTimer = 0;
uint32 WorldBossStageMap = 0;
float WorldBossStageX = 0.0f;
float WorldBossStageY = 0.0f;
float WorldBossStageZ = 0.0f;
std::map<uint32, WorldBossStagedCandidate> WorldBossStagedBots;
std::string WorldBossStageCleanupReason;
std::set<uint32> WorldBossStageBuffedBots;
bool WorldBossStageEncounterStarted = false;
bool WorldBossStageWipePending = false;
uint32 WorldBossStageBossDefeatedTimer = 0;

char const* WorldBossStagedStateName();
void BeginWorldBossStageCleanup(char const* reason);
bool RequestWorldBossRebuff(Player* requester, std::string& error);

WorldBossPreviewRole GetWorldBossPreviewRole(Specializations specialization)
{
    switch (specialization)
    {
        case SPEC_PALADIN_PROTECTION:
        case SPEC_WARRIOR_PROTECTION:
        case SPEC_DRUID_GUARDIAN:
        case SPEC_DEATH_KNIGHT_BLOOD:
        case SPEC_MONK_BREWMASTER:
            return WorldBossPreviewRole::Tank;
        case SPEC_PALADIN_HOLY:
        case SPEC_DRUID_RESTORATION:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
        case SPEC_SHAMAN_RESTORATION:
        case SPEC_MONK_MISTWEAVER:
            return WorldBossPreviewRole::Healer;
        case SPEC_NONE:
            return WorldBossPreviewRole::None;
        default:
            return WorldBossPreviewRole::Damage;
    }
}

char const* GetSupportedWorldBossName(uint32 entry)
{
    switch (entry)
    {
        case 60491: return "Sha of Anger";
        case 62346: return "Galleon";
        case 69099: return "Nalak";
        case 69161: return "Oondasta";
        case 71952: return "Chi-Ji";
        case 71953: return "Xuen";
        case 71954: return "Niuzao";
        case 71955: return "Yu'lon";
        case 72057: return "Ordos";
        default: return nullptr;
    }
}

void PrepareSoloArenaBotForLogout(Player* bot, char const* context)
{
    if (!bot)
        return;

    uint32 guid = bot->GetGUID().GetCounter();
    bool wasAlive = bot->IsAlive();
    bool wasCharmed = bot->IsCharmed();
    uint32 oldHealth = bot->GetHealth();
    uint32 oldAttackers = uint32(bot->getAttackers().size());

    if (wasCharmed)
        bot->RemoveCharmAuras();

    // WorldSession::LogoutPlayer treats any remaining attacker or charm as a
    // combat logout and kills the character. Arena participants can retain a
    // stale hostile reference for a few updates after leaving the instance,
    // so clear both sides before RandomPlayerbotMgr saves and logs the bot out.
    bot->CombatStop();
    bot->getHostileRefManager().deleteReferences();

    if (!bot->IsAlive())
    {
        bot->ResurrectPlayer(1.0f, false);
        bot->SpawnCorpseBones();
    }
    bot->SetFullHealth();

    TC_LOG_INFO("server",
        "SoloArena prepared bot logout context=%s name=%s guid=%u alive=%u charmed=%u attackers=%u/%u health=%u/%u",
        context ? context : "unknown", bot->GetName().c_str(), guid,
        wasAlive ? 1u : 0u, wasCharmed ? 1u : 0u, oldAttackers,
        uint32(bot->getAttackers().size()), oldHealth, bot->GetMaxHealth());
}

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

WorldBossPveLoadoutPlan const* GetWorldBossPveLoadoutPlan(
    Specializations specialization)
{
    // Genuine Siege of Orgrimmar Mythic/566 T16 five-piece sets from this
    // 5.4.8 world database. Item order is head, shoulders, chest/robe, legs,
    // hands. These are permanent PvE upgrades for random bots; the player's
    // equipment is never modified and replaced bot items remain in its bags.
    static WorldBossPveLoadoutPlan const plans[] =
    {
        { SPEC_DEATH_KNIGHT_BLOOD, 1201, {{ 99323, 99325, 99330, 99324, 99331 }} },
        { SPEC_DEATH_KNIGHT_FROST, 1200, {{ 99337, 99339, 99335, 99338, 99336 }} },
        { SPEC_DEATH_KNIGHT_UNHOLY, 1200, {{ 99337, 99339, 99335, 99338, 99336 }} },
        { SPEC_DRUID_FERAL, 1196, {{ 99421, 99423, 99419, 99422, 99420 }} },
        { SPEC_DRUID_BALANCE, 1197, {{ 99433, 99428, 99427, 99434, 99432 }} },
        { SPEC_DRUID_RESTORATION, 1198, {{ 99436, 99431, 99430, 99429, 99435 }} },
        { SPEC_DRUID_GUARDIAN, 1199, {{ 99328, 99322, 99326, 99329, 99327 }} },
        { SPEC_HUNTER_BEAST_MASTERY, 1195, {{ 99402, 99404, 99405, 99403, 99406 }} },
        { SPEC_HUNTER_MARKSMANSHIP, 1195, {{ 99402, 99404, 99405, 99403, 99406 }} },
        { SPEC_HUNTER_SURVIVAL, 1195, {{ 99402, 99404, 99405, 99403, 99406 }} },
        { SPEC_MAGE_ARCANE, 1194, {{ 99398, 99401, 99400, 99399, 99397 }} },
        { SPEC_MAGE_FIRE, 1194, {{ 99398, 99401, 99400, 99399, 99397 }} },
        { SPEC_MAGE_FROST, 1194, {{ 99398, 99401, 99400, 99399, 99397 }} },
        // ItemSet.dbc 1191 carries the Brewmaster bonuses (145049/145055),
        // while 1193 carries the Windwalker bonuses (145004/145022).
        { SPEC_MONK_WINDWALKER, 1193, {{ 99393, 99395, 99396, 99394, 99392 }} },
        { SPEC_MONK_MISTWEAVER, 1192, {{ 99389, 99381, 99391, 99390, 99388 }} },
        { SPEC_MONK_BREWMASTER, 1191, {{ 99384, 99386, 99382, 99385, 99383 }} },
        { SPEC_PALADIN_PROTECTION, 1188, {{ 99370, 99364, 99368, 99371, 99369 }} },
        { SPEC_PALADIN_HOLY, 1189, {{ 99376, 99378, 99374, 99377, 99375 }} },
        { SPEC_PALADIN_RETRIBUTION, 1190, {{ 99379, 99373, 99387, 99372, 99380 }} },
        { SPEC_PRIEST_SHADOW, 1186, {{ 99360, 99363, 99362, 99361, 99359 }} },
        { SPEC_PRIEST_DISCIPLINE, 1187, {{ 99366, 99358, 99357, 99367, 99365 }} },
        { SPEC_PRIEST_HOLY, 1187, {{ 99366, 99358, 99357, 99367, 99365 }} },
        { SPEC_ROGUE_ASSASSINATION, 1185, {{ 99348, 99350, 99356, 99349, 99355 }} },
        { SPEC_ROGUE_COMBAT, 1185, {{ 99348, 99350, 99356, 99349, 99355 }} },
        { SPEC_ROGUE_SUBTLETY, 1185, {{ 99348, 99350, 99356, 99349, 99355 }} },
        { SPEC_SHAMAN_ELEMENTAL, 1182, {{ 99332, 99334, 99344, 99333, 99345 }} },
        { SPEC_SHAMAN_ENHANCEMENT, 1183, {{ 99341, 99343, 99347, 99342, 99340 }} },
        { SPEC_SHAMAN_RESTORATION, 1184, {{ 99353, 99346, 99351, 99354, 99352 }} },
        { SPEC_WARLOCK_AFFLICTION, 1181, {{ 99425, 99417, 99416, 99426, 99424 }} },
        { SPEC_WARLOCK_DEMONOLOGY, 1181, {{ 99425, 99417, 99416, 99426, 99424 }} },
        { SPEC_WARLOCK_DESTRUCTION, 1181, {{ 99425, 99417, 99416, 99426, 99424 }} },
        { SPEC_WARRIOR_PROTECTION, 1179, {{ 99409, 99407, 99415, 99410, 99408 }} },
        { SPEC_WARRIOR_ARMS, 1180, {{ 99418, 99414, 99411, 99413, 99412 }} },
        { SPEC_WARRIOR_FURY, 1180, {{ 99418, 99414, 99411, 99413, 99412 }} }
    };

    for (WorldBossPveLoadoutPlan const& plan : plans)
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

struct SoloArenaLoadoutBackupRow
{
    uint8 EquipmentSlot = 0;
    uint32 OriginalItemGuid = 0;
    uint32 OriginalItemEntry = 0;
    uint8 StorageBag = 0;
    uint8 StorageSlot = 0;
    uint32 TemporaryItemGuid = 0;
    uint32 TemporaryItemEntry = 0;
};

uint32 GetSoloArenaLoadoutBackupCount(uint32 ownerGuid = 0)
{
    QueryResult result = ownerGuid ? CharacterDatabase.PQuery(
        "SELECT COUNT(*) FROM `solo_arena_loadout_backup` WHERE `owner_guid`=%u", ownerGuid) :
        CharacterDatabase.Query("SELECT COUNT(*) FROM `solo_arena_loadout_backup`");
    return result ? (*result)[0].GetUInt32() : 0;
}

std::vector<SoloArenaLoadoutBackupRow> LoadSoloArenaLoadoutBackups(uint32 ownerGuid)
{
    std::vector<SoloArenaLoadoutBackupRow> rows;
    QueryResult result = CharacterDatabase.PQuery(
        "SELECT `equipment_slot`,`original_item_guid`,`original_item_entry`,"
        "`storage_bag`,`storage_slot`,`temporary_item_guid`,`temporary_item_entry` "
        "FROM `solo_arena_loadout_backup` WHERE `owner_guid`=%u ORDER BY `equipment_slot`",
        ownerGuid);
    if (!result)
        return rows;

    do
    {
        Field* fields = result->Fetch();
        SoloArenaLoadoutBackupRow row;
        row.EquipmentSlot = fields[0].GetUInt8();
        row.OriginalItemGuid = fields[1].GetUInt32();
        row.OriginalItemEntry = fields[2].GetUInt32();
        row.StorageBag = fields[3].GetUInt8();
        row.StorageSlot = fields[4].GetUInt8();
        row.TemporaryItemGuid = fields[5].GetUInt32();
        row.TemporaryItemEntry = fields[6].GetUInt32();
        rows.push_back(row);
    }
    while (result->NextRow());

    return rows;
}

bool CommitSoloArenaCharacterTransaction(CharacterDatabaseTransaction transaction,
                                         char const* operation, std::string& error)
{
    // Character inventory prepared statements are registered for asynchronous
    // connections. Waiting for that worker here preserves the recovery
    // journal's required ordering without executing those statements through
    // a synchronous connection, where they are not prepared.
    TransactionCallback callback = CharacterDatabase.AsyncCommitTransaction(transaction);
    try
    {
        if (callback.m_future.get())
            return true;
    }
    catch (std::exception const& exception)
    {
        error = Trinity::StringFormat("%s database transaction raised an exception: %s",
            operation, exception.what());
        return false;
    }

    error = Trinity::StringFormat("%s database transaction failed", operation);
    return false;
}

bool SaveSoloArenaInventory(Player* participant, char const* operation, std::string& error)
{
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    participant->SaveInventoryAndGoldToDB(transaction);
    return CommitSoloArenaCharacterTransaction(transaction, operation, error);
}

uint32 GetWorldBossLegendaryCloak(Player const* bot)
{
    if (!bot)
        return 0;

    Specializations specialization = bot->GetSpecialization();
    switch (GetWorldBossPreviewRole(specialization))
    {
        case WorldBossPreviewRole::Tank:
            // Agility tanks use Qian-Le; plate tanks use Qian-Ying.
            return bot->GetClass() == CLASS_DRUID || bot->GetClass() == CLASS_MONK ?
                102245 : 102250;
        case WorldBossPreviewRole::Healer:
            return 102247; // Jina-Kang, Kindness of Chi-Ji
        case WorldBossPreviewRole::Damage:
            switch (specialization)
            {
                case SPEC_DRUID_BALANCE:
                case SPEC_MAGE_ARCANE:
                case SPEC_MAGE_FIRE:
                case SPEC_MAGE_FROST:
                case SPEC_PRIEST_SHADOW:
                case SPEC_SHAMAN_ELEMENTAL:
                case SPEC_WARLOCK_AFFLICTION:
                case SPEC_WARLOCK_DEMONOLOGY:
                case SPEC_WARLOCK_DESTRUCTION:
                    return 102246; // Xing-Ho, intellect damage
                case SPEC_DRUID_FERAL:
                case SPEC_HUNTER_BEAST_MASTERY:
                case SPEC_HUNTER_MARKSMANSHIP:
                case SPEC_HUNTER_SURVIVAL:
                case SPEC_MONK_WINDWALKER:
                case SPEC_ROGUE_ASSASSINATION:
                case SPEC_ROGUE_COMBAT:
                case SPEC_ROGUE_SUBTLETY:
                case SPEC_SHAMAN_ENHANCEMENT:
                    return 102248; // Fen-Yu, agility damage
                default:
                    return 102249; // Gong-Lu, strength damage
            }
        case WorldBossPreviewRole::None:
            break;
    }
    return 0;
}

bool EnsureWorldBossLegendaryCloak(Player* bot, uint32& cloakEntry,
    bool& changed, std::string& error)
{
    changed = false;
    cloakEntry = GetWorldBossLegendaryCloak(bot);
    if (!bot || !cloakEntry)
    {
        error = "specialization has no legendary cloak mapping";
        return false;
    }

    Item* equipped = bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
        EQUIPMENT_SLOT_BACK);
    if (equipped && equipped->GetEntry() == cloakEntry)
        return true;

    ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(cloakEntry);
    if (!itemTemplate || itemTemplate->InventoryType != INVTYPE_CLOAK ||
        bot->CanUseItem(itemTemplate) != EQUIP_ERR_OK)
    {
        error = "mapped legendary cloak failed template/use validation";
        return false;
    }

    uint16 equipmentDestination = 0;
    Item* cloak = bot->GetItemByEntry(cloakEntry);
    bool created = false;
    if (cloak)
    {
        if (bot->CanEquipItem(EQUIPMENT_SLOT_BACK, equipmentDestination,
            cloak, true, true) != EQUIP_ERR_OK)
        {
            error = "existing legendary cloak cannot be equipped";
            return false;
        }
    }
    else
    {
        if (bot->CanEquipNewItem(EQUIPMENT_SLOT_BACK, equipmentDestination,
            cloakEntry, true) != EQUIP_ERR_OK)
        {
            error = "legendary cloak cannot be equipped in the back slot";
            return false;
        }

        ItemPosCountVec storageDestination;
        if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, storageDestination,
            cloakEntry, 1) != EQUIP_ERR_OK)
        {
            error = "no free inventory slot is available for the legendary cloak swap";
            return false;
        }
        cloak = bot->StoreNewItem(storageDestination, cloakEntry, true);
        if (!cloak)
        {
            error = "core failed to create the mapped legendary cloak";
            return false;
        }
        created = true;
    }

    uint16 cloakPosition = cloak->GetPos();
    uint32 cloakGuid = cloak->GetGUID().GetCounter();
    uint16 equipmentPosition = uint16(INVENTORY_SLOT_BAG_0) << 8 |
        EQUIPMENT_SLOT_BACK;
    bot->SwapItem(cloakPosition, equipmentPosition);
    equipped = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_BACK);
    if (!equipped || equipped->GetGUID().GetCounter() != cloakGuid)
    {
        if (created)
            if (Item* failed = bot->GetItemByGuid(
                ObjectGuid(HighGuid::Item, cloakGuid)))
                bot->DestroyItem(failed->GetBagSlot(), failed->GetSlot(), true);
        error = "core refused the legendary cloak equipment swap";
        return false;
    }

    if (!SaveSoloArenaInventory(bot, "world-boss legendary cloak", error))
        return false;

    // SaveInventoryAndGoldToDB retires the character inventory queue, but
    // both sides of SwapItem can still be present in the owner's Map update
    // set. A staged bot may be logged out immediately after cleanup, before
    // that Map tick runs. Retire only the two already-persisted item updates
    // while the bot and its Map are still available.
    if (Item* equippedCloak = bot->GetItemByPos(
        INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_BACK))
        equippedCloak->ClearUpdateMask(true);
    if (Item* preservedCloak = bot->GetItemByPos(cloakPosition))
        preservedCloak->ClearUpdateMask(true);

    changed = true;
    return true;
}

bool EnsureWorldBossPveArmor(Player* bot, uint32& itemSet,
    uint32& changedSlots, std::string& error)
{
    changedSlots = 0;
    itemSet = 0;
    if (!bot)
    {
        error = "bot is offline";
        return false;
    }
    if (GetSoloArenaLoadoutBackupCount(bot->GetGUID().GetCounter()))
    {
        error = "bot still has an active temporary PvP loadout journal";
        return false;
    }

    WorldBossPveLoadoutPlan const* plan = GetWorldBossPveLoadoutPlan(
        bot->GetSpecialization());
    if (!plan)
    {
        error = "specialization has no mapped T16 PvE set";
        return false;
    }
    itemSet = plan->ItemSet;
    std::vector<std::pair<uint8, uint16>> changedPositions;

    auto fail = [&](std::string const& reason) -> bool
    {
        error = reason;
        if (changedSlots)
        {
            std::string saveError;
            if (!SaveSoloArenaInventory(bot,
                "partial world-boss T16 PvE armor", saveError))
                error += "; partial inventory save also failed: " + saveError;
        }
        return false;
    };

    for (uint8 index = 0; index < plan->Items.size(); ++index)
    {
        uint8 equipmentSlot = SoloArenaLoadoutEquipmentSlots[index];
        uint16 equipmentPosition = uint16(INVENTORY_SLOT_BAG_0) << 8 |
            equipmentSlot;
        uint32 entry = plan->Items[index];
        Item* equipped = bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
            equipmentSlot);
        if (equipped && equipped->GetEntry() == entry)
            continue;

        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(entry);
        if (!itemTemplate || itemTemplate->ItemSet != plan->ItemSet ||
            itemTemplate->ItemLevel != 566 ||
            !IsSoloArenaLoadoutInventoryType(index,
                itemTemplate->InventoryType) ||
            !(uint32(itemTemplate->AllowableClass) &
                (1u << (bot->GetClass() - 1))) ||
            bot->CanUseItem(itemTemplate) != EQUIP_ERR_OK)
            return fail("mapped T16 item failed template/class/use validation");

        if (equipped &&
            bot->CanUnequipItem(equipmentPosition, true) != EQUIP_ERR_OK)
            return fail("current armor cannot be moved safely to inventory");

        Item* replacement = bot->GetItemByEntry(entry);
        bool created = false;
        uint16 equipDestination = 0;
        if (replacement)
        {
            if (Player::IsEquipmentPos(replacement->GetPos()) ||
                bot->CanEquipItem(equipmentSlot, equipDestination,
                    replacement, true, true) != EQUIP_ERR_OK)
                return fail("existing mapped T16 item cannot be equipped safely");
        }
        else
        {
            if (bot->CanEquipNewItem(equipmentSlot, equipDestination,
                entry, true) != EQUIP_ERR_OK)
                return fail("mapped T16 item cannot be equipped in its required slot");

            ItemPosCountVec storageDestination;
            if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT,
                storageDestination, entry, 1) != EQUIP_ERR_OK)
                return fail("not enough free inventory space to preserve old armor");
            replacement = bot->StoreNewItem(storageDestination, entry, true);
            if (!replacement)
                return fail("core failed to create the mapped T16 item");
            created = true;
        }

        uint32 replacementGuid = replacement->GetGUID().GetCounter();
        uint16 replacementPosition = replacement->GetPos();
        bot->SwapItem(replacementPosition, equipmentPosition);
        equipped = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, equipmentSlot);
        if (!equipped || equipped->GetGUID().GetCounter() != replacementGuid)
        {
            if (created)
                if (Item* failed = bot->GetItemByGuid(
                    ObjectGuid(HighGuid::Item, replacementGuid)))
                    bot->DestroyItem(failed->GetBagSlot(), failed->GetSlot(), true);
            return fail("core refused the T16 armor equipment swap");
        }
        changedPositions.emplace_back(equipmentSlot, replacementPosition);
        ++changedSlots;
    }

    if (changedSlots && !SaveSoloArenaInventory(bot,
        "world-boss T16 PvE armor", error))
        return false;

    // As with the legendary cloak swap above, the durable DB save completes
    // before a staged bot can be logged out. Clear the two Map-update markers
    // created by every successful swap so Item::~Item never has to look up an
    // owner which has already left ObjectAccessor.
    for (auto const& changed : changedPositions)
    {
        if (Item* equippedItem = bot->GetItemByPos(
            INVENTORY_SLOT_BAG_0, changed.first))
            equippedItem->ClearUpdateMask(true);
        if (Item* preservedItem = bot->GetItemByPos(changed.second))
            preservedItem->ClearUpdateMask(true);
    }
    return true;
}

bool RestoreSoloArenaLoadout(Player* participant, char const* reason, uint32& restoredSlots,
                             uint32& remainingSlots, std::string& error)
{
    restoredSlots = 0;
    remainingSlots = 0;
    error.clear();
    if (!participant)
    {
        error = "participant is offline";
        return false;
    }

    uint32 ownerGuid = participant->GetGUID().GetCounter();
    std::vector<SoloArenaLoadoutBackupRow> rows = LoadSoloArenaLoadoutBackups(ownerGuid);
    if (rows.empty())
        return true;

    std::vector<uint8> completedSlots;
    for (SoloArenaLoadoutBackupRow const& row : rows)
    {
        uint16 equipmentPos = uint16(INVENTORY_SLOT_BAG_0) << 8 | row.EquipmentSlot;
        Item* equipped = participant->GetItemByPos(INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
        Item* original = row.OriginalItemGuid ? participant->GetItemByGuid(
            ObjectGuid(HighGuid::Item, row.OriginalItemGuid)) : nullptr;
        Item* temporary = participant->GetItemByGuid(
            ObjectGuid(HighGuid::Item, row.TemporaryItemGuid));

        if (original && original->GetEntry() != row.OriginalItemEntry)
        {
            error = "original item GUID resolves to an unexpected entry";
            continue;
        }
        if (temporary && temporary->GetEntry() != row.TemporaryItemEntry)
        {
            error = "temporary item GUID resolves to an unexpected entry";
            continue;
        }

        if (row.OriginalItemGuid)
        {
            if (equipped && equipped->GetGUID().GetCounter() == row.OriginalItemGuid)
            {
                // Crash before the swap, or this slot was already restored. Only
                // the exact temporary item owned by the journal may be removed.
            }
            else if (equipped && equipped->GetGUID().GetCounter() == row.TemporaryItemGuid && original)
            {
                uint16 originalPos = original->GetPos();
                participant->SwapItem(originalPos, equipmentPos);
                equipped = participant->GetItemByPos(INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
                if (!equipped || equipped->GetGUID().GetCounter() != row.OriginalItemGuid)
                {
                    // Generated random-bot gear can fail normal SwapItem
                    // validation (for example because an old item no longer
                    // satisfies current template requirements). This is still
                    // an exact journaled pair: the recorded temporary instance
                    // occupies the recorded equipment slot and the recorded
                    // original instance is owned by this character. Remove only
                    // that temporary instance, then restore only that original
                    // instance through the same guarded primitives used by the
                    // empty-slot crash recovery below. If the final equip fails,
                    // the journal remains and the original remains owned by the
                    // character, so a later recovery can retry safely.
                    equipped = participant->GetItemByPos(
                        INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
                    if (!equipped ||
                        equipped->GetGUID().GetCounter() != row.TemporaryItemGuid)
                    {
                        error = "swap failed and the recorded temporary item no longer occupies the slot";
                        continue;
                    }

                    participant->DestroyItem(
                        equipped->GetBagSlot(), equipped->GetSlot(), true);
                    if (participant->GetItemByGuid(
                        ObjectGuid(HighGuid::Item, row.TemporaryItemGuid)) ||
                        participant->GetItemByPos(
                            INVENTORY_SLOT_BAG_0, row.EquipmentSlot))
                    {
                        error = "core refused to remove the recorded temporary item";
                        continue;
                    }

                    original = participant->GetItemByGuid(
                        ObjectGuid(HighGuid::Item, row.OriginalItemGuid));
                    if (!original || original->GetEntry() != row.OriginalItemEntry)
                    {
                        error = "recorded original item disappeared during guarded recovery";
                        continue;
                    }

                    participant->RemoveItem(
                        original->GetBagSlot(), original->GetSlot(), true);
                    participant->EquipItem(equipmentPos, original, true);
                    equipped = participant->GetItemByPos(
                        INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
                    if (!equipped ||
                        equipped->GetGUID().GetCounter() != row.OriginalItemGuid)
                    {
                        error = "core refused the guarded occupied-slot crash recovery";
                        continue;
                    }
                }
                temporary = participant->GetItemByGuid(ObjectGuid(HighGuid::Item, row.TemporaryItemGuid));
            }
            else if (!equipped && original && !temporary)
            {
                // A process crash can persist the original item's move to the
                // backpack after the journal commit but before the temporary
                // item reaches its equipment slot. In that exact state the
                // recorded equipment slot is empty, the exact original GUID is
                // still owned by the character and the exact temporary GUID no
                // longer exists. Re-equip only that recorded original instance.
                uint16 originalPos = original->GetPos();
                participant->SwapItem(originalPos, equipmentPos);
                equipped = participant->GetItemByPos(
                    INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
                if (!equipped ||
                    equipped->GetGUID().GetCounter() != row.OriginalItemGuid)
                {
                    // Normal SwapItem validation can reject old generated bot
                    // gear even though this is the exact previously equipped
                    // instance. The journal, owner GUID, entry and empty target
                    // slot have all been verified, so restore that known item
                    // through the core remove/equip primitives.
                    participant->RemoveItem(
                        original->GetBagSlot(), original->GetSlot(), true);
                    participant->EquipItem(equipmentPos, original, true);
                    equipped = participant->GetItemByPos(
                        INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
                    if (!equipped ||
                        equipped->GetGUID().GetCounter() != row.OriginalItemGuid)
                    {
                        error = "core refused the guarded empty-slot crash recovery";
                        continue;
                    }
                }
            }
            else
            {
                error = !original ? "original item instance is not in the character inventory" :
                    "equipment slot contains neither the recorded original nor temporary item";
                continue;
            }
        }

        if (temporary)
        {
            uint16 temporaryPos = temporary->GetPos();
            if (Player::IsEquipmentPos(temporaryPos) &&
                participant->CanUnequipItem(temporaryPos, false) != EQUIP_ERR_OK)
            {
                error = "temporary item cannot currently be unequipped";
                continue;
            }
            participant->DestroyItem(temporary->GetBagSlot(), temporary->GetSlot(), true);
        }

        if (participant->GetItemByGuid(ObjectGuid(HighGuid::Item, row.TemporaryItemGuid)))
        {
            error = "temporary item still exists after the guarded destroy";
            continue;
        }

        Item* finalEquipped = participant->GetItemByPos(INVENTORY_SLOT_BAG_0, row.EquipmentSlot);
        if (row.OriginalItemGuid && (!finalEquipped ||
            finalEquipped->GetGUID().GetCounter() != row.OriginalItemGuid))
        {
            error = "original item was not restored to its exact equipment slot";
            continue;
        }

        completedSlots.push_back(row.EquipmentSlot);
        ++restoredSlots;
    }

    if (!completedSlots.empty())
    {
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        participant->SaveInventoryAndGoldToDB(transaction);
        for (uint8 equipmentSlot : completedSlots)
            transaction->PAppend(
                "DELETE FROM `solo_arena_loadout_backup` WHERE `owner_guid`=%u AND `equipment_slot`=%u",
                ownerGuid, uint32(equipmentSlot));
        if (!CommitSoloArenaCharacterTransaction(transaction, "loadout restore", error))
        {
            remainingSlots = GetSoloArenaLoadoutBackupCount(ownerGuid);
            TC_LOG_ERROR("server",
                "SoloArena loadout restore database failure name=%s guid=%u reason=%s "
                "remaining=%u error=%s",
                participant->GetName().c_str(), ownerGuid, reason ? reason : "unspecified",
                remainingSlots, error.c_str());
            return false;
        }

        // SwapItem marks the restored item for a map update. Staged bots can leave
        // the Arena and log out before that map processes its update set. Remove
        // the marker while the owner still belongs to the same map; the inventory
        // transaction above has already persisted the exact restored position.
        // Otherwise Item::~Item later attempts RemoveFromUpdate after the bot has
        // left ObjectAccessor and emits "owner not found" for every restored slot.
        for (uint8 equipmentSlot : completedSlots)
            if (Item* restored = participant->GetItemByPos(
                INVENTORY_SLOT_BAG_0, equipmentSlot))
                restored->ClearUpdateMask(true);
    }

    remainingSlots = GetSoloArenaLoadoutBackupCount(ownerGuid);
    TC_LOG_INFO("server",
        "SoloArena loadout restore name=%s guid=%u reason=%s restored=%u remaining=%u result=%s",
        participant->GetName().c_str(), ownerGuid, reason ? reason : "unspecified",
        restoredSlots, remainingSlots, remainingSlots ? "incomplete" : "complete");
    return remainingSlots == 0;
}

bool ApplySoloArenaLoadout(Player* participant, uint32 requesterGuid, uint32& changedSlots,
                           std::string& error)
{
    changedSlots = 0;
    error.clear();
    if (!participant || !participant->IsAlive() || participant->IsBeingTeleported() ||
        participant->GetGroup() || participant->InBattlegroundQueue() || participant->InBattleground())
    {
        error = participant ? Trinity::StringFormat(
            "participant %s not ready (alive=%u teleporting=%u group=%u queue=%u battleground=%u)",
            participant->GetName().c_str(), participant->IsAlive() ? 1u : 0u,
            participant->IsBeingTeleported() ? 1u : 0u,
            participant->GetGroup() ? 1u : 0u,
            participant->InBattlegroundQueue() ? 1u : 0u,
            participant->InBattleground() ? 1u : 0u) : "participant is offline";
        return false;
    }

    uint32 ownerGuid = participant->GetGUID().GetCounter();
    if (GetSoloArenaLoadoutBackupCount(ownerGuid))
    {
        error = "participant already has an active recovery journal";
        return false;
    }

    SoloArenaLoadoutPlan const* plan = GetSoloArenaLoadoutPlan(participant->GetSpecialization());
    if (!plan)
    {
        error = "specialization has no mapped Prideful set";
        return false;
    }

    std::array<uint32, 5> const& plannedItems = participant->GetTeam() == ALLIANCE ?
        plan->AllianceItems : plan->HordeItems;
    for (uint8 itemIndex = 0; itemIndex < plannedItems.size(); ++itemIndex)
    {
        uint8 equipmentSlot = SoloArenaLoadoutEquipmentSlots[itemIndex];
        uint16 equipmentPos = uint16(INVENTORY_SLOT_BAG_0) << 8 | equipmentSlot;
        Item* original = participant->GetItemByPos(INVENTORY_SLOT_BAG_0, equipmentSlot);
        if (original && original->GetEntry() == plannedItems[itemIndex])
            continue;

        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(plannedItems[itemIndex]);
        if (!itemTemplate || itemTemplate->ItemSet != plan->ItemSet ||
            !IsSoloArenaLoadoutInventoryType(itemIndex, itemTemplate->InventoryType) ||
            !(uint32(itemTemplate->AllowableClass) & (1u << (participant->GetClass() - 1))) ||
            participant->CanUseItem(itemTemplate) != EQUIP_ERR_OK)
        {
            error = "planned item failed the strict template/class/spec validation";
            return false;
        }

        if (original && participant->CanUnequipItem(equipmentPos, true) != EQUIP_ERR_OK)
        {
            error = "original item cannot currently be unequipped";
            return false;
        }

        uint16 equipDestination = 0;
        if (participant->CanEquipNewItem(equipmentSlot, equipDestination,
            plannedItems[itemIndex], true) != EQUIP_ERR_OK)
        {
            error = "planned item cannot be equipped in the required slot";
            return false;
        }

        ItemPosCountVec storageDestination;
        if (participant->CanStoreNewItem(NULL_BAG, NULL_SLOT, storageDestination,
            plannedItems[itemIndex], 1) != EQUIP_ERR_OK)
        {
            error = "no inventory slot is available for the temporary/original item swap";
            return false;
        }

        Item* temporary = participant->StoreNewItem(storageDestination,
            plannedItems[itemIndex], true);
        if (!temporary)
        {
            error = "core failed to create the temporary item";
            return false;
        }

        uint16 temporaryPos = temporary->GetPos();
        uint32 temporaryGuid = temporary->GetGUID().GetCounter();
        uint32 originalGuid = original ? original->GetGUID().GetCounter() : 0;
        uint32 originalEntry = original ? original->GetEntry() : 0;

        // Persist both the still-unswapped inventory and its recovery journal
        // before changing the equipped slot. The asynchronous character DB
        // worker is awaited, so a crash after this point can always identify
        // the exact original and the exact module-created temporary item.
        CharacterDatabaseTransaction beforeSwap = CharacterDatabase.BeginTransaction();
        participant->SaveInventoryAndGoldToDB(beforeSwap);
        beforeSwap->PAppend(
            "INSERT INTO `solo_arena_loadout_backup` "
            "(`owner_guid`,`requester_guid`,`equipment_slot`,`original_item_guid`,`original_item_entry`,"
            "`storage_bag`,`storage_slot`,`temporary_item_guid`,`temporary_item_entry`) "
            "VALUES (%u,%u,%u,%u,%u,%u,%u,%u,%u)",
            ownerGuid, requesterGuid, uint32(equipmentSlot), originalGuid, originalEntry,
            uint32(temporary->GetBagSlot()), uint32(temporary->GetSlot()), temporaryGuid,
            plannedItems[itemIndex]);
        if (!CommitSoloArenaCharacterTransaction(beforeSwap, "pre-swap journal", error))
        {
            // The failed transaction did not create a recovery row or persist
            // the temporary item. Remove its in-memory instance and persist the
            // cleanup before returning to the caller.
            Item* failedTemporary = participant->GetItemByGuid(
                ObjectGuid(HighGuid::Item, temporaryGuid));
            if (failedTemporary)
                participant->DestroyItem(failedTemporary->GetBagSlot(), failedTemporary->GetSlot(), true);

            std::string cleanupError;
            if (!SaveSoloArenaInventory(participant, "failed pre-swap cleanup", cleanupError))
                error += "; cleanup also failed: " + cleanupError;
            return false;
        }

        participant->SwapItem(temporaryPos, equipmentPos);
        Item* equipped = participant->GetItemByPos(INVENTORY_SLOT_BAG_0, equipmentSlot);
        if (!equipped || equipped->GetGUID().GetCounter() != temporaryGuid)
        {
            error = "core refused the guarded temporary/original item swap";
            return false;
        }
        if (originalGuid)
        {
            Item* storedOriginal = participant->GetItemByGuid(ObjectGuid(HighGuid::Item, originalGuid));
            if (!storedOriginal || storedOriginal->GetPos() != temporaryPos)
            {
                error = "original item did not arrive in the journaled storage slot";
                return false;
            }
        }

        if (!SaveSoloArenaInventory(participant, "post-swap inventory", error))
            return false;
        ++changedSlots;
    }

    TC_LOG_INFO("server",
        "SoloArena temporary loadout applied name=%s guid=%u requester=%u changed=%u target-set=%u",
        participant->GetName().c_str(), ownerGuid, requesterGuid, changedSlots, plan->ItemSet);
    return true;
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
    if (!guid)
        return false;

    if (std::find(SoloArenaAutomaticRequesterTeam.begin(),
        SoloArenaAutomaticRequesterTeam.end(), guid) != SoloArenaAutomaticRequesterTeam.end() ||
        std::find(SoloArenaAutomaticOpponentTeam.begin(),
        SoloArenaAutomaticOpponentTeam.end(), guid) != SoloArenaAutomaticOpponentTeam.end())
        return true;

    return guid && (guid == SoloArenaStagedRequester || guid == SoloArenaStagedTeammate ||
        guid == SoloArenaStagedOpponentHealer || guid == SoloArenaStagedOpponentDamage);
}

BattlegroundQueueTypeId GetSoloArenaQueueType(uint8 arenaType)
{
    switch (arenaType)
    {
        case ARENA_TYPE_2v2: return BATTLEGROUND_QUEUE_2v2;
        case ARENA_TYPE_3v3: return BATTLEGROUND_QUEUE_3v3;
        case ARENA_TYPE_5v5: return BATTLEGROUND_QUEUE_5v5;
        default:             return BATTLEGROUND_QUEUE_NONE;
    }
}

std::vector<uint32> GetSoloArenaAutomaticParticipantGuids()
{
    std::vector<uint32> guids = SoloArenaAutomaticRequesterTeam;
    guids.insert(guids.end(), SoloArenaAutomaticOpponentTeam.begin(),
        SoloArenaAutomaticOpponentTeam.end());
    return guids;
}

std::vector<uint32> GetSoloArenaTrackedParticipantGuids()
{
    std::vector<uint32> guids = GetSoloArenaAutomaticParticipantGuids();
    if (!guids.empty())
        return guids;
    return { SoloArenaStagedRequester, SoloArenaStagedTeammate,
        SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage };
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

bool HasExactSoloArenaQueueGroup(BattlegroundQueue& queue,
                                 std::vector<uint32> const& memberGuids,
                                 uint8 arenaType, uint32& invitedInstance)
{
    if (memberGuids.empty())
        return false;

    GroupQueueInfo reference;
    ObjectGuid first = ObjectGuid::Create<HighGuid::Player>(memberGuids.front());
    if (!queue.GetPlayerGroupInfoData(first, &reference))
        return false;

    auto isExact = [&memberGuids, arenaType](GroupQueueInfo const& info) -> bool
    {
        if (info.BgTypeId != BATTLEGROUND_AA || info.ArenaType != arenaType ||
            info.IsRated || info.Players.size() != memberGuids.size())
            return false;

        for (uint32 guid : memberGuids)
            if (info.Players.find(ObjectGuid::Create<HighGuid::Player>(guid)) == info.Players.end())
                return false;
        return true;
    };

    if (!isExact(reference))
        return false;

    for (uint32 guid : memberGuids)
    {
        GroupQueueInfo memberInfo;
        if (!queue.GetPlayerGroupInfoData(ObjectGuid::Create<HighGuid::Player>(guid), &memberInfo) ||
            !isExact(memberInfo) || memberInfo.JoinTime != reference.JoinTime ||
            memberInfo.IsInvitedToBGInstanceGUID != reference.IsInvitedToBGInstanceGUID)
            return false;
    }

    invitedInstance = reference.IsInvitedToBGInstanceGUID;
    return true;
}

bool HasExactSoloArenaQueueGroup(BattlegroundQueue& queue, uint32 firstGuid, uint32 secondGuid,
                                 uint32& invitedInstance)
{
    return HasExactSoloArenaQueueGroup(queue, { firstGuid, secondGuid },
        ARENA_TYPE_2v2, invitedInstance);
}

bool AcceptSoloArenaInvite(Player* participant, uint32 invitedInstance,
                           BattlegroundQueueTypeId queueType = BATTLEGROUND_QUEUE_2v2)
{
    if (!participant || !participant->GetSession() || !invitedInstance ||
        participant->InBattleground() || participant->IsBeingTeleported() ||
        !participant->IsInvitedForBattlegroundQueueType(queueType))
        return false;

    uint32 queueSlot = participant->GetBattlegroundQueueIndex(queueType);
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
    std::vector<SoloArenaPreviewCandidate const*> eligible;
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
        eligible.push_back(&candidate);
    }

    if (eligible.empty())
        return nullptr;

    // Candidates have already passed faction, specialization and equipment
    // requirements. Random choice prevents every match from reusing the
    // first (highest GUID/score ordered) characters.
    return eligible[urand(0, uint32(eligible.size() - 1))];
}

Player* FindSoloArenaParticipant(uint32 guid)
{
    return guid ? ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
}

bool GetSoloArenaAutomaticParticipants(std::vector<Player*>& participants)
{
    participants.clear();
    for (uint32 guid : GetSoloArenaAutomaticParticipantGuids())
    {
        Player* participant = FindSoloArenaParticipant(guid);
        if (!participant)
            return false;
        participants.push_back(participant);
    }
    return !participants.empty();
}

bool GetSoloArenaAutomaticLoadoutReadyParticipants(
    std::vector<Player*>& participants, std::string& waitingReason)
{
    waitingReason.clear();
    if (!GetSoloArenaAutomaticParticipants(participants))
    {
        waitingReason = "one or more participants are still logging in";
        return false;
    }

    for (Player* participant : participants)
    {
        if (!participant->IsInWorld() || participant->IsBeingTeleported())
        {
            waitingReason = Trinity::StringFormat("%s is still entering the world",
                participant->GetName().c_str());
            return false;
        }

        uint32 guid = participant->GetGUID().GetCounter();
        if (!participant->IsAlive() &&
            SoloArenaStagedBots.find(guid) != SoloArenaStagedBots.end() &&
            !participant->GetGroup() && !participant->InBattlegroundQueue() &&
            !participant->InBattleground())
        {
            bool hadGhostFlag = participant->HasPlayerFlag(PLAYER_FLAGS_GHOST);
            uint32 oldHealth = participant->GetHealth();
            participant->ResurrectPlayer(1.0f, false);
            participant->SpawnCorpseBones();
            participant->SetFullHealth();
            TC_LOG_INFO("server",
                "SoloArena revived selected bot name=%s guid=%u ghost=%u health=%u/%u",
                participant->GetName().c_str(), guid, hadGhostFlag ? 1u : 0u,
                oldHealth, participant->GetMaxHealth());
        }

        if (!participant->IsAlive() || participant->GetGroup() ||
            participant->InBattlegroundQueue() || participant->InBattleground())
        {
            waitingReason = Trinity::StringFormat(
                "%s is not ready (alive=%u group=%u queue=%u battleground=%u)",
                participant->GetName().c_str(), participant->IsAlive() ? 1u : 0u,
                participant->GetGroup() ? 1u : 0u,
                participant->InBattlegroundQueue() ? 1u : 0u,
                participant->InBattleground() ? 1u : 0u);
            return false;
        }
    }

    return true;
}

bool LoadSoloArenaAutomaticCandidates(Player* requester,
    std::vector<SoloArenaPreviewCandidate>& candidates, uint32& rejectedNeutral,
    uint32& rejectedSpec, uint32& rejectedGear, std::string& error)
{
    candidates.clear();
    rejectedNeutral = rejectedSpec = rejectedGear = 0;
    error.clear();
    if (!requester || sPlayerbotAIConfig->randomBotAccounts.empty())
    {
        error = "no requester or configured random-bot accounts";
        return false;
    }

    uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
    uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
    QueryResult result = CharacterDatabase.PQuery(
        "SELECT guid,name,race,class,level,talentTree,activespec,equipmentCache "
        "FROM characters WHERE account >= %u AND account <= %u AND level = %u AND online = 0 "
        "AND guid NOT IN (SELECT guid FROM guild_member) "
        "AND guid NOT IN (SELECT memberGuid FROM group_member)",
        minAccount, maxAccount, requester->GetLevel());
    if (!result)
    {
        error = "no unused offline random-bot characters";
        return false;
    }

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
        if ((!IsSoloArenaDamage(candidate.Role) && candidate.Role != SoloArenaPreviewRole::Healer) ||
            !GetSoloArenaLoadoutPlan(candidate.Specialization))
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
    return true;
}

SoloArenaPreviewCandidate const* SelectSoloArenaAutomaticCandidate(
    std::vector<SoloArenaPreviewCandidate> const& candidates,
    SoloArenaPreviewRole role, uint32 team, std::vector<uint32> const& selected,
    uint8 forbiddenClass = 0)
{
    SoloArenaPreviewCandidate const* candidate = FindSoloArenaCandidate(
        candidates, role, team, true, forbiddenClass, selected);
    if (!candidate && forbiddenClass)
        candidate = FindSoloArenaCandidate(candidates, role, team, true, 0, selected);
    return candidate;
}

bool StageSoloArenaAutomaticBots(Player* requester, std::string& error)
{
    error.clear();
    std::vector<SoloArenaPreviewCandidate> candidates;
    uint32 rejectedNeutral = 0;
    uint32 rejectedSpec = 0;
    uint32 rejectedGear = 0;
    if (!LoadSoloArenaAutomaticCandidates(requester, candidates, rejectedNeutral,
        rejectedSpec, rejectedGear, error))
        return false;

    SoloArenaPreviewRole requesterRole = GetSoloArenaPreviewRole(requester->GetSpecialization());
    if (!IsSoloArenaDamage(requesterRole) && requesterRole != SoloArenaPreviewRole::Healer)
    {
        error = "requester requires an active damage or healer specialization";
        return false;
    }

    uint32 requesterTeam = requester->GetTeam();
    uint32 opponentTeam = requesterTeam == ALLIANCE ? HORDE : ALLIANCE;
    std::vector<uint32> selected;
    std::vector<SoloArenaPreviewCandidate const*> requesterBots;
    std::vector<SoloArenaPreviewCandidate const*> opponentBots;

    if (requesterRole != SoloArenaPreviewRole::Healer)
    {
        SoloArenaPreviewCandidate const* healer = SelectSoloArenaAutomaticCandidate(
            candidates, SoloArenaPreviewRole::Healer, requesterTeam, selected,
            requester->GetClass());
        if (!healer)
        {
            error = "no same-faction healer is available";
            return false;
        }
        requesterBots.push_back(healer);
        selected.push_back(healer->Guid);
    }

    while (requesterBots.size() + 1 < SoloArenaAutomaticTeamSize)
    {
        SoloArenaPreviewCandidate const* damage = SelectSoloArenaAutomaticCandidate(
            candidates, SoloArenaPreviewRole::Melee, requesterTeam, selected,
            requesterBots.empty() ? requester->GetClass() : requesterBots.back()->Class);
        if (!damage)
        {
            error = "not enough same-faction damage players are available";
            return false;
        }
        requesterBots.push_back(damage);
        selected.push_back(damage->Guid);
    }

    SoloArenaPreviewCandidate const* opponentHealer = SelectSoloArenaAutomaticCandidate(
        candidates, SoloArenaPreviewRole::Healer, opponentTeam, selected);
    if (!opponentHealer)
    {
        error = "no opposing-faction healer is available";
        return false;
    }
    opponentBots.push_back(opponentHealer);
    selected.push_back(opponentHealer->Guid);

    while (opponentBots.size() < SoloArenaAutomaticTeamSize)
    {
        SoloArenaPreviewCandidate const* damage = SelectSoloArenaAutomaticCandidate(
            candidates, SoloArenaPreviewRole::Melee, opponentTeam, selected,
            opponentBots.back()->Class);
        if (!damage)
        {
            error = "not enough opposing-faction damage players are available";
            return false;
        }
        opponentBots.push_back(damage);
        selected.push_back(damage->Guid);
    }

    for (SoloArenaPreviewCandidate const* candidate : requesterBots)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(candidate->Guid);
        if (ObjectAccessor::FindPlayer(guid) || sRandomPlayerbotMgr->GetPlayerBot(guid) ||
            sRandomPlayerbotMgr->IsBotLoading(guid))
        {
            error = "a selected teammate is already online or loading";
            return false;
        }
    }
    for (SoloArenaPreviewCandidate const* candidate : opponentBots)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(candidate->Guid);
        if (ObjectAccessor::FindPlayer(guid) || sRandomPlayerbotMgr->GetPlayerBot(guid) ||
            sRandomPlayerbotMgr->IsBotLoading(guid))
        {
            error = "a selected opponent is already online or loading";
            return false;
        }
    }

    SoloArenaAutomaticRequesterTeam.clear();
    SoloArenaAutomaticOpponentTeam.clear();
    SoloArenaAutomaticRequesterTeam.push_back(requester->GetGUID().GetCounter());
    for (SoloArenaPreviewCandidate const* candidate : requesterBots)
        SoloArenaAutomaticRequesterTeam.push_back(candidate->Guid);
    for (SoloArenaPreviewCandidate const* candidate : opponentBots)
        SoloArenaAutomaticOpponentTeam.push_back(candidate->Guid);

    // Preserve the original 2v2 diagnostic fields for the verified manual
    // commands. Automatic 3v3/5v5 uses the vectors above exclusively.
    SoloArenaStagedRequester = requester->GetGUID().GetCounter();
    SoloArenaStagedTeammate = requesterBots.empty() ? 0 : requesterBots.front()->Guid;
    SoloArenaStagedOpponentHealer = opponentBots.empty() ? 0 : opponentBots.front()->Guid;
    SoloArenaStagedOpponentDamage = opponentBots.size() < 2 ? 0 : opponentBots[1]->Guid;
    SoloArenaAutomaticHealthRestoreScheduled.clear();
    SoloArenaAutomaticExitTimer = 0;

    auto login = [](SoloArenaPreviewCandidate const* candidate, char const* side)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(candidate->Guid);
        SoloArenaStagedBots[candidate->Guid] = candidate->Name;
        sRandomPlayerbotMgr->AddPlayerBot(guid, 0);
        TC_LOG_INFO("server",
            "SoloArena automatic login requested side=%s name=%s guid=%u faction=%s role=%s",
            side, candidate->Name.c_str(), candidate->Guid,
            SoloArenaTeamName(candidate->Team), SoloArenaRoleName(candidate->Role));
    };
    for (SoloArenaPreviewCandidate const* candidate : requesterBots)
        login(candidate, "requester");
    for (SoloArenaPreviewCandidate const* candidate : opponentBots)
        login(candidate, "opponent");

    TC_LOG_INFO("server",
        "SoloArena automatic %uv%u selected requester=%s faction=%s bots=%u eligible=%u rejected(neutral/spec/gear)=%u/%u/%u",
        uint32(SoloArenaAutomaticTeamSize), uint32(SoloArenaAutomaticTeamSize),
        requester->GetName().c_str(), SoloArenaTeamName(requesterTeam),
        uint32(SoloArenaStagedBots.size()), uint32(candidates.size()), rejectedNeutral,
        rejectedSpec, rejectedGear);
    return true;
}

bool IsExactSoloArenaAutomaticGroup(Group* group, std::vector<uint32> const& memberGuids)
{
    if (!group || memberGuids.empty() || group->GetMembersCount() != memberGuids.size() ||
        group->GetLeaderGUID() != ObjectGuid::Create<HighGuid::Player>(memberGuids.front()))
        return false;
    for (uint32 guid : memberGuids)
        if (!group->IsMember(ObjectGuid::Create<HighGuid::Player>(guid)))
            return false;
    return true;
}

bool CreateSoloArenaAutomaticGroup(std::vector<uint32> const& memberGuids,
                                   uint32& groupId, std::string& error)
{
    if (memberGuids.empty())
    {
        error = "team has no members";
        return false;
    }

    std::vector<Player*> members;
    for (uint32 guid : memberGuids)
    {
        Player* member = FindSoloArenaParticipant(guid);
        if (!member || member->GetGroup() || member->InBattlegroundQueue() ||
            member->InBattleground() || sLFGMgr->GetActiveState(member->GetGUID()) != lfg::LFG_STATE_NONE)
        {
            error = "a team member is offline, grouped, queued, or inside an instance";
            return false;
        }
        members.push_back(member);
    }

    Group* group = new Group();
    if (!group->Create(members.front()))
    {
        delete group;
        error = "core refused to create a team group";
        return false;
    }
    for (size_t index = 1; index < members.size(); ++index)
    {
        if (!group->AddMember(members[index]))
        {
            group->Disband();
            error = "core refused to add a team member";
            return false;
        }
    }
    groupId = group->GetLowGUID();
    return true;
}

bool ApplySoloArenaAutomaticLoadouts(std::string& error)
{
    std::vector<Player*> participants;
    if (!GetSoloArenaAutomaticParticipants(participants))
    {
        error = "one or more participants are offline";
        return false;
    }
    if (GetSoloArenaLoadoutBackupCount())
    {
        error = "protected loadout recovery rows already exist";
        return false;
    }

    for (Player* participant : participants)
    {
        if (participant->GetGUID().GetCounter() == SoloArenaStagedRequester)
        {
            TC_LOG_INFO("server",
                "SoloArena automatic loadout skipped requester name=%s guid=%u; player equipment remains unchanged",
                participant->GetName().c_str(), participant->GetGUID().GetCounter());
            continue;
        }

        BotFactory factory(participant, participant->GetLevel());
        factory.InitTalentsTree(false);
        factory.InitGlyphs();

        uint32 talentCount = participant->GetUsedTalentCount();
        uint32 glyphCount = 0;
        for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
            if (participant->GetGlyph(participant->GetActiveSpec(), slot))
                ++glyphCount;
        TC_LOG_INFO("server",
            "SoloArena automatic build name=%s guid=%u specialization=%u talents=%u glyphs=%u",
            participant->GetName().c_str(), participant->GetGUID().GetCounter(),
            uint32(participant->GetSpecialization()), talentCount, glyphCount);

        uint32 changed = 0;
        if (!ApplySoloArenaLoadout(participant, SoloArenaStagedRequester, changed, error))
        {
            for (Player* rollback : participants)
            {
                uint32 restored = 0;
                uint32 remaining = 0;
                std::string rollbackError;
                RestoreSoloArenaLoadout(rollback, "automatic-apply-rollback",
                    restored, remaining, rollbackError);
            }
            return false;
        }
        TC_LOG_INFO("server", "SoloArena automatic loadout name=%s guid=%u changed=%u",
            participant->GetName().c_str(), participant->GetGUID().GetCounter(), changed);
    }
    return true;
}

bool CreateSoloArenaAutomaticGroups(std::string& error)
{
    if (!CreateSoloArenaAutomaticGroup(SoloArenaAutomaticRequesterTeam,
        SoloArenaRequesterGroup, error))
        return false;
    if (!CreateSoloArenaAutomaticGroup(SoloArenaAutomaticOpponentTeam,
        SoloArenaOpponentGroup, error))
    {
        if (Group* requesterGroup = sGroupMgr->GetGroupByGUID(SoloArenaRequesterGroup))
            requesterGroup->Disband();
        SoloArenaRequesterGroup = 0;
        return false;
    }

    TC_LOG_INFO("server",
        "SoloArena automatic %uv%u groups created requester-group=%u opponent-group=%u",
        uint32(SoloArenaAutomaticTeamSize), uint32(SoloArenaAutomaticTeamSize),
        SoloArenaRequesterGroup, SoloArenaOpponentGroup);
    return true;
}

bool QueueSoloArenaAutomaticGroups(std::string& error)
{
    Group* requesterGroup = sGroupMgr->GetGroupByGUID(SoloArenaRequesterGroup);
    Group* opponentGroup = sGroupMgr->GetGroupByGUID(SoloArenaOpponentGroup);
    if (!IsExactSoloArenaAutomaticGroup(requesterGroup, SoloArenaAutomaticRequesterTeam) ||
        !IsExactSoloArenaAutomaticGroup(opponentGroup, SoloArenaAutomaticOpponentTeam))
    {
        error = "tracked group membership changed";
        return false;
    }

    Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
    if (!arenaTemplate || DisableMgr::IsDisabledFor(
        DISABLE_TYPE_BATTLEGROUND, BATTLEGROUND_AA, nullptr))
    {
        error = "the all-Arena template is absent or disabled";
        return false;
    }

    Player* requester = FindSoloArenaParticipant(SoloArenaAutomaticRequesterTeam.front());
    Player* opponentLeader = FindSoloArenaParticipant(SoloArenaAutomaticOpponentTeam.front());
    PvPDifficultyEntry const* requesterBracket = requester ?
        GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), requester->GetLevel()) : nullptr;
    PvPDifficultyEntry const* opponentBracket = opponentLeader ?
        GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), opponentLeader->GetLevel()) : nullptr;
    if (!requester || !opponentLeader || !requesterBracket || requesterBracket != opponentBracket)
    {
        error = "the two teams are not online in one Arena bracket";
        return false;
    }

    GroupJoinBattlegroundResult requesterResult = requesterGroup->CanJoinBattlegroundQueue(
        arenaTemplate, SoloArenaAutomaticQueueType, SoloArenaAutomaticTeamSize,
        SoloArenaAutomaticTeamSize, false, 0);
    GroupJoinBattlegroundResult opponentResult = opponentGroup->CanJoinBattlegroundQueue(
        arenaTemplate, SoloArenaAutomaticQueueType, SoloArenaAutomaticTeamSize,
        SoloArenaAutomaticTeamSize, false, 0);
    if (requesterResult != ERR_BATTLEGROUND_NONE || opponentResult != ERR_BATTLEGROUND_NONE)
    {
        error = Trinity::StringFormat("core queue validation failed (%u/%u)",
            uint32(requesterResult), uint32(opponentResult));
        return false;
    }

    BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(
        SoloArenaAutomaticQueueType);
    if (!arenaQueue.m_QueuedPlayers.empty())
    {
        error = "the selected Arena-size queue is not empty";
        return false;
    }

    GroupQueueInfo* requesterInfo = arenaQueue.AddGroup(requester, requesterGroup,
        BATTLEGROUND_AA, requesterBracket, SoloArenaAutomaticTeamSize, false, false, 0, 0);
    GroupQueueInfo* opponentInfo = arenaQueue.AddGroup(opponentLeader, opponentGroup,
        BATTLEGROUND_AA, opponentBracket, SoloArenaAutomaticTeamSize, false, false, 0, 0);
    if (!requesterInfo || !opponentInfo)
    {
        error = "core failed to create one of the two queue groups";
        return false;
    }

    BattlegroundBracketId bracketId = requesterBracket->GetBracketId();
    auto sendQueuedStatus = [&arenaQueue, arenaTemplate, bracketId](Group* group, GroupQueueInfo* info)
    {
        uint32 averageWait = arenaQueue.GetAverageQueueWaitTime(info, bracketId);
        for (auto&& member : *group)
        {
            uint32 queueSlot = member->AddBattlegroundQueueId(SoloArenaAutomaticQueueType);
            member->AddBattlegroundQueueJoinTime(BATTLEGROUND_AA, info->JoinTime);
            WorldPacket data;
            sBattlegroundMgr->BuildBattlegroundStatusPacket(&data, arenaTemplate, member,
                queueSlot, STATUS_WAIT_QUEUE, averageWait, info->JoinTime,
                SoloArenaAutomaticTeamSize);
            member->GetSession()->SendPacket(&data);
        }
    };
    sendQueuedStatus(requesterGroup, requesterInfo);
    sendQueuedStatus(opponentGroup, opponentInfo);
    SoloArenaQueuesStaged = true;
    SoloArenaMatchScheduled = false;
    TC_LOG_INFO("server", "SoloArena automatic %uv%u queue created players=%u",
        uint32(SoloArenaAutomaticTeamSize), uint32(SoloArenaAutomaticTeamSize),
        uint32(arenaQueue.m_QueuedPlayers.size()));
    return true;
}

bool ScheduleSoloArenaAutomaticMatch(bool forceTolviron, std::string& error)
{
    BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(
        SoloArenaAutomaticQueueType);
    uint32 requesterInvite = 0;
    uint32 opponentInvite = 0;
    if (!HasExactSoloArenaQueueGroup(arenaQueue, SoloArenaAutomaticRequesterTeam,
        SoloArenaAutomaticTeamSize, requesterInvite) ||
        !HasExactSoloArenaQueueGroup(arenaQueue, SoloArenaAutomaticOpponentTeam,
        SoloArenaAutomaticTeamSize, opponentInvite) || requesterInvite || opponentInvite ||
        arenaQueue.m_QueuedPlayers.size() != size_t(SoloArenaAutomaticTeamSize * 2))
    {
        error = "the selected queue no longer contains exactly the two staged teams";
        return false;
    }

    Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
    Player* requester = FindSoloArenaParticipant(SoloArenaAutomaticRequesterTeam.front());
    PvPDifficultyEntry const* bracket = arenaTemplate && requester ?
        GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), requester->GetLevel()) : nullptr;
    if (!arenaTemplate || !bracket)
    {
        error = "Arena template or bracket is unavailable";
        return false;
    }

    arenaQueue.SetForcedArenaType(forceTolviron ? BATTLEGROUND_TV : BATTLEGROUND_TYPE_NONE);
    sBattlegroundMgr->ScheduleQueueUpdate(0, SoloArenaAutomaticTeamSize,
        SoloArenaAutomaticQueueType, BATTLEGROUND_AA, bracket->GetBracketId());
    SoloArenaMatchScheduled = true;
    return true;
}

bool GetSoloArenaAutomaticSharedInvite(uint32& instanceId)
{
    instanceId = 0;
    if (!SoloArenaQueuesStaged || !SoloArenaMatchScheduled)
        return false;
    BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(
        SoloArenaAutomaticQueueType);
    uint32 requesterInvite = 0;
    uint32 opponentInvite = 0;
    if (!HasExactSoloArenaQueueGroup(arenaQueue, SoloArenaAutomaticRequesterTeam,
        SoloArenaAutomaticTeamSize, requesterInvite) ||
        !HasExactSoloArenaQueueGroup(arenaQueue, SoloArenaAutomaticOpponentTeam,
        SoloArenaAutomaticTeamSize, opponentInvite) || !requesterInvite ||
        requesterInvite != opponentInvite)
        return false;
    instanceId = requesterInvite;
    return true;
}

bool EnterSoloArenaAutomaticMatch(std::string& error)
{
    uint32 invitedInstance = 0;
    if (!GetSoloArenaAutomaticSharedInvite(invitedInstance))
    {
        error = "the two teams do not share one Arena invitation";
        return false;
    }
    Battleground* arena = sBattlegroundMgr->GetBattleground(
        invitedInstance, BATTLEGROUND_TYPE_NONE);
    if (!arena || !arena->IsArena() || arena->GetArenaType() != SoloArenaAutomaticTeamSize ||
        arena->GetStatus() != STATUS_WAIT_JOIN)
    {
        error = "the invited instance has the wrong type or status";
        return false;
    }

    std::vector<Player*> participants;
    if (!GetSoloArenaAutomaticParticipants(participants))
    {
        error = "one or more invited participants are offline";
        return false;
    }
    for (Player* participant : participants)
        if (participant->InBattleground() || participant->IsBeingTeleported() ||
            !participant->InBattlegroundQueueForBattlegroundQueueType(SoloArenaAutomaticQueueType) ||
            !participant->IsInvitedForBattlegroundQueueType(SoloArenaAutomaticQueueType))
        {
            error = "one or more participants lack the exact invitation";
            return false;
        }

    SoloArenaEnteredInstance = invitedInstance;
    // Accept bots first and the real requester last. A partial failure remains
    // tracked and is handled by the guarded automatic cleanup state.
    for (auto itr = participants.rbegin(); itr != participants.rend(); ++itr)
        if (!AcceptSoloArenaInvite(*itr, invitedInstance, SoloArenaAutomaticQueueType))
        {
            error = Trinity::StringFormat("invitation acceptance failed for %s",
                (*itr)->GetName().c_str());
            return false;
        }

    SoloArenaQueuesStaged = false;
    SoloArenaMatchScheduled = false;
    return true;
}

bool GetSoloArenaPreparationFacingTarget(Battleground* arena, Player* participant,
    float& x, float& y, char const*& targetType)
{
    if (!arena || !participant)
        return false;

    // Blade's Edge Arena starts are diagonally offset from the actual doors.
    // Face the nearest one of the two opening doors instead of the opposing
    // start location. Object indexes 0 and 1 are BG_BE_OBJECT_DOOR_1/2.
    if (arena->GetMapId() == 562)
    {
        GameObject* firstDoor = arena->GetBGObject(0);
        GameObject* secondDoor = arena->GetBGObject(1);
        GameObject* nearestDoor = nullptr;
        if (firstDoor && secondDoor)
            nearestDoor = participant->GetDistance2d(firstDoor) <=
                participant->GetDistance2d(secondDoor) ? firstDoor : secondDoor;
        else
            nearestDoor = firstDoor ? firstDoor : secondDoor;
        if (nearestDoor)
        {
            x = nearestDoor->GetPositionX();
            y = nearestDoor->GetPositionY();
            targetType = "nearest-gate";
            return true;
        }
    }

    float z = 0.0f;
    float orientation = 0.0f;
    arena->GetTeamStartLoc(arena->GetOtherTeam(participant->GetBGTeam()),
        x, y, z, orientation);
    targetType = "opponent-start";
    return true;
}

std::vector<char const*> GetSoloArenaPreparationBuffActions(Player* bot)
{
    if (!bot)
        return {};

    switch (bot->GetClass())
    {
        case CLASS_PRIEST:       return { "power word: fortitude on party" };
        case CLASS_DRUID:        return { "mark of the wild on party" };
        case CLASS_MAGE:         return { "arcane brilliance on party" };
        case CLASS_PALADIN:      return { "blessing of kings", "blessing of might" };
        case CLASS_WARRIOR:      return { "battle shout" };
        case CLASS_DEATH_KNIGHT: return { "horn of winter" };
        case CLASS_WARLOCK:      return { "dark intent" };
        // Water Shield and Lightning Shield are mutually exclusive. Returning
        // both made the preparation loop alternate between them for the entire
        // countdown. A healer needs mana regeneration; damage specializations
        // keep the offensive shield instead.
        case CLASS_SHAMAN:
            return PlayerBotSpec::IsHeal(bot, true) ?
                std::vector<char const*> { "water shield" } :
                std::vector<char const*> { "lightning shield" };
        case CLASS_HUNTER:       return { "trueshot aura", "aspect of the hawk" };
        default:                 return {};
    }
}

void CastSoloArenaAutomaticPreparationBuffs(Battleground* arena,
    std::vector<Player*> const& participants)
{
    if (!arena || arena->GetStatus() != STATUS_WAIT_JOIN ||
        !sPlayerbotAIConfig->autoQueueArenaPreparationBuffs)
        return;

    for (Player* participant : participants)
    {
        if (!participant ||
            participant->GetGUID().GetCounter() == SoloArenaAutomaticRequester ||
            SoloArenaAutomaticPreparationBuffedBots.count(
                participant->GetGUID().GetCounter()))
            continue;

        PlayerbotAI* botAI = GET_PLAYERBOT_AI(participant);
        if (!botAI || botAI->IsRealPlayer())
            continue;

        // Execute real, class-supported PlayerbotAI actions. This is retried by
        // the preparation state until a cast succeeds, so teleport/GCD timing
        // cannot silently turn the old generic strategy toggle into a no-op.
        for (char const* action : GetSoloArenaPreparationBuffActions(participant))
            if (botAI->DoSpecificAction(action, Event(), true))
            {
                SoloArenaAutomaticPreparationBuffedBots.insert(
                    participant->GetGUID().GetCounter());
                TC_LOG_INFO("server",
                    "SoloArena preparation buff cast instance=%u map=%u name=%s guid=%u class=%u action=%s",
                    arena->GetInstanceID(), arena->GetMapId(),
                    participant->GetName().c_str(),
                    participant->GetGUID().GetCounter(),
                    uint32(participant->GetClass()), action);
                break;
            }
    }
}

void FinishSoloArenaAutomaticPreparationBuffs()
{
    if (!SoloArenaAutomaticPreparationBuffedBots.empty())
        TC_LOG_INFO("server", "SoloArena preparation buffs finished instance=%u successful-bots=%u",
            SoloArenaEnteredInstance,
            uint32(SoloArenaAutomaticPreparationBuffedBots.size()));

    SoloArenaAutomaticPreparationBuffedBots.clear();
}

void PrepareSoloArenaAutomaticParticipants(Battleground* arena,
    std::vector<Player*> const& participants)
{
    if (!arena || arena->GetStatus() != STATUS_WAIT_JOIN)
        return;

    for (Player* participant : participants)
    {
        if (!participant)
            continue;

        if (sPlayerbotAIConfig->autoQueueArenaPreparationFaceOpponent &&
            !SoloArenaAutomaticPreparationFacingApplied)
        {
            float x = 0.0f;
            float y = 0.0f;
            char const* targetType = "unknown";
            if (!GetSoloArenaPreparationFacingTarget(
                arena, participant, x, y, targetType))
                continue;
            float oldOrientation = participant->GetOrientation();
            float newOrientation = participant->GetAngle(x, y);
            participant->SetFacingTo(newOrientation);
            TC_LOG_INFO("server",
                "SoloArena preparation facing instance=%u map=%u name=%s guid=%u team=%u old=%.4f new=%.4f target-type=%s target=%.2f/%.2f",
                arena->GetInstanceID(), arena->GetMapId(), participant->GetName().c_str(),
                participant->GetGUID().GetCounter(), participant->GetBGTeam(),
                oldOrientation, newOrientation, targetType, x, y);
        }
    }

    SoloArenaAutomaticPreparationFacingApplied = true;
    CastSoloArenaAutomaticPreparationBuffs(arena, participants);
}

Player* FindNearestSoloArenaOpponent(Player* participant,
    std::vector<uint32> const& opponentGuids)
{
    if (!participant)
        return nullptr;

    Player* nearest = nullptr;
    float nearestDistance = std::numeric_limits<float>::max();
    for (uint32 guid : opponentGuids)
    {
        Player* candidate = FindSoloArenaParticipant(guid);
        if (!candidate || candidate->isDead() || !candidate->IsInWorld() ||
            candidate->GetMap() != participant->GetMap() ||
            candidate->GetBattlegroundId() != SoloArenaEnteredInstance ||
            !participant->IsValidAttackTarget(candidate))
            continue;

        float distance = participant->GetDistance(candidate);
        if (distance < nearestDistance)
        {
            nearest = candidate;
            nearestDistance = distance;
        }
    }
    return nearest;
}

void ActivateSoloArenaAutomaticCombat(Battleground* arena,
    std::vector<Player*> const& participants)
{
    if (!arena || arena->GetStatus() != STATUS_IN_PROGRESS)
        return;

    for (Player* participant : participants)
    {
        if (!participant || participant->isDead() ||
            participant->GetGUID().GetCounter() == SoloArenaAutomaticRequester ||
            SoloArenaAutomaticCombatActivatedBots.count(
                participant->GetGUID().GetCounter()))
            continue;

        PlayerbotAI* botAI = GET_PLAYERBOT_AI(participant);
        if (!botAI || botAI->IsRealPlayer())
            continue;

        bool requesterSide = std::find(SoloArenaAutomaticRequesterTeam.begin(),
            SoloArenaAutomaticRequesterTeam.end(),
            participant->GetGUID().GetCounter()) != SoloArenaAutomaticRequesterTeam.end();
        std::vector<uint32> const& opponentGuids = requesterSide ?
            SoloArenaAutomaticOpponentTeam : SoloArenaAutomaticRequesterTeam;
        Player* opponent = FindNearestSoloArenaOpponent(participant, opponentGuids);
        if (!opponent)
            continue;

        botAI->GetAiObjectContext()->GetValue<Unit*>("current target")->Set(opponent);
        participant->SetSelection(opponent->GetGUID());
        botAI->ChangeEngine(BOT_STATE_COMBAT);
        // A hostile current target does not prevent party-heal actions from
        // selecting their own lowest-health ally.  Healers need this target as
        // much as damage bots do: their interrupt/CC triggers inspect it and
        // their gated healer-DPS strategy uses it when nobody currently needs
        // healing.  Previously every healer was deliberately skipped here,
        // leaving the last surviving healer with no victim and therefore idle.
        bool attackStarted = participant->Attack(
            opponent, PlayerBotSpec::IsMelee(participant));
        botAI->DoSpecificAction("pet attack", Event(), true);
        SoloArenaAutomaticCombatActivatedBots.insert(
            participant->GetGUID().GetCounter());
        TC_LOG_INFO("server",
            "SoloArena post-gate combat activated instance=%u bot=%s guid=%u class=%u healer=%u target=%s target-guid=%u direct-attack=%u",
            arena->GetInstanceID(), participant->GetName().c_str(),
            participant->GetGUID().GetCounter(), uint32(participant->GetClass()),
            PlayerBotSpec::IsHeal(participant, true) ? 1u : 0u,
            opponent->GetName().c_str(), opponent->GetGUID().GetCounter(),
            uint32(attackStarted));
    }
}

void ProcessSoloArenaAutomaticReward(Battleground* arena)
{
    if (SoloArenaAutomaticRewardProcessed || !arena || !arena->IsArena() ||
        arena->GetInstanceID() != SoloArenaEnteredInstance ||
        arena->GetStatus() != STATUS_WAIT_LEAVE)
        return;

    // Mark first, including a loss/draw, so repeated exit polling can never
    // award the same completed instance twice.
    SoloArenaAutomaticRewardProcessed = true;
    if (!sPlayerbotAIConfig->autoQueueArenaRewardEnabled)
        return;

    Player* requester = SoloArenaStagedRequester ? ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedRequester)) : nullptr;
    if (!requester)
    {
        TC_LOG_ERROR("server",
            "SoloArena reward skipped instance=%u requester=%u reason=requester-offline",
            arena->GetInstanceID(), SoloArenaStagedRequester);
        return;
    }

    uint8 winner = arena->GetWinner();
    Team winnerTeam = winner == WINNER_ALLIANCE ? ALLIANCE :
        (winner == WINNER_HORDE ? HORDE : Team(0));
    if (!winnerTeam || requester->GetBGTeam() != winnerTeam)
    {
        ChatHandler(requester->GetSession()).SendSysMessage(
            winner == WINNER_NONE ? "Solo Arena ended without a winner; no reward was granted." :
                "Solo Arena defeat; no conquest reward was granted.");
        TC_LOG_INFO("server",
            "SoloArena reward result=none instance=%u requester=%s guid=%u arena=%uv%u winner=%u",
            arena->GetInstanceID(), requester->GetName().c_str(),
            requester->GetGUID().GetCounter(), uint32(SoloArenaAutomaticTeamSize),
            uint32(SoloArenaAutomaticTeamSize), uint32(winner));
        return;
    }

    uint32 conquest = SoloArenaAutomaticTeamSize == ARENA_TYPE_5v5 ?
        sPlayerbotAIConfig->autoQueueArenaReward5v5 :
        (SoloArenaAutomaticTeamSize == ARENA_TYPE_3v3 ?
            sPlayerbotAIConfig->autoQueueArenaReward3v3 :
            sPlayerbotAIConfig->autoQueueArenaReward2v2);
    if (!conquest)
        return;

    requester->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_WIN_ARENA,
        arena->GetMapId());
    requester->ModifyCurrency(CURRENCY_TYPE_CONQUEST_META_ARENA,
        int32(conquest * 100));
    ChatHandler(requester->GetSession()).PSendSysMessage(
        "Solo Arena %uv%u victory reward: %u conquest points.",
        uint32(SoloArenaAutomaticTeamSize), uint32(SoloArenaAutomaticTeamSize), conquest);
    TC_LOG_INFO("server",
        "SoloArena reward result=win instance=%u requester=%s guid=%u arena=%uv%u conquest=%u",
        arena->GetInstanceID(), requester->GetName().c_str(),
        requester->GetGUID().GetCounter(), uint32(SoloArenaAutomaticTeamSize),
        uint32(SoloArenaAutomaticTeamSize), conquest);
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

    ProcessSoloArenaAutomaticReward(arena);

    // The real requester can still be dead and attached to the Arena map while
    // the client Leave request is being processed. The core refuses equipment
    // swaps in that transition. Keep the recovery journal intact and restore the
    // requester's exact original items in automatic-exit-finalize after landing.
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
        ProcessSoloArenaAutomaticReward(arena);
        std::vector<uint32> participantGuids = GetSoloArenaTrackedParticipantGuids();
        for (uint32 guid : participantGuids)
        {
            Player* participant = guid ? ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
            // Staged bots must restore before their session is logged out. The
            // real requester remains connected and is restored only after the
            // client has completed its return teleport; trying here every 250 ms
            // only produces repeated, expected SwapItem failures while dead.
            if (participant && guid != SoloArenaStagedRequester)
            {
                uint32 restored = 0;
                uint32 remaining = 0;
                std::string restoreError;
                if (!RestoreSoloArenaLoadout(participant, "wait-leave", restored, remaining, restoreError))
                    TC_LOG_ERROR("server",
                        "SoloArena wait-leave loadout restore incomplete name=%s guid=%u restored=%u remaining=%u error=%s",
                        participant->GetName().c_str(), guid, restored, remaining, restoreError.c_str());
            }
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
    std::vector<uint32> participantGuids = GetSoloArenaTrackedParticipantGuids();
    for (uint32 guid : participantGuids)
    {
        Player* participant = guid ? ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
        if (participant && (participant->GetBattlegroundId() == instanceId ||
            participant->IsBeingTeleported() ||
            participant->InBattlegroundQueueForBattlegroundQueueType(
                SoloArenaAutomaticRequesterTeam.empty() ? BATTLEGROUND_QUEUE_2v2 :
                    SoloArenaAutomaticQueueType)))
        {
            pendingExit = true;
            break;
        }
    }

    if (pendingExit)
        return;

    for (uint32 guid : participantGuids)
    {
        Player* participant = guid ? ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(guid)) : nullptr;
        if (!participant)
            continue;

        uint32 restored = 0;
        uint32 remaining = 0;
        std::string restoreError;
        if (!RestoreSoloArenaLoadout(participant, "automatic-exit-finalize",
            restored, remaining, restoreError))
            TC_LOG_ERROR("server",
                "SoloArena automatic-finalize loadout restore incomplete name=%s guid=%u restored=%u remaining=%u error=%s",
                participant->GetName().c_str(), guid, restored, remaining, restoreError.c_str());
    }

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
            { "worldbossbots",  SEC_ADMINISTRATOR,          false,          &HandleWorldBossBotsCommand},
        };
        return commandTable;
    }

    static bool HandlePlayerbotCommand(ChatHandler* handler, char const* args)
    {
        return PlayerbotMgr::HandlePlayerbotMgrCommand(handler, args);
    }

    static bool HandleWorldBossBotsCommand(ChatHandler* handler, char const* args)
    {
        Player* requester = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (args && !strcmp(args, "status"))
        {
            uint32 loading = 0;
            uint32 online = 0;
            uint32 alive = 0;
            uint32 grouped = 0;
            uint32 nearby = 0;
            for (auto const& staged : WorldBossStagedBots)
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
                if (sRandomPlayerbotMgr->IsBotLoading(guid))
                    ++loading;
                Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
                if (!bot || !bot->IsInWorld())
                    continue;
                ++online;
                if (bot->IsAlive())
                    ++alive;
                if (bot->GetGroup() && bot->GetGroup()->GetLowGUID() == WorldBossStageGroup)
                    ++grouped;
                if (requester && bot->GetMapId() == requester->GetMapId() &&
                    bot->GetDistance2d(requester) <= 30.0f)
                    ++nearby;
            }
            handler->PSendSysMessage(
                "World-boss staged status: state=%s, raid-size=%u, bots=%u, loading=%u, online=%u, alive=%u, grouped=%u, nearby=%u, buffed=%u, group=%u, elapsed=%us, boss-entry=%u.",
                WorldBossStagedStateName(), WorldBossStageRaidSize,
                uint32(WorldBossStagedBots.size()), loading, online, alive,
                grouped, nearby, uint32(WorldBossStageBuffedBots.size()),
                WorldBossStageGroup, WorldBossStageElapsed / 1000,
                WorldBossStageBossEntry);
            if (WorldBossStageState == WorldBossStagedState::Cleanup &&
                !WorldBossStageCleanupReason.empty())
                handler->PSendSysMessage("Cleanup reason: %s.",
                    WorldBossStageCleanupReason.c_str());
            return true;
        }
        if (args && !strcmp(args, "dismiss"))
        {
            if (WorldBossStageState == WorldBossStagedState::Idle)
                handler->SendSysMessage("There is no staged world-boss raid to dismiss.");
            else if (!requester || requester->GetGUID().GetCounter() != WorldBossStageRequester)
                handler->SendSysMessage(
                    "Only the player who started this staged raid may dismiss it.");
            else
            {
                BeginWorldBossStageCleanup(".worldbossbots dismiss requested");
                handler->SendSysMessage(
                    "World-boss staged raid cleanup started. Use .worldbossbots status to follow it.");
            }
            return true;
        }
        if (args && !strcmp(args, "rebuff"))
        {
            std::string error;
            if (!RequestWorldBossRebuff(requester, error))
                handler->PSendSysMessage("World-boss rebuff refused: %s.", error.c_str());
            else
                handler->SendSysMessage(
                    "World-boss raid rebuff requested. Living out-of-combat bots will renew missing raid buffs; revived bots are retried automatically.");
            return true;
        }

        uint32 raidSize = 0;
        if (args && !strcmp(args, "preview 10"))
            raidSize = 10;
        else if (args && !strcmp(args, "preview 25"))
            raidSize = 25;
        else
        {
            handler->SendSysMessage(
                "Usage: select a supported Pandaria world boss, then use "
                ".worldbossbots preview 10|25; active-stage controls: "
                ".worldbossbots status, .worldbossbots rebuff, or .worldbossbots dismiss");
            return true;
        }

        Creature* boss = handler->getSelectedCreature();
        char const* bossName = boss ? GetSupportedWorldBossName(boss->GetEntry()) : nullptr;
        if (!requester || !boss || !bossName)
        {
            handler->SendSysMessage(
                "Select Sha of Anger, Galleon, Nalak, Oondasta, a Celestial, or Ordos first.");
            return true;
        }

        if (sPlayerbotAIConfig->randomBotAccounts.empty())
        {
            handler->SendSysMessage("No random-bot accounts are configured.");
            return true;
        }

        uint32 requiredTanks = 2;
        uint32 requiredHealers = raidSize == 10 ? 2 : 5;
        uint32 requiredDamage = raidSize - requiredTanks - requiredHealers;
        switch (GetWorldBossPreviewRole(requester->GetSpecialization()))
        {
            case WorldBossPreviewRole::Tank:    --requiredTanks; break;
            case WorldBossPreviewRole::Healer:  --requiredHealers; break;
            case WorldBossPreviewRole::Damage:  --requiredDamage; break;
            case WorldBossPreviewRole::None:
                handler->SendSysMessage("Your active specialization has no recognized raid role.");
                return true;
        }

        uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
        uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
        QueryResult result = CharacterDatabase.PQuery(
            "SELECT guid,name,race,class,level,talentTree,activespec,equipmentCache "
            "FROM characters WHERE account >= %u AND account <= %u AND level = %u AND online = 0 "
            "AND guid NOT IN (SELECT memberGuid FROM group_member)",
            minAccount, maxAccount, requester->GetLevel());
        if (!result)
        {
            handler->SendSysMessage("No unused offline random-bot characters were found.");
            return true;
        }

        uint32 availableTanks = 0;
        uint32 availableHealers = 0;
        uint32 availableDamage = 0;
        uint32 rejectedFaction = 0;
        uint32 rejectedSpec = 0;
        uint32 rejectedGear = 0;
        std::array<std::vector<std::string>, 3> samples;
        do
        {
            Field* fields = result->Fetch();
            uint8 race = fields[2].GetUInt8();
            uint32 team = Player::TeamForRace(race);
            if (team == PANDAREN_NEUTRAL || team != requester->GetTeam())
            {
                ++rejectedFaction;
                continue;
            }

            uint32 specs[MAX_TALENT_SPECS] = { 0, 0 };
            std::istringstream talentTrees(fields[5].GetString());
            for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
                talentTrees >> specs[spec];
            uint8 activeSpec = fields[6].GetUInt8();
            if (activeSpec >= MAX_TALENT_SPECS)
                activeSpec = 0;
            WorldBossPreviewRole role = GetWorldBossPreviewRole(
                Specializations(specs[activeSpec]));
            if (role == WorldBossPreviewRole::None)
            {
                ++rejectedSpec;
                continue;
            }

            SoloArenaPreviewCandidate gear;
            ReadSoloArenaGear(fields[7].GetString(), gear);
            if (gear.EquippedItems < 15 || gear.AverageItemLevel < 450)
                ++rejectedGear;
            uint32* count = nullptr;
            size_t sampleIndex = 0;
            if (role == WorldBossPreviewRole::Tank)
            {
                count = &availableTanks;
                sampleIndex = 0;
            }
            else if (role == WorldBossPreviewRole::Healer)
            {
                count = &availableHealers;
                sampleIndex = 1;
            }
            else
            {
                count = &availableDamage;
                sampleIndex = 2;
            }
            ++*count;
            if (samples[sampleIndex].size() < 3)
                samples[sampleIndex].push_back(fields[1].GetString());
        }
        while (result->NextRow());

        auto joinedSamples = [](std::vector<std::string> const& names) -> std::string
        {
            if (names.empty())
                return "none";
            std::ostringstream stream;
            for (size_t index = 0; index < names.size(); ++index)
            {
                if (index)
                    stream << ", ";
                stream << names[index];
            }
            return stream.str();
        };

        bool ready = availableTanks >= requiredTanks &&
            availableHealers >= requiredHealers && availableDamage >= requiredDamage;
        handler->PSendSysMessage(
            "World-boss preview: %s (entry %u), raid=%u, requester=%s, result=%s.",
            bossName, boss->GetEntry(), raidSize, requester->GetName().c_str(),
            ready ? "candidate pool ready" : "candidate pool incomplete");
        handler->PSendSysMessage(
            "Bots needed/available: tanks=%u/%u [%s], healers=%u/%u [%s], damage=%u/%u [%s].",
            requiredTanks, availableTanks, joinedSamples(samples[0]).c_str(),
            requiredHealers, availableHealers, joinedSamples(samples[1]).c_str(),
            requiredDamage, availableDamage, joinedSamples(samples[2]).c_str());
        handler->PSendSysMessage(
            "Audit filters: wrong/neutral faction=%u, unknown spec=%u. Undergeared candidates retained=%u because Call supplies T16 armor and a role cloak. No bot was logged in, grouped, equipped, or moved.",
            rejectedFaction, rejectedSpec, rejectedGear);
        return true;
    }

    static bool HandleSoloArenaCommand(ChatHandler* handler, char const* args)
    {
        bool preview = args && !strcmp(args, "preview");
        bool login = args && !strcmp(args, "login");
        bool status = args && !strcmp(args, "status");
        bool buildAudit = args && !strcmp(args, "build");
        bool loadoutAudit = args && !strcmp(args, "loadout");
        bool loadoutApply = args && !strcmp(args, "loadout apply");
        bool loadoutRestore = args && !strcmp(args, "loadout restore");
        bool loadoutRecover = args && !strcmp(args, "loadout recover");
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
        if (!preview && !login && !status && !buildAudit && !loadoutAudit && !loadoutApply && !loadoutRestore &&
            !loadoutRecover && !logout && !formGroups && !ungroup &&
            !stageQueue && !stageMatch && !stageEnter && !combatStatus && !leaveArena && !unstageQueue)
        {
            handler->SendSysMessage(
                "Usage: .soloarena preview|login|status|build|loadout [apply|restore|recover]|group|queue|match [tolviron]|enter|combatstatus|leave|unqueue|ungroup|logout");
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
            handler->PSendSysMessage("Solo Arena persistent loadout recovery rows: %u.",
                GetSoloArenaLoadoutBackupCount());
            return true;
        }

        if (buildAudit)
        {
            if (SoloArenaStagedBots.size() != 3 || !SoloArenaStagedRequester ||
                player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Solo Arena build audit requires this requester's complete staged-login set. Use .soloarena login first.");
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
            uint32 onlineParticipants = 0;
            uint32 emptyTalentParticipants = 0;
            uint32 emptyGlyphParticipants = 0;
            for (uint8 participantIndex = 0; participantIndex < 4; ++participantIndex)
            {
                Player* participant = participants[participantIndex];
                if (!participant)
                {
                    handler->PSendSysMessage("Solo Arena build %s: offline.", labels[participantIndex]);
                    continue;
                }

                ++onlineParticipants;
                uint8 activeSpec = participant->GetActiveSpec();
                std::vector<uint32> talents;
                if (PlayerTalentMap const* talentMap = participant->GetTalentMap(activeSpec))
                    for (auto const& talent : *talentMap)
                        if (participant->HasTalent(talent.first, activeSpec))
                            talents.push_back(talent.first);
                std::sort(talents.begin(), talents.end());

                std::ostringstream talentEntries;
                if (talents.empty())
                {
                    talentEntries << '-';
                    ++emptyTalentParticipants;
                }
                else
                    for (uint8 talentIndex = 0; talentIndex < talents.size(); ++talentIndex)
                    {
                        if (talentIndex)
                            talentEntries << '/';
                        talentEntries << talents[talentIndex];
                    }

                std::ostringstream glyphEntries;
                uint32 glyphCount = 0;
                for (uint8 glyphSlot = 0; glyphSlot < MAX_GLYPH_SLOT_INDEX; ++glyphSlot)
                {
                    if (glyphSlot)
                        glyphEntries << '/';
                    uint32 glyph = participant->GetGlyph(activeSpec, glyphSlot);
                    glyphEntries << glyph;
                    glyphCount += glyph ? 1 : 0;
                }
                if (!glyphCount)
                    ++emptyGlyphParticipants;

                uint32 unlockedTalents = participant->CalculateTalentsPoints();
                uint32 usedTalents = uint32(talents.size());
                uint32 remainingTalents = unlockedTalents > usedTalents ? unlockedTalents - usedTalents : 0;
                handler->PSendSysMessage(
                    "Solo Arena build %s %s: class=%u level=%u active-spec=%u specialization=%u talents=%u/%u remaining=%u talent-spells=%s glyphs=%u/6 glyph-properties=%s.",
                    labels[participantIndex], participant->GetName().c_str(), participant->GetClass(),
                    participant->GetLevel(), uint32(activeSpec), uint32(participant->GetSpecialization()),
                    usedTalents, unlockedTalents, remainingTalents, talentEntries.str().c_str(),
                    glyphCount, glyphEntries.str().c_str());
                TC_LOG_INFO("server",
                    "SoloArena build audit label=%s name=%s guid=%u class=%u level=%u active-spec=%u specialization=%u talents=%u/%u remaining=%u talent-spells=%s glyphs=%u/6 glyph-properties=%s",
                    labels[participantIndex], participant->GetName().c_str(),
                    participant->GetGUID().GetCounter(), participant->GetClass(), participant->GetLevel(),
                    uint32(activeSpec), uint32(participant->GetSpecialization()), usedTalents,
                    unlockedTalents, remainingTalents, talentEntries.str().c_str(), glyphCount,
                    glyphEntries.str().c_str());
            }

            handler->PSendSysMessage(
                "Dry-run only: %u/4 participants online; empty talents=%u, empty glyphs=%u. No specialization, talent, glyph, item or database row was changed.",
                onlineParticipants, emptyTalentParticipants, emptyGlyphParticipants);
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
                        INVENTORY_SLOT_BAG_0, SoloArenaLoadoutEquipmentSlots[itemIndex]))
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

        if (loadoutRecover)
        {
            QueryResult recoveryOwners = CharacterDatabase.Query(
                "SELECT DISTINCT b.`owner_guid`,c.`name`,c.`account` "
                "FROM `solo_arena_loadout_backup` b "
                "LEFT JOIN `characters` c ON c.`guid`=b.`owner_guid` ORDER BY b.`owner_guid`");
            if (!recoveryOwners)
            {
                handler->SendSysMessage("Solo Arena has no persistent loadout recovery rows.");
                return true;
            }

            uint32 restoredOwners = 0;
            uint32 requestedLogins = 0;
            uint32 waitingOwners = 0;
            do
            {
                Field* fields = recoveryOwners->Fetch();
                uint32 ownerGuid = fields[0].GetUInt32();
                std::string ownerName = fields[1].GetString();
                uint32 accountId = fields[2].GetUInt32();
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(ownerGuid);
                Player* owner = ObjectAccessor::FindConnectedPlayer(guid);
                if (owner)
                {
                    uint32 restored = 0;
                    uint32 remaining = 0;
                    std::string restoreError;
                    if (RestoreSoloArenaLoadout(owner, "manual-recovery", restored, remaining, restoreError))
                    {
                        ++restoredOwners;
                        handler->PSendSysMessage(
                            "Solo Arena recovered %s (guid %u): restored=%u, remaining=0.",
                            ownerName.c_str(), ownerGuid, restored);
                    }
                    else
                    {
                        ++waitingOwners;
                        handler->PSendSysMessage(
                            "Solo Arena recovery for %s (guid %u) remains protected: restored=%u, remaining=%u, error=%s.",
                            ownerName.c_str(), ownerGuid, restored, remaining, restoreError.c_str());
                    }
                    continue;
                }

                bool randomBotAccount = std::find(sPlayerbotAIConfig->randomBotAccounts.begin(),
                    sPlayerbotAIConfig->randomBotAccounts.end(), accountId) !=
                    sPlayerbotAIConfig->randomBotAccounts.end();
                if (randomBotAccount)
                {
                    if (!sRandomPlayerbotMgr->IsBotLoading(guid))
                    {
                        SoloArenaLoadoutRecoveryBots.insert(ownerGuid);
                        sRandomPlayerbotMgr->AddPlayerBot(guid, 0);
                        ++requestedLogins;
                        handler->PSendSysMessage(
                            "Solo Arena requested recovery login for bot %s (guid %u). Wait, then repeat .soloarena loadout recover.",
                            ownerName.c_str(), ownerGuid);
                    }
                    else
                    {
                        ++waitingOwners;
                        handler->PSendSysMessage(
                            "Solo Arena recovery bot %s (guid %u) is still loading; repeat the command shortly.",
                            ownerName.c_str(), ownerGuid);
                    }
                }
                else
                {
                    ++waitingOwners;
                    handler->PSendSysMessage(
                        "Solo Arena recovery owner %s (guid %u) is a real offline character; log into that exact character and run .soloarena loadout recover.",
                        ownerName.c_str(), ownerGuid);
                }
            }
            while (recoveryOwners->NextRow());

            for (auto itr = SoloArenaLoadoutRecoveryBots.begin();
                 itr != SoloArenaLoadoutRecoveryBots.end();)
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(*itr);
                Player* recoveryBot = sRandomPlayerbotMgr->GetPlayerBot(guid);
                if (!recoveryBot || GetSoloArenaLoadoutBackupCount(*itr) || recoveryBot->GetGroup() ||
                    recoveryBot->InBattlegroundQueue() || recoveryBot->InBattleground())
                {
                    ++itr;
                    continue;
                }

                PrepareSoloArenaBotForLogout(recoveryBot, "recovery");
                sRandomPlayerbotMgr->LogoutPlayerBot(guid);
                itr = SoloArenaLoadoutRecoveryBots.erase(itr);
            }

            handler->PSendSysMessage(
                "Solo Arena recovery summary: restored-owners=%u, login-requests=%u, waiting=%u, persistent-rows=%u.",
                restoredOwners, requestedLogins, waitingOwners, GetSoloArenaLoadoutBackupCount());
            return true;
        }

        if (loadoutApply || loadoutRestore)
        {
            if (SoloArenaStagedBots.size() != 3 || !SoloArenaStagedRequester ||
                player->GetGUID().GetCounter() != SoloArenaStagedRequester)
            {
                handler->SendSysMessage(
                    "Solo Arena loadout changes require this requester's complete staged-login set. Use .soloarena login first.");
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

            for (uint8 index = 0; index < 4; ++index)
            {
                if (!participants[index])
                {
                    handler->PSendSysMessage("Solo Arena loadout %s is offline.", labels[index]);
                    return true;
                }
            }

            if (loadoutApply)
            {
                uint32 existingRows = GetSoloArenaLoadoutBackupCount();
                if (existingRows)
                {
                    handler->PSendSysMessage(
                        "Solo Arena loadout apply refused: %u persistent recovery rows already exist. Use .soloarena loadout recover.",
                        existingRows);
                    return true;
                }

                uint32 changedTotal = 0;
                handler->PSendSysMessage(
                    "Solo Arena temporary loadout requester %s: skipped; player equipment remains unchanged.",
                    participants[0]->GetName().c_str());
                for (uint8 index = 1; index < 4; ++index)
                {
                    uint32 changed = 0;
                    std::string applyError;
                    if (!ApplySoloArenaLoadout(participants[index], SoloArenaStagedRequester,
                        changed, applyError))
                    {
                        handler->PSendSysMessage(
                            "Solo Arena loadout apply stopped at %s %s: %s. Starting guarded rollback.",
                            labels[index], participants[index]->GetName().c_str(), applyError.c_str());
                        for (Player* rollbackParticipant : participants)
                        {
                            uint32 restored = 0;
                            uint32 remaining = 0;
                            std::string restoreError;
                            RestoreSoloArenaLoadout(rollbackParticipant, "apply-rollback",
                                restored, remaining, restoreError);
                        }
                        handler->PSendSysMessage(
                            "Solo Arena guarded rollback finished; persistent recovery rows=%u.",
                            GetSoloArenaLoadoutBackupCount());
                        return true;
                    }

                    changedTotal += changed;
                    handler->PSendSysMessage(
                        "Solo Arena temporary loadout %s %s: changed=%u, journal-rows=%u.",
                        labels[index], participants[index]->GetName().c_str(), changed,
                        GetSoloArenaLoadoutBackupCount(participants[index]->GetGUID().GetCounter()));
                }

                handler->PSendSysMessage(
                    "Solo Arena temporary five-piece loadouts applied: changed=%u, persistent recovery rows=%u. "
                    "Use .soloarena loadout to audit and .soloarena loadout restore to undo before logout.",
                    changedTotal, GetSoloArenaLoadoutBackupCount());
                return true;
            }

            uint32 restoredTotal = 0;
            uint32 failedOwners = 0;
            for (uint8 index = 0; index < 4; ++index)
            {
                uint32 restored = 0;
                uint32 remaining = 0;
                std::string restoreError;
                bool restoredAll = RestoreSoloArenaLoadout(participants[index], "manual-restore",
                    restored, remaining, restoreError);
                restoredTotal += restored;
                failedOwners += restoredAll ? 0 : 1;
                handler->PSendSysMessage(
                    "Solo Arena loadout restore %s %s: restored=%u, remaining=%u%s%s.",
                    labels[index], participants[index]->GetName().c_str(), restored, remaining,
                    restoreError.empty() ? "" : ", error=", restoreError.c_str());
            }

            handler->PSendSysMessage(
                "Solo Arena loadout restore summary: restored=%u, failed-owners=%u, persistent-rows=%u.",
                restoredTotal, failedOwners, GetSoloArenaLoadoutBackupCount());
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

            uint32 loadoutRestoreFailures = 0;
            for (uint8 index = 0; index < 4; ++index)
            {
                uint32 restored = 0;
                uint32 remaining = 0;
                std::string restoreError;
                if (!RestoreSoloArenaLoadout(participants[index], "manual-leave",
                    restored, remaining, restoreError))
                {
                    ++loadoutRestoreFailures;
                    handler->PSendSysMessage(
                        "Solo Arena leave loadout restore incomplete for %s: restored=%u, remaining=%u, error=%s.",
                        labels[index], restored, remaining, restoreError.c_str());
                }
            }
            if (loadoutRestoreFailures)
            {
                handler->PSendSysMessage(
                    "Solo Arena leave refused until %u protected loadout owner(s) are fully restored.",
                    loadoutRestoreFailures);
                return true;
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

            Player* restoreParticipants[] =
            {
                player,
                sRandomPlayerbotMgr->GetPlayerBot(ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedTeammate)),
                sRandomPlayerbotMgr->GetPlayerBot(ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentHealer)),
                sRandomPlayerbotMgr->GetPlayerBot(ObjectGuid::Create<HighGuid::Player>(SoloArenaStagedOpponentDamage))
            };
            uint32 restoreParticipantGuids[] =
            {
                SoloArenaStagedRequester, SoloArenaStagedTeammate,
                SoloArenaStagedOpponentHealer, SoloArenaStagedOpponentDamage
            };
            uint32 restoreFailures = 0;
            for (uint8 index = 0; index < 4; ++index)
            {
                Player* restoreParticipant = restoreParticipants[index];
                if (!restoreParticipant)
                {
                    if (GetSoloArenaLoadoutBackupCount(restoreParticipantGuids[index]))
                        ++restoreFailures;
                    continue;
                }

                uint32 restored = 0;
                uint32 remaining = 0;
                std::string restoreError;
                if (!RestoreSoloArenaLoadout(restoreParticipant, "staged-logout",
                    restored, remaining, restoreError))
                {
                    ++restoreFailures;
                    handler->PSendSysMessage(
                        "Solo Arena logout loadout restore incomplete for %s: restored=%u, remaining=%u, error=%s.",
                        restoreParticipant->GetName().c_str(), restored, remaining, restoreError.c_str());
                }
            }
            if (restoreFailures)
            {
                handler->PSendSysMessage(
                    "Solo Arena logout refused: %u participant(s) are offline or still have protected loadout rows. Use .soloarena loadout recover.",
                    restoreFailures);
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
                    PrepareSoloArenaBotForLogout(bot, "manual-staged-cleanup");
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

        if (login && GetSoloArenaLoadoutBackupCount())
        {
            handler->PSendSysMessage(
                "Solo Arena staged login refused: %u persistent loadout recovery rows exist. Use .soloarena loadout recover first.",
                GetSoloArenaLoadoutBackupCount());
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

namespace
{
enum WorldBossCallerActions : uint32
{
    WORLD_BOSS_CALLER_PREVIEW_10 = GOSSIP_ACTION_INFO_DEF + 1,
    WORLD_BOSS_CALLER_PREVIEW_25 = GOSSIP_ACTION_INFO_DEF + 2,
    WORLD_BOSS_CALLER_STATUS = GOSSIP_ACTION_INFO_DEF + 3,
    WORLD_BOSS_CALLER_LOCKED_10 = GOSSIP_ACTION_INFO_DEF + 4,
    WORLD_BOSS_CALLER_LOCKED_25 = GOSSIP_ACTION_INFO_DEF + 5,
    WORLD_BOSS_CALLER_STAGE_10 = GOSSIP_ACTION_INFO_DEF + 6,
    WORLD_BOSS_CALLER_DISMISS = GOSSIP_ACTION_INFO_DEF + 7,
    WORLD_BOSS_CALLER_STAGE_25 = GOSSIP_ACTION_INFO_DEF + 8,
    WORLD_BOSS_CALLER_REBUFF = GOSSIP_ACTION_INFO_DEF + 9
};

enum WorldBossCallerRaidMask : uint8
{
    WORLD_BOSS_CALLER_RAID_10 = 0x01,
    WORLD_BOSS_CALLER_RAID_25 = 0x02
};

struct WorldBossCallerConfig
{
    uint32 BossEntry = 0;
    float SearchRadius = 0.0f;
    uint8 RaidSizeMask = 0;
    bool StrategyReady = false;
};

bool LoadWorldBossCallerConfig(Creature* caller, WorldBossCallerConfig& config)
{
    if (!caller || !caller->GetDBTableGUIDLow())
        return false;

    QueryResult result = WorldDatabase.PQuery(
        "SELECT boss_entry,boss_search_radius,raid_size_mask,strategy_ready "
        "FROM playerbot_world_boss_caller WHERE guid=%u",
        caller->GetDBTableGUIDLow());
    if (!result)
        return false;

    Field* fields = result->Fetch();
    config.BossEntry = fields[0].GetUInt32();
    config.SearchRadius = fields[1].GetFloat();
    config.RaidSizeMask = fields[2].GetUInt8();
    config.StrategyReady = fields[3].GetBool();
    return GetSupportedWorldBossName(config.BossEntry) && config.SearchRadius > 0.0f;
}

Creature* FindConfiguredWorldBoss(Creature* caller, WorldBossCallerConfig const& config,
    bool aliveOnly = true)
{
    return caller ? caller->FindNearestCreature(
        config.BossEntry, config.SearchRadius, aliveOnly) : nullptr;
}

char const* WorldBossStagedStateName()
{
    switch (WorldBossStageState)
    {
        case WorldBossStagedState::Idle:        return "idle";
        case WorldBossStagedState::WaitForBots: return "waiting for bots";
        case WorldBossStagedState::WaitForTeleport: return "moving bots to caller";
        case WorldBossStagedState::Grouped:     return "raid grouped";
        case WorldBossStagedState::Cleanup:     return "cleanup";
    }
    return "unknown";
}

bool RequestWorldBossRebuff(Player* requester, std::string& error)
{
    if (!requester)
    {
        error = "no requesting player";
        return false;
    }
    if (WorldBossStageState != WorldBossStagedState::Grouped)
    {
        error = "no assembled staged raid is active";
        return false;
    }
    if (requester->GetGUID().GetCounter() != WorldBossStageRequester)
    {
        error = "only the player who started this staged raid may request it";
        return false;
    }

    WorldBossStageBuffedBots.clear();
    TC_LOG_INFO("server",
        "WorldBoss rebuff requested requester=%u group=%u boss=%u bots=%u",
        WorldBossStageRequester, WorldBossStageGroup, WorldBossStageBossEntry,
        uint32(WorldBossStagedBots.size()));
    return true;
}

bool StartWorldBossStage(Player* requester, Creature* caller, Creature* boss,
    uint32 raidSize, std::string& error)
{
    if (!requester || !caller || !boss)
    {
        error = "requester, caller, or boss is missing";
        return false;
    }
    if (WorldBossStageState != WorldBossStagedState::Idle)
    {
        error = "another world-boss staging session is already active";
        return false;
    }
    if (IsSoloArenaAutomationBusy())
    {
        error = "Solo Arena automation currently owns playerbots";
        return false;
    }
    if (requester->GetLevel() != DEFAULT_MAX_LEVEL || requester->GetGroup() ||
        requester->InBattleground() || requester->InBattlegroundQueue() ||
        requester->IsUsingLfg() || requester->IsInCombat())
    {
        error = "requester must be level 90, out of combat, ungrouped, and outside queues";
        return false;
    }
    if (sPlayerbotAIConfig->randomBotAccounts.empty())
    {
        error = "no random-bot accounts are configured";
        return false;
    }
    if (raidSize != 10 && raidSize != 25)
    {
        error = "raid size must be 10 or 25";
        return false;
    }

    uint32 neededTanks = 2;
    uint32 neededHealers = raidSize == 10 ? 2 : 5;
    uint32 neededDamage = raidSize - neededTanks - neededHealers;
    switch (GetWorldBossPreviewRole(requester->GetSpecialization()))
    {
        case WorldBossPreviewRole::Tank:    --neededTanks; break;
        case WorldBossPreviewRole::Healer:  --neededHealers; break;
        case WorldBossPreviewRole::Damage:  --neededDamage; break;
        case WorldBossPreviewRole::None:
            error = "requester active specialization has no recognized raid role";
            return false;
    }

    uint32 minAccount = sPlayerbotAIConfig->randomBotAccounts.front();
    uint32 maxAccount = sPlayerbotAIConfig->randomBotAccounts.back();
    QueryResult result = CharacterDatabase.PQuery(
        "SELECT guid,name,race,class,talentTree,activespec,equipmentCache,"
        "map,position_x,position_y,position_z,orientation "
        "FROM characters WHERE account >= %u AND account <= %u AND level = %u AND online = 0 "
        "AND guid NOT IN (SELECT memberGuid FROM group_member) ORDER BY guid",
        minAccount, maxAccount, requester->GetLevel());
    if (!result)
    {
        error = "no unused offline random-bot characters were found";
        return false;
    }

    std::array<std::vector<WorldBossStagedCandidate>, 3> candidates;
    do
    {
        Field* fields = result->Fetch();
        uint32 guidLow = fields[0].GetUInt32();
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(guidLow);
        if (ObjectAccessor::FindConnectedPlayer(guid) ||
            sRandomPlayerbotMgr->GetPlayerBot(guid) ||
            sRandomPlayerbotMgr->IsBotLoading(guid))
            continue;

        uint32 team = Player::TeamForRace(fields[2].GetUInt8());
        if (team == PANDAREN_NEUTRAL || team != requester->GetTeam())
            continue;

        uint32 specs[MAX_TALENT_SPECS] = { 0, 0 };
        std::istringstream talentTrees(fields[4].GetString());
        for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
            talentTrees >> specs[spec];
        uint8 activeSpec = fields[5].GetUInt8();
        if (activeSpec >= MAX_TALENT_SPECS)
            activeSpec = 0;
        Specializations specialization = Specializations(specs[activeSpec]);
        WorldBossPreviewRole role = GetWorldBossPreviewRole(specialization);
        if (role == WorldBossPreviewRole::None ||
            !GetWorldBossPveLoadoutPlan(specialization))
            continue;

        SoloArenaPreviewCandidate gear;
        ReadSoloArenaGear(fields[6].GetString(), gear);

        size_t roleIndex = role == WorldBossPreviewRole::Tank ? 0 :
            (role == WorldBossPreviewRole::Healer ? 1 : 2);
        WorldBossStagedCandidate candidate;
        candidate.Guid = guidLow;
        candidate.Name = fields[1].GetString();
        candidate.Class = fields[3].GetUInt8();
        candidate.Role = role;
        candidate.Specialization = specialization;
        candidate.PvpItems = gear.PvpItems;
        candidate.AverageItemLevel = gear.AverageItemLevel;
        candidate.OriginalMap = fields[7].GetUInt32();
        candidate.OriginalX = fields[8].GetFloat();
        candidate.OriginalY = fields[9].GetFloat();
        candidate.OriginalZ = fields[10].GetFloat();
        candidate.OriginalO = fields[11].GetFloat();
        candidates[roleIndex].push_back(candidate);
    }
    while (result->NextRow());

    // Prefer raid-oriented starting gear. A lower number of equipped PvP
    // pieces wins; within that, use the higher average item level. No minimum
    // rejects a class: every selected bot receives T16 armor and a role cloak
    // after login. The GUID tie-breaker keeps the base order deterministic.
    auto pveOrder = [](WorldBossStagedCandidate const& left,
        WorldBossStagedCandidate const& right)
    {
        if (left.PvpItems != right.PvpItems)
            return left.PvpItems < right.PvpItems;
        if (left.AverageItemLevel != right.AverageItemLevel)
            return left.AverageItemLevel > right.AverageItemLevel;
        return left.Guid < right.Guid;
    };
    for (auto& roleCandidates : candidates)
        std::sort(roleCandidates.begin(), roleCandidates.end(), pveOrder);

    if (candidates[0].size() < neededTanks ||
        candidates[1].size() < neededHealers ||
        candidates[2].size() < neededDamage)
    {
        std::ostringstream message;
        message << "candidate pool incomplete: tanks " << candidates[0].size()
            << "/" << neededTanks << ", healers " << candidates[1].size()
            << "/" << neededHealers << ", damage " << candidates[2].size()
            << "/" << neededDamage;
        error = message.str();
        return false;
    }

    WorldBossPreviewRole requesterRole = GetWorldBossPreviewRole(
        requester->GetSpecialization());
    std::array<std::vector<uint32>, 3> selectedIndices;
    std::array<uint16, 3> selectedClasses = {{ 0, 0, 0 }};
    uint8 coveredBuffs = GetWorldBossRaidBuffMask(
        requester->GetSpecialization());
    std::array<uint32, 3> selectedCounts =
        {{ neededTanks, neededHealers, neededDamage }};
    for (size_t roleIndex = 0; roleIndex < candidates.size(); ++roleIndex)
    {
        WorldBossPreviewRole role = roleIndex == 0 ?
            WorldBossPreviewRole::Tank : (roleIndex == 1 ?
                WorldBossPreviewRole::Healer : WorldBossPreviewRole::Damage);
        if (!SelectWorldBossDiverseRole(candidates[roleIndex],
            selectedCounts[roleIndex], requester->GetClass(),
            requesterRole == role, coveredBuffs, selectedIndices[roleIndex],
            selectedClasses[roleIndex]))
        {
            error = "class-diverse raid composition could not form the requested role counts";
            return false;
        }
    }

    TC_LOG_INFO("server",
        "WorldBoss Call %u class-diverse composition classes=tank:%u healer:%u damage:%u raid-buff coverage=%u/8 categories=%s",
        raidSize, uint32(CountWorldBossClasses(selectedClasses[0])),
        uint32(CountWorldBossClasses(selectedClasses[1])),
        uint32(CountWorldBossClasses(selectedClasses[2])),
        uint32(CountWorldBossRaidBuffs(coveredBuffs)),
        DescribeWorldBossRaidBuffs(coveredBuffs).c_str());

    auto stageRole = [](std::vector<WorldBossStagedCandidate> const& roleCandidates,
        std::vector<uint32> const& indices)
    {
        for (uint32 index : indices)
        {
            WorldBossStagedCandidate const& candidate = roleCandidates[index];
            WorldBossStagedBots[candidate.Guid] = candidate;
        }
    };
    stageRole(candidates[0], selectedIndices[0]);
    stageRole(candidates[1], selectedIndices[1]);
    stageRole(candidates[2], selectedIndices[2]);

    WorldBossStageRequester = requester->GetGUID().GetCounter();
    WorldBossStageCaller = caller->GetDBTableGUIDLow();
    WorldBossStageBoss = boss->GetGUID().GetCounter();
    WorldBossStageBossEntry = boss->GetEntry();
    WorldBossStageGroup = 0;
    WorldBossStageRaidSize = raidSize;
    WorldBossStageElapsed = 0;
    WorldBossStageUpdateTimer = 0;
    WorldBossStageMap = 0;
    WorldBossStageX = 0.0f;
    WorldBossStageY = 0.0f;
    WorldBossStageZ = 0.0f;
    WorldBossStageCleanupReason.clear();
    WorldBossStageBuffedBots.clear();
    WorldBossStageEncounterStarted = false;
    WorldBossStageWipePending = false;
    WorldBossStageBossDefeatedTimer = 0;
    WorldBossStageState = WorldBossStagedState::WaitForBots;

    for (auto const& staged : WorldBossStagedBots)
    {
        sRandomPlayerbotMgr->AddPlayerBot(
            ObjectGuid::Create<HighGuid::Player>(staged.first), 0);
        TC_LOG_INFO("server",
            "WorldBoss Call %u staged login requested boss=%u requester=%u name=%s guid=%u role=%u; summon waits for all logins; PvE build and legendary cloak are applied after login",
            WorldBossStageRaidSize, boss->GetEntry(), WorldBossStageRequester, staged.second.Name.c_str(),
            staged.first, uint32(staged.second.Role));
    }
    return true;
}

void BeginWorldBossStageCleanup(char const* reason)
{
    WorldBossStageCleanupReason = reason ? reason : "requested cleanup";
    WorldBossStageState = WorldBossStagedState::Cleanup;
    WorldBossStageElapsed = 0;
    WorldBossStageUpdateTimer = 0;
    for (auto& staged : WorldBossStagedBots)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
        if (Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid))
        {
            bot->BeginWorldBossStagingCleanup();
            staged.second.CleanupReadyAt = 2000;
        }
    }
    TC_LOG_INFO("server", "WorldBoss staged raid cleanup requested requester=%u reason=%s",
        WorldBossStageRequester, WorldBossStageCleanupReason.c_str());
}

void PrepareWorldBossBotForSummon(Player* bot)
{
    if (!bot)
        return;

    if (bot->IsCharmed())
        bot->RemoveCharmAuras();
    bot->CombatStop();
    bot->getHostileRefManager().deleteReferences();
    if (!bot->IsAlive())
    {
        bot->ResurrectPlayer(1.0f, false);
        bot->SpawnCorpseBones();
    }
    bot->SetFullHealth();
    bot->ResetAllPowers();
}

void ShowWorldBossCallerMenu(Player* player, Creature* caller)
{
    ClearGossipMenuFor(player);

    WorldBossCallerConfig config;
    if (!LoadWorldBossCallerConfig(caller, config))
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "Boss Bot Caller spawn %u has no valid configuration.",
            caller ? caller->GetDBTableGUIDLow() : 0);
        CloseGossipMenuFor(player);
        return;
    }

    char const* bossName = GetSupportedWorldBossName(config.BossEntry);
    if (config.RaidSizeMask & WORLD_BOSS_CALLER_RAID_10)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            std::string("Preview 10-player pool for ") + bossName,
            GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_PREVIEW_10);
    if (config.RaidSizeMask & WORLD_BOSS_CALLER_RAID_25)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            std::string("Preview 25-player pool for ") + bossName,
            GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_PREVIEW_25);

    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Encounter status",
        GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_STATUS);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Rebuff living staged raid",
        GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_REBUFF);

    if (config.RaidSizeMask & WORLD_BOSS_CALLER_RAID_10)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "Call 10 (PvE build, cloak, group and summon)",
            GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_STAGE_10);
    if (config.RaidSizeMask & WORLD_BOSS_CALLER_RAID_25)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "Call 25 (PvE build, cloak, group and summon)",
            GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_STAGE_25);
    AddGossipItemFor(player, GOSSIP_ICON_CHAT,
        WorldBossStageState == WorldBossStagedState::Idle ?
            "Dismiss staged raid (none active)" : "Dismiss staged raid",
        GOSSIP_SENDER_MAIN, WORLD_BOSS_CALLER_DISMISS);

    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, caller->GetGUID());
}

struct npc_world_boss_bot_caller : public ScriptedAI
{
    npc_world_boss_bot_caller(Creature* creature) : ScriptedAI(creature) { }

    bool OnGossipHello(Player* player) override
    {
        ShowWorldBossCallerMenu(player, me);
        return true;
    }

    bool OnGossipSelect(Player* player, uint32 /*menuId*/, uint32 gossipListId) override
    {
        uint32 action = player->PlayerTalkClass->GetGossipOptionAction(gossipListId);
        WorldBossCallerConfig config;
        ChatHandler handler(player->GetSession());
        if (!LoadWorldBossCallerConfig(me, config))
        {
            handler.PSendSysMessage("Boss Bot Caller spawn %u has no valid configuration.",
                me->GetDBTableGUIDLow());
            CloseGossipMenuFor(player);
            return true;
        }

        char const* bossName = GetSupportedWorldBossName(config.BossEntry);
        Creature* aliveBoss = FindConfiguredWorldBoss(me, config, true);
        if (action == WORLD_BOSS_CALLER_STATUS)
        {
            uint32 onlineBots = 0;
            uint32 aliveBots = 0;
            uint32 nearbyBots = 0;
            uint32 groupedBots = 0;
            for (auto const& staged : WorldBossStagedBots)
            {
                Player* bot = sRandomPlayerbotMgr->GetPlayerBot(
                    ObjectGuid::Create<HighGuid::Player>(staged.first));
                if (!bot || !bot->IsInWorld())
                    continue;

                ++onlineBots;
                if (bot->IsAlive())
                    ++aliveBots;
                if (bot->GetGroup() && bot->GetGroup()->GetLowGUID() ==
                    WorldBossStageGroup)
                    ++groupedBots;
                if (bot->GetMapId() == player->GetMapId() &&
                    bot->GetDistance2d(player) <= 30.0f)
                    ++nearbyBots;
            }

            handler.PSendSysMessage(
                "Boss Bot Caller: %s (entry %u), active-nearby=%s, strategy=%s, staged-state=%s, staged-bots=%u, online=%u, alive=%u, grouped=%u, nearby-player=%u, buffed=%u, raid-group=%u, elapsed=%us.",
                bossName, config.BossEntry, aliveBoss ? "yes" : "no",
                config.StrategyReady ? "audited" : "not ready",
                WorldBossStagedStateName(), uint32(WorldBossStagedBots.size()),
                onlineBots, aliveBots, groupedBots, nearbyBots,
                uint32(WorldBossStageBuffedBots.size()), WorldBossStageGroup,
                WorldBossStageElapsed / 1000);
            if (WorldBossStageState == WorldBossStagedState::Cleanup &&
                !WorldBossStageCleanupReason.empty())
                handler.PSendSysMessage("Cleanup reason: %s.",
                    WorldBossStageCleanupReason.c_str());
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        if (action == WORLD_BOSS_CALLER_DISMISS)
        {
            if (WorldBossStageState == WorldBossStagedState::Idle)
                handler.SendSysMessage("There is no staged world-boss raid to dismiss.");
            else if (player->GetGUID().GetCounter() != WorldBossStageRequester)
                handler.SendSysMessage(
                    "Only the player who started this staged raid may dismiss it.");
            else
            {
                BeginWorldBossStageCleanup("caller Dismiss selected");
                handler.SendSysMessage(
                    "Staged raid cleanup started. Reopen Encounter status in a few seconds.");
            }
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        if (action == WORLD_BOSS_CALLER_REBUFF)
        {
            std::string error;
            if (!RequestWorldBossRebuff(player, error))
                handler.PSendSysMessage("Rebuff refused: %s.", error.c_str());
            else
                handler.SendSysMessage(
                    "Rebuff requested. Living out-of-combat bots will renew missing raid buffs.");
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        if (action == WORLD_BOSS_CALLER_STAGE_10 ||
            action == WORLD_BOSS_CALLER_STAGE_25)
        {
            uint32 raidSize = action == WORLD_BOSS_CALLER_STAGE_10 ? 10 : 25;
            uint8 requiredMask = raidSize == 10 ? WORLD_BOSS_CALLER_RAID_10 :
                WORLD_BOSS_CALLER_RAID_25;
            if (!(config.RaidSizeMask & requiredMask))
            {
                handler.PSendSysMessage("Call %u is not enabled at this caller.", raidSize);
                ShowWorldBossCallerMenu(player, me);
                return true;
            }
            if (!aliveBoss)
            {
                handler.PSendSysMessage(
                    "%s is not alive within %.0f yards; no bots were logged in.",
                    bossName, config.SearchRadius);
                ShowWorldBossCallerMenu(player, me);
                return true;
            }

            std::string error;
            if (!StartWorldBossStage(player, me, aliveBoss, raidSize, error))
                handler.PSendSysMessage("Call %u staging refused: %s.", raidSize, error.c_str());
            else
                handler.PSendSysMessage(
                    "Call %u staged %u bots for login. After all are ready they will be revived, "
                    "given a PvE build and role cloak, grouped and summoned around you.",
                    raidSize, uint32(WorldBossStagedBots.size()));
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        if (action == WORLD_BOSS_CALLER_LOCKED_10 ||
            action == WORLD_BOSS_CALLER_LOCKED_25)
        {
            handler.PSendSysMessage(
                "Real bot Call is locked for %s. Preview is safe; no bot will be changed.",
                bossName);
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        uint32 raidSize = action == WORLD_BOSS_CALLER_PREVIEW_10 ? 10 :
            (action == WORLD_BOSS_CALLER_PREVIEW_25 ? 25 : 0);
        uint8 requiredMask = raidSize == 10 ? WORLD_BOSS_CALLER_RAID_10 :
            WORLD_BOSS_CALLER_RAID_25;
        if (!raidSize || !(config.RaidSizeMask & requiredMask))
        {
            CloseGossipMenuFor(player);
            return true;
        }

        if (!aliveBoss)
        {
            handler.PSendSysMessage(
                "%s is not alive within %.0f yards of this caller; preview was not run.",
                bossName, config.SearchRadius);
            ShowWorldBossCallerMenu(player, me);
            return true;
        }

        ObjectGuid oldSelection = player->GetTarget();
        player->SetSelection(aliveBoss->GetGUID());
        playerbots_commandscript::HandleWorldBossBotsCommand(
            &handler, raidSize == 10 ? "preview 10" : "preview 25");
        player->SetSelection(oldSelection);
        ShowWorldBossCallerMenu(player, me);
        return true;
    }
};
}

void UpdateWorldBossStagedRaid(uint32 diff)
{
    if (WorldBossStageState == WorldBossStagedState::Idle)
        return;
    if (WorldBossStageUpdateTimer > diff)
    {
        WorldBossStageUpdateTimer -= diff;
        return;
    }
    WorldBossStageUpdateTimer = 1000;
    WorldBossStageElapsed += 1000;

    Player* requester = WorldBossStageRequester ? ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(WorldBossStageRequester)) : nullptr;

    if (WorldBossStageState == WorldBossStagedState::WaitForBots)
    {
        if (!requester)
        {
            BeginWorldBossStageCleanup("requester disconnected while bots were loading");
            return;
        }
        // A fresh server spends roughly its first minute initializing the
        // random-bot manager. A 25-player Call also has substantially more
        // asynchronous character queries than Solo Arena. Keep the process
        // bounded, but allow enough time for the retry loop to recover bot
        // logins made during that startup window.
        uint32 loginTimeout = WorldBossStageRaidSize == 25 ? 300000 : 180000;
        if (WorldBossStageElapsed >= loginTimeout)
        {
            std::ostringstream timeoutReason;
            timeoutReason << "bot login timeout after "
                << loginTimeout / 1000 << " seconds";
            BeginWorldBossStageCleanup(timeoutReason.str().c_str());
            ChatHandler(requester->GetSession()).PSendSysMessage(
                "World-boss Call %u timed out after %u seconds while loading bots; automatic cleanup started.",
                WorldBossStageRaidSize, loginTimeout / 1000);
            return;
        }
        if (requester->GetGroup() || requester->InBattleground() ||
            requester->InBattlegroundQueue() || requester->IsUsingLfg() ||
            requester->IsInCombat())
        {
            BeginWorldBossStageCleanup("requester became grouped, queued, or busy");
            return;
        }

        uint32 readyBots = 0;
        uint32 loadingBots = 0;
        uint32 offlineBots = 0;
        uint32 teleportingBots = 0;
        for (auto const& staged : WorldBossStagedBots)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
            if (sRandomPlayerbotMgr->IsBotLoading(guid))
            {
                ++loadingBots;
                continue;
            }
            Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
            if (!bot || !bot->IsInWorld())
            {
                ++offlineBots;
                // A failed asynchronous login removes the GUID from
                // botLoading. The old coordinator then waited until its
                // timeout without ever asking again. Retry only an actually
                // offline, non-loading bot at a conservative interval.
                if (WorldBossStageElapsed % 15000 == 0)
                {
                    sRandomPlayerbotMgr->AddPlayerBot(guid, 0);
                    TC_LOG_INFO("server",
                        "WorldBoss Call %u login retry requested name=%s guid=%u elapsed=%us",
                        WorldBossStageRaidSize, staged.second.Name.c_str(),
                        staged.first, WorldBossStageElapsed / 1000);
                }
                continue;
            }
            if (bot->IsBeingTeleported())
            {
                ++teleportingBots;
                continue;
            }
            ++readyBots;
        }
        if (readyBots != WorldBossStagedBots.size())
        {
            if (WorldBossStageElapsed % 15000 == 0)
                ChatHandler(requester->GetSession()).PSendSysMessage(
                    "World-boss Call %u login progress: ready=%u/%u, loading=%u, offline=%u, teleporting=%u. Dismiss remains available at every Boss Bot Caller.",
                    WorldBossStageRaidSize, readyBots,
                    uint32(WorldBossStagedBots.size()), loadingBots,
                    offlineBots, teleportingBots);
            return;
        }

        std::vector<Player*> bots;
        bots.reserve(WorldBossStagedBots.size());
        for (auto const& staged : WorldBossStagedBots)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
            if (sRandomPlayerbotMgr->IsBotLoading(guid))
                return;
            Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
            if (!bot || !bot->IsInWorld())
                return;
            if (bot->IsBeingTeleported())
                return;
            if (bot->GetGroup() || bot->InBattleground() ||
                bot->InBattlegroundQueue() || bot->IsUsingLfg())
            {
                TC_LOG_ERROR("server",
                    "WorldBoss staged bot became externally busy before grouping name=%s guid=%u group=%u battleground=%u queue=%u lfg=%u",
                    bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                    bot->GetGroup() ? bot->GetGroup()->GetLowGUID() : 0,
                    bot->InBattleground() ? 1u : 0u,
                    bot->InBattlegroundQueue() ? 1u : 0u,
                    bot->IsUsingLfg() ? 1u : 0u);
                BeginWorldBossStageCleanup("a staged bot became externally owned before grouping");
                return;
            }
            // A random bot can finish loading at its saved position in combat,
            // dead, or with stale hostile references. Those are precisely the
            // transient states this coordinator owns and normalizes before it
            // creates the raid; they must not be mistaken for another queue or
            // group owning the bot.
            PrepareWorldBossBotForSummon(bot);

            // Fill missing PvE build data before the raid is formed. These
            // helpers preserve an existing valid build and only initialize
            // what the bot lacks; the requester's build is never touched.
            BotFactory factory(bot, bot->GetLevel());
            factory.InitTalentsTree(false);
            factory.InitGlyphs();
            factory.InitPet();
            factory.InitEquipmentForSpec();
            bool expectsPersistentPet = bot->GetClass() == CLASS_HUNTER ||
                bot->GetClass() == CLASS_WARLOCK ||
                bot->GetSpecialization() == SPEC_MAGE_FROST;
            if (Guardian* guardian = bot->GetGuardianPet())
            {
                Pet* controlledPet = guardian->ToPet();
                TC_LOG_INFO("server",
                    "WorldBoss PvE pet prepared owner=%s guid=%u class=%u pet-entry=%u pet-number=%u pet-spec=%u reaction=%u",
                    bot->GetName().c_str(), staged.first,
                    uint32(bot->GetClass()), guardian->GetEntry(),
                    controlledPet ? controlledPet->GetCharmInfo()->GetPetNumber() : 0,
                    controlledPet ? uint32(controlledPet->GetSpecializationId()) : 0,
                    uint32(guardian->GetReactState()));
            }
            else if (expectsPersistentPet)
                TC_LOG_WARN("server",
                    "WorldBoss PvE pet missing after preparation owner=%s guid=%u class=%u specialization=%u",
                    bot->GetName().c_str(), staged.first,
                    uint32(bot->GetClass()), uint32(bot->GetSpecialization()));
            uint32 pveItemSet = 0;
            uint32 armorChanged = 0;
            std::string armorError;
            if (!EnsureWorldBossPveArmor(bot, pveItemSet,
                armorChanged, armorError))
            {
                TC_LOG_ERROR("server",
                    "WorldBoss PvE armor preparation failed name=%s guid=%u specialization=%u error=%s",
                    bot->GetName().c_str(), staged.first,
                    uint32(bot->GetSpecialization()), armorError.c_str());
                BeginWorldBossStageCleanup(
                    "a staged bot could not receive its specialization T16 PvE armor");
                return;
            }
            uint32 legendaryCloak = 0;
            bool cloakChanged = false;
            std::string cloakError;
            if (!EnsureWorldBossLegendaryCloak(bot, legendaryCloak,
                cloakChanged, cloakError))
            {
                TC_LOG_ERROR("server",
                    "WorldBoss PvE cloak preparation failed name=%s guid=%u error=%s",
                    bot->GetName().c_str(), staged.first,
                    cloakError.c_str());
                BeginWorldBossStageCleanup(
                    "a staged bot could not receive its role-appropriate legendary cloak");
                return;
            }
            uint32 glyphCount = 0;
            for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
                if (bot->GetGlyph(bot->GetActiveSpec(), slot))
                    ++glyphCount;
            TC_LOG_INFO("server",
                "WorldBoss PvE build prepared name=%s guid=%u specialization=%u talents=%u glyphs=%u T16-set=%u armor-changed=%u selected-pvp-items=%u selected-avg-ilvl=%u legendary-cloak=%u cloak-changed=%u",
                bot->GetName().c_str(), staged.first,
                uint32(bot->GetSpecialization()), bot->GetUsedTalentCount(),
                glyphCount, pveItemSet, armorChanged,
                staged.second.PvpItems, staged.second.AverageItemLevel,
                legendaryCloak,
                cloakChanged ? 1u : 0u);
            bots.push_back(bot);
        }

        uint32 expectedBots = WorldBossStageRaidSize > 0 ? WorldBossStageRaidSize - 1 : 0;
        if (bots.size() != expectedBots)
        {
            BeginWorldBossStageCleanup("Call did not own the expected bot count");
            return;
        }

        Group* group = new Group();
        if (!group->Create(requester))
        {
            delete group;
            BeginWorldBossStageCleanup("raid group creation failed");
            return;
        }
        group->ConvertToRaid();
        for (Player* bot : bots)
        {
            if (!group->AddMember(bot))
            {
                group->Disband();
                BeginWorldBossStageCleanup("a staged bot could not join the raid");
                return;
            }
        }

        auto roleFlag = [](WorldBossPreviewRole role) -> uint32
        {
            switch (role)
            {
                case WorldBossPreviewRole::Tank:   return lfg::PLAYER_ROLE_TANK;
                case WorldBossPreviewRole::Healer: return lfg::PLAYER_ROLE_HEALER;
                case WorldBossPreviewRole::Damage: return lfg::PLAYER_ROLE_DAMAGE;
                case WorldBossPreviewRole::None:   return lfg::PLAYER_ROLE_NONE;
            }
            return lfg::PLAYER_ROLE_NONE;
        };

        WorldBossPreviewRole requesterRole = GetWorldBossPreviewRole(
            requester->GetSpecialization());
        group->SetMemberRole(requester->GetGUID(), roleFlag(requesterRole));

        ObjectGuid mainTank;
        ObjectGuid primaryHealer;
        if (requesterRole == WorldBossPreviewRole::Tank)
            mainTank = requester->GetGUID();
        else if (requesterRole == WorldBossPreviewRole::Healer)
            primaryHealer = requester->GetGUID();

        for (Player* bot : bots)
        {
            auto staged = WorldBossStagedBots.find(bot->GetGUID().GetCounter());
            if (staged == WorldBossStagedBots.end())
                continue;
            group->SetMemberRole(bot->GetGUID(), roleFlag(staged->second.Role));
            if (mainTank.IsEmpty() && staged->second.Role == WorldBossPreviewRole::Tank)
                mainTank = bot->GetGUID();
            if (primaryHealer.IsEmpty() &&
                staged->second.Role == WorldBossPreviewRole::Healer)
                primaryHealer = bot->GetGUID();
        }

        // Standard raid marker indices: Moon=4 and Square=5.
        if (!mainTank.IsEmpty())
        {
            group->SetGroupMemberFlag(mainTank, true, MEMBER_FLAG_MAINTANK);
            group->SetTargetIcon(5, requester->GetGUID(), mainTank, 0);
        }
        if (!primaryHealer.IsEmpty())
            group->SetTargetIcon(4, requester->GetGUID(), primaryHealer, 0);

        WorldBossStageGroup = group->GetLowGUID();
        WorldBossStageMap = requester->GetMapId();
        WorldBossStageX = requester->GetPositionX();
        WorldBossStageY = requester->GetPositionY();
        WorldBossStageZ = requester->GetPositionZ();

        for (size_t index = 0; index < bots.size(); ++index)
        {
            Player* bot = bots[index];
            uint32 ring = uint32(index / 8);
            uint32 ringIndex = uint32(index % 8);
            uint32 ringCount = std::min<uint32>(8,
                uint32(bots.size()) - ring * 8);
            float distance = 6.0f + float(ring * 4);
            float angle = requester->GetOrientation() +
                float(2.0 * M_PI * ringIndex / ringCount);
            float x = WorldBossStageX;
            float y = WorldBossStageY;
            float z = WorldBossStageZ;
            requester->GetNearPoint(bot, x, y, z, bot->GetObjectSize(),
                distance, angle);
            // Nalak's zone normally rejects characters that have not completed
            // the Isle of Thunder introduction. These temporary raid members
            // are owned by this coordinator and must remain eligible only for
            // the lifetime of the staged call.
            bot->SetWorldBossStagingAccess(true);
            if (!bot->TeleportTo(WorldBossStageMap, x, y, z,
                requester->GetOrientation()))
            {
                BeginWorldBossStageCleanup("a staged bot teleport was refused");
                return;
            }
            TC_LOG_INFO("server",
                "WorldBoss Call %u summon requested name=%s guid=%u map=%u position=%.3f/%.3f/%.3f",
                WorldBossStageRaidSize, bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                WorldBossStageMap, x, y, z);
        }

        WorldBossStageState = WorldBossStagedState::WaitForTeleport;
        WorldBossStageElapsed = 0;
        TC_LOG_INFO("server",
            "WorldBoss Call %u staged raid created requester=%u group=%u bots=%u; square-tank=%u moon-healer=%u; summon-to-requester requested; PvE builds and role cloaks prepared",
            WorldBossStageRaidSize, WorldBossStageRequester, WorldBossStageGroup,
            uint32(WorldBossStagedBots.size()), mainTank.GetCounter(),
            primaryHealer.GetCounter());
        ChatHandler(requester->GetSession()).PSendSysMessage(
            "World-boss raid formed. Reviving and summoning all %u bots around you...",
            uint32(WorldBossStagedBots.size()));
        return;
    }

    if (WorldBossStageState == WorldBossStagedState::WaitForTeleport)
    {
        if (!requester)
        {
            BeginWorldBossStageCleanup("requester disconnected during summon");
            return;
        }
        if (WorldBossStageElapsed >= 60000)
        {
            BeginWorldBossStageCleanup("bot summon timeout after 60 seconds");
            ChatHandler(requester->GetSession()).SendSysMessage(
                "World-boss bot summon timed out; automatic cleanup started.");
            return;
        }

        uint32 arrivedBots = 0;
        for (auto const& staged : WorldBossStagedBots)
        {
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
            Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
            if (!bot)
            {
                BeginWorldBossStageCleanup("a summoned bot went offline");
                return;
            }
            if (bot->IsBeingTeleported() || !bot->IsInWorld())
                continue;
            if (bot->GetMapId() != WorldBossStageMap ||
                bot->GetDistance2d(WorldBossStageX, WorldBossStageY) > 25.0f)
            {
                continue;
            }
            PrepareWorldBossBotForSummon(bot);
            ++arrivedBots;
        }

        if (arrivedBots != WorldBossStagedBots.size())
        {
            if (WorldBossStageElapsed % 10000 == 0)
                ChatHandler(requester->GetSession()).PSendSysMessage(
                    "World-boss summon progress: arrived alive near you=%u/%u.",
                    arrivedBots, uint32(WorldBossStagedBots.size()));
            return;
        }

        WorldBossStageState = WorldBossStagedState::Grouped;
        WorldBossStageElapsed = 0;
        WorldBossStageBuffedBots.clear();
        WorldBossStageEncounterStarted = false;
        WorldBossStageWipePending = false;
        WorldBossStageBossDefeatedTimer = 0;
        TC_LOG_INFO("server",
            "WorldBoss Call %u staged raid ready requester=%u group=%u bots=%u map=%u center=%.3f/%.3f/%.3f; all bots alive and nearby",
            WorldBossStageRaidSize, WorldBossStageRequester, WorldBossStageGroup,
            uint32(WorldBossStagedBots.size()), WorldBossStageMap,
            WorldBossStageX, WorldBossStageY, WorldBossStageZ);
        ChatHandler(requester->GetSession()).PSendSysMessage(
            "World-boss staged raid %u is ready with %u living bots around you. "
            "Square marks the main tank; Moon marks the primary healer. "
            "PvE talents, glyphs and role-appropriate legendary cloaks are ready. "
            "Use Dismiss staged raid when finished.",
            WorldBossStageGroup, uint32(WorldBossStagedBots.size()));
        return;
    }

    if (WorldBossStageState == WorldBossStagedState::Grouped)
    {
        if (!requester)
        {
            BeginWorldBossStageCleanup("requester disconnected after raid assembly");
            return;
        }

        Group* group = WorldBossStageGroup ?
            sGroupMgr->GetGroupByGUID(WorldBossStageGroup) : nullptr;
        if (!group || requester->GetGroup() != group)
        {
            BeginWorldBossStageCleanup("staged raid group no longer exists");
            return;
        }

        uint32 aliveMembers = requester->IsAlive() ? 1 : 0;
        for (auto const& staged : WorldBossStagedBots)
        {
            Player* bot = sRandomPlayerbotMgr->GetPlayerBot(
                ObjectGuid::Create<HighGuid::Player>(staged.first));
            if (!bot || bot->GetGroup() != group)
            {
                BeginWorldBossStageCleanup("a staged raid member went offline or left the raid");
                return;
            }

            // A death strips ordinary raid buffs. Forget this bot's completed
            // preparation state immediately so the normal aura-aware class
            // actions can renew missing buffs after a combat resurrection or
            // corpse run. This does not cast while dead or in combat.
            if (!bot->IsAlive())
                WorldBossStageBuffedBots.erase(staged.first);

            // Rebirth/Raise Ally and any other real combat-resurrection spell
            // creates a normal resurrection request. A client player accepts
            // it through CMSG_RESURRECT_RESPONSE, but a headless playerbot has
            // no client to send that packet. Accept only an already-created
            // core request, and only for a dead bot owned by this staged raid;
            // this neither invents a resurrection nor bypasses spell cooldowns.
            if (!bot->IsAlive() && bot->IsRessurectRequested())
            {
                bot->ResurrectUsingRequestData();
                TC_LOG_INFO("server",
                    "WorldBoss combat resurrection accepted raid=%u boss=%u name=%s guid=%u",
                    WorldBossStageGroup, WorldBossStageBossEntry,
                    bot->GetName().c_str(), staged.first);
            }

            if (bot->IsAlive())
                ++aliveMembers;

            // Use the real class actions already shared with Arena/BG
            // preparation. Their own aura checks prevent recasting the same
            // raid buff, while a second paladin can still contribute the other
            // blessing. Classes without a preparation action are marked done
            // immediately instead of being retried forever.
            if (bot->IsAlive() && !bot->IsInCombat() &&
                !WorldBossStageBuffedBots.count(staged.first))
            {
                std::vector<char const*> actions =
                    GetSoloArenaPreparationBuffActions(bot);
                bool complete = actions.empty();
                if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                {
                    if (!botAI->IsRealPlayer())
                    {
                        botAI->SetMaster(requester);
                        botAI->ChangeStrategy("+follow", BOT_STATE_NON_COMBAT);
                        botAI->ChangeStrategy("+avoid aoe", BOT_STATE_COMBAT);
                        for (char const* action : actions)
                            if (botAI->DoSpecificAction(action, Event(), true))
                            {
                                complete = true;
                                TC_LOG_INFO("server",
                                    "WorldBoss preparation buff cast raid=%u boss=%u name=%s guid=%u action=%s",
                                    WorldBossStageGroup, WorldBossStageBossEntry,
                                    bot->GetName().c_str(), staged.first, action);
                                break;
                            }
                    }
                }
                if (complete)
                    WorldBossStageBuffedBots.insert(staged.first);
            }
        }

        // FindNearestCreature's final argument is an exact alive-state filter,
        // not an "include dead" switch.  Looking up only `false` made a live
        // world boss invisible to the coordinator, so encounter start and wipe
        // recovery could never be armed. Resolve the living spawn first and
        // fall back to its corpse only for the post-kill cleanup path.
        Creature* boss = requester->FindNearestCreature(
            WorldBossStageBossEntry, 500.0f, true);
        if (!boss)
            boss = requester->FindNearestCreature(
                WorldBossStageBossEntry, 500.0f, false);

        // A raid marker is persistent even when its player dies.  Without
        // moving MEMBER_FLAG_MAINTANK, PlayerBotSpec::IsMainTank keeps
        // returning the dead tank and every living tank remains an assist
        // tank forever.  Promote an alive tank, preferring the boss's current
        // tank, so generic tank AI and the source-backed encounter reactions
        // have one unambiguous owner.  This is especially important for
        // taunt-immune Oondasta, where Alpha Male makes the second threat tank
        // the intended failover instead of permitting an artificial taunt.
        ObjectGuid markedMainTank;
        for (Group::MemberSlot const& member : group->GetMemberSlots())
        {
            if (member.flags & MEMBER_FLAG_MAINTANK)
            {
                markedMainTank = member.guid;
                break;
            }
        }

        Player* markedTank = nullptr;
        if (!markedMainTank.IsEmpty())
        {
            if (requester->GetGUID() == markedMainTank)
                markedTank = requester;
            else
                markedTank = sRandomPlayerbotMgr->GetPlayerBot(markedMainTank);
        }

        if (!markedTank || markedTank->GetGroup() != group ||
            !markedTank->IsAlive())
        {
            Player* replacement = nullptr;
            if (boss && boss->IsAlive())
            {
                if (Player* victim = boss->GetVictim() ?
                    boss->GetVictim()->ToPlayer() : nullptr)
                {
                    if (victim->GetGroup() == group && victim->IsAlive() &&
                        PlayerBotSpec::IsTank(victim, true))
                        replacement = victim;
                }
            }

            if (!replacement)
            {
                for (GroupReference* ref = group->GetFirstMember(); ref;
                    ref = ref->next())
                {
                    Player* member = ref->GetSource();
                    if (member && member->IsAlive() &&
                        PlayerBotSpec::IsTank(member, true))
                    {
                        replacement = member;
                        break;
                    }
                }
            }

            if (replacement && replacement->GetGUID() != markedMainTank)
            {
                group->SetGroupMemberFlag(replacement->GetGUID(), true,
                    MEMBER_FLAG_MAINTANK);
                group->SetTargetIcon(5, requester->GetGUID(),
                    replacement->GetGUID(), 0);
                TC_LOG_INFO("server",
                    "WorldBoss main-tank failover raid=%u boss=%u old=%u new=%s/%u",
                    WorldBossStageGroup, WorldBossStageBossEntry,
                    markedMainTank.GetCounter(), replacement->GetName().c_str(),
                    replacement->GetGUID().GetCounter());
                ChatHandler(requester->GetSession()).PSendSysMessage(
                    "World-boss main tank changed to %s after the marked tank became unavailable.",
                    replacement->GetName().c_str());
            }
        }

        if (boss && boss->IsAlive() && boss->IsInCombat())
        {
            WorldBossStageEncounterStarted = true;
            WorldBossStageWipePending = false;
            WorldBossStageBossDefeatedTimer = 0;
        }
        else if (WorldBossStageEncounterStarted && boss && !boss->IsAlive())
        {
            WorldBossStageBossDefeatedTimer += 1000;
            if (WorldBossStageBossDefeatedTimer >= 10000)
            {
                ChatHandler(requester->GetSession()).SendSysMessage(
                    "World boss defeated. The staged raid will now be dismissed safely.");
                BeginWorldBossStageCleanup("world boss defeated");
                return;
            }
        }
        else if (boss && boss->IsAlive())
        {
            // A released player can be moved to a graveyard farther than the
            // local 500-yard lookup while the rest of the raid is still
            // fighting. Never interpret an absent boss as a defeated boss:
            // doing so used to dismiss the raid before corpse runback could
            // finish. Only a positively observed dead creature starts the
            // automatic post-kill cleanup timer.
            WorldBossStageBossDefeatedTimer = 0;
        }

        if (WorldBossStageEncounterStarted && aliveMembers == 0)
            WorldBossStageWipePending = true;

        // Never grant an in-combat resurrection. Dead bots continue through
        // the module's normal release-spirit/corpse logic. After a complete
        // wipe, once the real requester has revived and the boss has reset,
        // rebuild the formation for a clean second pull.
        if (WorldBossStageWipePending && requester->IsAlive() && boss &&
            boss->IsAlive() && !boss->IsInCombat())
        {
            size_t index = 0;
            for (auto const& staged : WorldBossStagedBots)
            {
                Player* bot = sRandomPlayerbotMgr->GetPlayerBot(
                    ObjectGuid::Create<HighGuid::Player>(staged.first));
                if (!bot)
                    continue;
                PrepareWorldBossBotForSummon(bot);
                float angle = requester->GetOrientation() +
                    float(2.0 * M_PI * index /
                        std::max<size_t>(1, WorldBossStagedBots.size()));
                float x = requester->GetPositionX();
                float y = requester->GetPositionY();
                float z = requester->GetPositionZ();
                requester->GetNearPoint(bot, x, y, z, bot->GetObjectSize(),
                    8.0f, angle);
                bot->TeleportTo(requester->GetMapId(), x, y, z,
                    requester->GetOrientation());
                ++index;
            }

            // A clean pull starts with the requester's tank role again when
            // applicable; otherwise use the first revived staged tank.  This
            // also replaces a failover marker left on the previous pull.
            Player* resetMainTank = nullptr;
            if (GetWorldBossPreviewRole(requester->GetSpecialization()) ==
                WorldBossPreviewRole::Tank)
                resetMainTank = requester;
            if (!resetMainTank)
            {
                for (auto const& staged : WorldBossStagedBots)
                {
                    if (staged.second.Role != WorldBossPreviewRole::Tank)
                        continue;
                    Player* bot = sRandomPlayerbotMgr->GetPlayerBot(
                        ObjectGuid::Create<HighGuid::Player>(staged.first));
                    if (bot && bot->IsAlive() && bot->GetGroup() == group)
                    {
                        resetMainTank = bot;
                        break;
                    }
                }
            }
            if (resetMainTank)
            {
                group->SetGroupMemberFlag(resetMainTank->GetGUID(), true,
                    MEMBER_FLAG_MAINTANK);
                group->SetTargetIcon(5, requester->GetGUID(),
                    resetMainTank->GetGUID(), 0);
            }
            WorldBossStageBuffedBots.clear();
            WorldBossStageEncounterStarted = false;
            WorldBossStageWipePending = false;
            WorldBossStageBossDefeatedTimer = 0;
            ChatHandler(requester->GetSession()).SendSysMessage(
                "World-boss wipe detected. Bots were revived and regrouped for a fresh pull; preparation buffs are being renewed.");
            TC_LOG_INFO("server",
                "WorldBoss full-wipe recovery requester=%u group=%u boss=%u bots=%u",
                WorldBossStageRequester, WorldBossStageGroup,
                WorldBossStageBossEntry, uint32(WorldBossStagedBots.size()));
        }
        return;
    }

    if (WorldBossStageState != WorldBossStagedState::Cleanup)
        return;

    // Playerbot AI is updated by map workers, while this coordinator is
    // updated by the world thread. Pause every loaded bot and give any action
    // that already passed the pause check two seconds to finish before group,
    // teleport, or logout state is mutated. Bots that finish loading during
    // cleanup receive their own complete quiescence interval.
    bool cleanupBotsQuiesced = true;
    for (auto& staged : WorldBossStagedBots)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
        if (sRandomPlayerbotMgr->IsBotLoading(guid))
        {
            cleanupBotsQuiesced = false;
            continue;
        }

        if (Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid))
        {
            if (!bot->IsWorldBossStagingCleanup())
            {
                bot->BeginWorldBossStagingCleanup();
                staged.second.CleanupReadyAt = WorldBossStageElapsed + 2000;
            }
            if (WorldBossStageElapsed < staged.second.CleanupReadyAt)
                cleanupBotsQuiesced = false;
        }
    }
    if (!cleanupBotsQuiesced)
        return;

    if (WorldBossStageGroup)
    {
        Group* group = sGroupMgr->GetGroupByGUID(WorldBossStageGroup);
        if (group)
        {
            bool containsUnknownMember = false;
            for (Group::MemberSlot const& member : group->GetMemberSlots())
            {
                uint32 guidLow = member.guid.GetCounter();
                if (guidLow != WorldBossStageRequester &&
                    WorldBossStagedBots.find(guidLow) == WorldBossStagedBots.end())
                {
                    containsUnknownMember = true;
                    break;
                }
            }

            if (!containsUnknownMember &&
                group->GetLeaderGUID().GetCounter() == WorldBossStageRequester)
            {
                group->Disband();
                return;
            }

            // The coordinator never disbands a group containing an unrelated
            // player.  It only removes the bots that this staged call owns.
            // Reacquire the group after every removal because the core may
            // destroy it when too few members remain.
            std::vector<ObjectGuid> ownedMembers;
            for (auto const& staged : WorldBossStagedBots)
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(staged.first);
                if (group->IsMember(guid))
                    ownedMembers.push_back(guid);
            }
            for (ObjectGuid const& guid : ownedMembers)
            {
                group = sGroupMgr->GetGroupByGUID(WorldBossStageGroup);
                if (!group)
                    break;
                group->RemoveMember(guid, GROUP_REMOVEMETHOD_LEAVE);
            }
            TC_LOG_INFO("server",
                "WorldBoss cleanup detached %u owned staged bots from changed group %u; unrelated members were preserved",
                uint32(ownedMembers.size()), WorldBossStageGroup);
        }
        WorldBossStageGroup = 0;
    }

    for (auto itr = WorldBossStagedBots.begin(); itr != WorldBossStagedBots.end();)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(itr->first);
        if (sRandomPlayerbotMgr->IsBotLoading(guid))
        {
            ++itr;
            continue;
        }
        Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
        if (bot && (bot->GetGroup() || bot->InBattleground() ||
            bot->InBattlegroundQueue() || bot->IsUsingLfg() ||
            bot->IsBeingTeleported()))
        {
            ++itr;
            continue;
        }
        if (bot)
        {
            WorldBossStagedCandidate& candidate = itr->second;
            if (!candidate.ReturnRequested)
            {
                PrepareWorldBossBotForSummon(bot);
                if (!bot->TeleportTo(candidate.OriginalMap, candidate.OriginalX,
                    candidate.OriginalY, candidate.OriginalZ,
                    candidate.OriginalO))
                {
                    TC_LOG_ERROR("server",
                        "WorldBoss cleanup could not return bot name=%s guid=%u to map=%u position=%.3f/%.3f/%.3f; logout paused",
                        candidate.Name.c_str(), candidate.Guid,
                        candidate.OriginalMap, candidate.OriginalX,
                        candidate.OriginalY, candidate.OriginalZ);
                    ++itr;
                    continue;
                }
                candidate.ReturnRequested = true;
                TC_LOG_INFO("server",
                    "WorldBoss cleanup return requested name=%s guid=%u map=%u position=%.3f/%.3f/%.3f",
                    candidate.Name.c_str(), candidate.Guid,
                    candidate.OriginalMap, candidate.OriginalX,
                    candidate.OriginalY, candidate.OriginalZ);
                ++itr;
                continue;
            }
            if (bot->GetMapId() != candidate.OriginalMap ||
                bot->GetDistance2d(candidate.OriginalX, candidate.OriginalY) > 5.0f)
            {
                ++itr;
                continue;
            }
            PrepareSoloArenaBotForLogout(bot, "world-boss-stage-cleanup");
            sRandomPlayerbotMgr->LogoutPlayerBot(guid);
        }
        itr = WorldBossStagedBots.erase(itr);
    }

    if (!WorldBossStagedBots.empty())
        return;

    if (requester)
        ChatHandler(requester->GetSession()).SendSysMessage(
            "World-boss staged raid cleanup completed.");
    TC_LOG_INFO("server",
        "WorldBoss staged raid cleanup completed requester=%u reason=%s",
        WorldBossStageRequester, WorldBossStageCleanupReason.c_str());
    WorldBossStageState = WorldBossStagedState::Idle;
    WorldBossStageRequester = 0;
    WorldBossStageCaller = 0;
    WorldBossStageBoss = 0;
    WorldBossStageBossEntry = 0;
    WorldBossStageGroup = 0;
    WorldBossStageRaidSize = 0;
    WorldBossStageElapsed = 0;
    WorldBossStageUpdateTimer = 0;
    WorldBossStageMap = 0;
    WorldBossStageX = 0.0f;
    WorldBossStageY = 0.0f;
    WorldBossStageZ = 0.0f;
    WorldBossStageCleanupReason.clear();
    WorldBossStageBuffedBots.clear();
    WorldBossStageEncounterStarted = false;
    WorldBossStageWipePending = false;
    WorldBossStageBossDefeatedTimer = 0;
}

namespace
{
char const* SoloArenaAutomaticStateName(SoloArenaAutomaticState state)
{
    switch (state)
    {
        case SoloArenaAutomaticState::Idle: return "idle";
        case SoloArenaAutomaticState::Login: return "login";
        case SoloArenaAutomaticState::WaitForBots: return "wait-bots";
        case SoloArenaAutomaticState::ApplyLoadout: return "loadout";
        case SoloArenaAutomaticState::Group: return "group";
        case SoloArenaAutomaticState::Queue: return "queue";
        case SoloArenaAutomaticState::Match: return "match";
        case SoloArenaAutomaticState::WaitForInvite: return "wait-invite";
        case SoloArenaAutomaticState::Enter: return "enter";
        case SoloArenaAutomaticState::WaitForEntry: return "wait-entry";
        case SoloArenaAutomaticState::Active: return "active";
        case SoloArenaAutomaticState::Cleanup: return "cleanup";
    }

    return "unknown";
}

void SetSoloArenaAutomaticState(SoloArenaAutomaticState state)
{
    TC_LOG_INFO("server", "SoloArena automatic state %s -> %s requester=%u elapsed-ms=%u",
        SoloArenaAutomaticStateName(SoloArenaAutomaticQueueState),
        SoloArenaAutomaticStateName(state), SoloArenaAutomaticRequester,
        SoloArenaAutomaticElapsed);
    SoloArenaAutomaticQueueState = state;
}

void BeginSoloArenaAutomaticCleanup(char const* reason)
{
    SoloArenaAutomaticCleanupReason = reason ? reason : "unspecified failure";
    TC_LOG_ERROR("server", "SoloArena automatic preparation stopped requester=%u state=%s reason=%s",
        SoloArenaAutomaticRequester, SoloArenaAutomaticStateName(SoloArenaAutomaticQueueState),
        SoloArenaAutomaticCleanupReason.c_str());
    SetSoloArenaAutomaticState(SoloArenaAutomaticState::Cleanup);
}

Player* GetSoloArenaAutomaticRequester()
{
    return SoloArenaAutomaticRequester ? ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(SoloArenaAutomaticRequester)) : nullptr;
}

bool HasExpectedSoloArenaLoadout(Player* participant)
{
    if (!participant)
        return false;

    SoloArenaLoadoutPlan const* plan = GetSoloArenaLoadoutPlan(participant->GetSpecialization());
    if (!plan)
        return false;

    std::array<uint32, 5> const& expected = participant->GetTeam() == ALLIANCE ?
        plan->AllianceItems : plan->HordeItems;
    for (uint8 index = 0; index < expected.size(); ++index)
    {
        Item* equipped = participant->GetItemByPos(
            INVENTORY_SLOT_BAG_0, SoloArenaLoadoutEquipmentSlots[index]);
        if (!equipped || equipped->GetEntry() != expected[index])
            return false;
    }

    return true;
}

bool CleanupSoloArenaAutomaticStep()
{
    FinishSoloArenaAutomaticPreparationBuffs();

    std::vector<uint32> participantGuids = GetSoloArenaAutomaticParticipantGuids();
    std::vector<Player*> participants;
    for (uint32 guid : participantGuids)
        if (Player* participant = FindSoloArenaParticipant(guid))
            participants.push_back(participant);

    if (SoloArenaEnteredInstance)
    {
        bool pending = false;
        for (Player* participant : participants)
        {
            if (participant->IsBeingTeleported())
            {
                pending = true;
                continue;
            }
            if (participant->GetBattlegroundId() == SoloArenaEnteredInstance)
            {
                uint32 restored = 0;
                uint32 remaining = 0;
                std::string restoreError;
                RestoreSoloArenaLoadout(participant, "automatic-cleanup-leave",
                    restored, remaining, restoreError);
                participant->LeaveBattleground(true);
                pending = true;
            }
            else if (participant->InBattlegroundQueueForBattlegroundQueueType(
                SoloArenaAutomaticQueueType))
            {
                sBattlegroundMgr->RemovePlayerFromQueue(participant,
                    SoloArenaAutomaticQueueType);
                pending = true;
            }
        }
        if (pending)
            return false;
        SoloArenaEnteredInstance = 0;
        SoloArenaQueuesStaged = false;
        SoloArenaMatchScheduled = false;
    }

    if (SoloArenaQueuesStaged)
    {
        BattlegroundQueue& arenaQueue = sBattlegroundMgr->GetBattlegroundQueue(
            SoloArenaAutomaticQueueType);
        arenaQueue.SetForcedArenaType(BATTLEGROUND_TYPE_NONE);
        bool pending = false;
        for (Player* participant : participants)
        {
            if (participant->InBattlegroundQueueForBattlegroundQueueType(
                SoloArenaAutomaticQueueType))
            {
                sBattlegroundMgr->RemovePlayerFromQueue(participant,
                    SoloArenaAutomaticQueueType);
                pending = true;
            }
        }
        if (pending)
            return false;
        SoloArenaQueuesStaged = false;
        SoloArenaMatchScheduled = false;
    }

    auto disband = [](uint32& groupId, std::vector<uint32> const& memberGuids) -> bool
    {
        if (!groupId)
            return true;
        Group* group = sGroupMgr->GetGroupByGUID(groupId);
        if (!group)
        {
            groupId = 0;
            return true;
        }
        if (!IsExactSoloArenaAutomaticGroup(group, memberGuids))
            return false;
        for (uint32 guid : memberGuids)
        {
            Player* member = FindSoloArenaParticipant(guid);
            if (!member || member->InBattlegroundQueue() || member->InBattleground() ||
                member->IsBeingTeleported())
                return false;
        }
        group->Disband();
        groupId = 0;
        return true;
    };
    if (!disband(SoloArenaOpponentGroup, SoloArenaAutomaticOpponentTeam) ||
        !disband(SoloArenaRequesterGroup, SoloArenaAutomaticRequesterTeam))
        return false;

    for (uint32 guid : participantGuids)
    {
        if (!GetSoloArenaLoadoutBackupCount(guid))
            continue;
        Player* participant = FindSoloArenaParticipant(guid);
        if (!participant)
            return false;
        uint32 restored = 0;
        uint32 remaining = 0;
        std::string restoreError;
        if (!RestoreSoloArenaLoadout(participant, "automatic-cleanup",
            restored, remaining, restoreError))
            return false;
    }

    for (auto itr = SoloArenaStagedBots.begin(); itr != SoloArenaStagedBots.end();)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(itr->first);
        if (sRandomPlayerbotMgr->IsBotLoading(guid))
            return false;
        Player* bot = sRandomPlayerbotMgr->GetPlayerBot(guid);
        if (bot && (bot->GetGroup() || bot->InBattlegroundQueue() ||
            bot->InBattleground() || bot->IsBeingTeleported()))
            return false;
        if (bot)
        {
            PrepareSoloArenaBotForLogout(bot, "automatic-cleanup");
            sRandomPlayerbotMgr->LogoutPlayerBot(guid);
        }
        itr = SoloArenaStagedBots.erase(itr);
    }
    return true;
}

void ResetSoloArenaAutomaticState()
{
    TC_LOG_INFO("server", "SoloArena automatic cleanup completed requester=%u reason=%s",
        SoloArenaAutomaticRequester,
        SoloArenaAutomaticCleanupReason.empty() ? "normal completion" :
            SoloArenaAutomaticCleanupReason.c_str());
    SoloArenaAutomaticQueueState = SoloArenaAutomaticState::Idle;
    SoloArenaAutomaticRequester = 0;
    SoloArenaAutomaticUpdateTimer = 0;
    SoloArenaAutomaticElapsed = 0;
    SoloArenaAutomaticCleanupReason.clear();
    SoloArenaAutomaticRequesterTeam.clear();
    SoloArenaAutomaticOpponentTeam.clear();
    SoloArenaAutomaticTeamSize = ARENA_TYPE_2v2;
    SoloArenaAutomaticQueueType = BATTLEGROUND_QUEUE_2v2;
    SoloArenaStagedRequester = 0;
    SoloArenaStagedTeammate = 0;
    SoloArenaStagedOpponentHealer = 0;
    SoloArenaStagedOpponentDamage = 0;
    SoloArenaRequesterGroup = 0;
    SoloArenaOpponentGroup = 0;
    SoloArenaQueuesStaged = false;
    SoloArenaMatchScheduled = false;
    SoloArenaEnteredInstance = 0;
    SoloArenaAutomaticRewardProcessed = false;
    SoloArenaAutomaticHealthRestoreScheduled.clear();
    SoloArenaAutomaticExitTimer = 0;
    SoloArenaAutomaticPreparationBuffedBots.clear();
    SoloArenaAutomaticCombatActivatedBots.clear();
    SoloArenaAutomaticPreparationFacingApplied = false;
}
}

bool IsSoloArenaManagedPlayer(uint32 guidLow)
{
    if (!guidLow)
        return false;

    // The random-bot auto-queue paths use this shared ownership guard. Keep
    // world-boss staged bots protected as well, even though the historical
    // function name predates that coordinator.
    if (WorldBossStagedBots.find(guidLow) != WorldBossStagedBots.end())
        return true;

    if (guidLow == SoloArenaAutomaticRequester ||
        guidLow == SoloArenaStagedRequester ||
        SoloArenaStagedBots.find(guidLow) != SoloArenaStagedBots.end())
        return true;

    return std::find(SoloArenaAutomaticRequesterTeam.begin(),
               SoloArenaAutomaticRequesterTeam.end(), guidLow) !=
               SoloArenaAutomaticRequesterTeam.end() ||
        std::find(SoloArenaAutomaticOpponentTeam.begin(),
               SoloArenaAutomaticOpponentTeam.end(), guidLow) !=
               SoloArenaAutomaticOpponentTeam.end();
}

bool IsSoloArenaAutomationBusy()
{
    return SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Idle ||
        !SoloArenaStagedBots.empty() || SoloArenaRequesterGroup ||
        SoloArenaOpponentGroup || SoloArenaQueuesStaged ||
        SoloArenaEnteredInstance;
}

bool ApplyAutomatedPvpBotLoadout(Player* bot, uint32 requesterGuid,
    uint32& changedSlots, std::string& error)
{
    if (!bot)
    {
        changedSlots = 0;
        error = "bot is offline";
        return false;
    }

    if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
        if (!botAI->IsRealPlayer())
            return ApplySoloArenaLoadout(bot, requesterGuid, changedSlots, error);

    changedSlots = 0;
    error = "real-player equipment is protected";
    return false;
}

bool HasAutomatedPvpBotLoadout(Specializations specialization)
{
    return GetSoloArenaLoadoutPlan(specialization) != nullptr;
}

bool RestoreAutomatedPvpBotLoadout(Player* bot, char const* reason,
    uint32& restoredSlots, uint32& remainingSlots, std::string& error)
{
    return RestoreSoloArenaLoadout(bot, reason, restoredSlots, remainingSlots, error);
}

bool CastAutomatedPvpPreparationBuff(Player* bot)
{
    PlayerbotAI* botAI = bot ? GET_PLAYERBOT_AI(bot) : nullptr;
    if (!botAI || botAI->IsRealPlayer())
        return false;

    for (char const* action : GetSoloArenaPreparationBuffActions(bot))
        if (botAI->DoSpecificAction(action, Event(), true))
            return true;

    return false;
}

void UpdateAutomatedPvpLoadoutRecovery(uint32 diff)
{
    if (AutomatedPvpLoadoutRecoveryTimer > diff)
    {
        AutomatedPvpLoadoutRecoveryTimer -= diff;
        return;
    }
    AutomatedPvpLoadoutRecoveryTimer = 5000;

    uint32 recoveryRows = GetSoloArenaLoadoutBackupCount();
    if (recoveryRows && !IsSoloArenaAutomationBusy())
    {
        QueryResult owners = CharacterDatabase.Query(
            "SELECT DISTINCT b.`owner_guid`,c.`name`,c.`account` "
            "FROM `solo_arena_loadout_backup` b "
            "JOIN `characters` c ON c.`guid`=b.`owner_guid` ORDER BY b.`owner_guid`");
        if (owners)
        {
            do
            {
                Field* fields = owners->Fetch();
                uint32 ownerGuid = fields[0].GetUInt32();
                std::string ownerName = fields[1].GetString();
                uint32 accountId = fields[2].GetUInt32();
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(ownerGuid);
                Player* owner = ObjectAccessor::FindConnectedPlayer(guid);

                if (owner)
                {
                    PlayerbotAI* botAI = GET_PLAYERBOT_AI(owner);
                    if (!botAI || botAI->IsRealPlayer() || owner->GetGroup() ||
                        owner->InBattlegroundQueue() || owner->InBattleground() ||
                        owner->IsBeingTeleported() || owner->IsInCombat())
                        continue;

                    uint32 restored = 0;
                    uint32 remaining = 0;
                    std::string error;
                    if (!RestoreSoloArenaLoadout(owner, "automatic-crash-recovery",
                        restored, remaining, error))
                    {
                        TC_LOG_ERROR("server",
                            "Automatic PvP loadout recovery pending name=%s guid=%u restored=%u remaining=%u error=%s",
                            ownerName.c_str(), ownerGuid, restored, remaining, error.c_str());
                    }
                    continue;
                }

                bool randomBotAccount = std::find(
                    sPlayerbotAIConfig->randomBotAccounts.begin(),
                    sPlayerbotAIConfig->randomBotAccounts.end(), accountId) !=
                    sPlayerbotAIConfig->randomBotAccounts.end();
                if (!randomBotAccount || sRandomPlayerbotMgr->IsBotLoading(guid))
                    continue;

                SoloArenaLoadoutRecoveryBots.insert(ownerGuid);
                sRandomPlayerbotMgr->AddPlayerBot(guid, 0);
                TC_LOG_INFO("server",
                    "Automatic PvP loadout recovery requested bot login name=%s guid=%u rows=%u",
                    ownerName.c_str(), ownerGuid, GetSoloArenaLoadoutBackupCount(ownerGuid));
            }
            while (owners->NextRow());
        }
    }

    // Only bots explicitly logged in by this recovery path are logged out.
    // Bots that were already online before recovery retain their normal state.
    for (auto itr = SoloArenaLoadoutRecoveryBots.begin();
         itr != SoloArenaLoadoutRecoveryBots.end();)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(*itr);
        if (sRandomPlayerbotMgr->IsBotLoading(guid))
        {
            ++itr;
            continue;
        }

        Player* recoveryBot = sRandomPlayerbotMgr->GetPlayerBot(guid);
        if (!recoveryBot || GetSoloArenaLoadoutBackupCount(*itr) ||
            recoveryBot->GetGroup() || recoveryBot->InBattlegroundQueue() ||
            recoveryBot->InBattleground() || recoveryBot->IsBeingTeleported())
        {
            ++itr;
            continue;
        }

        PrepareSoloArenaBotForLogout(recoveryBot, "automatic-crash-recovery");
        sRandomPlayerbotMgr->LogoutPlayerBot(guid);
        itr = SoloArenaLoadoutRecoveryBots.erase(itr);
    }
}

bool HandleSoloArenaAutomaticJoinRequest(Player* player, uint8 arenaSlot)
{
    if (!sPlayerbotAIConfig->autoQueueArenaAutomatic || !player)
        return false;

    if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(player))
        if (!botAI->IsRealPlayer())
            return false;

    uint8 arenaType = 0;
    switch (arenaSlot)
    {
        case PVP_SLOT_ARENA_2v2: arenaType = ARENA_TYPE_2v2; break;
        case PVP_SLOT_ARENA_3v3: arenaType = ARENA_TYPE_3v3; break;
        case PVP_SLOT_ARENA_5v5: arenaType = ARENA_TYPE_5v5; break;
        default: return false;
    }

    if (!sPlayerbotAIConfig->autoQueueEnabled || !sPlayerbotAIConfig->autoQueueArena ||
        !sPlayerbotAIConfig->autoQueueDryRun ||
        !sPlayerbotAIConfig->autoQueueArenaStageLogin ||
        !sPlayerbotAIConfig->autoQueueArenaStageGroup ||
        !sPlayerbotAIConfig->autoQueueArenaStageQueue ||
        !sPlayerbotAIConfig->autoQueueArenaStageMatch ||
        !sPlayerbotAIConfig->autoQueueArenaStageEnter ||
        !sPlayerbotAIConfig->autoQueueArenaStageHealthRestore ||
        !sPlayerbotAIConfig->autoQueueArenaStageAutomaticExit)
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "Automatic Solo Arena is enabled but its verified safety stages are not all enabled.");
        return true;
    }

    if (SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Idle ||
        !SoloArenaStagedBots.empty() || SoloArenaRequesterGroup || SoloArenaOpponentGroup ||
        SoloArenaQueuesStaged || SoloArenaEnteredInstance)
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "Another Solo Arena preparation or cleanup is already active. Please try again shortly.");
        return true;
    }

    if (GetSoloArenaLoadoutBackupCount())
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "Automatic Solo Arena is blocked by protected loadout recovery rows.");
        return true;
    }

    if (player->GetLevel() != DEFAULT_MAX_LEVEL || player->GetGroup() ||
        player->InBattleground() || player->InBattlegroundQueue() ||
        sLFGMgr->GetActiveState(player->GetGUID()) != lfg::LFG_STATE_NONE)
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "Leave your current group, battleground and queue before joining automatic Solo Arena %uv%u.",
            uint32(arenaType), uint32(arenaType));
        return true;
    }

    SoloArenaAutomaticTeamSize = arenaType;
    SoloArenaAutomaticQueueType = GetSoloArenaQueueType(arenaType);
    SoloArenaAutomaticRequester = player->GetGUID().GetCounter();
    SoloArenaAutomaticElapsed = 0;
    SoloArenaAutomaticUpdateTimer = 0;
    SoloArenaAutomaticCleanupReason.clear();
    SoloArenaAutomaticRewardProcessed = false;
    SetSoloArenaAutomaticState(SoloArenaAutomaticState::Login);
    ChatHandler(player->GetSession()).PSendSysMessage(
        "Automatic Solo Arena %uv%u accepted. Selecting and preparing %u bots...",
        uint32(arenaType), uint32(arenaType), uint32(arenaType * 2 - 1));
    TC_LOG_INFO("server", "SoloArena automatic %uv%u request accepted name=%s guid=%u arena=%s",
        uint32(arenaType), uint32(arenaType), player->GetName().c_str(), SoloArenaAutomaticRequester,
        sPlayerbotAIConfig->autoQueueArenaAutomaticForceTolviron ? "Tol'viron" : "random");
    return true;
}

void UpdateSoloArenaAutomaticQueue(uint32 diff)
{
    if (SoloArenaAutomaticQueueState == SoloArenaAutomaticState::Idle)
        return;

    SoloArenaAutomaticElapsed += diff;
    if (SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Active &&
        SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Cleanup &&
        SoloArenaAutomaticElapsed > sPlayerbotAIConfig->autoQueueArenaAutomaticTimeout)
    {
        BeginSoloArenaAutomaticCleanup("preparation timeout");
    }

    if (SoloArenaAutomaticUpdateTimer > diff)
    {
        SoloArenaAutomaticUpdateTimer -= diff;
        return;
    }
    SoloArenaAutomaticUpdateTimer = 500;

    Player* requester = GetSoloArenaAutomaticRequester();
    if (!requester || !requester->GetSession())
    {
        if (SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Cleanup)
            BeginSoloArenaAutomaticCleanup("requester disconnected");
        if (SoloArenaAutomaticQueueState != SoloArenaAutomaticState::Cleanup)
            return;
    }

    std::vector<Player*> participants;
    std::string error;
    switch (SoloArenaAutomaticQueueState)
    {
        case SoloArenaAutomaticState::Login:
            if (StageSoloArenaAutomaticBots(requester, error) &&
                SoloArenaStagedRequester == SoloArenaAutomaticRequester &&
                SoloArenaStagedBots.size() == size_t(SoloArenaAutomaticTeamSize * 2 - 1))
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::WaitForBots);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ?
                    "candidate selection or login request failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::WaitForBots:
            if (GetSoloArenaAutomaticLoadoutReadyParticipants(participants, error) &&
                participants.size() == size_t(SoloArenaAutomaticTeamSize * 2))
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::ApplyLoadout);
            break;
        case SoloArenaAutomaticState::ApplyLoadout:
            if (ApplySoloArenaAutomaticLoadouts(error) &&
                GetSoloArenaAutomaticParticipants(participants) &&
                std::all_of(participants.begin(), participants.end(), [](Player* participant)
                {
                    return participant &&
                        (participant->GetGUID().GetCounter() == SoloArenaStagedRequester ||
                         HasExpectedSoloArenaLoadout(participant));
                }))
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Group);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ?
                    "temporary PvP loadout verification failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::Group:
            if (CreateSoloArenaAutomaticGroups(error) &&
                SoloArenaRequesterGroup && SoloArenaOpponentGroup)
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Queue);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ? "group creation failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::Queue:
            if (QueueSoloArenaAutomaticGroups(error) && SoloArenaQueuesStaged)
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Match);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ? "Arena queue creation failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::Match:
            if (ScheduleSoloArenaAutomaticMatch(
                sPlayerbotAIConfig->autoQueueArenaAutomaticForceTolviron, error) &&
                SoloArenaMatchScheduled)
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::WaitForInvite);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ?
                    "matchmaking schedule failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::WaitForInvite:
        {
            uint32 invite = 0;
            if (GetSoloArenaAutomaticSharedInvite(invite))
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Enter);
            break;
        }
        case SoloArenaAutomaticState::Enter:
            if (EnterSoloArenaAutomaticMatch(error) && SoloArenaEnteredInstance)
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::WaitForEntry);
            else
                BeginSoloArenaAutomaticCleanup(error.empty() ?
                    "shared Arena invitation acceptance failed" : error.c_str());
            break;
        case SoloArenaAutomaticState::WaitForEntry:
            if (GetSoloArenaAutomaticParticipants(participants) &&
                std::all_of(participants.begin(), participants.end(),
                    [](Player* participant)
                    {
                        return participant->GetBattlegroundId() == SoloArenaEnteredInstance &&
                            !participant->IsBeingTeleported();
                    }))
            {
                Battleground* arena = sBattlegroundMgr->GetBattleground(
                    SoloArenaEnteredInstance, BATTLEGROUND_TYPE_NONE);
                if (!arena || arena->GetStatus() != STATUS_WAIT_JOIN)
                {
                    BeginSoloArenaAutomaticCleanup(
                        "Arena left preparation before participant setup");
                    break;
                }
                PrepareSoloArenaAutomaticParticipants(arena, participants);
                ChatHandler(requester->GetSession()).SendSysMessage(
                    "Automatic Solo Arena is ready. Wait for the gates, then fight normally.");
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Active);
            }
            break;
        case SoloArenaAutomaticState::Active:
            if (SoloArenaEnteredInstance)
            {
                Battleground* arena = sBattlegroundMgr->GetBattleground(
                    SoloArenaEnteredInstance, BATTLEGROUND_TYPE_NONE);
                if (arena && arena->GetStatus() == STATUS_WAIT_JOIN &&
                    GetSoloArenaAutomaticParticipants(participants))
                    CastSoloArenaAutomaticPreparationBuffs(arena, participants);
                else if (arena && arena->GetStatus() == STATUS_IN_PROGRESS &&
                    GetSoloArenaAutomaticParticipants(participants))
                {
                    FinishSoloArenaAutomaticPreparationBuffs();
                    ActivateSoloArenaAutomaticCombat(arena, participants);
                }
                else if (!SoloArenaAutomaticPreparationBuffedBots.empty())
                    FinishSoloArenaAutomaticPreparationBuffs();
            }
            if (!SoloArenaEnteredInstance)
                SetSoloArenaAutomaticState(SoloArenaAutomaticState::Cleanup);
            break;
        case SoloArenaAutomaticState::Cleanup:
            if (CleanupSoloArenaAutomaticStep())
                ResetSoloArenaAutomaticState();
            break;
        case SoloArenaAutomaticState::Idle:
            break;
    }
}

void AddSC_playerbots_commandscript()
{
    new playerbots_commandscript();
    RegisterCreatureAI(npc_world_boss_bot_caller);
}
