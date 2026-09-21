/*
* This file is part of the Pandaria 5.4.8 Project. See THANKS file for Copyright information
*
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

#include "ServiceBoost.h"
#include "WorldSession.h"
#include "BattlePayMgr.h"
#include "Player.h"
#include "ServiceMgr.h"
#include "Realm.h"
#include "DBCStores.h"
#include "SpellMgr.h"

#include <set>

namespace
{
uint8 GetCharacterBoostTargetLevel(uint8 boostTier)
{
    return boostTier == CHARACTER_BOOST_TIER_LEVEL_80 ? 80 : 90;
}

uint32 GetCharacterBoostLoadoutId(uint8 boostTier, uint32 specialization)
{
    bool level80 = boostTier == CHARACTER_BOOST_TIER_LEVEL_80;
    switch (specialization)
    {
        case SPEC_MAGE_ARCANE:            return level80 ? 123 : 543;
        case SPEC_MAGE_FIRE:              return level80 ? 124 : 544;
        case SPEC_MAGE_FROST:             return level80 ? 125 : 545;
        case SPEC_PALADIN_HOLY:           return level80 ? 164 : 523;
        case SPEC_PALADIN_PROTECTION:     return level80 ? 166 : 506;
        case SPEC_PALADIN_RETRIBUTION:    return level80 ? 168 : 524;
        case SPEC_WARRIOR_ARMS:           return level80 ? 133 : 539;
        case SPEC_WARRIOR_FURY:           return level80 ? 148 : 538;
        case SPEC_WARRIOR_PROTECTION:     return level80 ? 149 : 537;
        case SPEC_DRUID_BALANCE:          return level80 ? 109 : 549;
        case SPEC_DRUID_FERAL:            return level80 ? 110 : 546;
        case SPEC_DRUID_GUARDIAN:         return level80 ? 117 : 548;
        case SPEC_DRUID_RESTORATION:      return level80 ? 111 : 547;
        case SPEC_DEATH_KNIGHT_BLOOD:     return level80 ? 152 : 513;
        case SPEC_DEATH_KNIGHT_FROST:     return level80 ? 153 : 514;
        case SPEC_DEATH_KNIGHT_UNHOLY:    return level80 ? 154 : 515;
        case SPEC_HUNTER_BEAST_MASTERY:  return level80 ? 158 : 531;
        case SPEC_HUNTER_MARKSMANSHIP:   return level80 ? 159 : 532;
        case SPEC_HUNTER_SURVIVAL:       return level80 ? 160 : 533;
        case SPEC_PRIEST_DISCIPLINE:     return level80 ? 156 : 534;
        case SPEC_PRIEST_HOLY:           return level80 ? 157 : 535;
        case SPEC_PRIEST_SHADOW:         return level80 ? 155 : 536;
        case SPEC_ROGUE_ASSASSINATION:   return level80 ? 129 : 510;
        case SPEC_ROGUE_COMBAT:          return level80 ? 130 : 511;
        case SPEC_ROGUE_SUBTLETY:        return level80 ? 131 : 512;
        case SPEC_SHAMAN_ELEMENTAL:      return level80 ? 161 : 528;
        case SPEC_SHAMAN_ENHANCEMENT:    return level80 ? 162 : 529;
        case SPEC_SHAMAN_RESTORATION:    return level80 ? 163 : 530;
        case SPEC_WARLOCK_AFFLICTION:    return level80 ? 126 : 540;
        case SPEC_WARLOCK_DEMONOLOGY:    return level80 ? 127 : 541;
        case SPEC_WARLOCK_DESTRUCTION:   return level80 ? 128 : 542;
        case SPEC_MONK_BREWMASTER:       return level80 ? 352 : 525;
        case SPEC_MONK_WINDWALKER:       return level80 ? 354 : 527;
        case SPEC_MONK_MISTWEAVER:       return level80 ? 353 : 526;
        default:                         return 0;
    }
}

void AddLoadoutEquipmentItem(PreparedItemsMap& items, ItemTemplate const* item)
{
    if (!item)
        return;

    auto addFirstFree = [&items, item](uint8 first, uint8 second)
    {
        if (items.find(first) == items.end())
            items.emplace(first, item->ItemId);
        else if (items.find(second) == items.end())
            items.emplace(second, item->ItemId);
    };

    switch (item->InventoryType)
    {
        case INVTYPE_HEAD:           items.emplace(EQUIPMENT_SLOT_HEAD, item->ItemId); break;
        case INVTYPE_NECK:           items.emplace(EQUIPMENT_SLOT_NECK, item->ItemId); break;
        case INVTYPE_SHOULDERS:      items.emplace(EQUIPMENT_SLOT_SHOULDERS, item->ItemId); break;
        case INVTYPE_BODY:           items.emplace(EQUIPMENT_SLOT_BODY, item->ItemId); break;
        case INVTYPE_CHEST:
        case INVTYPE_ROBE:           items.emplace(EQUIPMENT_SLOT_CHEST, item->ItemId); break;
        case INVTYPE_WAIST:          items.emplace(EQUIPMENT_SLOT_WAIST, item->ItemId); break;
        case INVTYPE_LEGS:           items.emplace(EQUIPMENT_SLOT_LEGS, item->ItemId); break;
        case INVTYPE_FEET:           items.emplace(EQUIPMENT_SLOT_FEET, item->ItemId); break;
        case INVTYPE_WRISTS:         items.emplace(EQUIPMENT_SLOT_WRISTS, item->ItemId); break;
        case INVTYPE_HANDS:          items.emplace(EQUIPMENT_SLOT_HANDS, item->ItemId); break;
        case INVTYPE_FINGER:         addFirstFree(EQUIPMENT_SLOT_FINGER1, EQUIPMENT_SLOT_FINGER2); break;
        case INVTYPE_TRINKET:        addFirstFree(EQUIPMENT_SLOT_TRINKET1, EQUIPMENT_SLOT_TRINKET2); break;
        case INVTYPE_CLOAK:          items.emplace(EQUIPMENT_SLOT_BACK, item->ItemId); break;
        case INVTYPE_SHIELD:
        case INVTYPE_WEAPONOFFHAND:
        case INVTYPE_HOLDABLE:       items.emplace(EQUIPMENT_SLOT_OFFHAND, item->ItemId); break;
        case INVTYPE_WEAPON:
        case INVTYPE_2HWEAPON:       addFirstFree(EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND); break;
        case INVTYPE_WEAPONMAINHAND:
        case INVTYPE_RANGED:
        case INVTYPE_THROWN:
        case INVTYPE_RANGEDRIGHT:    items.emplace(EQUIPMENT_SLOT_MAINHAND, item->ItemId); break;
        default:                     break;
    }
}

uint8 GetStoredCharacterBoostTier(uint32 accountId)
{
    if (QueryResult result = LoginDatabase.PQuery("SELECT boost_level FROM account_boost WHERE id = %u AND realmid = %u AND counter > 0", accountId, realm.Id.Realm))
        return (*result)[0].GetUInt8();

    return CHARACTER_BOOST_TIER_LEGACY;
}
}

bool IsCharacterBoostProduct(uint32 productId)
{
    return productId == BATTLE_PAY_SERVICE_BOOST ||
           productId == BATTLE_PAY_SERVICE_BOOST_LEVEL_80 ||
           productId == BATTLE_PAY_SERVICE_BOOST_LEVEL_90;
}

uint8 GetCharacterBoostTierForProduct(uint32 productId)
{
    if (productId == BATTLE_PAY_SERVICE_BOOST_LEVEL_80)
        return CHARACTER_BOOST_TIER_LEVEL_80;
    if (productId == BATTLE_PAY_SERVICE_BOOST_LEVEL_90)
        return CHARACTER_BOOST_TIER_LEVEL_90;
    return CHARACTER_BOOST_TIER_LEGACY;
}

void LoadBoostItems()
{
    uint32 oldMSTime = getMSTime();

    mBoostItemsMap.clear();                                // need for reload case

    //                                                0                 1       2
    QueryResult result = WorldDatabase.Query("SELECT specialization, slot - 1, itemId FROM battle_pay_boost_items ORDER BY specialization, slot ASC");
    if (!result)
    {
        TC_LOG_INFO("server.loading", ">> Loaded 0 boost items. DB table `battle_pay_boost_items` is empty.");
        return;
    }

    uint32 count = 0;
    do
    {
        Field* fields = result->Fetch();

        BoostItems* items = new BoostItems();

        items->spec = fields[0].GetUInt32();
        items->slot = fields[1].GetUInt32();
        items->itemId = fields[2].GetUInt32();

        if (!sObjectMgr->GetItemTemplate(items->itemId))
        {
            TC_LOG_ERROR("sql.sql", "Item %u specified in `battle_pay_boost_items` does not exist, skipped.", items->itemId);
            continue;
        }

        mBoostItemsMap.push_back(items);
        count++;
    } while (result->NextRow());

    TC_LOG_INFO("server.loading", ">> Loaded %u boost items in %u ms", count, GetMSTimeDiffToNow(oldMSTime));
}

CharacterBooster::CharacterBooster(WorldSession* session) : m_session(session), m_timer(0), m_boosting(false), m_sendPacket(false) { }

void SetBoosting(WorldSession* session, uint32 accountId, bool boost, uint8 boostLevel)
{
    if (!accountId && !session)
        return;

    if (sWorld->getBoolConfig(CONFIG_BOOST_PROMOTION) && !boost)
    {
        // to be impl new here
    }

    uint32 counter = 0;

    LoginDatabasePreparedStatement* stmt = LoginDatabase.GetPreparedStatement(LOGIN_SEL_ACCOUNT_BOOST);
    stmt->setUInt32(0, accountId);
    stmt->setUInt32(1, realm.Id.Realm);
    if (PreparedQueryResult result = LoginDatabase.Query(stmt))
    {
        Field* fields = result->Fetch();
        counter = fields[0].GetUInt32();
        if (!boost)
            boostLevel = fields[1].GetUInt8();
    }

    if (!boost)
    {
        if (session && counter <= 1)
            session->SetBoost(false);

        counter--;
    }
    else
    {
        if (session)
            session->SetBoost(boost);
        counter++;
    }

    if (counter > 0)
    {
        stmt = LoginDatabase.GetPreparedStatement(LOGIN_INS_ACCOUNT_BOOST);
        stmt->setUInt32(0, accountId);
        stmt->setUInt32(1, realm.Id.Realm);
        stmt->setUInt32(2, counter);
        stmt->setUInt8(3, boostLevel);
    }
    else
    {
        stmt = LoginDatabase.GetPreparedStatement(LOGIN_DEL_ACCOUNT_BOOST);
        stmt->setUInt32(0, accountId);
        stmt->setUInt32(1, realm.Id.Realm);
    }
    LoginDatabase.Execute(stmt);
}

void CharacterBooster::_GetCharBoostItems(PreparedItemsMap& itemsToMail, PreparedItemsMap& itemsToEquip) const
{
    if (m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_80 ||
        m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_90)
    {
        uint32 loadoutId = GetCharacterBoostLoadoutId(m_charBoostInfo.boostLevel, m_charBoostInfo.specialization);
        CharacterLoadoutEntry const* loadout = sCharacterLoadoutStore.LookupEntry(loadoutId);
        if (!loadout)
        {
            TC_LOG_ERROR("sql.sql", "Character boost loadout %u is missing from CharacterLoadout.dbc.", loadoutId);
            return;
        }

        for (uint32 i = 0; i < sCharacterLoadoutItemStore.GetNumRows(); ++i)
        {
            CharacterLoadoutItemEntry const* loadoutItem = sCharacterLoadoutItemStore.LookupEntry(i);
            if (!loadoutItem || loadoutItem->CharacterLoadoutID != loadoutId)
                continue;

            AddLoadoutEquipmentItem(itemsToEquip, sObjectMgr->GetItemTemplate(loadoutItem->ItemID));
        }

        return;
    }

    // Preserve the original custom promotion exactly as it was configured.
    switch (m_charBoostInfo.specialization)
    {
        case SPEC_MAGE_ARCANE:
        case SPEC_MAGE_FIRE:
        case SPEC_MAGE_FROST:
        case SPEC_PRIEST_DISCIPLINE:
        case SPEC_PRIEST_HOLY:
        case SPEC_PRIEST_SHADOW:
        case SPEC_WARLOCK_AFFLICTION:
        case SPEC_WARLOCK_DEMONOLOGY:
        case SPEC_WARLOCK_DESTRUCTION:
            itemsToMail.emplace(0, 82590);
            break;
    }  

    if (m_charBoostInfo.allianceFaction)
        itemsToMail.emplace(1, 25472);
    else
        itemsToMail.emplace(1, 25474);

    for (auto&& item : mBoostItemsMap)
        if (item->spec == m_charBoostInfo.specialization)
            itemsToEquip.emplace(item->slot, item->itemId);
}

void CharacterBooster::SendCharBoostPacket(PreparedItemsMap items) const
{
    ObjectGuid guid = m_charBoostInfo.charGuid;
    WorldPacket data(SMSG_CHARACTER_UPGRADE_COMPLETE, 8 + 3 + items.size());

    data.WriteBit(guid[2]);
    data.WriteBit(guid[0]);
    data.WriteBit(guid[7]);
    data.WriteBit(guid[5]);
    data.WriteBit(guid[3]);
    data.WriteBit(guid[4]);
    data.WriteBit(guid[1]);
    data.WriteBits(items.size(), 22);
    data.WriteBit(guid[6]);

    data.FlushBits();

    data.WriteByteSeq(guid[7]);
    data.WriteByteSeq(guid[2]);
    data.WriteByteSeq(guid[6]);
    data.WriteByteSeq(guid[5]);

    for (auto&& item : items)
        data << uint32(item.second);

    data.WriteByteSeq(guid[0]);
    data.WriteByteSeq(guid[1]);
    data.WriteByteSeq(guid[3]);
    data.WriteByteSeq(guid[4]);


    GetSession()->SendPacket(&data);
}

void CharacterBooster::LearnNonExistedSpell(CharacterDatabaseTransaction trans, uint32 spell) const
{
    if (!spell)
        return;

    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_REP_CHAR_SPELL);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    stmt->setUInt32(1, spell);
    stmt->setUInt32(2, 1);
    stmt->setUInt32(3, 0);
    trans->Append(stmt);
}

void CharacterBooster::LearnNonExistedSkill(CharacterDatabaseTransaction trans, uint32 skill, uint16 value, uint16 max) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARACTER_SKILL_BOOST);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    stmt->setUInt32(1, skill);

    if (!CharacterDatabase.Query(stmt))
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_SKILLS);
        stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(1, skill);
        stmt->setUInt32(2, value);
        stmt->setUInt32(3, max);
        trans->Append(stmt);
    }
}

uint32 CharacterBooster::_PrepareMail(CharacterDatabaseTransaction trans, std::string const subject, std::string const body) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_MAIL);
    uint32 mailId = sObjectMgr->GenerateMailID();

    stmt->setUInt32(0, mailId);
    stmt->setUInt8(1, MAIL_NORMAL);
    stmt->setInt8(2, MAIL_STATIONERY_DEFAULT);
    stmt->setUInt16(3, 0);
    stmt->setUInt32(4, m_charBoostInfo.charGuid.GetCounter());
    stmt->setUInt32(5, m_charBoostInfo.charGuid.GetCounter());
    stmt->setString(6, subject);
    stmt->setString(7, body);
    stmt->setBool(8, true);
    stmt->setUInt64(9, time(NULL) + 180 * DAY);
    stmt->setUInt64(10, time(NULL));
    stmt->setUInt32(11, 0);
    stmt->setUInt32(12, 0);
    stmt->setUInt8(13, 0);
    trans->Append(stmt);

    return mailId;
}

void CharacterBooster::_SendMail(CharacterDatabaseTransaction trans, PreparedItemsMap items) const
{
    if (items.empty())
        return;

    MailTemplateEntry const* mailTemplateEntry = sMailTemplateStore.LookupEntry(MAIL_CHARRACTER_BOOST_EQUIPED_ITEMS_BODY);
    if (!mailTemplateEntry) // should never happen
        return;

    uint32 mailId = _PrepareMail(trans, mailTemplateEntry->subject[GetSession()->GetSessionDbcLocale()], mailTemplateEntry->content[GetSession()->GetSessionDbcLocale()]);
    CharacterDatabasePreparedStatement* stmt = NULL;

    for (auto&& itr : items)
    {
        if (Item* item = Item::CreateItem(itr.second, 1, 0))
        {
            item->SaveToDB(trans);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_MAIL_ITEM);
            stmt->setUInt32(0, mailId);
            stmt->setUInt32(1, item->GetGUID().GetCounter());
            stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
            trans->Append(stmt);
        }
        else
            TC_LOG_ERROR("sql.sql", "Can't create item %u for _SendMail in Boost. Skip.", itr.second);
    }
}

void CharacterBooster::_PrepareInventory(CharacterDatabaseTransaction trans) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_INVENTORY_BOOST);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    PreparedQueryResult result = CharacterDatabase.Query(stmt);

    MailTemplateEntry const* mailTemplateEntry = sMailTemplateStore.LookupEntry(MAIL_CHARRACTER_BOOST_EQUIPED_ITEMS_BODY);
    if (!mailTemplateEntry) // should never happen
        return;

    if (result)
    {
        uint32 mailId = _PrepareMail(trans, mailTemplateEntry->subject[GetSession()->GetSessionDbcLocale()], mailTemplateEntry->content[GetSession()->GetSessionDbcLocale()]);
        uint32 itemCount = 0;
        do
        {
            if (itemCount > 11)
            {
                itemCount = 0;
                mailId = _PrepareMail(trans, mailTemplateEntry->subject[GetSession()->GetSessionDbcLocale()], mailTemplateEntry->content[GetSession()->GetSessionDbcLocale()]);
            }

            uint32 itemGuid = (*result)[0].GetUInt32();

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_MAIL_ITEM);
            stmt->setUInt32(0, mailId);
            stmt->setUInt32(1, itemGuid);
            stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
            trans->Append(stmt);

            itemCount++;
        } while (result->NextRow());

        // Unequip after sending the old inventory to the character by mail.
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_INVENTORY_BOOST);
        stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
        trans->Append(stmt);
    }

    // move or create hearthstone to first slot
    stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_HEARTHSTONE_BOOST);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    if (!CharacterDatabase.Query(stmt))
    {
        if (Item* item = Item::CreateItem(ITEM_HEARTHSTONE, 1, 0))
        {
            item->SaveToDB(trans);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_INVENTORY);
            stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
            stmt->setUInt32(1, 0);
            stmt->setUInt8(2, INVENTORY_SLOT_ITEM_START);
            stmt->setUInt32(3, item->GetGUID().GetCounter());
            trans->Append(stmt);
        }
    }
    else
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_CHAR_HEARTHSTONE_BOOST);
        stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
        trans->Append(stmt);
    }

    uint32 foodItem = m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_80 ? ITEM_BAKED_MANTA_RAY : ITEM_LEMON_FLAVOUR_PUDING;

    // Insert the loadout-appropriate stack of food in the second backpack slot.
    if (Item* item = Item::CreateItem(foodItem, 20, 0))
    {
        item->SaveToDB(trans);

        stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_INVENTORY);
        stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(1, 0);
        stmt->setUInt8(2, INVENTORY_SLOT_ITEM_START + 1);
        stmt->setUInt32(3, item->GetGUID().GetCounter());
        trans->Append(stmt);
    }

    // The original level-80 DBC loadout also contains Heavy Frostweave Bandages.
    if (m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_80)
        if (Item* item = Item::CreateItem(ITEM_HEAVY_FROSTWEAVE_BANDAGE, 20, 0))
        {
            item->SaveToDB(trans);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_INVENTORY);
            stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
            stmt->setUInt32(1, 0);
            stmt->setUInt8(2, INVENTORY_SLOT_ITEM_START + 2);
            stmt->setUInt32(3, item->GetGUID().GetCounter());
            trans->Append(stmt);
        }

    // insert bag in inventory slots
    uint32 bagItem = m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_80 ? ITEM_FROSTWEAVE_BAG : ITEM_EMBERSILK_BAG;
    uint8 slot = INVENTORY_SLOT_BAG_START;
    for (uint8 i = 0; i < 4; i++)
    {
        if (Item* item = Item::CreateItem(bagItem, 1, 0))
        {
            item->SaveToDB(trans);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_INVENTORY);
            stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
            stmt->setUInt32(1, 0);
            stmt->setUInt8(2, slot);
            stmt->setUInt32(3, item->GetGUID().GetCounter());
            trans->Append(stmt);
        }
        slot++;
    }
}

std::string CharacterBooster::_SetSpecialization(CharacterDatabaseTransaction trans, uint8 const classId) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_TALENT);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
    {
        do
        {
            stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_SPELL_BY_SPELL);
            stmt->setUInt32(0, (*result)[0].GetUInt32());
            stmt->setUInt32(1, m_charBoostInfo.charGuid.GetCounter());
            trans->Append(stmt);
        } while (result->NextRow());
    }

    for (auto&& spec : dbc::GetClassSpecializations(classId))
    {
        if (std::vector<uint32> const* spells = dbc::GetSpecializetionSpells(spec))
        {
            for (auto&& spell : *spells)
            {
                stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_SPELL_BY_SPELL);
                stmt->setUInt32(0, spell);
                stmt->setUInt32(1, m_charBoostInfo.charGuid.GetCounter());
                trans->Append(stmt);
            }
        }
    }

    stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_TALENT);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    trans->Append(stmt);

    std::ostringstream talentTree;
    talentTree << m_charBoostInfo.specialization << " 0 ";
    return talentTree.str();
}

void CharacterBooster::_LearnClassSpells(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const
{
    uint32 raceMask = 1u << (raceId - 1);
    uint32 classMask = 1u << (classId - 1);
    std::set<uint32> spells;

    // Learn every baseline class ability that is valid for this race/class and
    // has been reached at the target level. Talents and spells owned by a
    // different specialization are intentionally excluded.
    for (uint32 i = 0; i < sSkillLineAbilityStore.GetNumRows(); ++i)
    {
        SkillLineAbilityEntry const* ability = sSkillLineAbilityStore.LookupEntry(i);
        if (!ability)
            continue;

        SkillLineEntry const* skill = sSkillLineStore.LookupEntry(ability->skillId);
        if (!skill || skill->categoryId != SKILL_CATEGORY_CLASS)
            continue;
        if (!GetSkillRaceClassInfo(ability->skillId, raceId, classId))
            continue;
        if (ability->classmask && !(ability->classmask & classMask))
            continue;
        if (ability->racemask && !(ability->racemask & raceMask))
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(ability->spellId);
        if (!spellInfo || spellInfo->SpellLevel > targetLevel || GetTalentSpellCost(spellInfo->GetFirstRankSpell()->Id) > 0)
            continue;

        if (!spellInfo->SpecializationIdList.empty())
        {
            bool activeSpecialization = false;
            for (uint32 specialization : spellInfo->SpecializationIdList)
                if (specialization == m_charBoostInfo.specialization)
                {
                    activeSpecialization = true;
                    break;
                }

            if (!activeSpecialization)
                continue;
        }

        spells.insert(spellInfo->Id);
    }

    if (std::vector<uint32> const* specializationSpells = dbc::GetSpecializetionSpells(m_charBoostInfo.specialization))
        for (uint32 spell : *specializationSpells)
            if (SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spell))
                if (spellInfo->SpellLevel <= targetLevel)
                    spells.insert(spell);

    for (uint32 spell : spells)
        LearnNonExistedSpell(trans, spell);
}

void CharacterBooster::_UpdateWeaponSkills(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const
{
    PlayerInfo const* info = sObjectMgr->GetPlayerInfo(raceId, classId);
    if (!info)
        return;

    uint16 skillValue = uint16(targetLevel) * 5;
    for (uint32 id : info->skills)
    {
        SkillRaceClassInfoEntry const* raceClassInfo = sSkillRaceClassInfoStore.LookupEntry(id);
        if (!raceClassInfo || raceClassInfo->ReqLevel > targetLevel)
            continue;

        SkillLineEntry const* skill = sSkillLineStore.LookupEntry(raceClassInfo->SkillId);
        if (!skill || skill->categoryId != SKILL_CATEGORY_WEAPON)
            continue;

        trans->PAppend("INSERT INTO character_skills (guid, skill, value, max) VALUES (%u, %u, %u, %u) "
                       "ON DUPLICATE KEY UPDATE value = GREATEST(value, VALUES(value)), max = GREATEST(max, VALUES(max))",
                       m_charBoostInfo.charGuid.GetCounter(), raceClassInfo->SkillId, skillValue, skillValue);
    }
}

void CharacterBooster::_LearnSpells(CharacterDatabaseTransaction trans, uint8 targetLevel, uint8 raceId, uint8 classId) const
{
    std::vector<uint32> spellsToLearn =
    {
        SPELL_APPRENTICE_RIDING,
        SPELL_JOURNEYMAN_RIDING,
        SPELL_EXPERT_RIDING,
        SPELL_ARTISAN_RIDING,
        SPELL_COLD_WHEATHER_FLYING,
        SPELL_FLIGHT_MASTER_LICENSE,
    };

    if (targetLevel >= 90)
        spellsToLearn.push_back(SPELL_WISDOM_OF_FOUR_WINDS);

    spellsToLearn.push_back(m_charBoostInfo.allianceFaction ? SPELL_SWIFT_PURPLE_GRYPGON : SPELL_SWIFT_PURPLE_WIND_RIDER);

    for (auto&& spell : spellsToLearn)
        LearnNonExistedSpell(trans, spell);

    _LearnClassSpells(trans, targetLevel, raceId, classId);
    _UpdateWeaponSkills(trans, targetLevel, raceId, classId);
}

void CharacterBooster::_GetBoostedCharacterData(uint8& raceId, uint8& classId, uint8& level) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_RACE);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());

    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
    {
        raceId = (*result)[0].GetUInt8();
        if (raceId == RACE_PANDAREN_NEUTRAL)
            raceId = m_charBoostInfo.allianceFaction ? RACE_PANDAREN_ALLIANCE : RACE_PANDAREN_HORDE;
    }

    stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_CLASS);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());

    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
        classId = (*result)[0].GetUInt8();

    stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_LEVEL);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());

    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
        level = (*result)[0].GetUInt8();
}

std::string CharacterBooster::_EquipItems(CharacterDatabaseTransaction trans, PreparedItemsMap itemsToEquip) const
{
    std::ostringstream items;
    CharacterDatabasePreparedStatement* stmt;
    for (uint32 i = 0; i < EQUIPMENT_SLOT_END; ++i)
    {
        auto itr = itemsToEquip.find(i);
        if (itr != itemsToEquip.end())
        {
            if (Item* item = Item::CreateItem(itr->second, 1, 0))
            {
                item->SaveToDB(trans);

                stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_CHAR_INVENTORY);
                stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
                stmt->setUInt32(1, 0);
                stmt->setUInt8(2, itr->first);
                stmt->setUInt32(3, item->GetGUID().GetCounter());
                trans->Append(stmt);

                items << (itr->second) << " 0 ";
            }
            else
            {
                TC_LOG_ERROR("sql.sql", "Can't create item %u for _EquipItems in Boost. Skip.", itr->second);

                items << "0 0 ";
            }
        }
        else
            items << "0 0 ";
    }

    uint32 bagItem = m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_80 ? ITEM_FROSTWEAVE_BAG : ITEM_EMBERSILK_BAG;
    for (uint32 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        items << bagItem << " 0 ";

    return items.str();
}

void CharacterBooster::_SaveBoostedChar(CharacterDatabaseTransaction trans, std::string items, uint8 targetLevel, uint8 const raceId, uint8 const classId) const
{
    uint8 locationTier = targetLevel >= 90 ? 1 : 0;
    CharacterBoostLocation const& location = boostLocations[locationTier][m_charBoostInfo.allianceFaction ? 1 : 0];
    uint32 money = m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEGACY ? 10000000 : (targetLevel >= 90 ? 1500000 : 1000000);

    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_CHARACTER_FOR_BOOST);
    stmt->setUInt8(0, raceId);
    stmt->setUInt32(1, money);
    stmt->setUInt8(2, targetLevel);
    stmt->setFloat(3, location.x);
    stmt->setFloat(4, location.y);
    stmt->setFloat(5, location.z);
    stmt->setFloat(6, location.orientation);
    stmt->setUInt16(7, location.map);
    stmt->setString(8, _SetSpecialization(trans, classId));
    stmt->setUInt16(9, AT_LOGIN_FIRST);
    stmt->setString(10, items);
    stmt->setUInt32(11, m_charBoostInfo.charGuid.GetCounter());
    trans->Append(stmt);

    // Keep the Hearthstone destination in sync with the selected tier's
    // landing point, including characters that have not completed a phased
    // race or hero-class starting experience.
    stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_PLAYER_HOMEBIND);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    trans->Append(stmt);

    stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_PLAYER_HOMEBIND);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());
    stmt->setUInt16(1, location.map);
    stmt->setUInt16(2, location.area);
    stmt->setFloat(3, location.x);
    stmt->setFloat(4, location.y);
    stmt->setFloat(5, location.z);
    trans->Append(stmt);
}

void CharacterBooster::_LearnVeteranBonuses(CharacterDatabaseTransaction trans, uint8 const classId) const
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARACTER_SKILLS_BOOST);
    stmt->setUInt32(0, m_charBoostInfo.charGuid.GetCounter());

    std::vector<uint32> primarySkills;
    bool fistAidBoosted = false;
    bool cookingBoosted = false;
    bool fishingBoosted = false;
    bool archaeologyBoosted = false;
    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
    {
        do
        {
            uint32 skillId = (*result)[0].GetUInt16();
            if (skillId == SKILL_BLACKSMITHING || skillId == SKILL_LEATHERWORKING || skillId == SKILL_ALCHEMY || skillId == SKILL_HERBALISM ||
                skillId == SKILL_MINING || skillId == SKILL_TAILORING || skillId == SKILL_ENGINEERING || skillId == SKILL_ENCHANTING ||
                skillId == SKILL_SKINNING || skillId == SKILL_JEWELCRAFTING || skillId == SKILL_INSCRIPTION)
                primarySkills.push_back(skillId);
            if (skillId == SKILL_FIRST_AID)
                fistAidBoosted = true;
            if (skillId == SKILL_COOKING)
                cookingBoosted = true;
            if (skillId == SKILL_FISHING)
                fishingBoosted = true;
            if (skillId == SKILL_ARCHAEOLOGY)
                archaeologyBoosted = true;
        } while (result->NextRow());
    }

    for (auto&& skill : primarySkills)
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_CHAR_SKILLS);
        stmt->setUInt32(0, 600);
        stmt->setUInt32(1, 600);
        stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(3, skill);
        trans->Append(stmt);

        uint32 spell = 0;
        switch (skill)
        {
            case SKILL_BLACKSMITHING:  spell = SPELL_BLACKSMITHING;  break;
            case SKILL_LEATHERWORKING: spell = SPELL_LEATHERWORKING; break;
            case SKILL_ALCHEMY:        spell = SPELL_ALCHEMY;        break;
            case SKILL_HERBALISM:      spell = SPELL_HERBALISM;      break;
            case SKILL_MINING:         spell = SPELL_MINING;         break;
            case SKILL_TAILORING:      spell = SPELL_TAILORING;      break;
            case SKILL_ENGINEERING:    spell = SPELL_ENGINEERING;    break;
            case SKILL_ENCHANTING:     spell = SPELL_ENCHANTING;     break;
            case SKILL_SKINNING:       spell = SPELL_SKINNING;       break;
            case SKILL_JEWELCRAFTING:  spell = SPELL_JEWELCRAFTING;  break;
            case SKILL_INSCRIPTION:    spell = SPELL_INSCRIPTION;    break;
        }
        LearnNonExistedSpell(trans, spell);
    }

    if (fistAidBoosted)
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_CHAR_SKILLS);
        stmt->setUInt32(0, 600);
        stmt->setUInt32(1, 600);
        stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(3, SKILL_FIRST_AID);
        trans->Append(stmt);
        LearnNonExistedSpell(trans, SPELL_FIRST_AID);
    }

    // Blizzard's level-90 boost only raised professions already owned by a
    // level-60+ character: both primary professions and First Aid. Keep the
    // broader legacy custom-promotion behavior below for product 83.
    if (m_charBoostInfo.boostLevel == CHARACTER_BOOST_TIER_LEVEL_90)
        return;

    if (cookingBoosted)
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_CHAR_SKILLS);
        stmt->setUInt32(0, 600);
        stmt->setUInt32(1, 600);
        stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(3, SKILL_COOKING);
        trans->Append(stmt);
        LearnNonExistedSpell(trans, SPELL_COOKING);
    }

    if (fishingBoosted)
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_CHAR_SKILLS);
        stmt->setUInt32(0, 600);
        stmt->setUInt32(1, 600);
        stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(3, SKILL_FISHING);
        trans->Append(stmt);
        LearnNonExistedSpell(trans, SPELL_FISHING);
    }

    if (archaeologyBoosted)
    {
        stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_CHAR_SKILLS);
        stmt->setUInt32(0, 600);
        stmt->setUInt32(1, 600);
        stmt->setUInt32(2, m_charBoostInfo.charGuid.GetCounter());
        stmt->setUInt32(3, SKILL_ARCHAEOLOGY);
        trans->Append(stmt);
        LearnNonExistedSpell(trans, SPELL_ARCHAEOLOGY);
    }

    if (primarySkills.empty())
    {
        std::vector<std::pair<uint32, uint32>> skillsAndSpells;
        switch (classId)
        {
            case CLASS_PRIEST:
            case CLASS_MAGE:
            case CLASS_WARLOCK:
                skillsAndSpells.emplace_back(SKILL_ENCHANTING, SPELL_ENCHANTING);
                skillsAndSpells.emplace_back(SKILL_TAILORING, SPELL_TAILORING);
                break;
            case CLASS_ROGUE:
            case CLASS_MONK:
            case CLASS_DRUID:
            case CLASS_HUNTER:
            case CLASS_SHAMAN:
                skillsAndSpells.emplace_back(SKILL_LEATHERWORKING, SPELL_LEATHERWORKING);
                skillsAndSpells.emplace_back(SKILL_SKINNING, SPELL_SKINNING);
                break;
            case CLASS_WARRIOR:
            case CLASS_PALADIN:
            case CLASS_DEATH_KNIGHT:
                skillsAndSpells.emplace_back(SKILL_BLACKSMITHING, SPELL_BLACKSMITHING);
                skillsAndSpells.emplace_back(SKILL_MINING, SPELL_MINING);
                break;
        }
        for (auto&& itr : skillsAndSpells)
        {
            LearnNonExistedSkill(trans, itr.first);
            LearnNonExistedSpell(trans, itr.second);
        }
    }

    if (!fistAidBoosted)
    {
        LearnNonExistedSkill(trans, SKILL_FIRST_AID);
        LearnNonExistedSpell(trans, SPELL_FIRST_AID);
    }

    if (!cookingBoosted)
    {
        LearnNonExistedSkill(trans, SKILL_COOKING);
        LearnNonExistedSpell(trans, SPELL_COOKING);
    }

    if (!fishingBoosted)
    {
        LearnNonExistedSkill(trans, SKILL_FISHING);
        LearnNonExistedSpell(trans, SPELL_FISHING);
    }

    if (!archaeologyBoosted)
    {
        LearnNonExistedSkill(trans, SKILL_ARCHAEOLOGY);
        LearnNonExistedSpell(trans, SPELL_ARCHAEOLOGY);
    }
}

void CharacterBooster::_HandleCharacterBoost() const
{
    if (!GetSession()->HasBoost())
        return;

    if (sWorld->getBoolConfig(CONFIG_BOOST_PROMOTION))
    {
        auto paid = LoginDatabase.PQuery("SELECT counter FROM account_boost WHERE id = '%d' AND realmid = '%d' AND counter > 0", GetSession()->GetAccountId(), realm.Id.Realm);
        if (!paid)
            return;
    }

    uint8 raceId = 0, classId = 0, level = 0;
    _GetBoostedCharacterData(raceId, classId, level);
    if (!raceId || !classId || !level)
        return;

    uint8 targetLevel = GetCharacterBoostTargetLevel(m_charBoostInfo.boostLevel);
    if (level >= targetLevel)
    {
        TC_LOG_ERROR("misc", "Character boost rejected for GUID %u: current level %u is not below target level %u.",
            m_charBoostInfo.charGuid.GetCounter(), level, targetLevel);
        return;
    }

    if (ChrSpecializationEntry const* specEntry = sChrSpecializationStore.LookupEntry(m_charBoostInfo.specialization))
        if (classId != specEntry->classId)
            return;

    PreparedItemsMap itemsToMail, itemsToEquip;
    _GetCharBoostItems(itemsToMail, itemsToEquip);
    if (itemsToEquip.empty())
        return;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    _PrepareInventory(trans);
    _SendMail(trans, itemsToMail);
    _LearnSpells(trans, targetLevel, raceId, classId);
    _SaveBoostedChar(trans, _EquipItems(trans, itemsToEquip), targetLevel, raceId, classId);
    if (level >= 60 && targetLevel >= 90)
        _LearnVeteranBonuses(trans, classId);
    // This completes the skipped Goblin, Worgen, Pandaren and Death Knight
    // starting chains. Other races are harmless no-ops, while class abilities
    // (including Druid forms) are handled by _LearnClassSpells above.
    sServiceMgr->AddSpecificPlayerData(m_charBoostInfo.charGuid, 0, raceId, classId, nullptr, true, false);
    CharacterDatabase.CommitTransaction(trans);
    SetBoosting(GetSession(), GetSession()->GetAccountId(), false);
    SendCharBoostPacket(itemsToEquip);

    auto data = sWorld->GetCharacterNameData(m_charBoostInfo.charGuid);
    sServiceMgr->ExecutedServices(m_charBoostInfo.charGuid, SERVICE_TYPE_BOOST, std::string("Boosted name: ") + (data ? data->m_name : std::string("error")), "");
}

void CharacterBooster::HandleCharacterBoost()
{
    if (!m_charBoostInfo.charGuid)
        return;

    switch (m_charBoostInfo.action)
    {
        case CHARACTER_BOOST_ITEMS:
            sBattlePayMgr->SendBattlePayDistributionUpdate(GetSession(), BATTLE_PAY_SERVICE_BOOST, m_charBoostInfo.action);
            m_charBoostInfo.action = CHARACTER_BOOST_APPLIED;
            m_timer = 500;
            m_sendPacket = true;
            break;
        case CHARACTER_BOOST_APPLIED:
            sBattlePayMgr->SendBattlePayDistributionUpdate(GetSession(), BATTLE_PAY_SERVICE_BOOST, m_charBoostInfo.action);
            m_charBoostInfo = CharacterBoostData();
            break;
        default:
            break;
    }
}

void CharacterBooster::SetBoostedCharInfo(ObjectGuid guid, uint32 action, uint32 specialization, bool allianceFaction)
{
    m_boosting = true;
    m_charBoostInfo.charGuid = guid;
    m_charBoostInfo.action = action;
    m_charBoostInfo.specialization = specialization;
    m_charBoostInfo.boostLevel = GetStoredCharacterBoostTier(GetSession()->GetAccountId());
    m_charBoostInfo.allianceFaction = allianceFaction;
}

void CharacterBooster::Update(uint32 diff)
{
    if (m_sendPacket)
    {
        if (m_timer <= diff)
        {
            m_sendPacket = false;
            _HandleCharacterBoost();
        }
        else
            m_timer -= diff;
    }
}
