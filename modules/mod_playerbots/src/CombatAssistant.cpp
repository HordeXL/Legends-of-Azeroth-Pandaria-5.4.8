/*
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#include "CombatAssistant.h"

#include "Chat.h"
#include "Group.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "WorldSession.h"

#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

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

struct CombatAssistantPlayerState
{
    uint32 UpdateTimer = 0;
    uint32 DamageWindowTimer = 0;
    float DamageWindowStartPct = 100.0f;
    float RecentDamagePct = 0.0f;
    std::string LastPayload;
};

std::unordered_map<uint32, CombatAssistantPlayerState> CombatAssistantStates;

Spell* PrepareCheckedSpell(Player* player, uint32 spellId, Unit* target, bool cast)
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

    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(knownRank);
    if (!spellInfo || player->GetGlobalCooldownMgr().HasGlobalCooldown(spellInfo))
        return nullptr;

    Spell* spell = new Spell(player, spellInfo, TRIGGERED_NONE);
    if (!spell->CanAutoCast(target))
    {
        delete spell;
        return nullptr;
    }

    if (cast)
    {
        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        spell->prepare(&targets);
        return nullptr;
    }

    return spell;
}

bool CanCast(Player* player, uint32 spellId, Unit* target)
{
    Spell* spell = PrepareCheckedSpell(player, spellId, target, false);
    if (!spell)
        return false;

    delete spell;
    return true;
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

void UpdateRecentDamage(Player* player, CombatAssistantPlayerState& state, uint32 diff)
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

CombatRecommendation SelectGenericRotation(Player* player, Unit* target)
{
    Specializations spec = Specializations(player->GetTalentSpecialization());
    switch (spec)
    {
        case SPEC_WARRIOR_ARMS: return RecommendFirstNamed(player, target, { "Colossus Smash", "Mortal Strike", "Execute", "Overpower", "Slam" }, "DAMAGE");
        case SPEC_WARRIOR_FURY: return RecommendFirstNamed(player, target, { "Bloodthirst", "Raging Blow", "Execute", "Wild Strike", "Heroic Strike" }, "DAMAGE");
        case SPEC_WARRIOR_PROTECTION: return RecommendFirstNamed(player, target, { "Shield Slam", "Revenge", "Devastate", "Heroic Strike" }, "DAMAGE");
        case SPEC_PALADIN_PROTECTION: return RecommendFirstNamed(player, target, { "Shield of the Righteous", "Judgment", "Hammer of the Righteous", "Crusader Strike", "Avenger's Shield" }, "DAMAGE");
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
        case SPEC_DEATH_KNIGHT_BLOOD: return RecommendFirstNamed(player, target, { "Death Strike", "Rune Strike", "Heart Strike", "Blood Boil" }, "DAMAGE");
        case SPEC_DEATH_KNIGHT_FROST: return RecommendFirstNamed(player, target, { "Soul Reaper", "Obliterate", "Frost Strike", "Howling Blast" }, "DAMAGE");
        case SPEC_DEATH_KNIGHT_UNHOLY:
            if (CombatRecommendation dot = RecommendFirstNamed(player, target, { "Outbreak", "Plague Strike" }, "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Soul Reaper", "Scourge Strike", "Death Coil", "Festering Strike" }, "DAMAGE");
        case SPEC_SHAMAN_ELEMENTAL:
            if (CombatRecommendation dot = RecommendNamed(player, target, "Flame Shock", "DOT", true)) return dot;
            return RecommendFirstNamed(player, target, { "Lava Burst", "Earth Shock", "Chain Lightning", "Lightning Bolt" }, "DAMAGE");
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

CombatRecommendation SelectRecommendation(Player* player)
{
    if (!player || !player->IsAlive())
        return {};

    if (player->GetClass() == CLASS_PALADIN &&
        player->GetTalentSpecialization() == SPEC_PALADIN_RETRIBUTION)
        return SelectRetributionRecommendation(player);

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
    if (power == POWER_RAGE || power == POWER_RUNIC_POWER)
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
            handler->SendSysMessage("Combat Assistant 5.4.8 is disabled in playerbots.conf.");
            PushRecommendation(player, true);
            return true;
        }

        bool const cast = args && !strcmp(args, "cast");
        bool const status = !args || !*args || !strcmp(args, "status");
        if (!cast && !status)
        {
            handler->SendSysMessage("Usage: .combatassist cast|status");
            return true;
        }

        CombatRecommendation const recommendation = SelectRecommendation(player);
        if (!recommendation)
        {
            if (status)
                handler->SendSysMessage("Combat Assistant: no usable recommendation (select a hostile target or wait for cooldown/GCD/range/LoS).");
            PushRecommendation(player, true);
            return true;
        }

        if (status)
        {
            auto const resource = GetAssistantPower(player);
            handler->PSendSysMessage("Combat Assistant recommends spell %u (%s), %s %u, class %u, specialization %u.",
                recommendation.SpellId, recommendation.Reason, resource.second,
                resource.first, uint32(player->GetClass()),
                uint32(player->GetTalentSpecialization()));
            PushRecommendation(player, true);
            return true;
        }

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

void AddSC_playerbots_combat_assistant()
{
    new combat_assistant_commandscript();
    new combat_assistant_playerscript();
}
