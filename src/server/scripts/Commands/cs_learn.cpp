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

/* ScriptData
Name: learn_commandscript
%Complete: 100
Comment: All learn related commands
Category: commandscripts
EndScriptData */

#include "Chat.h"
#include "ScriptMgr.h"
#include "ObjectMgr.h"
#include "Language.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "Player.h"
#include "Pet.h"
#include "ClassSpellCommandPolicy.h"
#include <algorithm>
#include <map>
#include <set>

class learn_commandscript : public CommandScript
{
public:
    learn_commandscript() : CommandScript("learn_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> learnAllMyCommandTable =
        {
            { "class",      SEC_GAMEMASTER, false, &HandleLearnAllMyClassCommand,
                "Syntax: .learn all my class\nLearn your class spells, all own-class talents, and active specialization spells (GM testing)." },
            { "pettalents", SEC_GAMEMASTER, false, &HandleLearnAllMyPetTalentsCommand,  },
            { "spells",     SEC_GAMEMASTER, false, &HandleLearnAllMySpellsCommand,      },
            { "talents",    SEC_GAMEMASTER, false, &HandleLearnAllMyTalentsCommand,     },
            { "glyphs",     SEC_GAMEMASTER, false, &HandleLearnAllMyGlyphsCommand,      },
        };

        static std::vector<ChatCommand> learnAllCommandTable =
        {
            { "my",         SEC_GAMEMASTER, false,  learnAllMyCommandTable              },
            { "gm",         SEC_GAMEMASTER, false,  &HandleLearnAllGMCommand,           },
            { "crafts",     SEC_GAMEMASTER, false,  &HandleLearnAllCraftsCommand,       },
            { "default",    SEC_GAMEMASTER, false,  &HandleLearnAllDefaultCommand,      },
            { "lang",       SEC_GAMEMASTER, false,  &HandleLearnAllLangCommand,         },
            { "recipes",    SEC_GAMEMASTER, false,  &HandleLearnAllRecipesCommand,      },
        };

        static std::vector<ChatCommand> learnCommandTable =
        {
            { "all",        SEC_GAMEMASTER, false,  learnAllCommandTable                },
            { "",           SEC_GAMEMASTER, false,  &HandleLearnCommand,                },
        };

        static std::vector<ChatCommand> unlearnAllMyCommandTable =
        {
            { "class",      SEC_GAMEMASTER, false, &HandleUnLearnAllMyClassCommand,
                "Syntax: .unlearn all my class\nUnlearn your class spells and own-class talents in both specs. Preserve shared skills and glyph unlocks." },
        };

        static std::vector<ChatCommand> unlearnAllCommandTable =
        {
            { "my",         SEC_GAMEMASTER, false, unlearnAllMyCommandTable             },
        };

        static std::vector<ChatCommand> unlearnCommandTable =
        {
            { "all",        SEC_GAMEMASTER, false, unlearnAllCommandTable               },
            { "",           SEC_GAMEMASTER, false, &HandleUnLearnCommand,               },
        };

        static std::vector<ChatCommand> commandTable =
        {
            { "learn",      SEC_GAMEMASTER, false,  learnCommandTable                   },
            { "unlearn",    SEC_GAMEMASTER, false,  unlearnCommandTable                 },
        };
        return commandTable;
    }

    static bool HandleLearnCommand(ChatHandler* handler, char const* args)
    {
        Player* targetPlayer = handler->getSelectedPlayer();

        if (!targetPlayer)
        {
            handler->SendSysMessage(LANG_PLAYER_NOT_FOUND);
            handler->SetSentErrorMessage(true);
            return false;
        }

        // number or [name] Shift-click form |color|Hspell:spell_id|h[name]|h|r or Htalent form
        uint32 spell = handler->extractSpellIdFromLink((char*)args);
        if (!spell || !sSpellMgr->GetSpellInfo(spell))
            return false;

        char const* all = strtok(NULL, " ");
        bool allRanks = all ? (strncmp(all, "all", strlen(all)) == 0) : false;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spell);
        if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, handler->GetSession()->GetPlayer()))
        {
            handler->PSendSysMessage(LANG_COMMAND_SPELL_BROKEN, spell);
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (!allRanks && targetPlayer->HasSpell(spell))
        {
            if (targetPlayer == handler->GetSession()->GetPlayer())
                handler->SendSysMessage(LANG_YOU_KNOWN_SPELL);
            else
                handler->PSendSysMessage(LANG_TARGET_KNOWN_SPELL, handler->GetNameLink(targetPlayer).c_str());
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (allRanks)
            targetPlayer->learnSpellHighRank(spell);
        else
            targetPlayer->LearnSpell(spell, false);

        if (GetTalentSpellCost(spellInfo->GetFirstRankSpell()->Id))
            targetPlayer->SendTalentsInfoData();

        return true;
    }

    static bool HandleLearnAllGMCommand(ChatHandler* handler, char const* /*args*/)
    {
        for (uint32 i = 0; i < sSpellMgr->GetSpellInfoStoreSize(); ++i)
        {
            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(i);
            if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, handler->GetSession()->GetPlayer(), false))
                continue;

            if (!spellInfo->IsAbilityOfSkillType(SKILL_INTERNAL))
                continue;

            handler->GetSession()->GetPlayer()->LearnSpell(i, false);
        }

        handler->SendSysMessage(LANG_LEARNING_GM_SKILLS);
        return true;
    }

    // Some glyph unlocks and shared skills use a class spell family. A family
    // match alone must not erase professions, racial abilities or glyph unlocks.
    static bool IsProtectedClassCommandSpell(Player* player, uint32 spellId)
    {
        if (SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId))
            if (spell->IsAccountWide() || spell->HasAura(SPELL_AURA_MOUNTED))
                return true;

        if (auto glyphs = sSpellMgr->GetGlyphsForClass(player->GetClass()))
            if (std::find(glyphs->begin(), glyphs->end(), spellId) != glyphs->end())
                return true;

        auto bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
        for (auto it = bounds.first; it != bounds.second; ++it)
        {
            SkillLineAbilityEntry const* ability = it->second;
            SkillLineEntry const* skill = sSkillLineStore.LookupEntry(ability->skillId);
            if (!skill)
                continue;
            if (skill->categoryId != SKILL_CATEGORY_CLASS)
                return true;
        }
        return false;
    }

    static bool HandleLearnAllMyClassCommand(ChatHandler* handler, char const* args)
    {
        if (*args)
            return false;
        Player* player = handler->GetSession()->GetPlayer();
        // Reapply native class-skill rewards too: some baseline passives have
        // SpellLevel=0 and are deliberately skipped by the broad GM spell scan.
        for (uint32 i = 0; i < sSkillLineStore.GetNumRows(); ++i)
        {
            SkillLineEntry const* skill = sSkillLineStore.LookupEntry(i);
            if (skill && skill->categoryId == SKILL_CATEGORY_CLASS && player->HasSkill(skill->id))
                player->LearnSkillRewardedSpells(skill->id, player->GetPureSkillValue(skill->id));
        }
        HandleLearnAllMySpellsCommand(handler, "");
        HandleLearnAllMyTalentsCommand(handler, "");
        player->LearnSpecializationSpells();
        player->SaveToDB();
        return true;
    }

    static bool HandleUnLearnAllMyClassCommand(ChatHandler* handler, char const* args)
    {
        if (*args)
            return false;

        Player* player = handler->GetSession()->GetPlayer();
        if (player->IsInCombat())
        {
            handler->SendSysMessage("Leave combat before unlearning your class spells.");
            return false;
        }

        ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(player->GetClass());
        if (!classEntry)
            return false;

        // Generic-family abilities still have owners in class skill lines,
        // specialization records or Talent.dbc. Family-only filtering misses
        // e.g. Pandemic, Soul Shards, Path of Frost and armor specializations.
        std::map<uint32, uint32> owners;
        for (uint32 i = 0; i < sSkillLineAbilityStore.GetNumRows(); ++i)
        {
            SkillLineAbilityEntry const* ability = sSkillLineAbilityStore.LookupEntry(i);
            if (!ability)
                continue;
            SkillLineEntry const* skill = sSkillLineStore.LookupEntry(ability->skillId);
            if (!skill || skill->categoryId != SKILL_CATEGORY_CLASS)
                continue;
            owners[ability->spellId] |= ability->classmask;
            if (!ability->classmask && player->HasSkill(ability->skillId) &&
                (!ability->racemask || (ability->racemask & player->GetRaceMask())))
                owners[ability->spellId] |= player->GetClassMask();
        }
        for (uint32 i = 0; i < sSpecializationSpellsStore.GetNumRows(); ++i)
        {
            SpecializationSpellsEntry const* entry = sSpecializationSpellsStore.LookupEntry(i);
            if (!entry)
                continue;
            ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(entry->SpecializationId);
            if (spec && spec->classId > 0 && spec->classId < MAX_CLASSES)
                owners[entry->SpellId] |= uint32(1) << (spec->classId - 1);
        }
        for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
        {
            TalentEntry const* talent = sTalentStore.LookupEntry(i);
            if (talent && talent->PlayerClass > 0 && talent->PlayerClass < MAX_CLASSES)
                owners[talent->SpellId] |= uint32(1) << (talent->PlayerClass - 1);
        }

        // Snapshot IDs before RemoveSpell recursively changes the spell map.
        // Include passive/level-zero class spells, but never another class's
        // family or common skills. This is not a cross-class corruption reset.
        std::set<uint32> spells;
        for (auto const& entry : player->GetSpellMap())
        {
            if (entry.second->state == PLAYERSPELL_REMOVED || entry.second->state == PLAYERSPELL_TEMPORARY)
                continue;
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(entry.first);
            if (spell && ClassSpellCommandPolicy::Select(player->GetClassMask(), classEntry->spellfamily,
                spell->SpellFamilyName, owners[entry.first], IsProtectedClassCommandSpell(player, entry.first)))
                spells.insert(entry.first);
        }

        // Talent ownership comes from Talent.dbc: some talents have generic
        // spell families. Clear both saved spec maps so a spec switch cannot
        // restore talents that this command explicitly removed.
        for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
        {
            TalentEntry const* talent = sTalentStore.LookupEntry(i);
            if (!talent || talent->PlayerClass != player->GetClass())
                continue;
            spells.insert(talent->SpellId);
            for (uint8 spec = 0; spec < MAX_TALENT_SPECS; ++spec)
            {
                auto talents = player->GetTalentMap(spec);
                auto it = talents->find(talent->SpellId);
                if (it != talents->end())
                    it->second->state = PLAYERSPELL_REMOVED;
            }
        }

        for (uint32 spellId : spells)
            player->RemoveSpell(spellId, false, false);

        player->RemoveInvalidSpellActionButtons();
        player->SendTalentsInfoData();
        player->SaveToDB();
        handler->SendSysMessage("Your class spells and talents have been unlearned. Shared skills and glyph unlocks were preserved.");
        return true;
    }

    static bool HandleLearnAllMySpellsCommand(ChatHandler* handler, char const* /*args*/)
    {
        ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(handler->GetSession()->GetPlayer()->GetClass());
        if (!classEntry)
            return true;
        uint32 family = classEntry->spellfamily;

        for (uint32 i = 0; i < sSkillLineAbilityStore.GetNumRows(); ++i)
        {
            SkillLineAbilityEntry const* entry = sSkillLineAbilityStore.LookupEntry(i);
            if (!entry)
                continue;

            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(entry->spellId);
            if (!spellInfo)
                continue;

            // skip server-side/triggered spells
            if (spellInfo->SpellLevel == 0)
                continue;

            // skip wrong class/race skills
            if (!handler->GetSession()->GetPlayer()->IsSpellFitByClassAndRace(spellInfo->Id))
                continue;

            // skip other spell families
            if (spellInfo->SpellFamilyName != family)
                continue;

            if (IsProtectedClassCommandSpell(handler->GetSession()->GetPlayer(), spellInfo->Id))
                continue;

            // skip spells with first rank learned as talent (and all talents then also)
            if (GetTalentSpellCost(spellInfo->GetFirstRankSpell()->Id) > 0)
                continue;

            // skip broken spells
            if (!SpellMgr::IsSpellValid(spellInfo, handler->GetSession()->GetPlayer(), false))
                continue;

            handler->GetSession()->GetPlayer()->LearnSpell(spellInfo->Id, false);
        }

        handler->SendSysMessage(LANG_COMMAND_LEARN_CLASS_SPELLS);
        return true;
    }

    static bool HandleLearnAllMyGlyphsCommand(ChatHandler* handler, char const* args)
    {
        Player* player;
        if (!handler->extractPlayerTarget((char*)args, &player))
            return false;

        if (auto glyphSpells = sSpellMgr->GetGlyphsForClass(player->GetClass()))
            for (auto&& spell : *glyphSpells)
                player->LearnSpell(spell, false);
        return true;
    }

    static bool HandleLearnAllMyTalentsCommand(ChatHandler* handler, char const* /*args*/)
    {
        Player* player = handler->GetSession()->GetPlayer();

        for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
        {
            TalentEntry const* talentInfo = sTalentStore.LookupEntry(i);
            if (!talentInfo)
                continue;

            if (talentInfo->PlayerClass != player->GetClass())
                continue;

            // search highest talent rank
            uint32 spellId = talentInfo->SpellId;

            if (!spellId)                                        // ??? none spells in talent
                continue;

            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
            if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, handler->GetSession()->GetPlayer(), false))
                continue;

            // learn highest rank of talent and learn all non-talent spell ranks (recursive by tree)
            player->learnSpellHighRank(spellId);
            player->AddTalent(spellId, player->GetActiveSpec(), true);
        }

        player->SendTalentsInfoData();
        handler->SendSysMessage(LANG_COMMAND_LEARN_CLASS_TALENTS);
        return true;
    }

    static bool HandleLearnAllMyPetTalentsCommand(ChatHandler* handler, char const* /*args*/)
    {
        return false;

        Player* player = handler->GetSession()->GetPlayer();

        Pet* pet = player->GetPet();
        if (!pet)
        {
            handler->SendSysMessage(LANG_NO_PET_FOUND);
            handler->SetSentErrorMessage(true);
            return false;
        }

        CreatureTemplate const* creatureInfo = pet->GetCreatureTemplate();
        if (!creatureInfo)
        {
            handler->SendSysMessage(LANG_WRONG_PET_TYPE);
            handler->SetSentErrorMessage(true);
            return false;
        }

        CreatureFamilyEntry const* petFamily = sCreatureFamilyStore.LookupEntry(creatureInfo->family);
        if (!petFamily)
        {
            handler->SendSysMessage(LANG_WRONG_PET_TYPE);
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (petFamily->petTalentType < 0)                       // not hunter pet
        {
            handler->SendSysMessage(LANG_WRONG_PET_TYPE);
            handler->SetSentErrorMessage(true);
            return false;
        }

        for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
        {
            TalentEntry const* talentInfo = sTalentStore.LookupEntry(i);
            if (!talentInfo)
                continue;

            /*TalentTabEntry const* talentTabInfo = sTalentTabStore.LookupEntry(talentInfo->TalentTab);
            if (!talentTabInfo)
                continue;

            // prevent learn talent for different family (cheating)
            if (((1 << petFamily->petTalentType) & talentTabInfo->petTalentMask) == 0)
                continue;*/

            // search highest talent rank
            uint32 spellId = 0;

            if (!spellId)                                        // ??? none spells in talent
                continue;

            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
            if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, handler->GetSession()->GetPlayer(), false))
                continue;

            // learn highest rank of talent and learn all non-talent spell ranks (recursive by tree)
            pet->learnSpellHighRank(spellId);
        }

        handler->SendSysMessage(LANG_COMMAND_LEARN_PET_TALENTS);
        return true;
    }

    static bool HandleLearnAllLangCommand(ChatHandler* handler, char const* /*args*/)
    {
        // skipping UNIVERSAL language (0)
        for (uint8 i = 1; i < LANGUAGES_COUNT; ++i)
            handler->GetSession()->GetPlayer()->LearnSpell(lang_description[i].spell_id, false);

        handler->SendSysMessage(LANG_COMMAND_LEARN_ALL_LANG);
        return true;
    }

    static bool HandleLearnAllDefaultCommand(ChatHandler* handler, char const* args)
    {
        Player* target;
        if (!handler->extractPlayerTarget((char*)args, &target))
            return false;

        target->LearnDefaultSkills();
        target->learnQuestRewardedSpells();

        handler->PSendSysMessage(LANG_COMMAND_LEARN_ALL_DEFAULT_AND_QUEST, handler->GetNameLink(target).c_str());
        return true;
    }

    static bool HandleLearnAllCraftsCommand(ChatHandler* handler, char const* args)
    {
        Player* target;
        if (!handler->extractPlayerTarget((char*)args, &target))
            return false;

        for (uint32 i = 0; i < sSkillLineStore.GetNumRows(); ++i)
        {
            SkillLineEntry const* skillInfo = sSkillLineStore.LookupEntry(i);
            if (!skillInfo)
                continue;

            if ((skillInfo->categoryId == SKILL_CATEGORY_PROFESSION || skillInfo->categoryId == SKILL_CATEGORY_SECONDARY) &&
                skillInfo->canLink)                             // only prof. with recipes have
            {
                HandleLearnSkillRecipesHelper(target, skillInfo->id);
            }
        }

        handler->SendSysMessage(LANG_COMMAND_LEARN_ALL_CRAFT);
        return true;
    }

    static bool HandleLearnAllRecipesCommand(ChatHandler* handler, char const* args)
    {
        //  Learns all recipes of specified profession and sets skill to max
        //  Example: .learn all recipes enchanting

        Player* target = handler->getSelectedPlayer();
        if (!target)
        {
            handler->SendSysMessage(LANG_PLAYER_NOT_FOUND);
            return false;
        }

        if (!*args)
            return false;

        std::string namePart = args;
        std::wstring wNamePart;

        // converting string that we try to find to lower case
        if (!Utf8toWStr(namePart, wNamePart))
            return false;

        wstrToLower(wNamePart);

        std::string name;
        std::string matchedName;

        SkillLineEntry const* targetSkillInfo = NULL;
        for (uint32 i = 1; i < sSkillLineStore.GetNumRows(); ++i)
        {
            SkillLineEntry const* skillInfo = sSkillLineStore.LookupEntry(i);
            if (!skillInfo)
                continue;

            if ((skillInfo->categoryId != SKILL_CATEGORY_PROFESSION &&
                skillInfo->categoryId != SKILL_CATEGORY_SECONDARY) ||
                !skillInfo->canLink)                            // only prof with recipes have set
                continue;

            name = skillInfo->name[handler->GetSessionDbcLocale()];
            if (name.empty())
                continue;

            if (!Utf8FitTo(name, wNamePart))
                continue;

            targetSkillInfo = skillInfo;
            matchedName = name;
            break;
        }

        if (!targetSkillInfo)
            return false;

        HandleLearnSkillRecipesHelper(target, targetSkillInfo->id);

        uint16 maxLevel = target->GetPureMaxSkillValue(targetSkillInfo->id);
        target->SetSkill(targetSkillInfo->id, target->GetSkillStep(targetSkillInfo->id), maxLevel, maxLevel);
        handler->PSendSysMessage(LANG_COMMAND_LEARN_ALL_RECIPES, matchedName.c_str());
        return true;
    }

    static void HandleLearnSkillRecipesHelper(Player* player, uint32 skillId)
    {
        uint32 classmask = player->GetClassMask();

        for (uint32 j = 0; j < sSkillLineAbilityStore.GetNumRows(); ++j)
        {
            SkillLineAbilityEntry const* skillLine = sSkillLineAbilityStore.LookupEntry(j);
            if (!skillLine)
                continue;

            // wrong skill
            if (skillLine->skillId != skillId)
                continue;

            // not high rank
            if (skillLine->forward_spellid)
                continue;

            // skip racial skills
            if (skillLine->racemask != 0)
                continue;

            // skip wrong class skills
            if (skillLine->classmask && (skillLine->classmask & classmask) == 0)
                continue;

            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(skillLine->spellId);
            if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, player, false))
                continue;

            player->LearnSpell(skillLine->spellId, false);
        }
    }

    static bool HandleUnLearnCommand(ChatHandler* handler, char const* args)
    {
        if (!*args)
            return false;

        // number or [name] Shift-click form |color|Hspell:spell_id|h[name]|h|r
        uint32 spellId = handler->extractSpellIdFromLink((char*)args);
        if (!spellId)
            return false;

        char const* allStr = strtok(NULL, " ");
        bool allRanks = allStr ? (strncmp(allStr, "all", strlen(allStr)) == 0) : false;

        Player* target = handler->getSelectedPlayer();
        if (!target)
        {
            handler->SendSysMessage(LANG_NO_CHAR_SELECTED);
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (allRanks)
            spellId = sSpellMgr->GetFirstSpellInChain(spellId);

        if (target->HasSpell(spellId))
            target->RemoveSpell(spellId, false, !allRanks);
        else
            handler->SendSysMessage(LANG_FORGET_SPELL);

        if (GetTalentSpellCost(spellId))
            target->SendTalentsInfoData();

        return true;
    }
};

void AddSC_learn_commandscript()
{
    new learn_commandscript();
}
