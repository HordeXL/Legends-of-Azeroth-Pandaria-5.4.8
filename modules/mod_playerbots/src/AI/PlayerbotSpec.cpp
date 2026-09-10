#include "PlayerbotSpec.h"

#include "AiFactory.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "Player.h"
#include "GroupPveCombat.h"
#include "PvePullState.h"
#include "ObjectAccessor.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "ThreatManager.h"
#include <map>
#include <mutex>
#include <tuple>

namespace
{
Group* GetActiveGroup(Player* player)
{
    Group* group = player ? player->GetGroup(GroupSlot::Instance) : nullptr;
    return group ? group : (player ? player->GetGroup() : nullptr);
}
}

unsigned int PlayerBotSpec::GetSpectab(Player* player)
{
    const Specializations& spec = player->GetSpecialization();
    switch (spec)
    {
        case SPEC_HUNTER_BEAST_MASTERY:
        case SPEC_DEATH_KNIGHT_BLOOD:
        case SPEC_DRUID_BALANCE:
        case SPEC_WARRIOR_ARMS:
        case SPEC_PALADIN_HOLY:
        case SPEC_MAGE_ARCANE:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_SHAMAN_ELEMENTAL:
        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_MONK_BREWMASTER:
        {
            return static_cast<unsigned int>(0);
        }

        case SPEC_HUNTER_MARKSMANSHIP:
        case SPEC_DEATH_KNIGHT_FROST:
        case SPEC_DRUID_FERAL:
        case SPEC_WARRIOR_FURY:
        case SPEC_PALADIN_PROTECTION:
        case SPEC_MAGE_FIRE:
        case SPEC_PRIEST_HOLY:
        case SPEC_ROGUE_COMBAT:
        case SPEC_SHAMAN_ENHANCEMENT:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_MONK_WINDWALKER:
        {
            return static_cast<unsigned int>(1);
        }

        case SPEC_HUNTER_SURVIVAL:
        case SPEC_DEATH_KNIGHT_UNHOLY:
        case SPEC_DRUID_GUARDIAN:
        case SPEC_WARRIOR_PROTECTION:
        case SPEC_PALADIN_RETRIBUTION:
        case SPEC_MAGE_FROST:
        case SPEC_PRIEST_SHADOW:
        case SPEC_ROGUE_SUBTLETY:
        case SPEC_SHAMAN_RESTORATION:
        case SPEC_WARLOCK_DESTRUCTION:
        case SPEC_MONK_MISTWEAVER:
        {
            return static_cast<unsigned int>(2);
        }
        case SPEC_DRUID_RESTORATION:
        {
            return static_cast<unsigned int>(3);
        }
    }
    return 99;
}

bool PlayerBotSpec::IsRanged(Player* player, bool bySpec)
{
    PlayerbotAI* botAi = GET_PLAYERBOT_AI(player);
    if (!bySpec && botAi)
        return botAi->ContainsStrategy(STRATEGY_TYPE_RANGED);

    const Specializations& spec = player->GetSpecialization();
    switch (player->GetClass())
    {
        case CLASS_DEATH_KNIGHT:
        case CLASS_WARRIOR:
        case CLASS_ROGUE:
        case CLASS_MONK:
        {
            return spec == Specializations::SPEC_MONK_MISTWEAVER;
        }
        case CLASS_DRUID:
        {
            if (spec == Specializations::SPEC_DRUID_FERAL || spec == Specializations::SPEC_DRUID_GUARDIAN)
            {
                return false;
            }
            break;
        }
        case CLASS_PALADIN:
        {
            if (spec != Specializations::SPEC_PALADIN_HOLY)
            {
                return false;
            }
            break;
        }
        case CLASS_SHAMAN:
        {
            if (spec == Specializations::SPEC_SHAMAN_ENHANCEMENT)
            {
                return false;
            }
            break;
        }
    }
    return true;
}

bool PlayerBotSpec::IsMelee(Player* player, bool bySpec)
{
    return !IsRanged(player, bySpec);
}

bool PlayerBotSpec::IsCaster(Player* player, bool bySpec)
{
    return IsRanged(player, bySpec) && player->GetClass() != CLASS_HUNTER;
}

bool PlayerBotSpec::IsCombo(Player* player, bool bySpec)
{
    // int tab = AiFactory::GetPlayerSpecTab(player);
    return player->GetClass() == CLASS_ROGUE ||
        (player->GetClass() == CLASS_DRUID && player->HasAura(768));  // cat druid
}

bool PlayerBotSpec::IsRangedDps(Player* player, bool bySpec)
{
    return IsRanged(player, bySpec) && IsDps(player, bySpec);
}

bool PlayerBotSpec::IsTank(Player* player, bool bySpec)
{
    PlayerbotAI* botAi = GET_PLAYERBOT_AI(player);
    if (!bySpec && botAi)
        return botAi->ContainsStrategy(STRATEGY_TYPE_TANK);

    if (player->GetSpecialization() == Specializations::SPEC_PALADIN_PROTECTION ||
        player->GetSpecialization() == Specializations::SPEC_WARRIOR_PROTECTION ||
        player->GetSpecialization() == Specializations::SPEC_MONK_BREWMASTER ||
        player->GetSpecialization() == Specializations::SPEC_DRUID_GUARDIAN ||
        player->GetSpecialization() == Specializations::SPEC_DEATH_KNIGHT_BLOOD)
        return true;
    return false;
}

bool PlayerBotSpec::IsHeal(Player* player, bool bySpec)
{
    PlayerbotAI* botAi = GET_PLAYERBOT_AI(player);
    if (!bySpec && botAi)
        return botAi->ContainsStrategy(STRATEGY_TYPE_HEAL);

    if (player->GetSpecialization() == Specializations::SPEC_PALADIN_HOLY ||
        player->GetSpecialization() == Specializations::SPEC_PRIEST_DISCIPLINE||
        player->GetSpecialization() == Specializations::SPEC_PRIEST_HOLY ||
        player->GetSpecialization() == Specializations::SPEC_DRUID_RESTORATION ||
        player->GetSpecialization() == Specializations::SPEC_SHAMAN_RESTORATION ||
        player->GetSpecialization() == Specializations::SPEC_MONK_MISTWEAVER)
        return true;

    return false;
}

bool PlayerBotSpec::IsDps(Player* player, bool bySpec)
{
    PlayerbotAI* botAi = GET_PLAYERBOT_AI(player);
    if (!bySpec && botAi)
        return botAi->ContainsStrategy(STRATEGY_TYPE_DPS);

    return !IsTank(player, bySpec) && !IsHeal(player, bySpec);
}

uint32 PlayerBotSpec::GetGroupTankNum(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group)
    {
        return 0;
    }
    uint32 result = 0;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (IsTank(member) && member->IsAlive())
        {
            result++;
        }
    }
    return result;
}

Player* PlayerBotSpec::GetDiamondMarkedTank(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group || player->InBattleground() || player->InArena())
        return nullptr;

    ObjectGuid const markedGuid = group->GetTargetIcon(2); // Purple diamond.
    if (markedGuid.IsEmpty())
        return nullptr;

    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (member && member->GetGUID() == markedGuid && member->IsInWorld() &&
            member->GetMap() == player->GetMap() && IsTank(member, true))
            return member;
    }
    return nullptr;
}

bool PlayerBotSpec::IsMainTank(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group)
    {
        return false;
    }
    if (Player* markedTank = GetDiamondMarkedTank(player))
        if (markedTank->IsAlive())
            return markedTank == player;

    ObjectGuid mainTank = ObjectGuid();
    Group::MemberSlotList const& slots = group->GetMemberSlots();
    for (Group::member_citerator itr = slots.begin(); itr != slots.end(); ++itr)
    {
        if (itr->flags & MEMBER_FLAG_MAINTANK)
        {
            mainTank = itr->guid;
            break;
        }
    }
    if (mainTank != ObjectGuid::Empty)
    {
        return player->GetGUID() == mainTank;
    }
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (IsTank(member) && member->IsAlive())
        {
            return player->GetGUID() == member->GetGUID();
        }
    }
    return false;
}
bool PlayerBotSpec::IsAssistTank(Player* player) { return IsTank(player) && !IsMainTank(player); }

bool PlayerBotSpec::IsAssistTankOfIndex(Player* bot, Player* player, int index)
{
    Group* group = GetActiveGroup(bot);
    if (!group)
    {
        return false;
    }
    Group::MemberSlotList const& slots = group->GetMemberSlots();
    int counter = 0;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (group->IsAssistant(member->GetGUID()) && IsAssistTank(member))
        {
            if (index == counter)
            {
                return player == member;
            }
            counter++;
        }
    }
    // not enough
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!group->IsAssistant(member->GetGUID()) && IsAssistTank(member))
        {
            if (index == counter)
            {
                return player == member;
            }
            counter++;
        }
    }
    return false;
}

Player* PlayerBotSpec::GetGroupPvePullTank(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group || player->InBattleground() || player->InArena()) return nullptr;
    // Keep a dead designated tank as the anchor: callers allow emergency
    // takeover, then restore ownership when that player is resurrected.
    if (Player* marked = GetDiamondMarkedTank(player)) return marked;
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(player))
        if (Player* master = ai->GetMaster())
            if (group->IsMember(master->GetGUID()) && master->IsInWorld() &&
                master->GetMap() == player->GetMap() && IsTank(master, true) &&
                (!GET_PLAYERBOT_AI(master) || GET_PLAYERBOT_AI(master)->IsRealPlayer()))
                return master;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->GetGUID() == group->GetLeaderGUID() && member->IsInWorld() &&
                member->GetMap() == player->GetMap() && IsTank(member, true))
                return member;
    Player* fallback = nullptr;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->IsAlive() && member->IsInWorld() && member->GetMap() == player->GetMap() &&
                IsTank(member, true) && (!fallback || member->GetGUID() < fallback->GetGUID()))
                fallback = member;
    return fallback;
}

bool GroupPveCombat::IsEngaged(Player* player, Unit* target)
{
    Group* group = GetActiveGroup(player);
    if (!player || !group || !target || !target->IsAlive() || !target->IsInWorld() ||
        target->GetMap() != player->GetMap() || !target->IsInCombat() ||
        !player->IsValidAttackTarget(target)) return false;
    Unit* victim = target->GetVictim();
    Player* owner = victim ? victim->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    if (owner && group->IsMember(owner->GetGUID())) return true;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->IsAlive() && member->IsInWorld() && member->GetMap() == player->GetMap() &&
                (member->GetVictim() == target || (target->CanHaveThreatList() &&
                    target->GetThreatManager().getThreat(member) > 0.0f))) return true;
    return false;
}

bool GroupPveCombat::IsCollected(Player* player, Unit* target)
{
    Group* group = GetActiveGroup(player);
    if (!group || !target) return false;
    bool hasTank = false;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* tank = ref->GetSource())
            if (tank->IsAlive() && tank->IsInWorld() && tank->GetMap() == player->GetMap() &&
                PlayerBotSpec::IsTank(tank, true))
            {
                hasTank = true;
                if (tank->GetDistance(target) <= 8.0f) return true;
            }
    return !hasTank;
}

namespace
{
PvePullState<ObjectGuid> ObserveGroupPull(Player* player)
{
    Group* group = GetActiveGroup(player);
    if (!group || !player->IsInWorld() || player->InBattleground() || player->InArena()) return {};
    std::vector<ObjectGuid> engaged;
    auto add = [&](Unit* unit)
    {
        if (GroupPveCombat::IsEngaged(player, unit) &&
            std::find(engaged.begin(), engaged.end(), unit->GetGUID()) == engaged.end())
            engaged.push_back(unit->GetGUID());
    };
    if (Player* tank = PlayerBotSpec::GetGroupPvePullTank(player)) add(tank->GetVictim());
    // Actual victim / positive threat is required; selecting an idle mob cannot pull.
    // Collect from the whole group, so observers and changing targets share one clock.
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->IsAlive() && member->IsInWorld() && member->GetMap() == player->GetMap())
            {
                add(member->GetVictim());
                add(member->GetSelectedUnit());
                for (Unit* attacker : member->getAttackers()) add(attacker);
            }
    struct Record { PvePullState<ObjectGuid> state; uint32 seen = 0; };
    using Key = std::tuple<ObjectGuid, uint32, uint32>;
    static std::map<Key, Record> records;
    static std::mutex mutex;
    std::lock_guard<std::mutex> guard(mutex);
    uint32 now = getMSTime();
    for (auto it = records.begin(); it != records.end();)
        if (uint32(now - it->second.seen) > 60000u) it = records.erase(it); else ++it;
    auto& record = records[Key(group->GetGUID(), player->GetMapId(), player->GetInstanceId())];
    record.seen = now;
    if (player->HasWorldBossStagingAccess() && !engaged.empty())
        player->NoteWorldBossStagingFirstContact(now);
    uint32 firstContact = player->HasWorldBossStagingAccess() ?
        player->GetWorldBossStagingFirstContact() : 0;
    record.state.Observe(now, engaged, firstContact);
    return record.state;
}
}

Unit* GroupPveCombat::OpeningTarget(Player* player)
{
    if (!player) return nullptr;
    ObjectGuid guid = ObserveGroupPull(player).OpeningTarget(getMSTime());
    return guid ? ObjectAccessor::GetUnit(*player, guid) : nullptr;
}

Unit* GroupPveCombat::ActiveWorldBossTarget(Player* player)
{
    if (!player || !player->HasWorldBossStagingAccess() ||
        player->IsWorldBossStagingCleanup())
        return nullptr;

    Group* group = GetActiveGroup(player);
    if (!group || !player->IsInWorld())
        return nullptr;

    auto isSupportedWorldBoss = [](Unit* target)
    {
        if (!target)
            return false;

        switch (target->GetEntry())
        {
            case 56439: // Sha of Anger alternate entry
            case 60491: // Sha of Anger
            case 62346: // Galleon
            case 69099: // Nalak
            case 69161: // Oondasta
            case 71952: // Chi-Ji
            case 71953: // Xuen
            case 71954: // Niuzao
            case 71955: // Yu'lon
            case 72057: // Ordos
                return true;
            default:
                return false;
        }
    };
    auto engagedBoss = [&](Unit* target) -> Unit*
    {
        return isSupportedWorldBoss(target) && IsEngaged(player, target) ?
            target : nullptr;
    };

    // Prefer the marked tank's victim so a scripted temporary boss target
    // cannot make different raid members select different enemies.
    if (Player* tank = PlayerBotSpec::GetGroupPvePullTank(player))
        if (Unit* target = engagedBoss(tank->GetVictim()))
            return target;

    // The real player may start the pull before the bot tank has reached the
    // boss. Every staged bot observes that same group combat relation and can
    // therefore join immediately instead of relying on a short opening timer.
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || !member->IsAlive() || !member->IsInWorld() ||
            member->GetMap() != player->GetMap())
            continue;

        if (Unit* target = engagedBoss(member->GetVictim()))
            return target;
        for (Unit* attacker : member->getAttackers())
            if (Unit* target = engagedBoss(attacker))
                return target;
    }

    return nullptr;
}

bool GroupPveCombat::AoeReady(Player* player, Unit* target)
{
    return IsEngaged(player, target) &&
        (PlayerBotSpec::IsTank(player, true) ||
            (ObserveGroupPull(player).Ready(getMSTime()) && IsCollected(player, target)));
}

bool GroupPveCombat::DamageAllowed(Player* player, Unit* target)
{
    if (!IsEngaged(player, target)) return false;
    if (PlayerBotSpec::IsTank(player, true)) return true;
    Unit* opening = OpeningTarget(player);

    // A staged raid uses the opening window to leave the compact follow
    // stack and take its encounter slots.  Selecting the opening target is
    // not enough: direct class rotations can cast without first issuing an
    // AttackAction, so explicitly suppress their damage until that window
    // has elapsed.  Tanks remain free to establish and turn the boss, while
    // healer casts on friendly targets never enter this hostile-target path.
    if (player->HasWorldBossStagingAccess() && opening)
        return false;

    return !opening || opening == target;
}

bool GroupPveCombat::NeedsRescue(Player* player, Unit* target)
{
    if (!IsEngaged(player, target) || !target->CanHaveThreatList() ||
        target->HasBreakableByDamageCrowdControlAura()) return false;
    // A successful taunt changes the attack victim before the threat manager
    // necessarily refreshes its cached reference. Do not send a second taunt.
    Unit* attacking = target->GetVictim();
    Player* attackingOwner = attacking ? attacking->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    if (attackingOwner && attackingOwner->IsAlive() &&
        GetActiveGroup(player)->IsMember(attackingOwner->GetGUID()) &&
        PlayerBotSpec::IsTank(attackingOwner, true)) return false;
    // Threat victim, not the temporary target of a scripted boss ability.
    HostileReference* reference = target->GetThreatManager().getCurrentVictim();
    Unit* victim = reference ? reference->getTarget() : target->GetVictim();
    Player* owner = victim ? victim->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    Group* group = GetActiveGroup(player);
    return owner && owner->IsAlive() && group->IsMember(owner->GetGUID()) &&
        !PlayerBotSpec::IsTank(owner, true);
}

unsigned GroupPveCombat::TauntSpell(Player* player)
{
    switch (player->GetClass())
    {
        case CLASS_WARRIOR: return 355;
        case CLASS_PALADIN: return 62124;
        case CLASS_DRUID: return 6795;
        case CLASS_DEATH_KNIGHT: return 56222;
        case CLASS_MONK: return 115546;
        default: return 0;
    }
}

Player* GroupPveCombat::RescueTank(Player* player, Unit* target)
{
    if (!NeedsRescue(player, target)) return nullptr;
    Player* best = nullptr;
    for (GroupReference* ref = GetActiveGroup(player)->GetFirstMember(); ref; ref = ref->next())
    {
        Player* tank = ref->GetSource();
        PlayerbotAI* ai = tank ? GET_PLAYERBOT_AI(tank) : nullptr;
        if (!tank || !tank->IsAlive() || !tank->IsInWorld() || tank->GetMap() != player->GetMap() ||
            !PlayerBotSpec::IsTank(tank, true) || tank->HasUnitState(UNIT_STATE_LOST_CONTROL) ||
            (tank != player && (!ai || ai->IsRealPlayer()))) continue;
        uint32 id = TauntSpell(tank);
        SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
        if (!info || !tank->HasSpell(id) || tank->HasSpellCooldown(id) ||
            target->IsImmunedToSpell(info, info->NegativeEffectMask)) continue;
        Spell probe(tank, info, TRIGGERED_NONE);
        if (!probe.CanAutoCast(target)) continue;
        if (!best || std::make_pair(tank->GetDistance(target), tank->GetGUID()) <
            std::make_pair(best->GetDistance(target), best->GetGUID())) best = tank;
    }
    return best;
}
