/*
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#include "CombatAssistant.h"

#include "Chat.h"
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

namespace
{
char const* CombatAssistantAddonPrefix = "CA548";

enum CombatAssistantPaladinSpells : uint32
{
    SPELL_DIVINE_SHIELD       = 642,
    SPELL_EXORCISM            = 879,
    SPELL_HAND_OF_FREEDOM     = 1044,
    SPELL_CLEANSE             = 4987,
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
    if (!player || !player->IsAlive() || player->GetClass() != CLASS_PALADIN ||
        player->GetTalentSpecialization() != SPEC_PALADIN_RETRIBUTION)
        return {};

    return SelectRetributionRecommendation(player);
}

std::string BuildPayload(Player* player, CombatRecommendation const& recommendation)
{
    std::ostringstream payload;
    if (!sPlayerbotAIConfig->combatAssistantEnabled)
        payload << "OFF|0|DISABLED|0";
    else if (player->GetClass() != CLASS_PALADIN ||
        player->GetTalentSpecialization() != SPEC_PALADIN_RETRIBUTION)
        payload << "OFF|0|UNSUPPORTED|0";
    else if (!player->IsAlive())
        payload << "WAIT|0|DEAD|" << player->GetPower(POWER_HOLY_POWER);
    else if (recommendation)
        payload << "READY|" << recommendation.SpellId << '|' << recommendation.Reason << '|'
            << player->GetPower(POWER_HOLY_POWER);
    else
        payload << "WAIT|0|NO_CAST|" << player->GetPower(POWER_HOLY_POWER);
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

        if (player->GetClass() != CLASS_PALADIN ||
            player->GetTalentSpecialization() != SPEC_PALADIN_RETRIBUTION)
        {
            handler->SendSysMessage("Combat Assistant prototype currently supports Retribution Paladin only.");
            PushRecommendation(player, true);
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
            handler->PSendSysMessage("Combat Assistant recommends spell %u (%s), Holy Power %u.",
                recommendation.SpellId, recommendation.Reason, player->GetPower(POWER_HOLY_POWER));
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
