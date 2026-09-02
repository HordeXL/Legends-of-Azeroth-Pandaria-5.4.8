#include "RandomItemManager.h"

#include "Player.h"
#include "PlayerbotSpec.h"

#include <bitset>
#include <map>
#include <tuple>

RandomItemManager::RandomItemManager()
{

}
RandomItemManager::~RandomItemManager()
{

}

// Cheat class copy to hack into the loot system
class LootTemplateAccess
{
public:
    class LootGroup;  // A set of loot definitions for items (refs are not allowed inside)
    typedef std::vector<LootGroup> LootGroups;
    LootStoreItemList Entries;  // not grouped only
    LootGroups Groups;          // groups have own (optimized) processing, grouped entries go there
};

std::vector<uint32> RandomItemManager::GetCachedEquipments(uint32 requiredLevel, uint32 inventoryType)
{
    return _equipCacheNew[requiredLevel][inventoryType];
}

void RandomItemManager::Init()
{
    _viable_slots[EQUIPMENT_SLOT_HEAD].insert(INVTYPE_HEAD);
    _viable_slots[EQUIPMENT_SLOT_NECK].insert(INVTYPE_NECK);
    _viable_slots[EQUIPMENT_SLOT_SHOULDERS].insert(INVTYPE_SHOULDERS);
    _viable_slots[EQUIPMENT_SLOT_BODY].insert(INVTYPE_BODY);
    _viable_slots[EQUIPMENT_SLOT_CHEST].insert(INVTYPE_CHEST);
    _viable_slots[EQUIPMENT_SLOT_CHEST].insert(INVTYPE_ROBE);
    _viable_slots[EQUIPMENT_SLOT_WAIST].insert(INVTYPE_WAIST);
    _viable_slots[EQUIPMENT_SLOT_LEGS].insert(INVTYPE_LEGS);
    _viable_slots[EQUIPMENT_SLOT_FEET].insert(INVTYPE_FEET);
    _viable_slots[EQUIPMENT_SLOT_WRISTS].insert(INVTYPE_WRISTS);
    _viable_slots[EQUIPMENT_SLOT_HANDS].insert(INVTYPE_HANDS);
    _viable_slots[EQUIPMENT_SLOT_FINGER1].insert(INVTYPE_FINGER);
    _viable_slots[EQUIPMENT_SLOT_FINGER2].insert(INVTYPE_FINGER);
    _viable_slots[EQUIPMENT_SLOT_TRINKET1].insert(INVTYPE_TRINKET);
    _viable_slots[EQUIPMENT_SLOT_TRINKET2].insert(INVTYPE_TRINKET);
    _viable_slots[EQUIPMENT_SLOT_MAINHAND].insert(INVTYPE_WEAPON);
    _viable_slots[EQUIPMENT_SLOT_MAINHAND].insert(INVTYPE_2HWEAPON);
    _viable_slots[EQUIPMENT_SLOT_MAINHAND].insert(INVTYPE_WEAPONMAINHAND);
    _viable_slots[EQUIPMENT_SLOT_MAINHAND].insert(INVTYPE_RANGED);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_WEAPON);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_2HWEAPON);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_WEAPONOFFHAND);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_SHIELD);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_WEAPONMAINHAND);
    _viable_slots[EQUIPMENT_SLOT_OFFHAND].insert(INVTYPE_HOLDABLE);
    _viable_slots[EQUIPMENT_SLOT_TABARD].insert(INVTYPE_TABARD);
    _viable_slots[EQUIPMENT_SLOT_BACK].insert(INVTYPE_CLOAK);

    TC_LOG_INFO("playerbots", "Loading equipments cache...");

    std::unordered_set<uint32> questItemIds;
    ObjectMgr::QuestMap const& questTemplates = sObjectMgr->GetQuestTemplates();
    for (ObjectMgr::QuestMap::const_iterator i = questTemplates.begin(); i != questTemplates.end(); ++i)
    {
        uint32 questId = i->first;
        Quest const* quest = i->second;

        if (quest->IsRepeatable())
            continue;

        if (quest->GetQuestLevel() <= 0)
            continue;

        if (quest->GetAllowableClasses())
            continue;

        for (int j = 0; j < quest->GetRewChoiceItemsCount(); j++)
            if (uint32 itemId = quest->RewardChoiceItemId[j])
            {
                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
                if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
                    continue;
                int requiredLevel = std::max((int)proto->RequiredLevel, quest->GetQuestLevel());
                _equipCacheNew[requiredLevel][proto->InventoryType].push_back(itemId);
                questItemIds.insert(itemId);
            }

        for (int j = 0; j < quest->GetRewItemsCount(); j++)
            if (uint32 itemId = quest->RewardItemId[j])
            {
                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
                if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
                    continue;
                int requiredLevel = std::max((int)proto->RequiredLevel, quest->GetQuestLevel());
                _equipCacheNew[requiredLevel][proto->InventoryType].push_back(itemId);
                questItemIds.insert(itemId);
            }
    }

    ItemTemplateContainer const* itemTemplates = sObjectMgr->GetItemTemplateStore();
    for (auto const& itr : *itemTemplates)
    {
        ItemTemplate const* proto = &itr.second;
        if (!proto)
            continue;
        uint32 itemId = proto->ItemId;

        if (questItemIds.find(itemId) != questItemIds.end())
            continue;

        // skip test items
        if (strstr(proto->Name1.c_str(), "(Test)") || strstr(proto->Name1.c_str(), "(TEST)") ||
            strstr(proto->Name1.c_str(), "(test)") || strstr(proto->Name1.c_str(), "(JEFFTEST)") ||
            strstr(proto->Name1.c_str(), "Test ") || strstr(proto->Name1.c_str(), "Test") ||
            strstr(proto->Name1.c_str(), "TEST") || strstr(proto->Name1.c_str(), "TEST ") ||
            strstr(proto->Name1.c_str(), " TEST") || strstr(proto->Name1.c_str(), "2200 ") ||
            strstr(proto->Name1.c_str(), "Deprecated ") || strstr(proto->Name1.c_str(), "Unused ") ||
            strstr(proto->Name1.c_str(), "Monster ") || strstr(proto->Name1.c_str(), "[PH]") ||
            strstr(proto->Name1.c_str(), "(OLD)") || strstr(proto->Name1.c_str(), "QR") ||
            strstr(proto->Name1.c_str(), "zzOLD"))
        {
            _itemForTest.insert(proto->ItemId);
            continue;
        }

        if (proto->Flags & ITEM_PROTO_FLAG_DEPRECATED)
        {
            _itemForTest.insert(proto->ItemId);
            continue;
        }

        if (itemId == 22784)
        {  // Sunwell Orb
            continue;
        }
        _equipCacheNew[proto->RequiredLevel][proto->InventoryType].push_back(itemId);
    }
}

void RandomItemManager::AddItemStats(uint32 mod, uint8& sp, uint8& ap, uint8& tank)
{
    switch (mod)
    {
        case ITEM_MOD_HEALTH:
        case ITEM_MOD_STAMINA:
        case ITEM_MOD_MANA:
        case ITEM_MOD_INTELLECT:
        case ITEM_MOD_SPIRIT:
            ++sp;
            break;
    }

    switch (mod)
    {
        case ITEM_MOD_AGILITY:
        case ITEM_MOD_STRENGTH:
        case ITEM_MOD_HEALTH:
        case ITEM_MOD_STAMINA:
            ++tank;
            break;
    }

    switch (mod)
    {
        case ITEM_MOD_HEALTH:
        case ITEM_MOD_STAMINA:
        case ITEM_MOD_AGILITY:
        case ITEM_MOD_STRENGTH:
            ++ap;
            break;
    }
}

bool RandomItemManager::CheckItemStats(Classes clazz, uint8 sp, uint8 ap, uint8 tank)
{
    switch (clazz)
    {
        case CLASS_PRIEST:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
            if (!sp || ap > sp || tank > sp)
                return false;
            break;
        case CLASS_PALADIN:
        case CLASS_WARRIOR:
            if ((!ap && !tank) || sp > ap || sp > tank)
                return false;
            break;
        case CLASS_HUNTER:
        case CLASS_ROGUE:
        case CLASS_MONK:
            if (!ap || sp > ap || sp > tank)
                return false;
            break;
    }

    return sp || ap || tank;
}

bool RandomItemManager::ShouldEquipArmorForSpec(uint32 level, Classes playerclass, Specializations spec, ItemTemplate const* proto)
{
    if (proto->InventoryType == INVTYPE_TABARD)
        return true;

    std::unordered_set<uint32> resultArmorSubClass;
    switch (playerclass)
    {
        case CLASS_WARRIOR:
        {
            if (proto->InventoryType == INVTYPE_HOLDABLE)
                return false;

            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_PLATE };
            if (level < 40)
                resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_LEATHER, ITEM_SUBCLASS_ARMOR_MAIL, ITEM_SUBCLASS_ARMOR_PLATE };
            break;
        }
        case CLASS_DEATH_KNIGHT:
        {
            if (proto->InventoryType == INVTYPE_HOLDABLE)
                return false;

            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_PLATE };
            break;
        }
        case CLASS_PALADIN:
        {
            if (spec == Specializations::SPEC_PALADIN_HOLY && proto->InventoryType == INVTYPE_HOLDABLE)
                return false;

            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_PLATE };
            if (level < 40)
                resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_LEATHER, ITEM_SUBCLASS_ARMOR_MAIL, ITEM_SUBCLASS_ARMOR_PLATE };

            break;
        }
        case CLASS_HUNTER:
        {
            if (proto->InventoryType == INVTYPE_HOLDABLE)
                return false;

            resultArmorSubClass = level < 40 ?
                std::unordered_set<uint32>{ ITEM_SUBCLASS_ARMOR_LEATHER,
                    ITEM_SUBCLASS_ARMOR_MAIL } :
                std::unordered_set<uint32>{ ITEM_SUBCLASS_ARMOR_MAIL };
            break;
        }
        case CLASS_ROGUE:
        {
            if (proto->InventoryType == INVTYPE_HOLDABLE)
                return false;
            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_LEATHER };
            break;
        }
        case CLASS_SHAMAN:
        {
            if (spec == Specializations::SPEC_SHAMAN_ENHANCEMENT && proto->InventoryType == INVTYPE_HOLDABLE)
                return false;
            resultArmorSubClass = level < 40 ?
                std::unordered_set<uint32>{ ITEM_SUBCLASS_ARMOR_CLOTH,
                    ITEM_SUBCLASS_ARMOR_LEATHER, ITEM_SUBCLASS_ARMOR_MAIL } :
                std::unordered_set<uint32>{ ITEM_SUBCLASS_ARMOR_MAIL };

            break;
        }
        case CLASS_PRIEST:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        {
            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_CLOTH };
            break;
        }
        case CLASS_DRUID:
        {
            if ((spec == Specializations::SPEC_DRUID_FERAL || spec == Specializations::SPEC_DRUID_GUARDIAN) &&
                proto->InventoryType == INVTYPE_HOLDABLE)
                return false;
            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_LEATHER };

            break;
        }
        case CLASS_MONK:
        {
            if (proto->InventoryType == INVTYPE_HOLDABLE && spec != Specializations::SPEC_MONK_MISTWEAVER)
                return false;
            resultArmorSubClass = { ITEM_SUBCLASS_ARMOR_LEATHER };
            break;
        }
    }

    return (resultArmorSubClass.find(proto->SubClass) != resultArmorSubClass.end());
}

bool RandomItemManager::ShouldEquipWeaponForSpec(Classes playerclass,
    Specializations spec, EquipmentSlots slot, ItemTemplate const* proto) const
{
    if (slot != EQUIPMENT_SLOT_MAINHAND && slot != EQUIPMENT_SLOT_OFFHAND)
        return false;

    std::unordered_set<uint32> mh_weapons;
    std::unordered_set<uint32> oh_weapons;

    switch (playerclass)
    {
        case CLASS_WARRIOR:
        {
            if (spec == Specializations::SPEC_WARRIOR_PROTECTION)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE,
                              ITEM_SUBCLASS_WEAPON_DAGGER, ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_SHIELD };
            }
            else if (spec == Specializations::SPEC_WARRIOR_FURY)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE,
                              ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_FIST_WEAPON,
                              ITEM_SUBCLASS_WEAPON_SWORD2, ITEM_SUBCLASS_WEAPON_AXE2,
                              ITEM_SUBCLASS_WEAPON_MACE2 };
                oh_weapons = mh_weapons;
            }
            else
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD2, ITEM_SUBCLASS_WEAPON_AXE2, ITEM_SUBCLASS_WEAPON_MACE2,
                              ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_POLEARM };
            }
            break;
        }
        case CLASS_DEATH_KNIGHT:
        {
            if (spec == Specializations::SPEC_DEATH_KNIGHT_FROST)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE,
                              ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_SWORD2,
                              ITEM_SUBCLASS_WEAPON_AXE2, ITEM_SUBCLASS_WEAPON_MACE2,
                              ITEM_SUBCLASS_WEAPON_POLEARM };
                oh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE,
                              ITEM_SUBCLASS_WEAPON_MACE };
            }
            else
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD2, ITEM_SUBCLASS_WEAPON_AXE2,
                              ITEM_SUBCLASS_WEAPON_MACE2, ITEM_SUBCLASS_WEAPON_POLEARM };
            break;
        }
        case CLASS_PALADIN:
        {
            if (spec == Specializations::SPEC_PALADIN_PROTECTION)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_SHIELD };
            }
            else if (spec == Specializations::SPEC_PALADIN_HOLY)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_SHIELD };
            }
            else
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_SWORD2, ITEM_SUBCLASS_WEAPON_AXE2, ITEM_SUBCLASS_WEAPON_MACE2,
                              ITEM_SUBCLASS_WEAPON_POLEARM };
            }
            break;
        }
        case CLASS_HUNTER:
        {
            mh_weapons = { ITEM_SUBCLASS_WEAPON_BOW, ITEM_SUBCLASS_WEAPON_CROSSBOW, ITEM_SUBCLASS_WEAPON_GUN };
            break;
        }
        case CLASS_ROGUE:
        {
            if (spec == Specializations::SPEC_ROGUE_COMBAT)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_DAGGER, ITEM_SUBCLASS_WEAPON_SWORD,
                              ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE,
                              ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
                oh_weapons = mh_weapons;
            }
            else
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_DAGGER };
                oh_weapons = { ITEM_SUBCLASS_WEAPON_DAGGER };
            }
            break;
        }
        case CLASS_PRIEST:
        {
            mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER,
                          ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_WAND };
            oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS };
            break;
        }
        case CLASS_SHAMAN:
        {
            if (spec == Specializations::SPEC_SHAMAN_RESTORATION)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER,
                              ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE,
                              ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS, ITEM_SUBCLASS_ARMOR_SHIELD };
            }
            else if (spec == Specializations::SPEC_SHAMAN_ENHANCEMENT)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE,
                              ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
                oh_weapons = mh_weapons;
            }
            else
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER,
                              ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_MACE,
                              ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS,
                              ITEM_SUBCLASS_ARMOR_SHIELD };
            }
            break;
        }
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        {
            mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER,
                          ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_WAND };
            oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS };
            break;
        }
        case CLASS_DRUID:
        {
            if (spec == Specializations::SPEC_DRUID_GUARDIAN)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_MACE2,
                              ITEM_SUBCLASS_WEAPON_POLEARM };
            }
            else if (spec == Specializations::SPEC_DRUID_RESTORATION)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER, ITEM_SUBCLASS_WEAPON_FIST_WEAPON,
                              ITEM_SUBCLASS_WEAPON_MACE };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS };
            }
            else if (spec == Specializations::SPEC_DRUID_FERAL)
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_MACE2,
                              ITEM_SUBCLASS_WEAPON_POLEARM };
            }
            else
            {
                mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_DAGGER,
                              ITEM_SUBCLASS_WEAPON_MACE };
                oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS };
            }
            break;
        }
        case CLASS_MONK:
        {
            mh_weapons = { ITEM_SUBCLASS_WEAPON_STAFF, ITEM_SUBCLASS_WEAPON_POLEARM,
                          ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_SWORD,
                          ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
            if (spec == Specializations::SPEC_MONK_MISTWEAVER)
                oh_weapons = { ITEM_SUBCLASS_ARMOR_MISCELLANEOUS };
            else
                oh_weapons = { ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_SWORD,
                              ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_FIST_WEAPON };
            break;
        }
    }

    if (slot == EQUIPMENT_SLOT_MAINHAND &&
        mh_weapons.find(proto->SubClass) != mh_weapons.end())
        return true;

    if (slot == EQUIPMENT_SLOT_OFFHAND &&
        oh_weapons.find(proto->SubClass) != oh_weapons.end())
        return true;

    return false;
}

/*
* stat_comb
* 108 armor / agi / stam / dodge / parry
* 105 armor / stam / stren / dodge / parry
* 104 armor / stam / dodge / expert / parry
* 96 armor / dodge / parry
* 77 armor / stren / agi / stam / parry
* 76 armor / stam / agi / parry
* 73 armor / stren / stam / parry
* 72 armor / stam / parry
* 65 armor / stren / parry
* 64 armor / parry / fire resi / heal.s / dodge / parry
* 58 armor / stam / intell / spirit / dodge
* 56 armor / starm / spirit / dodge
* 48 armor / spirit / dodge
* 46 armor / stam / intell / agi / hit / dodge
* 45 armor / agi / stren / stam / dodge / frost res
* 44 armor / stam / agi / dodge
* 42 armor / stam / intel / dodge / crit
* 41 armor / stren / stam / dodge / mastery
* 40 armor / stam / dodge / exprt
* 36 armor / agi / crit / dodge
* 33 armor / stren / dodge / crit
* 32 armor / dodge / health 
* 31 armor / stren / stam / intell / agi / spirit
* 28 armor / agi / stam / spirit / attack power
* 26 armor / intell / stam / spirit / crit
* 25 armor / stam / spirit / hit / pvp power / pvp resi / rage cost
* 24 armor / stam / spirit / spell power / haste
* 18 armor / spirit / intell / crit
* 16 armor / spirit / pvp power / pvp resi
* 14 armor / agi / intel / stam / hit
* 13 armor / stren / stam / agi / haste
* 12 armor / agi / stam / expert / crit / mastery
* 11 armor / stren / intell / stam 
* 10 armor / intell / stam / haste
* 9 armor / stren / stam / haste / mastery
* 8 armor / stam / crit / pvp resi / attack power / haste
* 6 armor / intell / agi / haste
* 5 armor / stren / agi / crit
* 4 armor / agi / hit / haste
* 3 armor / intell / stren (staff unique)
* 2 armor / intell / haste / 
* 1 armor / stren / mastery / crit / hit
* 0 any
*/

bool RandomItemManager::CanEquipItem(EquipmentSlots slot, ItemTemplate const* proto)
{
    if (proto->Duration & 0x80000000)
        return false;

    if (proto->Bonding == BIND_QUEST || proto->Bonding == BIND_ON_USE)
        return false;

    if (proto->Class == ITEM_CLASS_CONTAINER)
        return true;

    std::set<InventoryType> slots = _viable_slots[slot];
    if (slots.find((InventoryType)proto->InventoryType) == slots.end())
        return false;

    return true;
}

bool RandomItemManager::CanEquipSubArmor(Player* bot, ItemTemplate const* proto)
{
    Classes clazz = (Classes)bot->GetClass();
    Specializations spec = bot->GetSpecialization();

    if (proto->InventoryType != InventoryType::INVTYPE_SHIELD && proto->InventoryType != InventoryType::INVTYPE_HOLDABLE)
        return true;

    switch (clazz)
    {
        case CLASS_HUNTER:
        case CLASS_ROGUE:
        case CLASS_DEATH_KNIGHT:
        {
            return false;
        }
        case CLASS_PRIEST:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        {
            if (proto->SubClass == ITEM_SUBCLASS_ARMOR_MISCELLANEOUS)
                return true;
            return false;
        }
        case CLASS_WARRIOR:
        {
            if (spec == Specializations::SPEC_WARRIOR_PROTECTION && proto->SubClass == ITEM_SUBCLASS_ARMOR_SHIELD)
                return true;
            return false;
        }
        case CLASS_PALADIN:
        {
            if ((spec == Specializations::SPEC_PALADIN_PROTECTION ||
                spec == Specializations::SPEC_PALADIN_HOLY) &&
                proto->SubClass == ITEM_SUBCLASS_ARMOR_SHIELD)
                return true;
            return false;
        }
        case CLASS_SHAMAN:
        {
            if ((spec == Specializations::SPEC_SHAMAN_ELEMENTAL || spec == Specializations::SPEC_SHAMAN_RESTORATION)
                && (proto->SubClass == ITEM_SUBCLASS_ARMOR_SHIELD || proto->SubClass == ITEM_SUBCLASS_ARMOR_MISCELLANEOUS))
                return true;
            return false;
        }
        case CLASS_DRUID:
        {
            if ((spec == Specializations::SPEC_DRUID_BALANCE || spec == Specializations::SPEC_DRUID_RESTORATION)
                && proto->SubClass == ITEM_SUBCLASS_ARMOR_MISCELLANEOUS)
                return true;
            return false;
        }
        case CLASS_MONK:
        {
            if (spec == Specializations::SPEC_MONK_MISTWEAVER &&
                proto->SubClass == ITEM_SUBCLASS_ARMOR_MISCELLANEOUS)
                return true;
            return false;
        }
    }

    return false;
}

bool RandomItemManager::CanEquipArmor(Player* bot, ItemTemplate const* proto)
{
    Classes clazz = (Classes)bot->GetClass();
    uint32 level = (uint32)bot->GetLevel();

    if (proto->InventoryType == INVTYPE_TABARD)
        return true;

    if (!ShouldEquipArmorForSpec(level, clazz, bot->GetSpecialization(), proto))
        return false;

    return MatchesPrimaryStatForSpec(bot, proto);
}

bool RandomItemManager::CanEquipWeapon(Player* bot, ItemTemplate const* proto)
{
    Classes clazz = (Classes)bot->GetClass();
    uint32 level = (uint32)bot->GetLevel();

    switch (clazz)
    {
        case CLASS_PRIEST:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF && proto->SubClass != ITEM_SUBCLASS_WEAPON_WAND &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE && proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER)
                return false;
            break;
        case CLASS_MAGE:
        case CLASS_WARLOCK:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF && proto->SubClass != ITEM_SUBCLASS_WEAPON_WAND &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER && proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD)
                return false;
            break;
        case CLASS_WARRIOR:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE2 && proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_POLEARM && proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD2 &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE && proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE2 && proto->SubClass != ITEM_SUBCLASS_WEAPON_FIST_WEAPON &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER && proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF)
                return false;
            break;
        case CLASS_PALADIN:
        case CLASS_DEATH_KNIGHT:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE2 && proto->SubClass != ITEM_SUBCLASS_WEAPON_POLEARM &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD2 && proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE2 &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE && proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD)
                return false;
            break;
        case CLASS_SHAMAN:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE && proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_FIST_WEAPON && proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE2 &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE2 && proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF)
                return false;
            break;
        case CLASS_DRUID:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE && proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE2 &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER && proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_POLEARM)
                return false;
            break;
        case CLASS_HUNTER:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_BOW && proto->SubClass != ITEM_SUBCLASS_WEAPON_GUN &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_CROSSBOW)
                return false;
            break;
        case CLASS_ROGUE:
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER && proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_FIST_WEAPON && proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE)
                return false;
            break;
        case CLASS_MONK:
        {
            if (proto->SubClass != ITEM_SUBCLASS_WEAPON_AXE && proto->SubClass != ITEM_SUBCLASS_WEAPON_SWORD &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_STAFF && proto->SubClass != ITEM_SUBCLASS_WEAPON_MACE &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_FIST_WEAPON &&
                proto->SubClass != ITEM_SUBCLASS_WEAPON_POLEARM)
                return false;
            break;
        }
    }

    if (!ShouldEquipWeaponForSpec((Classes)bot->GetClass(),
            bot->GetSpecialization(), EQUIPMENT_SLOT_MAINHAND, proto) &&
        !ShouldEquipWeaponForSpec((Classes)bot->GetClass(),
            bot->GetSpecialization(), EQUIPMENT_SLOT_OFFHAND, proto))
        return false;

    return MatchesPrimaryStatForSpec(bot, proto);
}

bool RandomItemManager::SupportsOffhandForSpec(Player* bot) const
{
    switch (bot->GetSpecialization())
    {
        case SPEC_WARRIOR_FURY:
        case SPEC_WARRIOR_PROTECTION:
        case SPEC_PALADIN_HOLY:
        case SPEC_PALADIN_PROTECTION:
        case SPEC_DEATH_KNIGHT_FROST:
        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_ROGUE_COMBAT:
        case SPEC_ROGUE_SUBTLETY:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
        case SPEC_PRIEST_SHADOW:
        case SPEC_SHAMAN_ELEMENTAL:
        case SPEC_SHAMAN_ENHANCEMENT:
        case SPEC_SHAMAN_RESTORATION:
        case SPEC_MAGE_ARCANE:
        case SPEC_MAGE_FIRE:
        case SPEC_MAGE_FROST:
        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_WARLOCK_DESTRUCTION:
        case SPEC_DRUID_BALANCE:
        case SPEC_DRUID_RESTORATION:
        case SPEC_MONK_BREWMASTER:
        case SPEC_MONK_WINDWALKER:
        case SPEC_MONK_MISTWEAVER:
            return true;
        default:
            return false;
    }
}

bool RandomItemManager::NeedsOffhandForSpec(Player* bot) const
{
    if (!SupportsOffhandForSpec(bot))
        return false;

    // Fury's Titan's Grip/Single-Minded Fury design always uses two weapons,
    // including a second two-hander when the specialization permits it.
    if (bot->GetSpecialization() == SPEC_WARRIOR_FURY)
        return true;

    Item* mainHand = bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
        EQUIPMENT_SLOT_MAINHAND);
    if (!mainHand)
        return false;

    InventoryType type = InventoryType(mainHand->GetTemplate()->InventoryType);
    return type != INVTYPE_2HWEAPON && type != INVTYPE_RANGED;
}

bool RandomItemManager::IsItemValidForEquipmentSlot(Player* bot,
    EquipmentSlots slot, ItemTemplate const* proto)
{
    if (!bot || !proto || !CanEquipItem(slot, proto))
        return false;

    if (slot == EQUIPMENT_SLOT_MAINHAND || slot == EQUIPMENT_SLOT_OFFHAND)
    {
        if (!ShouldEquipWeaponForSpec((Classes)bot->GetClass(),
                bot->GetSpecialization(), slot, proto))
            return false;
        return MatchesPrimaryStatForSpec(bot, proto);
    }

    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD:
        case EQUIPMENT_SLOT_SHOULDERS:
        case EQUIPMENT_SLOT_CHEST:
        case EQUIPMENT_SLOT_WAIST:
        case EQUIPMENT_SLOT_LEGS:
        case EQUIPMENT_SLOT_FEET:
        case EQUIPMENT_SLOT_WRISTS:
        case EQUIPMENT_SLOT_HANDS:
            return CanEquipArmor(bot, proto);
        case EQUIPMENT_SLOT_BODY:
        case EQUIPMENT_SLOT_TABARD:
            return true;
        default:
            return MatchesPrimaryStatForSpec(bot, proto);
    }
}

// Définition des seuils de qualité avec une valeur de repli
static const std::map<uint32, std::tuple<ItemQualities, ItemQualities, uint32, uint32>> qualityRules =
{
    {1,   std::make_tuple(ItemQualities::ITEM_QUALITY_NORMAL,   ItemQualities::ITEM_QUALITY_POOR,       20, 5)},
    {10,  std::make_tuple(ItemQualities::ITEM_QUALITY_UNCOMMON, ItemQualities::ITEM_QUALITY_NORMAL,     20, 5)},
    {35,  std::make_tuple(ItemQualities::ITEM_QUALITY_RARE,     ItemQualities::ITEM_QUALITY_UNCOMMON,   30, 10)},
    {60,  std::make_tuple(ItemQualities::ITEM_QUALITY_EPIC,     ItemQualities::ITEM_QUALITY_RARE,       40, 15)},
    {61,  std::make_tuple(ItemQualities::ITEM_QUALITY_UNCOMMON, ItemQualities::ITEM_QUALITY_NORMAL,     20, 5)},
    {65,  std::make_tuple(ItemQualities::ITEM_QUALITY_RARE,     ItemQualities::ITEM_QUALITY_UNCOMMON,   30, 10)},
    {70,  std::make_tuple(ItemQualities::ITEM_QUALITY_EPIC,     ItemQualities::ITEM_QUALITY_RARE,       40, 15)},
    {71,  std::make_tuple(ItemQualities::ITEM_QUALITY_UNCOMMON, ItemQualities::ITEM_QUALITY_NORMAL,     20, 5)},
    {75,  std::make_tuple(ItemQualities::ITEM_QUALITY_RARE,     ItemQualities::ITEM_QUALITY_UNCOMMON,   30, 10)},
    {80,  std::make_tuple(ItemQualities::ITEM_QUALITY_EPIC,     ItemQualities::ITEM_QUALITY_RARE,       40, 15)},
    {81,  std::make_tuple(ItemQualities::ITEM_QUALITY_UNCOMMON, ItemQualities::ITEM_QUALITY_NORMAL,     20, 5)},
    {83,  std::make_tuple(ItemQualities::ITEM_QUALITY_RARE,     ItemQualities::ITEM_QUALITY_UNCOMMON,   30, 10)},
    {85,  std::make_tuple(ItemQualities::ITEM_QUALITY_EPIC,     ItemQualities::ITEM_QUALITY_RARE,       40, 15)},
    {86,  std::make_tuple(ItemQualities::ITEM_QUALITY_UNCOMMON, ItemQualities::ITEM_QUALITY_NORMAL,     20, 5)},
    {88,  std::make_tuple(ItemQualities::ITEM_QUALITY_RARE,     ItemQualities::ITEM_QUALITY_UNCOMMON,   30, 10)},
    {90,  std::make_tuple(ItemQualities::ITEM_QUALITY_EPIC,     ItemQualities::ITEM_QUALITY_RARE,       40, 15)}    
};

/*
* Know issues:
* Not always wear wearable (plate / mail etc)
* Hunt have incorrect weapon
* Random items stat not supposed to be assigned (ex shaman enhance with intellect spell power etc)
*/

bool RandomItemManager::IsCustomServerItem(uint32 itemId) const
{
    // The server shop/VIP equipment lives in this private high-entry range.
    // Its stats are valid server-side, but stock 5.4.8 clients do not reliably
    // have matching item appearances. Managed PvE/PvP fillers must therefore
    // use genuine client-known equipment.
    return itemId >= 990000u;
}

uint32 RandomItemManager::FindBestItemForLevelAndEquip(Player* bot,
    InventoryType invType, bool genuineItemsOnly)
{
    uint32 level = (uint32)bot->GetLevel();
    int32 delta = std::min(level, 10u);

    for (uint32 requiredLevel = bot->GetLevel(); requiredLevel > std::max((int32)bot->GetLevel() - delta, 0); requiredLevel--)
    {
        std::mt19937 gen(std::chrono::system_clock::now().time_since_epoch().count());
        auto& items = _equipCacheNew[requiredLevel][invType];
        std::shuffle(items.begin(), items.end(), gen);

        for (auto it = items.end(); it != items.begin(); )
        {
            --it;

            uint32 itemID = *it;

            if (IsTestItem(itemID)) continue;
            if (genuineItemsOnly && IsCustomServerItem(itemID)) continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemID);
            if (proto->RequiredLevel > level) continue;
            if ((proto->AllowableClass & bot->GetClassMask()) == 0 || (proto->AllowableRace & bot->GetRaceMask()) == 0) continue;
            if (level < 10 && proto->ItemLevel > 100) continue;

            // Item Quality
            {
                auto quality_iterator = qualityRules.upper_bound(bot->GetLevel());
                if (quality_iterator != qualityRules.begin()) --quality_iterator; // Récupérer la tranche correcte
                // Extraire les valeurs correspondantes
                ItemQualities minQuality = std::get<0>(quality_iterator->second);
                ItemQualities fallbackQuality = std::get<1>(quality_iterator->second); // Qualité inférieure en cas d'absence
                uint32 rareChance = std::get<2>(quality_iterator->second);
                uint32 uncommonChance = std::get<3>(quality_iterator->second);
                // Vérification de la qualité de l'objet
                if (proto->Quality >= minQuality) {
                    // Accepter immédiatement l'objet
                }
                else if (proto->Quality >= fallbackQuality) {
                    // Accepter un objet de qualité inférieure en dernier recours
                }
                else if (proto->Quality == ItemQualities::ITEM_QUALITY_RARE && urand(1, 100) <= rareChance) {
                    // Accepter avec un % pour Rare
                }
                else if (proto->Quality == ItemQualities::ITEM_QUALITY_UNCOMMON && urand(1, 100) <= uncommonChance) {
                    // Accepter avec un % pour Uncommon
                }
                else {
                    continue; // Sinon, ignorer l'objet
                }
            }

            if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR &&
                proto->Class != ITEM_CLASS_CONTAINER && proto->Class != ITEM_CLASS_PROJECTILE)
                continue;

            if (proto->Class == ITEM_CLASS_ARMOR &&
                (proto->InventoryType == InventoryType::INVTYPE_HEAD || proto->InventoryType == InventoryType::INVTYPE_SHOULDERS ||
                    proto->InventoryType == InventoryType::INVTYPE_CHEST || proto->InventoryType == InventoryType::INVTYPE_WAIST ||
                    proto->InventoryType == InventoryType::INVTYPE_LEGS || proto->InventoryType == InventoryType::INVTYPE_FEET ||
                    proto->InventoryType == InventoryType::INVTYPE_WRISTS || proto->InventoryType == InventoryType::INVTYPE_HANDS ||
                    proto->InventoryType == InventoryType::INVTYPE_ROBE) &&
                !CanEquipArmor(bot, proto))
                continue;

            else if (proto->Class == ITEM_CLASS_ARMOR &&
                (proto->SubClass == ItemSubclassArmor::ITEM_SUBCLASS_ARMOR_MISCELLANEOUS ||
                proto->SubClass == ItemSubclassArmor::ITEM_SUBCLASS_ARMOR_SHIELD) &&
                !CanEquipSubArmor(bot, proto)) continue;

            else if ((proto->Class == ITEM_CLASS_WEAPON) &&
                !CanEquipWeapon(bot, proto))
                continue;

            if (!MatchesPrimaryStatForSpec(bot, proto))
                continue;

            // ok ?
            return proto->ItemId;
        }
    }
    return 0;
}

bool RandomItemManager::MatchesPrimaryStatForSpec(Player* bot,
    ItemTemplate const* proto) const
{
    bool intellect = false;
    bool agility = false;
    bool strength = false;
    for (uint8 index = 0; index < MAX_ITEM_PROTO_STATS; ++index)
    {
        if (proto->ItemStat[index].ItemStatValue <= 0)
            continue;
        switch (proto->ItemStat[index].ItemStatType)
        {
            case ITEM_MOD_INTELLECT:
            case ITEM_MOD_SPELL_POWER:
                intellect = true;
                break;
            case ITEM_MOD_AGILITY:
                agility = true;
                break;
            case ITEM_MOD_STRENGTH:
                strength = true;
                break;
            default:
                break;
        }
    }

    // Jewelry and low-level items can legitimately carry only secondary
    // stats. Preserve/allow them rather than creating an unfillable slot.
    if (!intellect && !agility && !strength)
        return true;

    switch (bot->GetSpecialization())
    {
        case SPEC_PALADIN_HOLY:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
        case SPEC_PRIEST_SHADOW:
        case SPEC_SHAMAN_ELEMENTAL:
        case SPEC_SHAMAN_RESTORATION:
        case SPEC_MAGE_ARCANE:
        case SPEC_MAGE_FIRE:
        case SPEC_MAGE_FROST:
        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_WARLOCK_DESTRUCTION:
        case SPEC_DRUID_BALANCE:
        case SPEC_DRUID_RESTORATION:
        case SPEC_MONK_MISTWEAVER:
            return intellect;
        case SPEC_HUNTER_BEAST_MASTERY:
        case SPEC_HUNTER_MARKSMANSHIP:
        case SPEC_HUNTER_SURVIVAL:
        case SPEC_ROGUE_ASSASSINATION:
        case SPEC_ROGUE_COMBAT:
        case SPEC_ROGUE_SUBTLETY:
        case SPEC_SHAMAN_ENHANCEMENT:
        case SPEC_DRUID_FERAL:
        case SPEC_DRUID_GUARDIAN:
        case SPEC_MONK_BREWMASTER:
        case SPEC_MONK_WINDWALKER:
            return agility;
        default:
            return strength;
    }
}
