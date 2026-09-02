#include "BotFactory.h"

#include <algorithm>
#include <random>
#include <set>
#include <utility>
#include <vector>
 
#include "AccountMgr.h"
#include "AiFactory.h"
#include "ArenaTeam.h"
#include "Bag.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "GuildMgr.h"
#include "Helper.h"
#include "Item.h"
#include "ItemVisitors.h"
#include "Log.h"
#include "LogCommon.h"
#include "LootMgr.h"
#include "MapManager.h"
#include "ObjectMgr.h"
#include "PetDefines.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotSpec.h"
#include "Playerbots.h"
#include "RandomPlayerbotFactory.h"
#include "RandomItemManager.h"
#include "SharedDefines.h"
#include "SpellAuraDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "World.h"
  
BotFactory::BotFactory(Player* bot, uint32 level, uint32 itemQuality, uint32 gearScoreLimit)
    : level(level), bot(bot)
{
    botAI = GET_PLAYERBOT_AI(bot);
}

void BotFactory::CancelAuras() { bot->RemoveAllAuras(); }
 
void BotFactory::Init()
{
    /*for (std::vector<uint32>::iterator i = sPlayerbotAIConfig->randomBotQuestIds.begin();
        i != sPlayerbotAIConfig->randomBotQuestIds.end(); ++i)
    {
        uint32 questId = *i;
        AddPrevQuests(questId, specialQuestIds);
        specialQuestIds.remove(questId);
        specialQuestIds.push_back(questId);
    }
    uint32 maxStoreSize = sSpellMgr->GetSpellInfoStoreSize();
    for (uint32 id = 1; id < maxStoreSize; ++id)
    {
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(id);
        if (!spellInfo)
            continue;
 
        if (id == 47181 || id == 50358 || id == 47242 || id == 52639 || id == 47147 || id == 7218)  // Test Enchant
            continue;
 
        uint32 requiredLevel = spellInfo->BaseLevel;
 
        for (uint8 j = 0; j < MAX_SPELL_EFFECTS; ++j)
        {
            if (spellInfo->Effects[j].Effect != SPELL_EFFECT_ENCHANT_ITEM)
                continue;
 
            uint32 enchant_id = spellInfo->Effects[j].MiscValue;
            if (!enchant_id)
                continue;
 
            SpellItemEnchantmentEntry const* enchant = sSpellItemEnchantmentStore.LookupEntry(enchant_id);
            if (!enchant || (enchant->Flags != PERM_ENCHANTMENT_SLOT && enchant->slot != TEMP_ENCHANTMENT_SLOT))
                continue;
 
            // SpellInfo const* enchantSpell = sSpellMgr->GetSpellInfo(enchant->spellid[0]);
            // if (!enchantSpell)
            //     continue;
            if (strstr(spellInfo->SpellName[0], "Test"))
                break;
 
            enchantSpellIdCache.push_back(id);
            break;
            // TC_LOG_INFO("playerbots", "Add {} to enchantment spells", id);
        }
    }
    TC_LOG_INFO("playerbots", "Loading {} enchantment spells", enchantSpellIdCache.size());
    for (auto iter = sSpellItemEnchantmentStore.begin(); iter != sSpellItemEnchantmentStore.end(); iter++)
    {
        uint32 gemId = iter->GemID;
        if (gemId == 0)
        {
            continue;
        }
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(gemId);
 
        if (proto->ItemLevel < 60)
            continue;
 
        if (proto->Flags & ITEM_FLAG_UNIQUE_EQUIPPABLE)
        {
            continue;
        }
        if (sRandomItemMgr->IsTestItem(gemId))
            continue;
 
        if (!proto || !sGemPropertiesStore.LookupEntry(proto->GemProperties))
        {
            continue;
        }
        // TC_LOG_INFO("playerbots", "Add {} to enchantment gems", gemId);
        enchantGemIdCache.push_back(gemId);
    }
    TC_LOG_INFO("playerbots", "Loading {} enchantment gems", enchantGemIdCache.size());*/
}
 
void BotFactory::Prepare()
{
    if (bot->isDead())
        bot->ResurrectPlayer(1.0f, false);
 
    bot->CombatStop(true);

    int32 newlevel = level;
    if (newlevel < 1)
        newlevel = 1;
    if (newlevel > 90)
        newlevel = 90;

    bot->GiveLevel(newlevel);
    bot->InitTalentForLevel();
    bot->SetUInt32Value(PLAYER_FIELD_XP, 0);
    bot->RemoveAllSpellCooldown();
    bot->InitStatsForLevel();
    CancelAuras();
}
 
void BotFactory::Randomize(bool incremental)
{
    TC_LOG_INFO("playerbots", "%s randomizing %s (level %u class = %s)...", (incremental ? "Incremental" : "Full"),
            bot->GetName().c_str(), level, ClassToString((Classes)bot->GetClass()).c_str());

    Prepare();
    if (!incremental)
    {
        // -- Unlearn talents and spec
        bot->ResetTalents(true, true, true);

        // -- release pet
        bot->RemovePet(PetRemoveMode::PET_REMOVE_ABANDON, PetRemoveFlag::PET_REMOVE_FLAG_NONE);

        // Destroy equipped items.
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            {
                std::string itemName = item->GetTemplate()->Name1;
                bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
            }
        }
    }

    InitTalentsTree(false);
    InitGlyphs();
    InitPet();
    InitEquipmentForSpec();
 
    bot->SetMoney(urand(level * 100000, level * 5 * 100000));
    bot->SetHealth(bot->GetMaxHealth());
    bot->SetPower(POWER_MANA, bot->GetMaxPower(POWER_MANA));

    bot->SaveToDB(false);
}
 
void BotFactory::Refresh()
{
    InitPet();
    bot->DurabilityRepairAll(false, 1.0f, false);
    if (bot->isDead())
        bot->ResurrectPlayer(1.0f, false);
    uint32 money = urand(level * 1000, level * 5 * 1000);
    if (bot->GetMoney() < money)
        bot->SetMoney(money);
}
 
void BotFactory::InitPet()
{
    Pet* pet = bot->GetPet();

    /*if (bot->GetClass() == CLASS_HUNTER)
    {
        if (pet)
        {
            bot->RemovePet(PET_REMOVE_ABANDON);
            pet = nullptr;
        }

        // -- Delete all pet slots if possible
        for (uint8 pet_slot_active = 0; pet_slot_active < PetSlot::PET_SLOT_ACTIVE_LAST; ++pet_slot_active)
        {
            uint32 pet_id = bot->GetPetIdBySlot(pet_slot_active);
            if (!pet_id) continue;

            bot->SummonPet(pet_id, bot->GetWorldLocation().GetPositionX(), bot->GetWorldLocation().GetPositionY(),
                           bot->GetWorldLocation().GetPositionZ(), 0.0f, 0);
            bot->RemovePet(PetRemoveMode::PET_REMOVE_ABANDON);
            pet = nullptr;
        }
    }*/

    // Older BotFactory pet creation saved hunter pets before registering an
    // active slot. Those rows consequently have slot 255 and are ignored by
    // Player::LoadPetList; a hunter then whistles Call Pet 1 every five
    // seconds forever because no usable active pet exists. Recover the newest
    // such pet for this random bot before generating another one.
    if (!pet && bot->GetClass() == CLASS_HUNTER)
    {
        QueryResult result = CharacterDatabase.PQuery(
            "SELECT id FROM character_pet WHERE owner = %u AND PetType = %u "
            "AND slot > %u ORDER BY savetime DESC, id DESC LIMIT 1",
            bot->GetGUID().GetCounter(), uint32(HUNTER_PET),
            uint32(PET_SLOT_STABLE_LAST));
        if (result)
        {
            Pet* recoveredPet = new Pet(bot);
            if (recoveredPet->LoadPetFromDB(
                    PET_LOAD_BY_ID, result->Fetch()[0].GetUInt32()))
                pet = recoveredPet;
            else
                delete recoveredPet;
        }
    }

    if (!pet)
    {
        if (bot->GetClass() != CLASS_HUNTER)
            return;
 
        Map* map = bot->GetMap();
        if (!map)
            return;

        std::vector<uint32> ids;
        CreatureTemplateContainer const* creatures = sObjectMgr->GetCreatureTemplates();
        for (CreatureTemplateContainer::const_iterator itr = creatures->begin(); itr != creatures->end(); ++itr)
        {
            if (!itr->second.IsTameable(bot->CanTameExoticPets()))
                continue;
 
            if (itr->second.minlevel > bot->GetLevel())
                continue;
 
            ids.push_back(itr->first);
        }
 
        if (ids.empty())
        {
            TC_LOG_ERROR("playerbots", "No pets available for bot %s (%u level)", bot->GetName().c_str(), bot->GetLevel());
            return;
        }

        for (uint32 i = 0; i < 10; i++)
        {
            uint32 index = urand(0, ids.size() - 1);
            CreatureTemplate const* co = sObjectMgr->GetCreatureTemplate(ids[index]);
            if (!co)
                continue;
            if (co->Name.size() > 21)
                continue;

            int8 newPetSlot = bot->GetSlotForNewPet();
            if (newPetSlot == -1)
                continue;

            // Everything looks OK, create new pet
            pet = bot->CreateTamedPetFrom(co->Entry, 0);
            if (!pet)
                continue;

            // prepare visual effect for levelup
            pet->SetUInt32Value(UNIT_FIELD_LEVEL, bot->GetLevel() - 1);
 
            // add to world
            pet->GetMap()->AddToMap(pet->ToCreature());
 
            // visual effect for levelup
            pet->SetUInt32Value(UNIT_FIELD_LEVEL, bot->GetLevel());
 
            // caster have pet now
            bot->SetMinion(pet, true);
 
            pet->InitTalentForLevel();

            // Register the active slot before saving. Pet::SavePetToDB derives
            // character_pet.slot from this in-memory list.
            bot->AddNewPet(newPetSlot, pet);
            bot->SetCurrentPetId(pet->GetCharmInfo()->GetPetNumber());
            pet->SavePetToDB();
            bot->PetSpellInitialize();
            break;
        }
    }

    // A current pet may itself have been loaded from a legacy slot-255 row.
    // Attach it to the first available active slot and rewrite that same row;
    // no pet or player inventory is discarded.
    if (pet && bot->GetClass() == CLASS_HUNTER &&
        bot->GetSlotByPetId(pet->GetCharmInfo()->GetPetNumber()) < 0)
    {
        int8 newPetSlot = bot->GetSlotForNewPet();
        if (newPetSlot >= 0)
        {
            bot->AddNewPet(newPetSlot, pet);
            bot->SetCurrentPetId(pet->GetCharmInfo()->GetPetNumber());
            pet->SavePetToDB();
            bot->PetSpellInitialize();
            TC_LOG_INFO("playerbots",
                "Repaired active hunter pet slot for bot %s guid=%u pet=%u slot=%d",
                bot->GetName().c_str(), bot->GetGUID().GetCounter(),
                pet->GetCharmInfo()->GetPetNumber(), int32(newPetSlot));
        }
    }
 
    if (pet)
    {
        pet->InitStatsForLevel(bot->GetLevel());
        pet->SetLevel(bot->GetLevel());
        pet->SetHealth(pet->GetMaxHealth());

        // MoP hunter pets use Ferocity/Tenacity/Cunning specializations rather
        // than the removed pet talent tree. Random hunters use PvE Ferocity.
        // Every controlled Playerbot pet (hunter, warlock, mage, etc.) stays
        // passive so only the owner's explicit AI command starts an attack.
        if (bot->GetClass() == CLASS_HUNTER &&
            pet->getPetType() == HUNTER_PET)
            pet->SetSpecialization(SPEC_PET_FEROCITY);
        pet->SetReactState(REACT_PASSIVE);
    }
    else
    {
        TC_LOG_ERROR("playerbots", "Cannot create pet for bot %s", bot->GetName().c_str());
        return;
    }
 
    // TC_LOG_INFO("playerbots", "Start make spell auto cast for {} spells. {} already auto casted.", pet->m_spells.size(),
    // pet->GetPetAutoSpellSize());
    for (PetSpellMap::const_iterator itr = pet->m_spells.begin(); itr != pet->m_spells.end(); ++itr)
    {
        if (itr->second.state == PETSPELL_REMOVED)
            continue;
 
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(itr->first);
        if (!spellInfo)
            continue;
 
        if (spellInfo->IsPassive())
            continue;

        // Growl and equivalent threat/taunt abilities are useful for solo
        // tanking, but a raid pet must never pull aggro from the marked tank.
        bool threatSpell = false;
        for (SpellEffectInfo const& effect : spellInfo->Effects)
        {
            if (effect.Effect == SPELL_EFFECT_ATTACK_ME ||
                effect.Effect == SPELL_EFFECT_THREAT ||
                effect.Effect == SPELL_EFFECT_THREAT_ALL ||
                effect.ApplyAuraName == SPELL_AURA_MOD_TAUNT ||
                effect.ApplyAuraName == SPELL_AURA_MOD_THREAT ||
                effect.ApplyAuraName == SPELL_AURA_MOD_TOTAL_THREAT)
            {
                threatSpell = true;
                break;
            }
        }
        pet->ToggleAutocast(spellInfo, !threatSpell);
    }

    // Persist Ferocity (where applicable), passive reaction and the corrected
    // autocast state so any permanent controlled pet cannot restore an old
    // tanking setup on its next login.
    pet->SavePetToDB();
}
namespace
{
uint32 GetPlayerbotBuildSpellScore(Player* bot, SpellInfo const* modifier)
{
    if (!bot || !modifier)
        return 0;

    uint32 score = 0;
    for (auto const& effect : modifier->Effects)
    {
        if (!effect.SpellClassMask)
            continue;

        for (auto const& knownSpell : bot->GetSpellMap())
        {
            uint32 spellId = knownSpell.first;
            if (!bot->HasSpell(spellId))
                continue;

            SpellInfo const* known = sSpellMgr->GetSpellInfo(spellId);
            if (known && known->SpellFamilyName == modifier->SpellFamilyName &&
                (effect.SpellClassMask & known->SpellFamilyFlags))
                ++score;
        }
    }
    return score;
}

uint32 GetPlayerbotTalentScore(Player* bot, TalentEntry const* talent)
{
    if (!bot || !talent)
        return 0;

    uint32 score = 0;
    if (talent->ReplacesSpell && bot->HasSpell(talent->ReplacesSpell))
        score += 10000;

    score += GetPlayerbotBuildSpellScore(bot, sSpellMgr->GetSpellInfo(talent->SpellId)) * 100;

    // DBC-valid ties remain deterministic but differ by active specialization.
    uint32 preferredColumn = (uint32(bot->GetSpecialization()) + talent->Row) % 3;
    score += talent->Col == preferredColumn ? 3 :
        ((talent->Col + 1) % 3 == preferredColumn ? 2 : 1);
    return score;
}
}

void BotFactory::InitTalentsTree(bool reset)
{
    /*std::map<uint32, std::list<const TalentEntry*>> talents_dbc;
    for (auto entry = sTalentStore.begin(); entry != sTalentStore.end(); ++entry)
    {
        if (talents_dbc.find(entry->PlayerClass) == talents_dbc.end())
            talents_dbc[entry->PlayerClass] = std::list<const TalentEntry*>();
        talents_dbc[entry->PlayerClass].push_back(*entry);
    }

    for (auto& ref : talents_dbc)
    {
        ref.second.sort([](const TalentEntry* a, const TalentEntry* b)
        {
            return (a->Row < b->Row) || (a->Row == b->Row && a->Col < b->Col);
        });
    }

    std::ofstream os("./talent_export.txt", std::ios::app);
    for (const auto& ref : talents_dbc)
    {
        auto classe = ClassToString((Classes)ref.first);
        os << classe << ":\n";
        uint32 currentRow = 0;
        for (const auto& tal : ref.second)
        {
            if (tal->Row != currentRow)
            {
                currentRow = tal->Row;
                os << "\n";
            }
            os << tal->TalentID << "\t";
        }
        os << "\n";
    }
    os.close();*/

    // -- reset spec in case we down level
    if (reset)
    {
        bot->ResetTalents(true, true, true);
    }
    
    // if no spec then pick one random (need to change that to balance)
    if (bot->GetSpecialization() == Specializations::SPEC_NONE)
    {
        // -- Select spec
        if (bot->GetLevel() >= 10)
        {
            uint32 tab = std::rand() % 3;
            WorldPacket p(CMSG_SET_PRIMARY_TALENT_TREE);
            p << tab;
            bot->GetSession()->HandeSetTalentSpecialization(p);
            bot->ActivateSpec(0);
        }
    }

    WorldPacket p(CMSG_LEARN_TALENT);
    uint32 alreadyUsedPoints = bot->GetUsedTalentCount();
    uint8 spec_tab = PlayerBotSpec::GetSpectab(bot);
    uint32 availablepoints = bot->CalculateTalentsPoints() - bot->GetUsedTalentCount();
    uint32 learnCount = 0;

    if (!availablepoints || spec_tab == 99) return;

    const std::vector<uint16>& talents = sPlayerbotAIConfig->premadeSpecLink[bot->GetClass()][spec_tab];
    if (talents.empty())
    {
        // The inherited premade links are WotLK-style and are intentionally not
        // treated as MoP talent IDs. Build a valid 5.4.8 baseline directly from
        // Talent.dbc, preserving every already selected row.
        for (uint32 row = 0; row < 6 && availablepoints > 0; ++row)
        {
            bool rowAlreadySelected = false;
            TalentEntry const* selected = nullptr;
            uint32 selectedScore = 0;
            for (uint32 talentId = 0; talentId < sTalentStore.GetNumRows(); ++talentId)
            {
                TalentEntry const* talent = sTalentStore.LookupEntry(talentId);
                if (!talent || talent->PlayerClass != bot->GetClass() || talent->Row != row)
                    continue;
                if (bot->HasSpell(talent->SpellId))
                {
                    rowAlreadySelected = true;
                    break;
                }

                uint32 score = GetPlayerbotTalentScore(bot, talent);
                if (!selected || score > selectedScore ||
                    (score == selectedScore && talent->TalentID < selected->TalentID))
                {
                    selected = talent;
                    selectedScore = score;
                }
            }

            if (!rowAlreadySelected && selected && bot->LearnTalent(uint16(selected->TalentID)))
                --availablepoints;
        }
        bot->SendTalentsInfoData();
        return;
    }

    
    std::vector<uint16> talent_to_learn;
    for (size_t i = alreadyUsedPoints; i < talents.size() && availablepoints > 0; ++i)
    {
        uint16 talentId = talents[i];
        if (!bot->HasTalent(talentId, bot->GetActiveSpec()))
        {
            learnCount++;
            talent_to_learn.push_back(talentId);
            availablepoints--;
        }
    }
    if (learnCount > 0)
    {
        p.WriteBits(learnCount, 23);
        for (const auto& c : talent_to_learn)
            p << c;
        bot->GetSession()->HandleLearnTalentOpcode(p);
    }
}

void BotFactory::InitGlyphs()
{
    if (!bot || bot->GetLevel() < 25 || bot->GetSpecialization() == SPEC_NONE)
        return;

    std::vector<uint32> const* glyphSpells = sSpellMgr->GetGlyphsForClass(bot->GetClass());
    if (!glyphSpells || glyphSpells->empty())
        return;

    std::set<uint32> usedGlyphs;
    for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
        if (uint32 glyph = bot->GetGlyph(bot->GetActiveSpec(), slot))
            usedGlyphs.insert(glyph);

    for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
    {
        if (bot->GetGlyph(bot->GetActiveSpec(), slot))
            continue;

        GlyphSlotEntry const* glyphSlot = sGlyphSlotStore.LookupEntry(bot->GetGlyphSlot(slot));
        if (!glyphSlot)
            continue;

        uint32 selectedGlyph = 0;
        uint32 selectedScore = 0;
        for (uint32 glyphSpellId : *glyphSpells)
        {
            SpellInfo const* glyphCast = sSpellMgr->GetSpellInfo(glyphSpellId);
            if (!glyphCast)
                continue;

            for (auto const& effect : glyphCast->Effects)
            {
                if (effect.Effect != SPELL_EFFECT_APPLY_GLYPH || effect.MiscValue <= 0)
                    continue;

                uint32 glyphId = uint32(effect.MiscValue);
                GlyphPropertiesEntry const* glyph = sGlyphPropertiesStore.LookupEntry(glyphId);
                if (!glyph || glyph->TypeFlags != glyphSlot->TypeFlags || usedGlyphs.count(glyphId))
                    continue;

                uint32 score = GetPlayerbotBuildSpellScore(
                    bot, sSpellMgr->GetSpellInfo(glyph->SpellId)) * 100;
                // Specialization-sensitive deterministic tie-breaker. This is a
                // valid baseline, not a claim of a hand-tuned tournament build.
                score += 99 - ((glyphId + uint32(bot->GetSpecialization()) * 17 + slot * 7) % 100);
                if (!selectedGlyph || score > selectedScore ||
                    (score == selectedScore && glyphId < selectedGlyph))
                {
                    selectedGlyph = glyphId;
                    selectedScore = score;
                }
            }
        }

        if (selectedGlyph)
        {
            bot->SetGlyph(slot, selectedGlyph);
            usedGlyphs.insert(selectedGlyph);
        }
    }

    bot->SendTalentsInfoData();
}

void BotFactory::ClearEverything()
{
    bot->GiveLevel(bot->GetClass() == CLASS_DEATH_KNIGHT ? sWorld->getIntConfig(CONFIG_START_HEROIC_PLAYER_LEVEL)
                                                        : sWorld->getIntConfig(CONFIG_START_PLAYER_LEVEL));
    bot->SetUInt32Value(PLAYER_FIELD_XP, 0);
    TC_LOG_INFO("playerbots", "Resetting player...");
    bot->ResetTalents(true);
}
  
ObjectGuid BotFactory::GetRandomBot()
{
    GuidVector guids;
    for (std::vector<uint32>::iterator i = sPlayerbotAIConfig->randomBotAccounts.begin();
        i != sPlayerbotAIConfig->randomBotAccounts.end(); i++)
    {
        uint32 accountId = *i;
        if (!AccountMgr::GetCharactersCount(accountId))
            continue;
 
        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARS_BY_ACCOUNT_ID);
        stmt->setUInt32(0, accountId);
        PreparedQueryResult result = CharacterDatabase.Query(stmt);
        if (!result)
            continue;
 
        do
        {
            Field* fields = result->Fetch();
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(fields[0].GetUInt32());
            if (!ObjectAccessor::FindPlayer(guid))
                guids.push_back(guid);
        } while (result->NextRow());
    }
 
    if (guids.empty())
        return ObjectGuid::Empty;
 
    uint32 index = urand(0, guids.size() - 1);
    return guids[index];
}
 
std::vector<InventoryType> BotFactory::GetPossibleInventoryTypeListBySlot(EquipmentSlots slot)
{
    std::vector<InventoryType> ret;
    switch (slot)
    {
    case EQUIPMENT_SLOT_HEAD:
        ret.push_back(INVTYPE_HEAD);
        break;
    case EQUIPMENT_SLOT_NECK:
        ret.push_back(INVTYPE_NECK);
        break;
    case EQUIPMENT_SLOT_SHOULDERS:
        ret.push_back(INVTYPE_SHOULDERS);
        break;
    case EQUIPMENT_SLOT_BODY:
        ret.push_back(INVTYPE_BODY);
        break;
    case EQUIPMENT_SLOT_CHEST:
        ret.push_back(INVTYPE_CHEST);
        ret.push_back(INVTYPE_ROBE);
        break;
    case EQUIPMENT_SLOT_WAIST:
        ret.push_back(INVTYPE_WAIST);
        break;
    case EQUIPMENT_SLOT_LEGS:
        ret.push_back(INVTYPE_LEGS);
        break;
    case EQUIPMENT_SLOT_FEET:
        ret.push_back(INVTYPE_FEET);
        break;
    case EQUIPMENT_SLOT_WRISTS:
        ret.push_back(INVTYPE_WRISTS);
        break;
    case EQUIPMENT_SLOT_HANDS:
        ret.push_back(INVTYPE_HANDS);
        break;
    case EQUIPMENT_SLOT_FINGER1:
    case EQUIPMENT_SLOT_FINGER2:
        ret.push_back(INVTYPE_FINGER);
        break;
    case EQUIPMENT_SLOT_TRINKET1:
    case EQUIPMENT_SLOT_TRINKET2:
        ret.push_back(INVTYPE_TRINKET);
        break;
    case EQUIPMENT_SLOT_BACK:
        ret.push_back(INVTYPE_CLOAK);
        break;
    case EQUIPMENT_SLOT_MAINHAND:
        ret.push_back(INVTYPE_WEAPON);
        ret.push_back(INVTYPE_2HWEAPON);
        ret.push_back(INVTYPE_WEAPONMAINHAND);
        ret.push_back(INVTYPE_RANGED);
        break;
    case EQUIPMENT_SLOT_OFFHAND:
        ret.push_back(INVTYPE_WEAPON);
        ret.push_back(INVTYPE_2HWEAPON);
        ret.push_back(INVTYPE_WEAPONOFFHAND);
        ret.push_back(INVTYPE_SHIELD);
        ret.push_back(INVTYPE_HOLDABLE);
        break;
    case EQUIPMENT_SLOT_RANGED:
        ret.push_back(INVTYPE_RANGED);
        break;
    default:
        break;
    }
    return ret;
}

bool BotFactory::CanEquipUnseenItem(uint8 slot, uint16& dest, uint32 item)
{
    dest = 0;

    if (Item* pItem = Item::CreateItem(item, 1, bot, true))
    {
        InventoryResult result = botAI ? botAI->CanEquipItem(slot, dest, pItem, true, true)
            : bot->CanEquipItem(slot, dest, pItem, true, true);
        pItem->RemoveFromUpdateQueueOf(bot);
        delete pItem;
        return result == EQUIP_ERR_OK;
    }

    return false;
}

bool BotFactory::CanEquipItem(ItemTemplate const* proto)
{
    if (proto->Duration != 0)
        return false;

    if (proto->Bonding == BIND_QUEST /*|| proto->Bonding == BIND_WHEN_USE*/)
        return false;

    if (proto->Class == ITEM_CLASS_CONTAINER)
        return true;

    uint32 requiredLevel = proto->RequiredLevel;
    bool hasItem = bot->HasItemCount(proto->ItemId, 1, false);
    if (!requiredLevel && hasItem)
        return false;

    uint32 level = bot->GetLevel();

    if (requiredLevel > level)
        return false;

    return true;
}

void BotFactory::InitBags()
{
    // A normal, unrestricted 28-slot MoP bag. Bags are prepared before armor
    // so Caller/spec initialization always has room to preserve replaced gear.
    static uint32 constexpr PlayerbotBagEntry = 82446; // Royal Satchel

    ItemTemplate const* desiredBag = sObjectMgr->GetItemTemplate(PlayerbotBagEntry);
    if (!desiredBag || desiredBag->InventoryType != INVTYPE_BAG)
    {
        TC_LOG_ERROR("playerbots", "Cannot initialize playerbot bags: item %u is not a valid bag",
            PlayerbotBagEntry);
        return;
    }

    for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < INVENTORY_SLOT_BAG_END; ++slot)
    {
        Bag* currentBag = bot->GetBagByPos(slot);
        if (currentBag)
        {
            // Never remove a bag containing items. Keep an equal or larger
            // empty bag as well; only a safely empty smaller bag is upgraded.
            if (!currentBag->IsEmpty() || currentBag->GetBagSize() >= desiredBag->ContainerSlots)
                continue;
        }
        else if (bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        {
            // An invalid non-bag object in a bag slot must not be destroyed by
            // automated maintenance.
            continue;
        }

        uint16 destination = 0;
        bool const replacing = currentBag != nullptr;
        if (bot->CanEquipNewItem(slot, destination, PlayerbotBagEntry, replacing) != EQUIP_ERR_OK)
            continue;

        if (currentBag)
        {
            uint16 const currentPosition = uint16(INVENTORY_SLOT_BAG_0) << 8 | slot;
            if (bot->CanUnequipItem(currentPosition, false) != EQUIP_ERR_OK)
                continue;

            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
        }

        if (!bot->EquipNewItem(destination, PlayerbotBagEntry, true))
            TC_LOG_ERROR("playerbots", "Failed to equip bag %u for bot %s in slot %u",
                PlayerbotBagEntry, bot->GetName().c_str(), uint32(slot));
    }
}

void BotFactory::InitEquipment(bool incremental, bool second_chance)
{
    InitEquipmentInternal(incremental, second_chance, false, false);
}

void BotFactory::InitMissingEquipment()
{
    InitEquipmentInternal(true, false, true, false);
}

void BotFactory::InitEquipmentForSpec()
{
    // The first pass repairs the main hand. A protection build which arrived
    // with a two-hander cannot equip its shield until that swap has happened,
    // so a second cheap pass completes dependent offhand combinations.
    InitEquipmentInternal(true, false, true, true);
    InitEquipmentInternal(true, false, true, true);
}

void BotFactory::InitManagedEquipmentForSpec(uint32 minimumItemLevel)
{
    // Managed group fillers must have every specialization-compatible slot,
    // not just five armor pieces and a weapon.  Two passes let a main-hand
    // replacement unlock a dependent shield/off-hand on the second pass.
    InitEquipmentInternal(true, false, true, true, minimumItemLevel, false, true);
    InitEquipmentInternal(true, false, true, true, minimumItemLevel, false, true);
}

uint32 BotFactory::InitManagedEnhancements(ManagedLoadoutMode mode)
{
    if (!bot || bot->GetSpecialization() == SPEC_NONE)
        return 0;

    Specializations const specialization = bot->GetSpecialization();
    bool const healer = PlayerBotSpec::IsHeal(bot, true);
    bool const tank = AiFactory::GetPlayerRoles(bot) == BOT_ROLE_TANK;
    bool agility = bot->GetClass() == CLASS_HUNTER ||
        bot->GetClass() == CLASS_ROGUE || bot->GetClass() == CLASS_MONK ||
        specialization == SPEC_DRUID_FERAL ||
        specialization == SPEC_DRUID_GUARDIAN ||
        specialization == SPEC_SHAMAN_ENHANCEMENT;
    bool intellect = healer || bot->GetClass() == CLASS_MAGE ||
        bot->GetClass() == CLASS_PRIEST || bot->GetClass() == CLASS_WARLOCK ||
        specialization == SPEC_DRUID_BALANCE ||
        specialization == SPEC_SHAMAN_ELEMENTAL;

    // MoP SpellItemEnchantment.dbc IDs.  Gems are represented by the
    // enchantment carried by the corresponding gem item.
    uint32 const primaryGem = intellect ? 4644u : (agility ? 4643u : 4646u);
    uint32 const pvpPowerGem = 4588u;
    uint32 const resilienceGem = 4586u;
    uint32 const metaGemItem = tank ? 76895u :
        (healer ? 76888u :
            (intellect ? 76885u : (agility ? 76884u : 76886u)));
    uint32 metaGemEnchant = 0;
    if (ItemTemplate const* metaGem = sObjectMgr->GetItemTemplate(metaGemItem))
        if (GemPropertiesEntry const* properties =
                sGemPropertiesStore.LookupEntry(metaGem->GemProperties))
            metaGemEnchant = properties->spellitemenchantement;
    uint32 changed = 0;
    Item* changedMetaItem = nullptr;
    EnchantmentSlot changedMetaSlot = SOCK_ENCHANTMENT_SLOT;

    auto replaceEnchant = [&](Item* item, EnchantmentSlot slot, uint32 enchant)
    {
        if (!item || !enchant || item->GetEnchantmentId(slot) == enchant)
            return;
        bot->ApplyEnchantment(item, slot, false);
        item->SetEnchantment(slot, enchant, 0, 0, bot->GetGUID());
        bot->ApplyEnchantment(item, slot, true);
        ++changed;
    };

    for (uint8 equipmentSlot = EQUIPMENT_SLOT_START;
         equipmentSlot < EQUIPMENT_SLOT_END; ++equipmentSlot)
    {
        Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, equipmentSlot);
        if (!item)
            continue;

        for (uint8 socket = 0; socket < MAX_GEM_SOCKETS; ++socket)
        {
            uint32 const color = item->GetTemplate()->Socket[socket].Color;
            if (!color || color == SOCKET_COLOR_COGWHEEL ||
                color == SOCKET_COLOR_HYDRAULIC)
                continue;

            EnchantmentSlot const enchantmentSlot =
                EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + socket);
            if (color == SOCKET_COLOR_META)
            {
                if (metaGemEnchant &&
                    item->GetEnchantmentId(enchantmentSlot) != metaGemEnchant)
                {
                    // Apply the new meta only after all ordinary gems are in
                    // place, otherwise its colour requirement can be tested
                    // against a half-finished loadout.
                    bot->ApplyEnchantment(item, enchantmentSlot, false);
                    item->SetEnchantment(enchantmentSlot, metaGemEnchant,
                        0, 0, bot->GetGUID());
                    changedMetaItem = item;
                    changedMetaSlot = enchantmentSlot;
                    ++changed;
                }
                continue;
            }

            uint32 gem = primaryGem;
            if (mode == ManagedLoadoutMode::Pvp)
                gem = tank || color == SOCKET_COLOR_YELLOW ?
                    resilienceGem : (color == SOCKET_COLOR_BLUE ?
                        pvpPowerGem : primaryGem);
            else if (healer && color == SOCKET_COLOR_BLUE)
                gem = 4589u; // Sparkling: Spirit

            replaceEnchant(item, enchantmentSlot, gem);
        }

        uint32 permanentEnchant = 0;
        switch (equipmentSlot)
        {
            case EQUIPMENT_SLOT_SHOULDERS:
                permanentEnchant = tank ? 4805u :
                    (intellect ? 4806u : (agility ? 4804u : 4803u));
                break;
            case EQUIPMENT_SLOT_BACK:
                permanentEnchant = intellect ? 4423u : 4424u;
                break;
            case EQUIPMENT_SLOT_CHEST:
                permanentEnchant = tank ? 4420u : 4419u;
                break;
            case EQUIPMENT_SLOT_WRISTS:
                permanentEnchant = intellect ? 4414u :
                    (agility ? 4411u : 4415u);
                break;
            case EQUIPMENT_SLOT_HANDS:
                permanentEnchant = intellect || agility ? 4430u : 4432u;
                break;
            case EQUIPMENT_SLOT_LEGS:
                permanentEnchant = tank ? 4824u : (intellect ?
                    (healer ? 4826u : 4825u) : (agility ? 4822u : 4823u));
                break;
            case EQUIPMENT_SLOT_FEET:
                permanentEnchant = agility ? 4428u : 4429u;
                break;
            case EQUIPMENT_SLOT_MAINHAND:
                permanentEnchant = tank ? 4445u :
                    (intellect ? 4442u : 4444u);
                break;
            case EQUIPMENT_SLOT_OFFHAND:
                if (intellect && item->GetTemplate()->Class == ITEM_CLASS_ARMOR)
                    permanentEnchant = 4434u;
                break;
            default:
                break;
        }
        replaceEnchant(item, PERM_ENCHANTMENT_SLOT, permanentEnchant);
    }

    if (changedMetaItem)
        bot->ApplyEnchantment(changedMetaItem, changedMetaSlot, true);

    return changed;
}

bool BotFactory::PrepareManagedLoadout(ManagedLoadoutMode mode,
                                       uint32 minimumItemLevel,
                                       std::string* reason)
{
    InitBags();
    InitManagedEquipmentForSpec(minimumItemLevel);
    InitTalentsTree(false);
    InitGlyphs();
    InitPet();
    uint32 const enhancements = InitManagedEnhancements(mode);

    if (!HasRequiredEquipmentForSpec(reason))
        return false;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        {
            if (!sRandomItemMgr->IsCustomServerItem(item->GetEntry()))
                continue;

            TC_LOG_ERROR("playerbots",
                "Managed loadout rejected custom item %u still equipped by bot %s in slot %u",
                item->GetEntry(), bot->GetName().c_str(), uint32(slot));
            if (reason)
                *reason = "custom-equipment-remains";
            return false;
        }
    }

    if (minimumItemLevel && bot->GetAverageItemLevel() < minimumItemLevel)
    {
        if (reason)
            *reason = "average-item-level-below-managed-floor";
        return false;
    }

    TC_LOG_INFO("playerbots",
        "Managed %s loadout ready name=%s guid=%u specialization=%u avg-ilvl=%u floor=%u enhancements=%u",
        mode == ManagedLoadoutMode::Pvp ? "PvP" : "PvE",
        bot->GetName().c_str(), bot->GetGUID().GetCounter(),
        uint32(bot->GetSpecialization()), uint32(bot->GetAverageItemLevel()),
        minimumItemLevel, enhancements);
    if (reason)
        reason->clear();
    return true;
}

uint32 BotFactory::GetWeaponReferenceItemLevel() const
{
    // Weapons dominate damage output, so compare them with the character's
    // actual core armor instead of accepting any level-appropriate weapon.
    // Jewelry and cloaks are intentionally excluded because their item level
    // can vary widely without representing the bot's combat tier.
    static uint8 const armorSlots[] =
    {
        EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_SHOULDERS,
        EQUIPMENT_SLOT_CHEST, EQUIPMENT_SLOT_WAIST,
        EQUIPMENT_SLOT_LEGS, EQUIPMENT_SLOT_FEET,
        EQUIPMENT_SLOT_WRISTS, EQUIPMENT_SLOT_HANDS
    };

    std::vector<uint32> levels;
    for (uint8 slot : armorSlots)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (ItemTemplate const* itemTemplate = item->GetTemplate())
                if (itemTemplate->ItemLevel)
                    levels.push_back(itemTemplate->ItemLevel);

    if (levels.empty())
        return bot->GetLevel() >= 90 ? 450 : 0;

    std::sort(levels.begin(), levels.end());
    uint32 reference = levels[levels.size() / 2];
    if (levels.size() % 2 == 0)
        reference = (reference + levels[levels.size() / 2 - 1]) / 2;

    return std::max(reference, bot->GetLevel() >= 90 ? 450u : 0u);
}

bool BotFactory::MoveEquippedItemToBag(uint8 slot)
{
    Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item)
        return true;

    uint16 position = uint16(INVENTORY_SLOT_BAG_0) << 8 | slot;
    ItemPosCountVec destination;
    if (bot->CanUnequipItem(position, false) != EQUIP_ERR_OK ||
        bot->CanStoreItem(NULL_BAG, NULL_SLOT, destination, item, false) !=
            EQUIP_ERR_OK)
        return false;

    bot->RemoveItem(INVENTORY_SLOT_BAG_0, slot, true);
    bot->StoreItem(destination, item, true);
    return true;
}

void BotFactory::InitEquipmentInternal(bool incremental, bool second_chance,
                                       bool missingOnly, bool specCompatible,
                                       uint32 minimumItemLevel,
                                       bool preserveReplaced,
                                       bool genuineItemsOnly)
{
    InitBags();

    std::unordered_map<uint8, std::vector<uint32>> items;
    uint32 blevel = bot->GetLevel();
    int32 delta = std::min(blevel, 10u);
    uint32 const weaponReferenceItemLevel = specCompatible ?
        GetWeaponReferenceItemLevel() : 0;
    uint32 const weaponMinimumItemLevel = weaponReferenceItemLevel > 35 ?
        weaponReferenceItemLevel - 35 : weaponReferenceItemLevel;

    for (int32 slot = (int32)EQUIPMENT_SLOT_TABARD; slot >= (int32)EQUIPMENT_SLOT_START; slot--)
    {
        if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_BODY || slot == EQUIPMENT_SLOT_RANGED)
            continue;

        if (level < 50 && (slot == EQUIPMENT_SLOT_TRINKET1 || slot == EQUIPMENT_SLOT_TRINKET2))
            continue;

        if (level < 30 && slot == EQUIPMENT_SLOT_NECK)
            continue;

        if (level < 25 && slot == EQUIPMENT_SLOT_HEAD)
            continue;

        if (level < 20 && (slot == EQUIPMENT_SLOT_FINGER1 || slot == EQUIPMENT_SLOT_FINGER2))
            continue;

        Item* oldItem = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        // LFG preparation must repair an incomplete character without
        // replacing equipment the bot already owns. The older InitEquipment
        // paths retain their historical full-randomization behaviour.
        if (missingOnly && oldItem)
        {
            bool const customServerItem = genuineItemsOnly &&
                sRandomItemMgr->IsCustomServerItem(oldItem->GetEntry());
            bool const validForSpec = !customServerItem &&
                (!specCompatible ||
                    sRandomItemMgr->IsItemValidForEquipmentSlot(
                        bot, EquipmentSlots(slot), oldItem->GetTemplate()));
            bool const weaponSlot = slot == EQUIPMENT_SLOT_MAINHAND ||
                slot == EQUIPMENT_SLOT_OFFHAND;
            uint32 const slotFloor = minimumItemLevel ? minimumItemLevel :
                (weaponSlot ? weaponMinimumItemLevel : 0u);
            bool const underleveledItem = specCompatible && validForSpec &&
                slotFloor && oldItem->GetTemplate()->ItemLevel < slotFloor;

            if (validForSpec && !underleveledItem)
                continue;

            if (underleveledItem)
                TC_LOG_INFO("playerbots",
                    "Upgrading underleveled managed item %u (ilvl %u, floor %u) for bot %s slot %u",
                    oldItem->GetEntry(), oldItem->GetTemplate()->ItemLevel,
                    slotFloor, bot->GetName().c_str(),
                    uint32(slot));
            else if (customServerItem)
                TC_LOG_INFO("playerbots",
                    "Replacing custom managed item %u for bot %s slot %u with client-known equipment",
                    oldItem->GetEntry(), bot->GetName().c_str(),
                    uint32(slot));
        }

        if (specCompatible && slot == EQUIPMENT_SLOT_OFFHAND &&
            !sRandomItemMgr->SupportsOffhandForSpec(bot))
        {
            if (oldItem)
            {
                if (preserveReplaced)
                {
                    if (!MoveEquippedItemToBag(slot))
                        TC_LOG_ERROR("playerbots",
                            "Cannot preserve unsupported offhand item %u for bot %s",
                            oldItem->GetEntry(), bot->GetName().c_str());
                }
                else
                    bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
            }
            continue;
        }
        if (oldItem && second_chance)
        {
            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
        }

        oldItem = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        bool isforcedbreak = false;
        int maxiRetry = 10;
        do
        {
            for (InventoryType inventoryType : GetPossibleInventoryTypeListBySlot((EquipmentSlots)slot))
            {
                uint32 itemid = sRandomItemMgr->FindBestItemForLevelAndEquip(
                    bot, inventoryType, genuineItemsOnly);
                if (itemid)
                {
                    uint32 skipProb = 25;
                    if (urand(1, 100) <= skipProb)
                        continue;

                    items[slot].push_back(itemid);
                }
                else
                {
                    maxiRetry--;
                    if (maxiRetry <= 0)
                    {
                        isforcedbreak = true;
                        break;
                    }
                }
            }
        } while (items[slot].size() < 25 && !isforcedbreak);

        std::vector<uint32>& ids = items[slot];
        if (ids.empty())
        {
            continue;
        }

        uint32 bestItemForSlot = 0;
        uint32 bestItemLevelDistance = UINT32_MAX;
        uint32 bestItemLevel = 0;
        for (int index = 0; index < ids.size(); index++)
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(ids[index]);

            // delay heavy check to here
            if (genuineItemsOnly &&
                sRandomItemMgr->IsCustomServerItem(proto->ItemId))
                continue;
            if (!CanEquipItem(proto))
                continue;
            if (specCompatible &&
                !sRandomItemMgr->IsItemValidForEquipmentSlot(bot,
                    EquipmentSlots(slot), proto))
                continue;
            uint16 dest;
            if (!CanEquipUnseenItem(slot, dest, proto->ItemId))
                continue;

            bool const weaponSlot = slot == EQUIPMENT_SLOT_MAINHAND ||
                slot == EQUIPMENT_SLOT_OFFHAND;
            if (specCompatible && weaponSlot &&
                proto->ItemLevel < weaponMinimumItemLevel)
                continue;
            if (minimumItemLevel && proto->ItemLevel < minimumItemLevel)
                continue;

            if (specCompatible && weaponSlot && weaponReferenceItemLevel)
            {
                uint32 const distance = proto->ItemLevel > weaponReferenceItemLevel ?
                    proto->ItemLevel - weaponReferenceItemLevel :
                    weaponReferenceItemLevel - proto->ItemLevel;
                if (bestItemForSlot &&
                    (distance > bestItemLevelDistance ||
                     (distance == bestItemLevelDistance &&
                      proto->ItemLevel <= bestItemLevel)))
                    continue;

                bestItemLevelDistance = distance;
                bestItemLevel = proto->ItemLevel;
            }
            bestItemForSlot = proto->ItemId;
        }

        if (bestItemForSlot == 0)
        {
            continue;
        }
        uint16 dest;
        if (!CanEquipUnseenItem(slot, dest, bestItemForSlot))
        {
            continue;
        }

        oldItem = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (oldItem && specCompatible && preserveReplaced)
        {
            if (!MoveEquippedItemToBag(slot))
            {
                TC_LOG_ERROR("playerbots",
                    "Cannot preserve incompatible item %u for bot %s slot %u",
                    oldItem->GetEntry(), bot->GetName().c_str(), uint32(slot));
                continue;
            }
        }
        else if (oldItem)
        {
            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
        }
        Item* newItem = bot->EquipNewItem(dest, bestItemForSlot, true);
        if (!newItem)
            TC_LOG_ERROR("playerbots",
                "Cannot equip generated item %u for bot %s slot %u",
                bestItemForSlot, bot->GetName().c_str(), uint32(slot));
        bot->AutoUnequipOffhandIfNeed();
    }

    // Secondary init for better equips
    /// @todo: clean up duplicate code
    if (second_chance)
    {
        for (int32 slot = (int32)EQUIPMENT_SLOT_TABARD; slot >= (int32)EQUIPMENT_SLOT_START; slot--)
        {
            if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_BODY)
                continue;

            if (level < 50 && (slot == EQUIPMENT_SLOT_TRINKET1 || slot == EQUIPMENT_SLOT_TRINKET2))
                continue;

            if (level < 30 && slot == EQUIPMENT_SLOT_NECK)
                continue;

            if (level < 25 && slot == EQUIPMENT_SLOT_HEAD)
                continue;

            if (level < 20 && (slot == EQUIPMENT_SLOT_FINGER1 || slot == EQUIPMENT_SLOT_FINGER2))
                continue;

            if (Item* oldItem = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);

            std::vector<uint32>& ids = items[slot];
            if (ids.empty())
                continue;

            float bestScoreForSlot = -1;
            uint32 bestItemForSlot = 0;
            for (int index = 0; index < ids.size(); index++)
            {
                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(ids[index]);
                // delay heavy check to here
                if (!CanEquipItem(proto))
                    continue;
                uint16 dest;
                if (!CanEquipUnseenItem(slot, dest, proto->ItemId))
                    continue;
                bestItemForSlot = proto->ItemId;
            }

            if (bestItemForSlot == 0)
            {
                continue;
            }
            uint16 dest;
            if (!CanEquipUnseenItem(slot, dest, bestItemForSlot))
            {
                continue;
            }
            Item* newItem = bot->EquipNewItem(dest, bestItemForSlot, true);
            bot->AutoUnequipOffhandIfNeed();
        }
    }
}

bool BotFactory::HasRequiredEquipmentForSpec(std::string* reason) const
{
    auto fail = [&](char const* issue) -> bool
    {
        if (reason)
            *reason = issue;
        return false;
    };

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (slot == EQUIPMENT_SLOT_BODY || slot == EQUIPMENT_SLOT_RANGED ||
            slot == EQUIPMENT_SLOT_TABARD)
            continue;
        if (level < 50 && (slot == EQUIPMENT_SLOT_TRINKET1 ||
            slot == EQUIPMENT_SLOT_TRINKET2))
            continue;
        if (level < 30 && slot == EQUIPMENT_SLOT_NECK)
            continue;
        if (level < 25 && slot == EQUIPMENT_SLOT_HEAD)
            continue;
        if (level < 20 && (slot == EQUIPMENT_SLOT_FINGER1 ||
            slot == EQUIPMENT_SLOT_FINGER2))
            continue;
        if (slot == EQUIPMENT_SLOT_OFFHAND &&
            !sRandomItemMgr->NeedsOffhandForSpec(bot))
            continue;

        Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item)
            return fail(slot == EQUIPMENT_SLOT_MAINHAND ?
                "missing-main-hand" :
                (slot == EQUIPMENT_SLOT_OFFHAND ?
                    "missing-required-off-hand" : "missing-equipment-slot"));
        if (!sRandomItemMgr->IsItemValidForEquipmentSlot(bot,
                EquipmentSlots(slot), item->GetTemplate()))
            return fail(slot == EQUIPMENT_SLOT_MAINHAND ?
                "invalid-main-hand-for-specialization" :
                (slot == EQUIPMENT_SLOT_OFFHAND ?
                    "invalid-off-hand-for-specialization" :
                    "invalid-equipment-for-specialization"));
    }

    if (reason)
        reason->clear();
    return true;
}

bool BotFactory::HasRequiredWeaponSetForSpec(std::string* reason) const
{
    auto fail = [&](char const* issue) -> bool
    {
        if (reason)
            *reason = issue;
        return false;
    };

    Item* mainHand = bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
        EQUIPMENT_SLOT_MAINHAND);
    if (!mainHand)
        return fail("missing-main-hand");
    if (!sRandomItemMgr->IsItemValidForEquipmentSlot(bot,
            EQUIPMENT_SLOT_MAINHAND, mainHand->GetTemplate()))
        return fail("invalid-main-hand-for-specialization");

    if (sRandomItemMgr->NeedsOffhandForSpec(bot))
    {
        Item* offHand = bot->GetItemByPos(INVENTORY_SLOT_BAG_0,
            EQUIPMENT_SLOT_OFFHAND);
        if (!offHand)
            return fail("missing-required-off-hand");
        if (!sRandomItemMgr->IsItemValidForEquipmentSlot(bot,
                EQUIPMENT_SLOT_OFFHAND, offHand->GetTemplate()))
            return fail("invalid-off-hand-for-specialization");
    }

    if (reason)
        reason->clear();
    return true;
}
