#include "SpellIdValue.h"

#include "Playerbots.h"
#include "Vehicle.h"
#include "World.h"

SpellIdValue::SpellIdValue(PlayerbotAI* botAI) : CalculatedValue<uint32>(botAI, "spell id", 20 * 1000) {}

VehicleSpellIdValue::VehicleSpellIdValue(PlayerbotAI* botAI) : CalculatedValue<uint32>(botAI, "vehicle spell id")
{
}

uint32 SpellIdValue::Calculate()
{
    std::string namepart = qualifier;
    // Strategy/action labels inherited from older cores are not always the
    // actual English spellbook names in the shipped 5.4.8 DBC. Resolve only
    // real renames here; the learned/active spell checks below still apply.
    static std::map<std::string, std::string> const mopSpellNames = {
        {"anti magic shell", "anti-magic shell"},
        {"anti magic zone", "anti-magic zone"},
        {"mangle (cat)", "mangle"}, {"mangle (bear)", "mangle"},
        {"swipe (cat)", "swipe"}, {"swipe (bear)", "swipe"},
        {"faerie fire (feral)", "faerie fire"},
        {"judgement", "judgment"},
        {"shield of righteousness", "shield of the righteous"},
        {"hand of reckoning", "reckoning"},
        {"hand of guldan", "hand of gul'dan"},
        {"dragonroar", "dragon roar"},
        {"remove lesser curse", "remove curse"}
    };
    if (auto const alias = mopSpellNames.find(namepart); alias != mopSpellNames.end())
        namepart = alias->second;
    if (namepart == "aspect of the hawk" && bot->HasSpell(109260))
        namepart = "aspect of the iron hawk";
    if (namepart.empty())
        return 0;
    //ItemIds itemIds = ChatHelper::parseItems(namepart);

    PlayerbotChatHandler handler(bot);
    uint32 extractedSpellId = handler.extractSpellId(namepart);
    if (extractedSpellId)
        if (SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(extractedSpellId))
            namepart = spellInfo->SpellName[0];

    std::wstring wnamepart;
    if (!Utf8toWStr(namepart, wnamepart))
    {
        TC_LOG_ERROR("playerbots", "Utf8 to WStr failed on Calculate SpellIdValue");
        return 0;
    }

    wstrToLower(wnamepart);
    char firstSymbol = tolower(namepart[0]);
    int spellLength = wnamepart.length();

    LocaleConstant loc = LOCALE_enUS;

    std::set<uint32> spellIds;
    for (PlayerSpellMap::iterator itr = bot->GetSpellMap().begin(); itr != bot->GetSpellMap().end(); ++itr)
    {
        uint32 spellId = itr->first;

        if (itr->second->state == PLAYERSPELL_REMOVED || !itr->second->active)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo || spellInfo->IsPassive())
            continue;

        // Cat and bear abilities share names in MoP. Picking the lowest ID
        // alone can select a wrong-form ability and fail every cast.
        if (botAI->IsGroupPveActivity() && bot->GetClass() == CLASS_DRUID &&
            (namepart == "mangle" || namepart == "swipe" || namepart == "thrash"))
        {
            uint32 form = bot->GetSpecialization() == SPEC_DRUID_GUARDIAN ? FORM_BEAR : FORM_CAT;
            if (spellInfo->CheckShapeshift(form) != SPELL_CAST_OK) continue;
        }

        if (spellInfo->Effects[0].Effect == SPELL_EFFECT_LEARN_SPELL)
            continue;

        bool useByItem = false;
        /*for (uint8 i = 0; i < 3; ++i)
        {
            if (spellInfo->Effects[i].Effect == SPELL_EFFECT_CREATE_ITEM &&
                itemIds.find(spellInfo->Effects[i].ItemType) != itemIds.end())
            {
                useByItem = true;
                break;
            }
        }*/

        char const* spellName = spellInfo->SpellName[loc];
        if (!useByItem && (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||
            !Utf8FitTo(spellName, wnamepart)))
            continue;

        spellIds.insert(spellId);
    }

    Pet* pet = bot->GetPet();
    if (spellIds.empty() && pet)
    {
        for (PetSpellMap::const_iterator itr = pet->m_spells.begin(); itr != pet->m_spells.end(); ++itr)
        {
            if (itr->second.state == PETSPELL_REMOVED)
                continue;

            uint32 spellId = itr->first;
            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
            if (!spellInfo)
                continue;

            if (spellInfo->Effects[0].Effect == SPELL_EFFECT_LEARN_SPELL)
                continue;

            char const* spellName = spellInfo->SpellName[loc];
            if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||
                !Utf8FitTo(spellName, wnamepart))
                continue;

            spellIds.insert(spellId);
        }
    }

    if (spellIds.empty())
        return 0;


    uint32 castSpellId = 0;
    for (auto it = spellIds.rbegin(); it != spellIds.rend(); ++it)
    {
        auto spellId = *it;
        const SpellInfo* pSpellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!pSpellInfo)
            continue;

        std::string spellName = pSpellInfo->Rank[0];

        // For atoi, the input string has to start with a digit, so lets search for the first digit
        size_t i = 0;
        for (; i < spellName.length(); i++)
        {
            if (isdigit(spellName[i]))
                break;
        }

        // remove the first chars, which aren't digits
        spellName = spellName.substr(i, spellName.length() - i);

        // convert the remaining text to an integer
        int id = atoi(spellName.c_str());

        if (!id)
        {
            castSpellId = spellId;
            continue;
        }

    }

    return castSpellId;
}

uint32 VehicleSpellIdValue::Calculate()
{
    /*Vehicle* vehicle = bot->GetVehicle();
    if (!vehicle)
        return 0;

    // do not allow if no spells
    VehicleSeatEntry const* seat = vehicle->GetSeatForPassenger(bot);
    if (!seat || !(seat->m_flags & VEHICLE_SEAT_FLAG_CAN_CAST))
        return 0;

    Unit* vehicleBase = vehicle->GetBase();
    if (!vehicleBase->IsAlive())
        return 0;

    std::string namepart = qualifier;

    PlayerbotChatHandler handler(bot);
    uint32 extractedSpellId = handler.extractSpellId(namepart);
    if (extractedSpellId)
        if (SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(extractedSpellId))
            namepart = spellInfo->SpellName[0];

    std::wstring wnamepart;
    if (!Utf8toWStr(namepart, wnamepart))
        return 0;

    wstrToLower(wnamepart);
    char firstSymbol = tolower(namepart[0]);
    int spellLength = wnamepart.length();

    const int loc = LocaleConstant::LOCALE_enUS;

    Creature* creature = vehicleBase->ToCreature();
    for (uint32 x = 0; x < MAX_CREATURE_SPELLS; ++x)
    {
        uint32 spellId = creature->m_spells[x];
        if (spellId == 2)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo || spellInfo->IsPassive())
            continue;

        char const* spellName = spellInfo->SpellName[loc];
        if (tolower(spellName[0]) != firstSymbol || strlen(spellName) != spellLength ||
            !Utf8FitTo(spellName, wnamepart))
            continue;

        return spellId;
    }*/

    return 0;
}
