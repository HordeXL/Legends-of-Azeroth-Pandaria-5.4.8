/*
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#include "CombatAssistant.h"
#include "AfflictionAssistantPolicy.h"
#include "GroupPveCombat.h"

#include "Chat.h"
#include "Group.h"
#include "Map.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "ThreatManager.h"
#include "WorldSession.h"
#include "DynamicObject.h"
#include "Timer.h"

#include <list>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

#pragma execution_character_set("UTF-8")

namespace
{
char const* CombatAssistantAddonPrefix = "CA548";

enum CombatAssistantPaladinSpells : uint32
{
    SPELL_DIVINE_SHIELD       = 642,
    SPELL_EXORCISM            = 879,
    SPELL_DIVINE_PROTECTION   = 498,
    SPELL_HAND_OF_FREEDOM     = 1044,
    SPELL_HAND_OF_PROTECTION  = 1022,
    SPELL_CLEANSE             = 4987,
    SPELL_SACRED_SHIELD       = 20925,
    SPELL_FLASH_OF_LIGHT      = 19750,
    SPELL_JUDGMENT            = 20271,
    SPELL_HAMMER_OF_WRATH     = 24275,
    SPELL_CRUSADER_STRIKE     = 35395,
    SPELL_DIVINE_STORM        = 53385,
    SPELL_EVERY_MAN_FOR_HIMSELF = 59752,
    SPELL_ART_OF_WAR          = 59578,
    SPELL_INQUISITION         = 84963,
    SPELL_TEMPLARS_VERDICT    = 85256,
    SPELL_WORD_OF_GLORY       = 85673,
    SPELL_DIVINE_PURPOSE      = 90174,
    SPELL_REBUKE              = 96231,
    SPELL_EXECUTION_SENTENCE  = 114157,
    SPELL_HAND_OF_PURITY      = 114039,
    SPELL_ETERNAL_FLAME       = 114163,
    SPELL_SELFLESS_HEALER     = 114250,
    SPELL_SELFLESS_HEALER_UI  = 128863,
    SPELL_DIVINE_CRUSADER     = 144595
};

struct CombatRecommendation
{
    uint32 SpellId = 0;
    Unit* Target = nullptr;
    char const* Reason = "WAIT";

    explicit operator bool() const { return SpellId && Target; }
};

struct CombatAoeState
{
    uint32 EnemyCount = 0;
    bool UseAoe = false;
};

struct CombatAssistantPlayerState : AfflictionRotationRuntime
{
    uint32 UpdateTimer = 0;
    std::string LastPayload;
};

std::unordered_map<uint32, CombatAssistantPlayerState> CombatAssistantStates;

bool UsesAfflictionAssistant(Player* player)
{
    return player->GetClass() == CLASS_WARLOCK &&
        player->GetTalentSpecialization() == SPEC_WARLOCK_AFFLICTION &&
        !player->InBattleground() && !player->InArena();
}

bool IsAfflictionProtectedAlly(Player* player, Unit* target);

Spell* PrepareCheckedSpell(Player* player, uint32 spellId, Unit* target, bool cast,
    AfflictionRotationRuntime* runtime = nullptr, PlayerbotAI* botAI = nullptr, bool* started = nullptr)
{
    if (!player || !target)
        return nullptr;

    uint32 knownRank = 0;
    uint32 nextRank = 0;
    if (player->HasSpell(spellId))
    {
        knownRank = spellId;
        nextRank = sSpellMgr->GetNextSpellInChain(spellId);
    }
    else
        nextRank = sSpellMgr->GetFirstSpellInChain(spellId);

    while (nextRank && player->HasSpell(nextRank))
    {
        knownRank = nextRank;
        nextRank = sSpellMgr->GetNextSpellInChain(knownRank);
    }

    if (!knownRank)
        return nullptr;

    bool const affliction = UsesAfflictionAssistant(player);
    if (affliction && spellId == AfflictionAssistant::UnendingResolve && player->HasAura(148683))
        return nullptr; // Eternal Resolve replaces the active button with a passive effect.
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(knownRank);
    if (affliction && spellInfo)
    {
        // Match the client's action-bar override path. Soulburn variants are
        // granted by an active aura, not necessarily learned in the spell book.
        Unit::AuraEffectList swaps = player->GetAuraEffectsByType(SPELL_AURA_OVERRIDE_ACTIONBAR_SPELLS);
        Unit::AuraEffectList const& swaps2 = player->GetAuraEffectsByType(SPELL_AURA_OVERRIDE_ACTIONBAR_SPELLS_2);
        swaps.insert(swaps.end(), swaps2.begin(), swaps2.end());
        for (AuraEffect const* effect : swaps)
            if (effect->IsAffectingSpell(spellInfo))
                if (SpellInfo const* replacement = sSpellMgr->GetSpellInfo(effect->GetAmount()))
                { spellInfo = replacement; break; }
        // Never turn an intended instant DoT application into normal inhale.
        if (spellId == AfflictionAssistant::SoulSwap &&
            (!player->HasAura(AfflictionAssistant::Soulburn) ||
             spellInfo->Id != AfflictionAssistant::SoulburnSwap)) return nullptr;
        if (spellId == AfflictionAssistant::Seed && player->HasAura(AfflictionAssistant::Soulburn) &&
            player->HasSpell(86664) && spellInfo->Id != AfflictionAssistant::SoulburnSeed) return nullptr;
    }
    if (!spellInfo || player->GetGlobalCooldownMgr().HasGlobalCooldown(spellInfo))
        return nullptr;

    // The shared player cast path does not go through PlayerbotAI::CastSpell.
    // Reapply bot engagement and area guards here, after resolving overrides,
    // both for recommendation probes and immediately before the actual cast.
    if (botAI)
    {
        if (player->HasUnitState(UNIT_STATE_LOST_CONTROL | UNIT_STATE_IN_FLIGHT) ||
            player->IsFlying() || botAI->IsInVehicle()) return nullptr;
        if (target != player && player->IsValidAttackTarget(target) &&
            (IsAfflictionProtectedAlly(player, target) || target->HasBreakableByDamageCrowdControlAura() ||
             !botAI->CanLfgAutoQueueEngage(target) || !GroupPveCombat::DamageAllowed(player, target)))
            return nullptr;
        if (!botAI->IsGroupPveOpeningSpellAllowed(spellInfo, target) ||
            !botAI->IsGroupPveAreaSpellSafe(spellInfo, target)) return nullptr;
    }

    Spell* channel = affliction ? player->GetCurrentSpell(CURRENT_CHANNELED_SPELL) : nullptr;
    bool const damageChannel = channel && (channel->GetSpellInfo()->Id == AfflictionAssistant::MaleficGrasp ||
        channel->GetSpellInfo()->Id == AfflictionAssistant::DrainSoul);
    if (cast && damageChannel)
    {
        if (channel->GetSpellInfo()->Id == spellInfo->Id && channel->m_targets.GetUnitTarget() == target)
            return nullptr;
        // Validate before interrupting; range, mana, GCD and cooldown failures
        // must leave the current channel intact. Actual casts remain untriggered.
        Spell* probe = PrepareCheckedSpell(player, spellId, target, false, runtime, botAI);
        if (!probe) return nullptr;
        delete probe;
        player->InterruptSpell(CURRENT_CHANNELED_SPELL);
        return PrepareCheckedSpell(player, spellId, target, true, runtime, botAI, started);
    }
    Spell* spell = new Spell(player, spellInfo,
        !cast && damageChannel ? TRIGGERED_IGNORE_CAST_IN_PROGRESS : TRIGGERED_NONE);
    if (affliction && player->isMoving() &&
        (spellInfo->IsChanneled() || spellInfo->CalcCastTime(player->GetLevel(), spell)) &&
        (spellInfo->InterruptFlags & SPELL_INTERRUPT_FLAG_MOVEMENT) &&
        !player->HasAuraTypeWithAffectMask(SPELL_AURA_CAST_WHILE_WALKING, spellInfo))
    { delete spell; return nullptr; }
    // Pet autocast deliberately rejects existing auras (even another caster's).
    // A player DoT refresh needs normal cast checks without that pet-only filter.
    bool const usable = affliction ? spell->CheckPetCast(target) == SPELL_CAST_OK : spell->CanAutoCast(target);
    if (!usable)
    {
        delete spell;
        return nullptr;
    }

    if (cast)
    {
        if (affliction && spellId == AfflictionAssistant::Haunt)
        {
            AfflictionRotationRuntime& state = runtime ? *runtime : CombatAssistantStates[player->GetGUID().GetCounter()];
            state.HauntTarget = target->GetGUID();
            state.HauntPendingTimer = spellInfo->CalcCastTime(player->GetLevel(), spell) + 500;
            if (spellInfo->Speed > 0)
                state.HauntPendingTimer += uint32(1000 * player->GetDistance(target) / spellInfo->Speed);
        }
        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        if (spellInfo->ExplicitTargetMask & TARGET_FLAG_DEST_LOCATION)
            targets.SetDst(*target);
        if (started) *started = true;
        spell->prepare(&targets);
        return nullptr;
    }

    return spell;
}

bool CanCast(Player* player, uint32 spellId, Unit* target, PlayerbotAI* botAI = nullptr)
{
    Spell* spell = PrepareCheckedSpell(player, spellId, target, false, nullptr, botAI);
    if (!spell)
        return false;

    delete spell;
    return true;
}

Group* GetCombatAssistantGroup(Player* player)
{
    if (!player)
        return nullptr;

    Group* group = player->GetGroup(GroupSlot::Instance);
    return group ? group : player->GetGroup();
}

bool IsEngagedWithPlayerOrGroup(Player* player, Unit* hostile, Group* group)
{
    if (!player || !hostile || !hostile->IsAlive() || !hostile->IsInCombat() ||
        !player->IsValidAttackTarget(hostile))
        return false;

    Unit* victim = hostile->GetVictim();
    Player* victimPlayer = victim ?
        victim->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    if (!victimPlayer || !victimPlayer->IsAlive() ||
        victimPlayer->GetMap() != player->GetMap())
        return false;

    return group ? group->IsMember(victimPlayer->GetGUID()) : victimPlayer == player;
}

CombatAoeState GetCombatAoeState(Player* player, Unit* selectedTarget)
{
    CombatAoeState state;
    if (!player || !selectedTarget || !player->IsValidAttackTarget(selectedTarget))
        return state;

    Group* group = GetCombatAssistantGroup(player);
    bool const playerIsTank = PlayerBotSpec::IsTank(player, true);
    bool const groupPve = group && player->GetMap() &&
        (player->GetMap()->IsDungeon() || player->GetMap()->IsRaid());

    bool hasLivingTank = false;
    if (groupPve && !playerIsTank)
    {
        for (GroupReference* reference = group->GetFirstMember(); reference;
             reference = reference->next())
        {
            Player* member = reference->GetSource();
            if (member && member->IsAlive() && member->GetMap() == player->GetMap() &&
                PlayerBotSpec::IsTank(member, true))
            {
                hasLivingTank = true;
                break;
            }
        }
    }

    bool packCollected = true;
    std::list<Unit*> nearbyHostiles;
    // A ranged target can be roughly 40 yards away and its pack can extend
    // another eight yards. Scan from the player, then cluster around the
    // selected target so unrelated packs never enable the AoE rotation.
    player->GetAttackableUnitListInRange(nearbyHostiles, 55.0f);
    for (Unit* hostile : nearbyHostiles)
    {
        if (!IsEngagedWithPlayerOrGroup(player, hostile, group) ||
            hostile->GetDistance(selectedTarget) > 8.0f)
            continue;

        ++state.EnemyCount;
        if (groupPve && !playerIsTank && hasLivingTank)
        {
            if (!GroupPveCombat::IsCollected(player, hostile)) packCollected = false;
        }
    }

    // Tanks start consolidating threat at two clustered enemies. Damage
    // specializations switch at three after the shared opening and collection.
    uint32 const threshold = playerIsTank ? 2u : 3u;
    state.UseAoe = state.EnemyCount >= threshold &&
        (!groupPve || playerIsTank || !hasLivingTank ||
            (packCollected && GroupPveCombat::AoeReady(player, selectedTarget)));
    return state;
}

bool HasHardLossOfControl(Player* player)
{
    uint32 const mechanicMask = (1 << MECHANIC_CHARM) | (1 << MECHANIC_DISORIENTED) |
        (1 << MECHANIC_FEAR) | (1 << MECHANIC_SLEEP) | (1 << MECHANIC_STUN) |
        (1 << MECHANIC_FREEZE) | (1 << MECHANIC_KNOCKOUT) | (1 << MECHANIC_POLYMORPH) |
        (1 << MECHANIC_SAPPED) | (1 << MECHANIC_TURN) | (1 << MECHANIC_HORROR);
    return player->HasFearAura() || player->HasConfuseAura() || player->HasStunAura() ||
        player->HasAuraType(SPELL_AURA_MOD_CHARM) || player->HasAuraWithMechanic(mechanicMask);
}

bool HasMovementLossOfControl(Player* player)
{
    return player->HasRootAura() || player->HasDecreaseSpeedAura();
}

void UpdateRecentDamage(Player* player, AfflictionRotationRuntime& state, uint32 diff)
{
    float const healthPct = player->GetHealthPct();
    if (!state.DamageWindowTimer)
    {
        state.DamageWindowTimer = 2000;
        state.DamageWindowStartPct = healthPct;
        state.RecentDamagePct = 0.0f;
        return;
    }

    float const healthLost = state.DamageWindowStartPct - healthPct;
    if (healthLost > state.RecentDamagePct)
        state.RecentDamagePct = healthLost;

    if (state.DamageWindowTimer > diff)
        state.DamageWindowTimer -= diff;
    else
    {
        state.DamageWindowTimer = 2000;
        state.DamageWindowStartPct = healthPct;
        state.RecentDamagePct = 0.0f;
    }
}

bool IsTakingBurstDamage(Player* player)
{
    auto const itr = CombatAssistantStates.find(player->GetGUID().GetCounter());
    return itr != CombatAssistantStates.end() && player->IsInCombat() &&
        player->GetHealthPct() <= 70.0f && itr->second.RecentDamagePct >= 20.0f;
}

Player* SelectCriticalAttackedGroupMember(Player* player)
{
    Group* group = player->GetGroup();
    if (!group)
        return nullptr;

    Player* selected = nullptr;
    float lowestHealthPct = 26.0f;
    for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
    {
        Player* member = reference->GetSource();
        if (!member || member == player || !member->IsAlive() || member->GetMap() != player->GetMap())
            continue;

        bool activelyAttacked = false;
        for (Unit* attacker : member->getAttackers())
        {
            if (attacker && attacker->IsAlive() && attacker->GetVictim() == member)
            {
                activelyAttacked = true;
                break;
            }
        }
        if (!activelyAttacked)
            continue;

        float const healthPct = member->GetHealthPct();
        if (healthPct <= 25.0f && healthPct < lowestHealthPct &&
            CanCast(player, SPELL_HAND_OF_PROTECTION, member))
        {
            selected = member;
            lowestHealthPct = healthPct;
        }
    }

    return selected;
}

bool HasInstantSelflessHealer(Player* player)
{
    if (player->HasAura(SPELL_SELFLESS_HEALER_UI))
        return true;

    Aura const* selflessHealer = player->GetAura(SPELL_SELFLESS_HEALER);
    return selflessHealer && selflessHealer->GetStackAmount() >= 3;
}

bool HasRetributionCleanseTarget(Player* player)
{
    // Build 18414 Retribution Cleanse removes harmful poison and disease.
    // Harmful magic dispel is intentionally not included: that requires the
    // Holy-only Sacred Cleansing capability in this client era.
    uint32 const dispelMask = (1 << DISPEL_DISEASE) | (1 << DISPEL_POISON);
    for (auto const& auraPair : player->GetAppliedAuras())
    {
        AuraApplication const* application = auraPair.second;
        if (!application || application->IsPositive())
            continue;

        Aura const* aura = application->GetBase();
        if (!aura || aura->IsPassive())
            continue;

        SpellInfo const* spellInfo = aura->GetSpellInfo();
        if (spellInfo && (spellInfo->GetDispelMask() & dispelMask))
            return true;
    }

    return false;
}

bool HasHarmfulPeriodicDamage(Player* player)
{
    for (auto const& auraPair : player->GetAppliedAuras())
    {
        AuraApplication const* application = auraPair.second;
        if (!application || application->IsPositive())
            continue;

        Aura const* aura = application->GetBase();
        SpellInfo const* spellInfo = aura ? aura->GetSpellInfo() : nullptr;
        if (spellInfo && (spellInfo->HasAura(SPELL_AURA_PERIODIC_DAMAGE) ||
            spellInfo->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT)))
            return true;
    }

    return false;
}

uint32 FindKnownSpellByName(Player* player, char const* name)
{
    if (!player || !name || !*name)
        return 0;

    uint32 found = 0;
    for (auto const& spellPair : player->GetSpellMap())
    {
        if (!spellPair.second || spellPair.second->state == PLAYERSPELL_REMOVED ||
            !spellPair.second->active)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellPair.first);
        if (!spellInfo || spellInfo->IsPassive() || !spellInfo->SpellName[LOCALE_enUS] ||
            strcmp(spellInfo->SpellName[LOCALE_enUS], name))
            continue;

        found = spellPair.first;
    }
    return found;
}

CombatRecommendation RecommendNamed(Player* player, Unit* target,
    char const* name, char const* reason, bool skipActiveAura = false)
{
    uint32 spellId = FindKnownSpellByName(player, name);
    if (!spellId || !target)
        return {};
    if (skipActiveAura && target->HasAura(spellId, player->GetGUID()))
        return {};
    if (!CanCast(player, spellId, target))
        return {};
    return { spellId, target, reason };
}

CombatRecommendation RecommendFirstNamed(Player* player, Unit* target,
    std::initializer_list<char const*> names, char const* reason,
    bool skipActiveAura = false)
{
    for (char const* name : names)
        if (CombatRecommendation recommendation = RecommendNamed(
            player, target, name, reason, skipActiveAura))
            return recommendation;
    return {};
}

CombatRecommendation RecommendFirstNamed(Player* player, Unit* target,
    std::vector<char const*> const& names, char const* reason,
    bool skipActiveAura = false)
{
    for (char const* name : names)
        if (CombatRecommendation recommendation = RecommendNamed(
            player, target, name, reason, skipActiveAura))
            return recommendation;
    return {};
}

bool HasRemovableHarmfulAura(Player* player, uint32 dispelMask)
{
    for (auto const& auraPair : player->GetAppliedAuras())
    {
        AuraApplication const* application = auraPair.second;
        if (!application || application->IsPositive())
            continue;
        Aura const* aura = application->GetBase();
        SpellInfo const* spellInfo = aura ? aura->GetSpellInfo() : nullptr;
        if (spellInfo && !aura->IsPassive() && (spellInfo->GetDispelMask() & dispelMask))
            return true;
    }
    return false;
}

Player* SelectLowestGroupMember(Player* player, float maximumHealthPct,
    bool requireAttacker)
{
    Player* selected = player->GetHealthPct() <= maximumHealthPct ? player : nullptr;
    float lowestHealthPct = selected ? player->GetHealthPct() : maximumHealthPct + 1.0f;
    Group* group = player->GetGroup();
    if (!group)
        return selected;

    for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
    {
        Player* member = reference->GetSource();
        if (!member || !member->IsAlive() || member->GetMap() != player->GetMap())
            continue;
        if (requireAttacker && member->getAttackers().empty())
            continue;
        float healthPct = member->GetHealthPct();
        if (healthPct <= maximumHealthPct && healthPct < lowestHealthPct)
        {
            selected = member;
            lowestHealthPct = healthPct;
        }
    }
    return selected;
}

std::vector<char const*> GetCrowdControlBreaks(uint8 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR:      return { "Berserker Rage" };
        case CLASS_PALADIN:      return { "Divine Shield" };
        case CLASS_HUNTER:       return { "Master's Call", "Deterrence" };
        case CLASS_ROGUE:        return { "Cloak of Shadows", "Vanish" };
        case CLASS_PRIEST:       return { "Dispersion" };
        case CLASS_DEATH_KNIGHT: return { "Icebound Fortitude", "Lichborne" };
        case CLASS_SHAMAN:       return { "Shamanistic Rage", "Tremor Totem" };
        case CLASS_MAGE:         return { "Ice Block", "Blink" };
        case CLASS_WARLOCK:      return { "Unbound Will" };
        case CLASS_MONK:         return { "Nimble Brew" };
        case CLASS_DRUID:        return { "Barkskin" };
        default:                 return {};
    }
}

std::vector<char const*> GetMovementBreaks(uint8 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR: return { "Heroic Leap", "Charge" };
        case CLASS_PALADIN: return { "Hand of Freedom" };
        case CLASS_HUNTER:  return { "Master's Call", "Disengage" };
        case CLASS_ROGUE:   return { "Cloak of Shadows", "Vanish" };
        case CLASS_PRIEST:  return { "Phantasm" };
        case CLASS_SHAMAN:  return { "Windwalk Totem" };
        case CLASS_MAGE:    return { "Blink" };
        case CLASS_WARLOCK: return { "Unbound Will" };
        case CLASS_MONK:    return { "Nimble Brew", "Tiger's Lust" };
        case CLASS_DRUID:   return { "Dash", "Stampeding Roar" };
        default:            return {};
    }
}

std::vector<char const*> GetDefensiveSpells(uint8 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR: return { "Shield Wall", "Die by the Sword", "Last Stand", "Demoralizing Banner", "Enraged Regeneration" };
        case CLASS_PALADIN: return { "Divine Protection", "Divine Shield", "Sacred Shield", "Hand of Purity" };
        case CLASS_HUNTER:  return { "Deterrence", "Exhilaration" };
        case CLASS_ROGUE:   return { "Cloak of Shadows", "Evasion", "Feint", "Combat Readiness" };
        case CLASS_PRIEST:  return { "Dispersion", "Desperate Prayer", "Power Word: Shield", "Spectral Guise" };
        case CLASS_DEATH_KNIGHT: return { "Icebound Fortitude", "Anti-Magic Shell", "Vampiric Blood", "Bone Shield", "Death Pact" };
        case CLASS_SHAMAN:  return { "Shamanistic Rage", "Astral Shift", "Stone Bulwark Totem" };
        case CLASS_MAGE:    return { "Ice Block", "Greater Invisibility", "Temporal Shield", "Ice Barrier" };
        case CLASS_WARLOCK: return { "Unending Resolve", "Dark Bargain", "Sacrificial Pact", "Twilight Ward" };
        case CLASS_MONK:    return { "Fortifying Brew", "Diffuse Magic", "Dampen Harm", "Elusive Brew" };
        case CLASS_DRUID:   return { "Barkskin", "Survival Instincts", "Might of Ursoc", "Cenarion Ward" };
        default:            return {};
    }
}

std::vector<char const*> GetEmergencySelfHeals(uint8 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR: return { "Impending Victory", "Victory Rush", "Enraged Regeneration" };
        case CLASS_PALADIN: return { "Eternal Flame", "Word of Glory", "Holy Shock", "Flash of Light" };
        case CLASS_HUNTER:  return { "Exhilaration" };
        case CLASS_ROGUE:   return { "Recuperate" };
        case CLASS_PRIEST:  return { "Desperate Prayer", "Power Word: Shield", "Flash Heal" };
        case CLASS_DEATH_KNIGHT: return { "Death Pact", "Death Siphon", "Death Strike" };
        case CLASS_SHAMAN:  return { "Ancestral Swiftness", "Healing Surge" };
        case CLASS_MAGE:    return { "Cold Snap", "Ice Barrier" };
        case CLASS_WARLOCK: return { "Mortal Coil", "Drain Life" };
        case CLASS_MONK:    return { "Expel Harm", "Chi Wave", "Healing Elixirs" };
        case CLASS_DRUID:   return { "Renewal", "Cenarion Ward", "Rejuvenation" };
        default:            return {};
    }
}

std::vector<char const*> GetInterruptSpells(uint8 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR: return { "Pummel", "Disrupting Shout" };
        case CLASS_PALADIN: return { "Rebuke" };
        case CLASS_HUNTER:  return { "Counter Shot", "Silencing Shot" };
        case CLASS_ROGUE:   return { "Kick" };
        case CLASS_PRIEST:  return { "Silence" };
        case CLASS_DEATH_KNIGHT: return { "Mind Freeze", "Strangulate" };
        case CLASS_SHAMAN:  return { "Wind Shear" };
        case CLASS_MAGE:    return { "Counterspell" };
        case CLASS_WARLOCK: return { "Spell Lock", "Optical Blast" };
        case CLASS_MONK:    return { "Spear Hand Strike" };
        case CLASS_DRUID:   return { "Skull Bash", "Solar Beam" };
        default:            return {};
    }
}

CombatRecommendation SelectClassCleanse(Player* player)
{
    uint32 mask = 0;
    std::vector<char const*> spells;
    switch (player->GetClass())
    {
        case CLASS_PALADIN:
            mask = (1 << DISPEL_DISEASE) | (1 << DISPEL_POISON);
            if (player->GetTalentSpecialization() == SPEC_PALADIN_HOLY)
                mask |= (1 << DISPEL_MAGIC);
            spells = { "Cleanse" };
            break;
        case CLASS_PRIEST:
            mask = (1 << DISPEL_DISEASE) | (1 << DISPEL_MAGIC);
            spells = { "Purify" };
            break;
        case CLASS_SHAMAN:
            mask = (1 << DISPEL_CURSE);
            if (player->GetTalentSpecialization() == SPEC_SHAMAN_RESTORATION)
                mask |= (1 << DISPEL_MAGIC);
            spells = { "Purify Spirit", "Cleanse Spirit" };
            break;
        case CLASS_MAGE:
            mask = (1 << DISPEL_CURSE);
            spells = { "Remove Curse" };
            break;
        case CLASS_MONK:
            mask = (1 << DISPEL_DISEASE) | (1 << DISPEL_POISON);
            if (player->GetTalentSpecialization() == SPEC_MONK_MISTWEAVER)
                mask |= (1 << DISPEL_MAGIC);
            spells = { "Detox" };
            break;
        case CLASS_DRUID:
            mask = (1 << DISPEL_CURSE) | (1 << DISPEL_POISON);
            if (player->GetTalentSpecialization() == SPEC_DRUID_RESTORATION)
                mask |= (1 << DISPEL_MAGIC);
            spells = { "Nature's Cure", "Remove Corruption" };
            break;
        default:
            return {};
    }

    if (!HasRemovableHarmfulAura(player, mask))
        return {};
    return RecommendFirstNamed(player, player, spells, "CLEANSE");
}

CombatRecommendation SelectAllyProtection(Player* player)
{
    Player* ally = SelectLowestGroupMember(player, 30.0f, true);
    if (!ally || ally == player)
        return {};

    switch (player->GetClass())
    {
        case CLASS_WARRIOR:
            return RecommendFirstNamed(player, ally, { "Safeguard", "Vigilance" }, "ALLY_PROTECTION");
        case CLASS_PALADIN:
            return RecommendFirstNamed(player, ally, { "Hand of Protection", "Hand of Sacrifice", "Sacred Shield" }, "ALLY_PROTECTION");
        case CLASS_PRIEST:
            return RecommendFirstNamed(player, ally, { "Pain Suppression", "Guardian Spirit", "Power Word: Shield" }, "ALLY_PROTECTION");
        case CLASS_SHAMAN:
            return RecommendFirstNamed(player, ally, { "Earth Shield" }, "ALLY_PROTECTION", true);
        case CLASS_MONK:
            return RecommendFirstNamed(player, ally, { "Life Cocoon", "Tiger's Lust" }, "ALLY_PROTECTION");
        case CLASS_DRUID:
            return RecommendFirstNamed(player, ally, { "Ironbark", "Cenarion Ward", "Rejuvenation" }, "ALLY_PROTECTION");
        default:
            return {};
    }
}

CombatRecommendation SelectHealerRecommendation(Player* player)
{
    Player* ally = SelectLowestGroupMember(player, 85.0f, false);
    if (!ally)
        return {};

    switch (player->GetTalentSpecialization())
    {
        case SPEC_PALADIN_HOLY:
            return RecommendFirstNamed(player, ally, { "Holy Shock", "Eternal Flame", "Word of Glory", "Flash of Light", "Divine Light", "Holy Light" }, "HEAL_ALLY");
        case SPEC_PRIEST_DISCIPLINE:
            return RecommendFirstNamed(player, ally, { "Penance", "Power Word: Shield", "Prayer of Mending", "Flash Heal", "Heal" }, "HEAL_ALLY");
        case SPEC_PRIEST_HOLY:
            return RecommendFirstNamed(player, ally, { "Holy Word: Serenity", "Circle of Healing", "Renew", "Flash Heal", "Heal" }, "HEAL_ALLY");
        case SPEC_SHAMAN_RESTORATION:
            return RecommendFirstNamed(player, ally, { "Riptide", "Unleash Elements", "Healing Surge", "Greater Healing Wave", "Healing Wave" }, "HEAL_ALLY");
        case SPEC_MONK_MISTWEAVER:
            return RecommendFirstNamed(player, ally, { "Life Cocoon", "Renewing Mist", "Expel Harm", "Surging Mist", "Enveloping Mist", "Soothing Mist" }, "HEAL_ALLY");
        case SPEC_DRUID_RESTORATION:
            return RecommendFirstNamed(player, ally, { "Swiftmend", "Cenarion Ward", "Rejuvenation", "Lifebloom", "Regrowth", "Healing Touch" }, "HEAL_ALLY");
        default:
            return {};
    }
}

CombatRecommendation SelectKnownTalentDamage(Player* player, Unit* target)
{
    switch (player->GetClass())
    {
        case CLASS_WARRIOR: return RecommendFirstNamed(player, target, { "Storm Bolt", "Dragon Roar", "Shockwave", "Bladestorm" }, "TALENT");
        case CLASS_PALADIN: return RecommendFirstNamed(player, target, { "Execution Sentence", "Holy Prism" }, "TALENT");
        case CLASS_HUNTER:  return RecommendFirstNamed(player, target, { "Glaive Toss", "Powershot", "Barrage" }, "TALENT");
        case CLASS_ROGUE:   return RecommendFirstNamed(player, target, { "Marked for Death", "Shadowstep" }, "TALENT");
        case CLASS_PRIEST:  return RecommendFirstNamed(player, target, { "Cascade", "Divine Star", "Halo", "Psyfiend" }, "TALENT");
        case CLASS_DEATH_KNIGHT: return RecommendFirstNamed(player, target, { "Death Siphon", "Asphyxiate" }, "TALENT");
        case CLASS_SHAMAN:  return RecommendFirstNamed(player, target, { "Elemental Blast", "Unleash Elements" }, "TALENT");
        case CLASS_MAGE:    return RecommendFirstNamed(player, target, { "Nether Tempest", "Living Bomb", "Frost Bomb" }, "TALENT", true);
        case CLASS_WARLOCK: return RecommendFirstNamed(player, target, { "Mortal Coil", "Shadowfury" }, "TALENT");
        case CLASS_MONK:    return RecommendFirstNamed(player, target, { "Chi Wave", "Zen Sphere", "Chi Burst" }, "TALENT");
        case CLASS_DRUID:   return RecommendFirstNamed(player, target, { "Force of Nature" }, "TALENT");
        default:            return {};
    }
}

CombatRecommendation SelectAoeRotation(Player* player, Unit* target)
{
    Specializations const spec = Specializations(player->GetTalentSpecialization());
    switch (spec)
    {
        case SPEC_WARRIOR_ARMS:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Sweeping Strikes", "AOE", true)) return spell;
            if (CombatRecommendation spell = RecommendFirstNamed(player, player, { "Bladestorm", "Thunder Clap", "Whirlwind" }, "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Dragon Roar", "Shockwave", "Cleave" }, "AOE");
        case SPEC_WARRIOR_FURY:
            if (CombatRecommendation spell = RecommendFirstNamed(player, player, { "Bladestorm", "Whirlwind", "Thunder Clap" }, "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Dragon Roar", "Shockwave", "Cleave" }, "AOE");
        case SPEC_WARRIOR_PROTECTION:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Thunder Clap", "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Shockwave", "Dragon Roar", "Revenge", "Cleave" }, "AOE");
        case SPEC_PALADIN_PROTECTION:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Consecration", "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Hammer of the Righteous", "Avenger's Shield", "Shield of the Righteous" }, "AOE");
        case SPEC_HUNTER_BEAST_MASTERY:
        case SPEC_HUNTER_MARKSMANSHIP:
        case SPEC_HUNTER_SURVIVAL:
            return RecommendNamed(player, target, "Multi-Shot", "AOE");
        case SPEC_ROGUE_COMBAT:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Blade Flurry", "AOE", true)) return spell;
            return RecommendNamed(player, target, "Fan of Knives", "AOE");
        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_ROGUE_SUBTLETY:
            return RecommendNamed(player, target, "Fan of Knives", "AOE");
        case SPEC_PRIEST_SHADOW:
            return RecommendNamed(player, target, "Mind Sear", "AOE");
        case SPEC_DEATH_KNIGHT_BLOOD:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Blood Boil", "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Death and Decay", "Pestilence", "Heart Strike" }, "AOE");
        case SPEC_DEATH_KNIGHT_FROST:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Howling Blast", "AOE")) return spell;
            if (CombatRecommendation spell = RecommendNamed(player, player, "Blood Boil", "AOE")) return spell;
            return RecommendFirstNamed(player, target, { "Death and Decay", "Pestilence" }, "AOE");
        case SPEC_DEATH_KNIGHT_UNHOLY:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Pestilence", "AOE")) return spell;
            if (CombatRecommendation spell = RecommendNamed(player, player, "Blood Boil", "AOE")) return spell;
            return RecommendNamed(player, target, "Death and Decay", "AOE");
        case SPEC_SHAMAN_ELEMENTAL:
            return RecommendNamed(player, target, "Chain Lightning", "AOE");
        case SPEC_SHAMAN_ENHANCEMENT:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Fire Nova", "AOE")) return spell;
            return RecommendNamed(player, target, "Chain Lightning", "AOE");
        case SPEC_MAGE_ARCANE:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Blizzard", "AOE")) return spell;
            return RecommendNamed(player, player, "Arcane Explosion", "AOE");
        case SPEC_MAGE_FIRE:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Flamestrike", "AOE")) return spell;
            return RecommendNamed(player, target, "Blizzard", "AOE");
        case SPEC_MAGE_FROST:
            return RecommendFirstNamed(player, target, { "Frozen Orb", "Blizzard", "Frost Bomb" }, "AOE");
        case SPEC_WARLOCK_AFFLICTION:
            return RecommendNamed(player, target, "Seed of Corruption", "AOE");
        case SPEC_WARLOCK_DEMONOLOGY:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Hand of Gul'dan", "AOE")) return spell;
            return RecommendNamed(player, player, "Immolation Aura", "AOE");
        case SPEC_WARLOCK_DESTRUCTION:
            return RecommendNamed(player, target, "Rain of Fire", "AOE");
        case SPEC_MONK_BREWMASTER:
            if (CombatRecommendation spell = RecommendNamed(player, target, "Keg Smash", "AOE")) return spell;
            return RecommendNamed(player, player, "Spinning Crane Kick", "AOE");
        case SPEC_MONK_WINDWALKER:
            return RecommendNamed(player, player, "Spinning Crane Kick", "AOE");
        case SPEC_DRUID_BALANCE:
            return RecommendNamed(player, target, "Hurricane", "AOE");
        case SPEC_DRUID_FERAL:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Thrash", "AOE")) return spell;
            return RecommendNamed(player, player, "Swipe", "AOE");
        case SPEC_DRUID_GUARDIAN:
            if (CombatRecommendation spell = RecommendNamed(player, player, "Thrash", "AOE")) return spell;
            return RecommendNamed(player, player, "Swipe", "AOE");
        default:
            return {};
    }
}

CombatRecommendation SelectGenericRotation(Player* player, Unit* target)
{
    Specializations spec = Specializations(player->GetTalentSpecialization());
    switch (spec)
    {
        case SPEC_WARRIOR_ARMS: return RecommendFirstNamed(player, target, { "Colossus Smash", "Mortal Strike", "Execute", "Overpower", "Slam" }, "DAMAGE");
        case SPEC_WARRIOR_FURY: return RecommendFirstNamed(player, target, { "Bloodthirst", "Raging Blow", "Execute", "Wild Strike", "Heroic Strike" }, "DAMAGE");
        case SPEC_WARRIOR_PROTECTION: return RecommendFirstNamed(player, target, { "Shield Slam", "Revenge", "Devastate", "Heroic Strike" }, "DAMAGE");
        case SPEC_PALADIN_PROTECTION: return RecommendFirstNamed(player, target, { "Shield of the Righteous", "Judgment", "Crusader Strike", "Avenger's Shield" }, "DAMAGE");
        case SPEC_HUNTER_BEAST_MASTERY: return RecommendFirstNamed(player, target, { "Kill Command", "Kill Shot", "Arcane Shot", "Cobra Shot" }, "DAMAGE");
        case SPEC_HUNTER_MARKSMANSHIP: return RecommendFirstNamed(player, target, { "Chimera Shot", "Kill Shot", "Aimed Shot", "Arcane Shot", "Steady Shot" }, "DAMAGE");
        case SPEC_HUNTER_SURVIVAL:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Black Arrow", "Serpent Sting" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Explosive Shot", "Kill Shot", "Arcane Shot", "Cobra Shot" }, "DAMAGE");
        case SPEC_ROGUE_ASSASSINATION:
            if (player->GetComboPoints() >= 4) return RecommendFirstNamed(player, target, { "Envenom", "Rupture" }, "SPEND");
            return RecommendFirstNamed(player, target, { "Dispatch", "Mutilate" }, "BUILD");
        case SPEC_ROGUE_COMBAT:
            if (player->GetComboPoints() >= 4) return RecommendFirstNamed(player, target, { "Eviscerate", "Slice and Dice" }, "SPEND");
            return RecommendFirstNamed(player, target, { "Revealing Strike", "Sinister Strike" }, "BUILD");
        case SPEC_ROGUE_SUBTLETY:
            if (player->GetComboPoints() >= 4) return RecommendFirstNamed(player, target, { "Eviscerate", "Rupture" }, "SPEND");
            return RecommendFirstNamed(player, target, { "Hemorrhage", "Backstab" }, "BUILD");
        case SPEC_PRIEST_SHADOW:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Shadow Word: Pain", "Vampiric Touch" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Devouring Plague", "Mind Blast", "Shadow Word: Death", "Mind Flay" }, "DAMAGE");
        case SPEC_DEATH_KNIGHT_BLOOD: return RecommendFirstNamed(player, target, { "Death Strike", "Rune Strike", "Heart Strike" }, "DAMAGE");
        case SPEC_DEATH_KNIGHT_FROST: return RecommendFirstNamed(player, target, { "Soul Reaper", "Obliterate", "Frost Strike", "Howling Blast" }, "DAMAGE");
        case SPEC_DEATH_KNIGHT_UNHOLY:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Outbreak", "Plague Strike" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Soul Reaper", "Scourge Strike", "Death Coil", "Festering Strike" }, "DAMAGE");
        case SPEC_SHAMAN_ELEMENTAL:
            if (CombatRecommendation dot = RecommendNamed(player, target, "Flame Shock", "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Lava Burst", "Earth Shock", "Lightning Bolt" }, "DAMAGE");
        case SPEC_SHAMAN_ENHANCEMENT:
            return RecommendFirstNamed(player, target, { "Stormstrike", "Lava Lash", "Earth Shock", "Lightning Bolt", "Primal Strike" }, "DAMAGE");
        case SPEC_MAGE_ARCANE: return RecommendFirstNamed(player, target, { "Arcane Missiles", "Arcane Barrage", "Arcane Blast" }, "DAMAGE");
        case SPEC_MAGE_FIRE: return RecommendFirstNamed(player, target, { "Pyroblast", "Inferno Blast", "Fire Blast", "Fireball" }, "DAMAGE");
        case SPEC_MAGE_FROST: return RecommendFirstNamed(player, target, { "Frostfire Bolt", "Ice Lance", "Frozen Orb", "Frostbolt" }, "DAMAGE");
        case SPEC_WARLOCK_AFFLICTION:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Agony", "Corruption", "Unstable Affliction" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Haunt", "Drain Soul", "Malefic Grasp" }, "DAMAGE");
        case SPEC_WARLOCK_DEMONOLOGY:
            if (CombatRecommendation dot = RecommendNamed(player, target, "Corruption", "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Soul Fire", "Hand of Gul'dan", "Touch of Chaos", "Shadow Bolt" }, "DAMAGE");
        case SPEC_WARLOCK_DESTRUCTION:
            if (CombatRecommendation dot = RecommendNamed(player, target, "Immolate", "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Chaos Bolt", "Shadowburn", "Conflagrate", "Incinerate" }, "DAMAGE");
        case SPEC_MONK_BREWMASTER: return RecommendFirstNamed(player, target, { "Keg Smash", "Blackout Kick", "Tiger Palm", "Jab" }, "DAMAGE");
        case SPEC_MONK_WINDWALKER: return RecommendFirstNamed(player, target, { "Rising Sun Kick", "Fists of Fury", "Blackout Kick", "Tiger Palm", "Jab" }, "DAMAGE");
        case SPEC_DRUID_BALANCE:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Moonfire", "Sunfire" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Starsurge", "Starfire", "Wrath" }, "DAMAGE");
        case SPEC_DRUID_FERAL:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Rake", "Rip" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Ferocious Bite", "Shred", "Mangle" }, "DAMAGE");
        case SPEC_DRUID_GUARDIAN: return RecommendFirstNamed(player, target, { "Savage Defense", "Mangle", "Thrash", "Lacerate", "Maul" }, "DAMAGE");
        default: return RecommendFirstNamed(player, target, { "Smite", "Wrath", "Lightning Bolt", "Crackling Jade Lightning" }, "DAMAGE");
    }
}

bool TargetIsCasting(Unit* target);

CombatRecommendation SelectProtectionRecommendation(Player* player)
{
    if (HasHardLossOfControl(player))
        if (CombatRecommendation escape = RecommendNamed(player, player, "Every Man for Himself", "RACIAL_ESCAPE"))
            return escape;
    if (player->GetHealthPct() < 20.0f)
        if (CombatRecommendation heal = RecommendFirstNamed(player, player, { "Lay on Hands", "Word of Glory" }, "EMERGENCY_HEAL"))
            return heal;
    if (IsTakingBurstDamage(player) || player->GetHealthPct() <= 40.0f)
        if (CombatRecommendation defense = RecommendFirstNamed(player, player,
            { "Ardent Defender", "Guardian of Ancient Kings", "Divine Protection" }, "BURST_DEFENSE", true))
            return defense;
    if (!player->HasAura(25780))
        if (CombatRecommendation fury = RecommendNamed(player, player, "Righteous Fury", "TANK_BUFF")) return fury;

    Group* group = GetCombatAssistantGroup(player);
    bool const groupPve = group && !player->InBattleground() && !player->InArena();
    if (groupPve)
    {
        // Recomputed on the button press too; never taunt a mob already on a tank.
        std::list<Unit*> nearby;
        player->GetAttackableUnitListInRange(nearby, 30.0f);
        nearby.sort([](Unit* a, Unit* b) { return a->GetGUID() < b->GetGUID(); });
        for (Unit* hostile : nearby)
            if (GroupPveCombat::NeedsRescue(player, hostile) && CanCast(player, 62124, hostile))
                return { 62124, hostile, "TANK_RESCUE" };
    }
    Unit* target = player->GetSelectedUnit();
    if (target && player->IsValidAttackTarget(target) && TargetIsCasting(target))
        if (CombatRecommendation interrupt = RecommendNamed(player, target, "Rebuke", "INTERRUPT")) return interrupt;
    if (player->IsInCombat())
    {
        if (!player->HasAura(20925))
            if (CombatRecommendation shield = RecommendNamed(player, player, "Sacred Shield", "ABSORB_DEFENSE")) return shield;
        if (!player->HasAura(20165))
            if (CombatRecommendation seal = RecommendNamed(player, player, "Seal of Insight", "TANK_BUFF")) return seal;
    }
    if (!target || !player->IsValidAttackTarget(target)) return {};
    unsigned power = player->GetPower(POWER_HOLY_POWER);
    bool incoming = !player->getAttackers().empty();
    if ((power >= 5 || (incoming && !player->HasAura(132403))) &&
        CanCast(player, 53600, target)) return { 53600, target, "TANK_MITIGATION" };
    CombatAoeState aoe = GetCombatAoeState(player, target);
    if (aoe.UseAoe)
    {
        if (CombatRecommendation builder = RecommendNamed(player, target, "Hammer of the Righteous", "BUILD")) return builder;
        if (CombatRecommendation shield = RecommendNamed(player, target, "Avenger's Shield", "AOE")) return shield;
        std::list<DynamicObject*> areas;
        player->GetDynObjectList(areas, 26573);
        bool covered = false;
        for (DynamicObject* area : areas)
            if (area && area->IsWithinDistInMap(target, 8.0f)) covered = true;
        if (!covered)
            if (CombatRecommendation ground = RecommendNamed(player, player, "Consecration", "AOE")) return ground;
    }
    if (CombatRecommendation builder = RecommendFirstNamed(player, target,
        { "Crusader Strike", "Judgment", "Avenger's Shield", "Hammer of Wrath" }, "BUILD")) return builder;
    return {};
}

CombatRecommendation SelectUniversalRecommendation(Player* player)
{
    if (HasHardLossOfControl(player))
    {
        if (CombatRecommendation racial = RecommendNamed(player, player,
            "Every Man for Himself", "RACIAL_ESCAPE"))
            return racial;
        if (CombatRecommendation escape = RecommendFirstNamed(player, player,
            GetCrowdControlBreaks(player->GetClass()), "ESCAPE_CC"))
            return escape;
    }

    if (player->GetHealthPct() < 15.0f)
        if (CombatRecommendation heal = RecommendFirstNamed(player, player,
            GetEmergencySelfHeals(player->GetClass()), "EMERGENCY_HEAL"))
            return heal;

    if (IsTakingBurstDamage(player) || player->GetHealthPct() <= 40.0f)
        if (CombatRecommendation defense = RecommendFirstNamed(player, player,
            GetDefensiveSpells(player->GetClass()), "BURST_DEFENSE", true))
            return defense;

    if (CombatRecommendation protection = SelectAllyProtection(player))
        return protection;

    if (HasMovementLossOfControl(player))
        if (CombatRecommendation movement = RecommendFirstNamed(player, player,
            GetMovementBreaks(player->GetClass()), "ESCAPE_MOVEMENT"))
            return movement;

    Unit* target = player->GetSelectedUnit();
    bool hostileTarget = target && player->IsValidAttackTarget(target);
    if (hostileTarget && TargetIsCasting(target))
        if (CombatRecommendation interrupt = RecommendFirstNamed(player, target,
            GetInterruptSpells(player->GetClass()), "INTERRUPT"))
            return interrupt;

    if (CombatRecommendation cleanse = SelectClassCleanse(player))
        return cleanse;

    if (CombatRecommendation healing = SelectHealerRecommendation(player))
        return healing;

    if (!hostileTarget)
        return {};

    CombatAoeState const aoe = GetCombatAoeState(player, target);
    if (aoe.UseAoe)
        if (CombatRecommendation recommendation = SelectAoeRotation(player, target))
            return recommendation;

    if (CombatRecommendation talent = SelectKnownTalentDamage(player, target))
        return talent;
    return SelectGenericRotation(player, target);
}

CombatRecommendation SelectEmergencyHeal(Player* player)
{
    if (player->GetHealthPct() >= 15.0f)
        return {};

    // Eternal Flame and Word of Glory are native instant Holy-Power heals.
    // Flash of Light is offered only with the three-stack Selfless Healer
    // instant-cast marker; a normal cast-time heal is never selected here.
    if (CanCast(player, SPELL_ETERNAL_FLAME, player))
        return { SPELL_ETERNAL_FLAME, player, "EMERGENCY_HEAL" };

    if (CanCast(player, SPELL_WORD_OF_GLORY, player))
        return { SPELL_WORD_OF_GLORY, player, "EMERGENCY_HEAL" };

    if (HasInstantSelflessHealer(player) && CanCast(player, SPELL_FLASH_OF_LIGHT, player))
        return { SPELL_FLASH_OF_LIGHT, player, "EMERGENCY_HEAL" };

    return {};
}

bool TargetIsCasting(Unit* target)
{
    if (!target || !target->IsNonMeleeSpellCasted(false))
        return false;

    for (uint8 type = CURRENT_GENERIC_SPELL; type <= CURRENT_CHANNELED_SPELL; ++type)
    {
        Spell const* spell = target->GetCurrentSpell(CurrentSpellTypes(type));
        if (!spell)
            continue;

        SpellInfo const* spellInfo = spell->GetSpellInfo();
        if (spellInfo && (spellInfo->InterruptFlags & SPELL_INTERRUPT_FLAG_INTERRUPT) &&
            spellInfo->PreventionType == SPELL_PREVENTION_TYPE_SILENCE)
            return true;
    }

    return false;
}

CombatRecommendation SelectRetributionRecommendation(Player* player)
{
    if (HasHardLossOfControl(player))
    {
        // Humans use their racial first, preserving Divine Shield as the
        // fallback when the racial is unknown or on cooldown.
        if (CanCast(player, SPELL_EVERY_MAN_FOR_HIMSELF, player))
            return { SPELL_EVERY_MAN_FOR_HIMSELF, player, "RACIAL_ESCAPE" };

        if (CanCast(player, SPELL_DIVINE_SHIELD, player))
            return { SPELL_DIVINE_SHIELD, player, "ESCAPE_CC" };
    }

    if (CombatRecommendation emergencyHeal = SelectEmergencyHeal(player))
        return emergencyHeal;

    if (IsTakingBurstDamage(player))
    {
        if (CanCast(player, SPELL_DIVINE_PROTECTION, player))
            return { SPELL_DIVINE_PROTECTION, player, "BURST_DEFENSE" };

        if (HasHarmfulPeriodicDamage(player) && CanCast(player, SPELL_HAND_OF_PURITY, player))
            return { SPELL_HAND_OF_PURITY, player, "PERIODIC_DEFENSE" };

        if (!player->HasAura(SPELL_SACRED_SHIELD) && CanCast(player, SPELL_SACRED_SHIELD, player))
            return { SPELL_SACRED_SHIELD, player, "ABSORB_DEFENSE" };
    }

    if (Player* member = SelectCriticalAttackedGroupMember(player))
        return { SPELL_HAND_OF_PROTECTION, member, "ALLY_PROTECTION" };

    if (HasMovementLossOfControl(player) && CanCast(player, SPELL_HAND_OF_FREEDOM, player))
        return { SPELL_HAND_OF_FREEDOM, player, "ESCAPE_MOVEMENT" };

    Unit* target = player->GetSelectedUnit();
    bool const hasHostileTarget = target && player->IsValidAttackTarget(target);

    if (hasHostileTarget && TargetIsCasting(target) && CanCast(player, SPELL_REBUKE, target))
        return { SPELL_REBUKE, target, "INTERRUPT" };

    if (HasRetributionCleanseTarget(player) && CanCast(player, SPELL_CLEANSE, player))
        return { SPELL_CLEANSE, player, "CLEANSE" };

    if (!hasHostileTarget)
        return {};

    uint32 const holyPower = player->GetPower(POWER_HOLY_POWER);
    bool const freeFinisher = player->HasAura(SPELL_DIVINE_PURPOSE);

    if ((holyPower >= 3 || freeFinisher) && !player->HasAura(SPELL_INQUISITION) &&
        CanCast(player, SPELL_INQUISITION, player))
        return { SPELL_INQUISITION, player, "BUFF" };

    // The T16 Divine Crusader overlay is a free, enhanced Divine Storm proc.
    // Honor the flashing action-button proc before normal rotational fillers.
    if (player->HasAura(SPELL_DIVINE_CRUSADER) && CanCast(player, SPELL_DIVINE_STORM, target))
        return { SPELL_DIVINE_STORM, target, "PROC_AOE" };

    CombatAoeState const aoe = GetCombatAoeState(player, target);
    if (aoe.UseAoe)
    {
        if ((holyPower >= 3 || freeFinisher) && CanCast(player, SPELL_DIVINE_STORM, target))
            return { SPELL_DIVINE_STORM, target, "AOE" };

        if (CombatRecommendation builder = RecommendNamed(
            player, target, "Hammer of the Righteous", "AOE"))
            return builder;
    }

    if (CanCast(player, SPELL_EXECUTION_SENTENCE, target))
        return { SPELL_EXECUTION_SENTENCE, target, "TALENT" };

    if (CanCast(player, SPELL_HAMMER_OF_WRATH, target))
        return { SPELL_HAMMER_OF_WRATH, target, "EXECUTE" };

    if ((holyPower >= 3 || freeFinisher) && CanCast(player, SPELL_TEMPLARS_VERDICT, target))
        return { SPELL_TEMPLARS_VERDICT, target, "SPEND" };

    if (player->HasAura(SPELL_ART_OF_WAR) && CanCast(player, SPELL_EXORCISM, target))
        return { SPELL_EXORCISM, target, "PROC" };

    if (CanCast(player, SPELL_CRUSADER_STRIKE, target))
        return { SPELL_CRUSADER_STRIKE, target, "BUILD" };

    if (CanCast(player, SPELL_JUDGMENT, target))
        return { SPELL_JUDGMENT, target, "BUILD" };

    if (CanCast(player, SPELL_EXORCISM, target))
        return { SPELL_EXORCISM, target, "BUILD" };

    return {};
}

int AfflictionAuraRemaining(Player* player, Unit* target, uint32 auraId)
{
    Aura const* aura = target->GetAura(auraId, player->GetGUID());
    return aura ? std::max(0, aura->GetDuration()) : 0;
}

bool IsAfflictionProtectedAlly(Player* player, Unit* target)
{
    if (!target) return false;
    // Check membership rather than faction: Sha's Aggressive Behavior changes
    // faction directly, and does not necessarily provide a charm-owner link.
    Player* member = target->ToPlayer();
    if (!member) member = target->GetCharmerOrOwnerPlayerOrPlayerItself();
    Group* group = GetCombatAssistantGroup(player);
    return member && (member == player || (group && group->IsMember(member->GetGUID())));
}

bool IsAfflictionEngaged(Player* player, Unit* target)
{
    if (!target || !target->IsAlive() || !target->IsInWorld() ||
        target->GetMap() != player->GetMap() || !player->IsValidAttackTarget(target)) return false;
    // Dummies need not have a victim. Own DoTs/threat also prove participation;
    // an unrelated creature merely being in combat does not.
    return IsEngagedWithPlayerOrGroup(player, target, GetCombatAssistantGroup(player)) ||
        GroupPveCombat::IsEngaged(player, target) ||
        target->HasAura(AfflictionAssistant::Agony, player->GetGUID()) ||
        target->HasAura(AfflictionAssistant::CorruptionAura, player->GetGUID()) ||
        target->HasAura(AfflictionAssistant::UnstableAffliction, player->GetGUID()) ||
        (target->CanHaveThreatList() && target->GetThreatManager().getThreat(player) > 0.0f);
}

uint32 AfflictionCastTime(Player* player, uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info) return 0;
    Spell probe(player, info, TRIGGERED_NONE);
    return info->CalcCastTime(player->GetLevel(), &probe);
}

AfflictionAssistant::State AfflictionPlayerState(Player* player, AfflictionRotationRuntime const* runtime = nullptr)
{
    using namespace AfflictionAssistant;
    State state;
    // Read effective glyph auras every request: changing glyphs needs no cached profile reset.
    state.Glyphs = ReadGlyphs([&](uint32 aura) { return player->HasAura(aura); });
    state.Casting = player->GetCurrentSpell(CURRENT_GENERIC_SPELL) != nullptr;
    state.Health = player->GetHealthPct();
    state.Mana = player->GetMaxPower(POWER_MANA) ?
        100.0f * player->GetPower(POWER_MANA) / player->GetMaxPower(POWER_MANA) : 0;
    // Include all remaining healing absorbs, not only an unconsumed Life Tap stack.
    // The live aura amount shrinks as heals consume it and disappears on expiry.
    if (player->GetMaxHealth())
        for (AuraEffect const* effect : player->GetAuraEffectsByType(SPELL_AURA_SCHOOL_HEAL_ABSORB))
            state.HealAbsorbPct += 100.0f * std::max(0.0f, effect->GetFloatAmount()) / player->GetMaxHealth();
    if (SpellInfo const* tap = sSpellMgr->GetSpellInfo(LifeTap))
    {
        state.NextTapHealthCostPct = std::max(0, tap->Effects[EFFECT_0].CalcValue(player));
        state.NextTapAbsorbPct = std::max(0, tap->Effects[EFFECT_2].CalcValue(player));
    }
    if (runtime)
        state.TakingDamage = runtime->RecentDamagePct > 0;
    else
    {
        auto const recent = CombatAssistantStates.find(player->GetGUID().GetCounter());
        state.TakingDamage = recent != CombatAssistantStates.end() && recent->second.RecentDamagePct > 0;
    }
    return state;
}

void ReportAfflictionGlyphs(ChatHandler* handler, Player* player)
{
    using namespace AfflictionAssistant;
    State const state = AfflictionPlayerState(player);
    std::ostringstream report;
    report << "Affliction glyphs: ";
    for (unsigned i = 0; i < GlyphCount; ++i)
    {
        if (i) report << "; ";
        report << GlyphCatalog[i].Name << '=' << (state.Glyphs[i] ? "ON" : "off");
    }
    handler->SendSysMessage(report.str().c_str());
    handler->PSendSysMessage("痛苦无常施法：%u 毫秒。治疗吸收：HP的%.1f%%；下一个雕文生命分流：+%.1f%%。近期生命值损失：%s。允许生命分流：危急=%s，维护=%s。",
        AfflictionCastTime(player, UnstableAffliction), state.HealAbsorbPct, state.NextTapAbsorbPct,
        state.TakingDamage ? "yes" : "no", CanLifeTap(state, true) ? "yes" : "no",
        CanLifeTap(state, false) ? "yes" : "no");
    handler->SendSysMessage("灵魂石：选择一名死亡的团队成员，然后使用助手。小型雕文使用游戏原生效果；助手不会替你上坐骑、游泳或激活传送门。");
}

CombatRecommendation SelectAfflictionRecommendation(Player* player, Unit* selected,
    AfflictionRotationRuntime& runtime, PlayerbotAI* botAI = nullptr)
{
    using namespace AfflictionAssistant;
    if (HasHardLossOfControl(player))
    {
        if (CombatRecommendation racial = RecommendNamed(player, player, "Every Man for Himself", "RACIAL_ESCAPE"))
            return racial;
        if (CombatRecommendation escape = RecommendFirstNamed(player, player,
            GetCrowdControlBreaks(player->GetClass()), "ESCAPE_CC")) return escape;
    }
    State state = AfflictionPlayerState(player, &runtime);
    state.SelectedGroupMember = IsAfflictionProtectedAlly(player, selected);
    if (state.Casting) return {};
    // Resurrection is an explicit target choice, never an automatic raid target switch.
    if (Player* ally = selected ? selected->ToPlayer() : nullptr)
    {
        Group* group = GetCombatAssistantGroup(player);
        state.SelectedDeadAlly = !ally->IsAlive() && group && group->IsMember(ally->GetGUID()) &&
            ally->GetMap() == player->GetMap() && player->IsFriendlyTo(ally);
        if (state.SelectedDeadAlly)
        {
            state.ResurrectionPending = ally->IsRessurectRequested();
            AfflictionAssistant::Action const action = Select(state, [&](AfflictionAssistant::Action const& candidate)
                { return CanCast(player, candidate.Spell, ally); });
            return action ? CombatRecommendation{action.Spell, ally, action.Reason} : CombatRecommendation{};
        }
    }
    if (state.SelectedGroupMember || !selected || !selected->IsAlive() || !player->IsValidAttackTarget(selected) ||
        selected->HasBreakableByDamageCrowdControlAura()) return {};
    // Bots already use the group interrupt coordinator before their rotation.
    if (!botAI && TargetIsCasting(selected))
        if (CombatRecommendation interrupt = RecommendFirstNamed(player, selected,
            GetInterruptSpells(player->GetClass()), "INTERRUPT")) return interrupt;
    if (player->GetHealthPct() < 15.0f)
        if (CombatRecommendation heal = RecommendNamed(player, player, "Dark Regeneration", "EMERGENCY_HEAL"))
            return heal;

    state.Shards = player->GetPower(POWER_SOUL_SHARDS) / 100;
    state.InCombat = IsAfflictionEngaged(player, selected);
    state.Pandemic = player->HasAura(131973);
    state.DarkSoulActive = player->HasAura(DarkSoul);
    state.SoulburnActive = player->HasAura(Soulburn);
    state.CanSoulburnSwap = player->HasSpell(141931) && player->HasSpell(SoulSwap) &&
        CanCast(player, Corruption, selected, botAI);
    state.CanSoulburnSeed = player->HasSpell(86664) && player->HasSpell(Seed) &&
        CanCast(player, Seed, selected, botAI);

    bool allowSecondary = true;
    if (GetCombatAssistantGroup(player) && (botAI || player->GetMap()->IsDungeon() || player->GetMap()->IsRaid()))
        allowSecondary = GroupPveCombat::AoeReady(player, selected);

    // Use the greater explosion radius, with a conservative floor if spell
    // data has no radius. Check idle/CC neighbours as well as counted enemies.
    float damageRadius = 0.0f;
    for (uint32 id : {27285u, 87385u})
        if (SpellInfo const* explosion = sSpellMgr->GetSpellInfo(id))
            for (uint32 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                damageRadius = std::max(damageRadius, explosion->Effects[i].CalcRadius(player));
    float const splashRadius = std::max(15.0f, damageRadius);
    std::list<Unit*> nearby;
    player->GetAttackableUnitListInRange(nearby, 40.0f + splashRadius);
    if (std::find(nearby.begin(), nearby.end(), selected) == nearby.end()) nearby.push_back(selected);
    std::vector<Unit*> secondary;
    unsigned clusterCount = 0;
    bool safeSplash = allowSecondary;
    for (Unit* enemy : nearby)
    {
        if (!enemy || !enemy->IsAlive() || !player->IsValidAttackTarget(enemy) ||
            !selected->IsWithinDistInMap(enemy, splashRadius)) continue;
        if (IsAfflictionProtectedAlly(player, enemy))
        {
            // Do not multidot a mind-controlled ally or place a Seed whose
            // explosion could spread Corruption to that ally.
            safeSplash = false;
            continue;
        }
        bool const engaged = IsAfflictionEngaged(player, enemy);
        bool const controlled = enemy->HasBreakableByDamageCrowdControlAura();
        bool const collected = !GetCombatAssistantGroup(player) || GroupPveCombat::IsCollected(player, enemy);
        if (!engaged || controlled || !collected) safeSplash = false;
        if (engaged && !controlled && collected && damageRadius > 0 &&
            selected->IsWithinDistInMap(enemy, damageRadius)) ++clusterCount;
        if (enemy != selected && allowSecondary && engaged && !controlled && collected &&
            player->IsWithinDistInMap(enemy, 40.0f) && player->IsWithinLOSInMap(enemy))
            secondary.push_back(enemy);
    }
    state.SeedSafe = safeSplash && clusterCount >= 4;
    std::sort(secondary.begin(), secondary.end(), [](Unit* left, Unit* right)
        { return left->GetGUID() < right->GetGUID(); });
    std::vector<Unit*> targets = {selected};
    for (Unit* enemy : secondary)
    {
        if (targets.size() == 3) break;
        targets.push_back(enemy);
    }
    std::array<uint32, 3> const auras = {{Agony, CorruptionAura, UnstableAffliction}};
    std::array<uint32, 3> const dotSpells = {{Agony, Corruption, UnstableAffliction}};
    float const castSpeed = player->GetFloatValue(UNIT_FIELD_MOD_CASTING_SPEED);
    std::array<int, 3> castLeads;
    for (unsigned d = 0; d < dotSpells.size(); ++d)
        castLeads[d] = DotRefreshLead(AfflictionCastTime(player, dotSpells[d]),
            std::max(1000, int(1500 * castSpeed)));
    for (Unit* target : targets)
    {
        Target snapshot;
        for (unsigned d = 0; d < auras.size(); ++d)
        {
            snapshot.Dots[d].Remaining = AfflictionAuraRemaining(player, target, auras[d]);
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(auras[d]))
                snapshot.Dots[d].BaseDuration = player->CalcSpellDuration(info);
            // The normal cast-time calculation includes UA's glyph and haste.
            snapshot.Dots[d].CastLead = castLeads[d];
        }
        snapshot.HauntRemaining = AfflictionAuraRemaining(player, target, Haunt);
        uint32 hauntTravelTime = 0;
        if (SpellInfo const* haunt = sSpellMgr->GetSpellInfo(Haunt))
            if (haunt->Speed > 0)
                hauntTravelTime = uint32(1000 * player->GetDistance(target) / haunt->Speed);
        snapshot.HauntLead = HauntRefreshLead(AfflictionCastTime(player, Haunt), hauntTravelTime);
        if (runtime.HauntPendingTimer && runtime.HauntTarget == target->GetGUID())
            snapshot.HauntRemaining = std::max(snapshot.HauntRemaining, snapshot.HauntLead + 1);
        snapshot.SeedRemaining = std::max(AfflictionAuraRemaining(player, target, Seed),
            AfflictionAuraRemaining(player, target, SoulburnSeed));
        snapshot.Execute = target->HasAuraState(AURA_STATE_HEALTHLESS_20_PERCENT);
        state.Targets.push_back(snapshot);
    }
    if (Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
    {
        state.Channel = channel->GetSpellInfo()->Id;
        // Preserve manually chosen channels (Drain Life, Health Funnel, etc.).
        if (state.Channel != MaleficGrasp && state.Channel != DrainSoul) return {};
        state.ChannelOnSelected = channel->m_targets.GetUnitTarget() == selected;
        if (AuraEffect const* effect = selected->GetAuraEffect(state.Channel, EFFECT_0, player->GetGUID()))
            state.JustTicked = effect->GetTickNumber() > 0 && effect->GetAmplitude() > 0 &&
                effect->GetAmplitude() - effect->GetPeriodicTimer() <= 250;
    }
    AfflictionAssistant::Action const action = Select(state, [&](AfflictionAssistant::Action const& candidate)
    {
        Unit* target = candidate.TargetIndex < 0 ? player : targets[candidate.TargetIndex];
        return CanCast(player, candidate.Spell, target, botAI);
    });
    if (!action) return {};
    return {action.Spell, action.TargetIndex < 0 ? player : targets[action.TargetIndex], action.Reason};
}

CombatRecommendation SelectRecommendation(Player* player)
{
    if (!player || !player->IsAlive())
        return {};

    if (UsesAfflictionAssistant(player))
        return SelectAfflictionRecommendation(player, player->GetSelectedUnit(),
            CombatAssistantStates[player->GetGUID().GetCounter()]);

    if (player->GetClass() == CLASS_PALADIN &&
        player->GetTalentSpecialization() == SPEC_PALADIN_RETRIBUTION)
        return SelectRetributionRecommendation(player);

    if (player->GetClass() == CLASS_PALADIN &&
        player->GetTalentSpecialization() == SPEC_PALADIN_PROTECTION)
        return SelectProtectionRecommendation(player);

    return SelectUniversalRecommendation(player);
}

std::pair<uint32, char const*> GetAssistantPower(Player* player)
{
    Powers power = POWER_MANA;
    char const* name = "Mana";
    switch (player->GetClass())
    {
        case CLASS_WARRIOR: power = POWER_RAGE; name = "Rage"; break;
        case CLASS_PALADIN: power = POWER_HOLY_POWER; name = "Holy Power"; break;
        case CLASS_HUNTER: power = POWER_FOCUS; name = "Focus"; break;
        case CLASS_ROGUE: return { player->GetComboPoints(), "Combo" };
        case CLASS_DEATH_KNIGHT: power = POWER_RUNIC_POWER; name = "Runic"; break;
        case CLASS_PRIEST:
            if (player->GetTalentSpecialization() == SPEC_PRIEST_SHADOW)
            { power = POWER_SHADOW_ORBS; name = "Orbs"; }
            break;
        case CLASS_MAGE:
            if (player->GetTalentSpecialization() == SPEC_MAGE_ARCANE)
            { power = POWER_ARCANE_CHARGES; name = "Charges"; }
            break;
        case CLASS_WARLOCK:
            if (player->GetTalentSpecialization() == SPEC_WARLOCK_AFFLICTION)
            { power = POWER_SOUL_SHARDS; name = "Shards"; }
            else if (player->GetTalentSpecialization() == SPEC_WARLOCK_DEMONOLOGY)
            { power = POWER_DEMONIC_FURY; name = "Fury"; }
            else
            { power = POWER_BURNING_EMBERS; name = "Embers"; }
            break;
        case CLASS_MONK: power = POWER_CHI; name = "Chi"; break;
        case CLASS_DRUID:
            if (player->GetTalentSpecialization() == SPEC_DRUID_FERAL)
            { power = POWER_ENERGY; name = "Energy"; }
            else if (player->GetTalentSpecialization() == SPEC_DRUID_GUARDIAN)
            { power = POWER_RAGE; name = "Rage"; }
            else if (player->GetTalentSpecialization() == SPEC_DRUID_BALANCE)
            { power = POWER_ECLIPSE; name = "Eclipse"; }
            break;
        default: break;
    }

    uint32 value = player->GetPower(power);
    if (power == POWER_SOUL_SHARDS)
        value /= 100;
    else if (power == POWER_RAGE || power == POWER_RUNIC_POWER)
        value /= 10;
    return { value, name };
}

std::string BuildPayload(Player* player, CombatRecommendation const& recommendation)
{
    auto const resource = GetAssistantPower(player);
    std::ostringstream payload;
    if (!sPlayerbotAIConfig->combatAssistantEnabled)
        payload << "OFF|0|DISABLED|" << resource.first << '|' << resource.second;
    else if (!player->IsAlive())
        payload << "WAIT|0|DEAD|" << resource.first << '|' << resource.second;
    else if (recommendation)
        payload << "READY|" << recommendation.SpellId << '|' << recommendation.Reason << '|'
            << resource.first << '|' << resource.second;
    else
        payload << "WAIT|0|NO_CAST|" << resource.first << '|' << resource.second;
    return payload.str();
}

void PushRecommendation(Player* player, bool force)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot())
        return;

    uint32 const guid = player->GetGUID().GetCounter();
    CombatAssistantPlayerState& state = CombatAssistantStates[guid];
    CombatRecommendation const recommendation = sPlayerbotAIConfig->combatAssistantEnabled ?
        SelectRecommendation(player) : CombatRecommendation{};
    std::string const payload = BuildPayload(player, recommendation);
    if (!force && payload == state.LastPayload)
        return;

    state.LastPayload = payload;
    player->WhisperAddon(payload, CombatAssistantAddonPrefix, player);
}

class combat_assistant_commandscript : public CommandScript
{
public:
    combat_assistant_commandscript() : CommandScript("combat_assistant_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> commands =
        {
            { "combatassist", SEC_PLAYER, false, &HandleCombatAssistCommand }
        };
        return commands;
    }

    static bool HandleCombatAssistCommand(ChatHandler* handler, char const* args)
    {
        Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (!sPlayerbotAIConfig->combatAssistantEnabled)
        {
            handler->SendSysMessage("战斗助手 5.4.8 已在 playerbots.conf 中禁用。");
            PushRecommendation(player, true);
            return true;
        }

        bool const cast = args && !strcmp(args, "cast");
        bool const status = !args || !*args || !strcmp(args, "status");
        if (!cast && !status)
        {
            handler->SendSysMessage("用法：.combatassist cast|status");
            return true;
        }

        if (status && UsesAfflictionAssistant(player))
            ReportAfflictionGlyphs(handler, player);
        CombatRecommendation const recommendation = SelectRecommendation(player);
        if (!recommendation)
        {
            if (status)
                handler->SendSysMessage("战斗助手：暂无可用建议（请选择敌对目标，或等待冷却/公共冷却/射程/视线）。");
            PushRecommendation(player, true);
            return true;
        }

        if (status)
        {
            auto const resource = GetAssistantPower(player);
            handler->PSendSysMessage("战斗助手建议法术 %u（%s），%s %u，职业 %u，专精 %u。",
                recommendation.SpellId, recommendation.Reason, resource.second,
                resource.first, uint32(player->GetClass()),
                uint32(player->GetTalentSpecialization()));
            PushRecommendation(player, true);
            return true;
        }

        if (strcmp(recommendation.Reason, "CHANNELING"))
            PrepareCheckedSpell(player, recommendation.SpellId, recommendation.Target, true);
        PushRecommendation(player, true);
        return true;
    }
};

class combat_assistant_playerscript : public PlayerScript
{
public:
    combat_assistant_playerscript() : PlayerScript("combat_assistant_playerscript") { }

    void OnLogin(Player* player) override
    {
        CombatAssistantStates.erase(player->GetGUID().GetCounter());
    }

    void OnLogout(Player* player) override
    {
        CombatAssistantStates.erase(player->GetGUID().GetCounter());
    }

    void OnUpdate(Player* player, uint32 diff) override
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        CombatAssistantPlayerState& state = CombatAssistantStates[player->GetGUID().GetCounter()];
        UpdateRecentDamage(player, state, diff);
        state.HauntPendingTimer = state.HauntPendingTimer > diff ? state.HauntPendingTimer - diff : 0;
        if (state.UpdateTimer > diff)
        {
            state.UpdateTimer -= diff;
            return;
        }

        state.UpdateTimer = sPlayerbotAIConfig->combatAssistantPushInterval;
        PushRecommendation(player, false);
    }
};
}

bool UsesAfflictionBotRotation(PlayerbotAI* botAI)
{
    return botAI && botAI->IsGroupPveActivity() && UsesAfflictionAssistant(botAI->GetBot());
}

bool RunAfflictionBotRotation(PlayerbotAI* botAI, Unit* target, AfflictionRotationRuntime& runtime)
{
    if (!UsesAfflictionBotRotation(botAI)) return false;
    Player* player = botAI->GetBot();
    if (!player->IsAlive() || !player->IsInWorld() || player->IsBeingTeleported() ||
        !target || !target->IsAlive() || !target->IsInWorld() || target->GetMap() != player->GetMap() ||
        IsAfflictionProtectedAlly(player, target) || !IsAfflictionEngaged(player, target) ||
        !botAI->CanLfgAutoQueueEngage(target) || !GroupPveCombat::DamageAllowed(player, target)) return false;

    uint32 const now = getMSTime();
    uint32 const elapsed = runtime.LastUpdate ? getMSTimeDiff(runtime.LastUpdate, now) : 0;
    runtime.LastUpdate = now;
    runtime.HauntPendingTimer = runtime.HauntPendingTimer > elapsed ? runtime.HauntPendingTimer - elapsed : 0;
    UpdateRecentDamage(player, runtime, elapsed);
    CombatRecommendation const recommendation = SelectAfflictionRecommendation(player, target, runtime, botAI);
    if (!recommendation) return false;
    if (!strcmp(recommendation.Reason, "CHANNELING")) return true;
    bool started = false;
    PrepareCheckedSpell(player, recommendation.SpellId, recommendation.Target, true, &runtime, botAI, &started);
    return started;
}

void AddSC_playerbots_combat_assistant()
{
    new combat_assistant_commandscript();
    new combat_assistant_playerscript();
}
