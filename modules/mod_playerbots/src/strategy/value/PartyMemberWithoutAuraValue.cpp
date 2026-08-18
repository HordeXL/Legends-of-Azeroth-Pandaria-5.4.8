#include "PartyMemberWithoutAuraValue.h"

#include "Playerbots.h"
#include "Helper.h"

class PlayerWithoutAuraPredicate : public FindPlayerPredicate, public PlayerbotAIAware
{
public:
    PlayerWithoutAuraPredicate(PlayerbotAI* botAI, std::string const aura)
        : PlayerbotAIAware(botAI), FindPlayerPredicate(), spellGroup(SPELL_GROUP_NONE), playersOnly(false)
    {
        static std::string const playerSpellGroupPrefix = "player spell group:";
        if (aura.compare(0, playerSpellGroupPrefix.length(), playerSpellGroupPrefix) == 0)
        {
            spellGroup = static_cast<SpellGroup>(atoi(aura.substr(playerSpellGroupPrefix.length()).c_str()));
            playersOnly = true;
        }
        else
            auras = split(aura, ',');
    }

public:
    bool Check(Unit* unit) override
    {
        if (!unit->IsAlive())
            return false;

        // Raid-wide player buffs already propagate to controlled pets.  Do
        // not repeatedly target a pet which does not retain the visible aura.
        if (playersOnly && !unit->ToPlayer())
            return false;

        if (spellGroup != SPELL_GROUP_NONE)
        {
            for (auto const& auraPair : unit->GetAppliedAuras())
            {
                AuraApplication const* application = auraPair.second;
                Aura const* aura = application ? application->GetBase() : nullptr;
                if (aura && sSpellMgr->IsSpellMemberOfSpellGroup(aura->GetId(), spellGroup))
                    return false;
            }

            return true;
        }

        for (std::vector<std::string>::iterator i = auras.begin(); i != auras.end(); ++i)
        {
            if (botAI->HasAura(*i, unit))
                return false;
        }

        return true;
    }

private:
    std::vector<std::string> auras;
    SpellGroup spellGroup;
    bool playersOnly;
};

Unit* PartyMemberWithoutAuraValue::Calculate()
{
    PlayerWithoutAuraPredicate predicate(botAI, qualifier);
    return FindPartyMember(predicate);
}
