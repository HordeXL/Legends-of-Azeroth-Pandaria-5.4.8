#ifndef _PLAYERBOT_PVE_ROTATION_TRIGGER_CONTEXT_H
#define _PLAYERBOT_PVE_ROTATION_TRIGGER_CONTEXT_H

#include "Playerbots.h"
#include "GenericTriggers.h"
#include "HealthTriggers.h"
#include "PlayerBotSpec.h"
#include "PveDispelAction.h"
#include "PveWeaponImbueAction.h"

class PveDispelTrigger : public Trigger
{
public:
    PveDispelTrigger(PlayerbotAI* ai, uint32 type) : Trigger(ai, "pve dispel", 1), type(type) {}
    bool IsActive() override
    {
        if (!botAI->IsGroupPveActivity()) return false;
        auto info = GetPveDispelSpell(bot);
        return (info.types & (1u << type)) && bot->HasSpell(info.id) &&
            AI_VALUE2(Unit*, "party member to dispel", std::to_string(type));
    }
private:
    uint32 type;
};

class PveWeaponImbueTrigger : public Trigger
{
public:
    PveWeaponImbueTrigger(PlayerbotAI* ai, uint8 slot) : Trigger(ai, "pve weapon imbue", 5), slot(slot) {}
    bool IsActive() override
    {
        return NeedsPveShamanImbue(botAI, slot);
    }
private:
    uint8 slot;
};

class PveHunterAspectTrigger : public Trigger
{
public:
    PveHunterAspectTrigger(PlayerbotAI* ai) : Trigger(ai, "pve hunter aspect", 5) {}
    bool IsActive() override
    {
        uint32 id = bot->HasSpell(109260) ? 109260 : 13165;
        return botAI->IsGroupPveActivity() && bot->HasSpell(id) && !bot->HasAura(id);
    }
};

class PveShamanShieldTrigger : public Trigger
{
public:
    PveShamanShieldTrigger(PlayerbotAI* ai, uint32 spell) : Trigger(ai, "pve shaman shield", 1), spell(spell) {}
    bool IsActive() override
    {
        uint32 desired = bot->GetSpecialization() == SPEC_SHAMAN_RESTORATION ? 52127 : 324;
        return botAI->IsGroupPveActivity() && spell == desired && bot->HasSpell(spell) && !bot->HasAura(spell);
    }
private:
    uint32 spell;
};

// Only restore audited MoP conditions. Do not enable legacy PvP interrupts,
// fears, obsolete buffs or the old 'aoe heal' value (which is not registered).
template<class T> class GroupPveTrigger : public T
{
public:
    template<class... Args> GroupPveTrigger(PlayerbotAI* ai, Args&&... args)
        : T(ai, std::forward<Args>(args)...) {}
    bool IsActive() override
    {
        return this->botAI->IsGroupPveActivity() && T::IsActive();
    }
};

class PveInjuredGroupTrigger : public Trigger
{
public:
    PveInjuredGroupTrigger(PlayerbotAI* ai, uint8 health)
        : Trigger(ai, "pve injured group", 1), health(health) {}
    bool IsActive() override
    {
        if (!botAI->IsGroupPveActivity() || !PlayerBotSpec::IsHeal(bot, true))
            return false;
        Group* group = bot->GetGroup(GroupSlot::Instance);
        if (!group) group = bot->GetGroup();
        if (!group) return false;
        uint32 injured = 0;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (member && member->IsAlive() && member->IsInWorld() &&
                member->GetMap() == bot->GetMap() && bot->IsWithinDistInMap(member, 30.0f) &&
                bot->IsWithinLOSInMap(member) && member->GetHealthPct() < health && ++injured >= 3)
                return true;
        }
        return false;
    }
private:
    uint8 health;
};

class PveSpellStateTrigger : public Trigger
{
public:
    enum State { MissingSelf, MissingDot, Proc, Ready, LunarFiller, SolarFiller,
        FeralBuild, FeralRip, FeralBite, FeralRoar, Combustion, Maelstrom, Stagger, CombatCleave };
    PveSpellStateTrigger(PlayerbotAI* ai, uint32 spell, State state, uint32 aura = 0)
        : Trigger(ai, "pve spell state", 1), spell(spell), state(state), aura(aura ? aura : spell) {}
    bool IsActive() override
    {
        if (!botAI->IsGroupPveActivity() || !bot->IsAlive() || !bot->HasSpell(spell))
            return false;
        if (state == MissingSelf)
            return (spell != 62606 || bot->IsInCombat()) && !bot->HasAura(aura);
        if (state == Stagger)
            return bot->HasAura(124274) || bot->HasAura(124273);
        if (state == CombatCleave)
        {
            LightAoeTrigger pack(botAI);
            if (!pack.IsActive())
            {
                botAI->RemoveAura("blade flurry");
                return false;
            }
            return !bot->HasAura(aura);
        }
        Unit* target = AI_VALUE(Unit*, "current target");
        if (!target || !target->IsAlive() || !bot->IsInCombat() ||
            !bot->IsValidAttackTarget(target) || !botAI->CanLfgAutoQueueEngage(target))
            return false;
        Aura* dot = target->GetAura(aura, bot->GetGUID());
        uint8 const points = bot->GetComboTarget() == target ? bot->GetComboPoints() : 0;
        switch (state)
        {
            case MissingDot: return !dot || (dot->GetDuration() >= 0 && dot->GetDuration() < 2000);
            case Proc: return bot->HasAura(aura);
            case Ready: return true; // Action still checks cooldown, resources and range.
            // Solar marker permits positive energy from Starfire; lunar marker
            // permits negative energy from Wrath (spell_druid.cpp).
            case LunarFiller: return bot->HasAura(67483);
            case SolarFiller: return !bot->HasAura(67483);
            case FeralBuild: return points < 5;
            case FeralRip: return points >= 5 && (!dot || dot->GetDuration() < 2000);
            case FeralBite: return points >= 5 && dot && dot->GetDuration() > 4000 && bot->HasAura(52610);
            case FeralRoar: return points > 0 && !bot->HasAura(52610);
            case Combustion: return target->HasAura(12654, bot->GetGUID()) &&
                target->HasAura(11366, bot->GetGUID()) && !dot;
            case Maelstrom:
                if (Aura* proc = bot->GetAura(53817)) return proc->GetStackAmount() >= 5;
                return false;
            default: return false;
        }
    }
private:
    uint32 spell;
    State state;
    uint32 aura;
};

class PveRotationTriggerContext : public NamedObjectContext<Trigger>
{
public:
    PveRotationTriggerContext()
    {
        creators["pve dispel magic"] = [](PlayerbotAI* ai) -> Trigger* { return new PveDispelTrigger(ai, DISPEL_MAGIC); };
        creators["pve dispel curse"] = [](PlayerbotAI* ai) -> Trigger* { return new PveDispelTrigger(ai, DISPEL_CURSE); };
        creators["pve dispel poison"] = [](PlayerbotAI* ai) -> Trigger* { return new PveDispelTrigger(ai, DISPEL_POISON); };
        creators["pve dispel disease"] = [](PlayerbotAI* ai) -> Trigger* { return new PveDispelTrigger(ai, DISPEL_DISEASE); };
        creators["main hand weapon no imbue"] = [](PlayerbotAI* ai) -> Trigger* { return new PveWeaponImbueTrigger(ai, EQUIPMENT_SLOT_MAINHAND); };
        creators["off hand weapon no imbue"] = [](PlayerbotAI* ai) -> Trigger* { return new PveWeaponImbueTrigger(ai, EQUIPMENT_SLOT_OFFHAND); };
        creators["pve medium aoe"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<MediumAoeTrigger>(ai); };
        creators["pve hunter aspect"] = [](PlayerbotAI* ai) -> Trigger* { return new PveHunterAspectTrigger(ai); };
        creators["group heal setting"] = [](PlayerbotAI* ai) -> Trigger* { return new PveInjuredGroupTrigger(ai, 85); };
        creators["medium group heal setting"] = [](PlayerbotAI* ai) -> Trigger* { return new PveInjuredGroupTrigger(ai, 65); };
        creators["party member dead"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<PartyMemberDeadTrigger>(ai); };
        creators["combat party member dead"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<CombatPartyMemberDeadTrigger>(ai); };
        creators["beacon of light on main tank"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<BuffOnMainTankTrigger>(ai, "beacon of light", true); };
        creators["earth shield on main tank"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<BuffOnMainTankTrigger>(ai, "earth shield", false); };
        creators["sacred shield on main tank"] = [](PlayerbotAI* ai) -> Trigger* { return new GroupPveTrigger<BuffOnMainTankTrigger>(ai, "sacred shield", true); };
        creators["pve combustion"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 11129, PveSpellStateTrigger::Combustion); };
        creators["pve lunar filler"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 2912, PveSpellStateTrigger::LunarFiller); };
        creators["pve solar filler"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 5176, PveSpellStateTrigger::SolarFiller); };
        creators["pve feral build"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 5221, PveSpellStateTrigger::FeralBuild); };
        creators["pve feral rip"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 1079, PveSpellStateTrigger::FeralRip); };
        creators["pve feral bite"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 22568, PveSpellStateTrigger::FeralBite, 1079); };
        creators["pve feral roar"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 52610, PveSpellStateTrigger::FeralRoar); };
        creators["pve maelstrom five"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 403, PveSpellStateTrigger::Maelstrom); };
        creators["pve crows"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 131894, PveSpellStateTrigger::Ready); };
        creators["pve glaive toss"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 117050, PveSpellStateTrigger::Ready); };
        creators["pve execution sentence"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 114157, PveSpellStateTrigger::Ready); };
        creators["pve cascade"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 121135, PveSpellStateTrigger::Ready); };
        creators["pve chi wave"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 115098, PveSpellStateTrigger::Ready); };
        creators["pve xuen"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 123904, PveSpellStateTrigger::Ready); };
        creators["fire elemental totem"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 2894, PveSpellStateTrigger::Ready); };
        creators["icy touch"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 45477, PveSpellStateTrigger::MissingDot, 55095); };
        creators["plague strike"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 45462, PveSpellStateTrigger::MissingDot, 55078); };
        creators["freezing fog"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 49184, PveSpellStateTrigger::Proc, 59052); };
        creators["bone shield"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 49222, PveSpellStateTrigger::MissingSelf); };
        creators["righteous fury"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 25780, PveSpellStateTrigger::MissingSelf); };
        creators["pve savage defense"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 62606, PveSpellStateTrigger::MissingSelf, 132402); };
        creators["rake"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 1822, PveSpellStateTrigger::MissingDot); };
        creators["moonfire"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 8921, PveSpellStateTrigger::MissingDot); };
        creators["sunfire"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 93402, PveSpellStateTrigger::MissingDot); };
        creators["pve purify stagger"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 119582, PveSpellStateTrigger::Stagger); };
        creators["pve tiger power"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 100787, PveSpellStateTrigger::MissingSelf, 125359); };
        creators["blade flurry"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 13877, PveSpellStateTrigger::CombatCleave); };
        creators["cat form"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 768, PveSpellStateTrigger::MissingSelf); };
        creators["bear form"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 5487, PveSpellStateTrigger::MissingSelf); };
        creators["flame shock"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 8050, PveSpellStateTrigger::MissingDot); };
        creators["lightning shield"] = [](PlayerbotAI* ai) -> Trigger* { return new PveShamanShieldTrigger(ai, 324); };
        creators["water shield"] = [](PlayerbotAI* ai) -> Trigger* { return new PveShamanShieldTrigger(ai, 52127); };
        creators["no stings"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 1978, PveSpellStateTrigger::MissingDot); };
        creators["black arrow"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 3674, PveSpellStateTrigger::MissingDot); };
        creators["rapid fire"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 3045, PveSpellStateTrigger::Ready); };
        creators["adrenaline rush"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 13750, PveSpellStateTrigger::Ready); };
        creators["avenging wrath"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 31884, PveSpellStateTrigger::Ready); };
        creators["shadowfiend"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 34433, PveSpellStateTrigger::Ready); };
        creators["inner fire"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 588, PveSpellStateTrigger::MissingSelf); };
        creators["berserk"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 50334, PveSpellStateTrigger::Ready); };
        creators["pve searing totem"] = [](PlayerbotAI* ai) -> Trigger* { return new PveSpellStateTrigger(ai, 3599, PveSpellStateTrigger::Ready); };
    }
};
#endif
