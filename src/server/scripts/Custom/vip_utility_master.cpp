#include "ScriptPCH.h"
#include "Chat.h"
#include "ScriptedGossip.h"

namespace
{
    enum VipUtilityActions
    {
        ACTION_VENDOR = GOSSIP_ACTION_INFO_DEF + 1,
        ACTION_MENU_RIDING = GOSSIP_ACTION_INFO_DEF + 2,
        ACTION_MENU_WEAPONS = GOSSIP_ACTION_INFO_DEF + 3,
        ACTION_MENU_PROFESSIONS = GOSSIP_ACTION_INFO_DEF + 4,
        ACTION_BACK = GOSSIP_ACTION_INFO_DEF + 5,

        ACTION_LEARN_RIDING = GOSSIP_ACTION_INFO_DEF + 20,
        ACTION_LEARN_WEAPONS = GOSSIP_ACTION_INFO_DEF + 21,
        ACTION_LEARN_ARMOR = GOSSIP_ACTION_INFO_DEF + 22,

        ACTION_PROF_FIRST_AID = GOSSIP_ACTION_INFO_DEF + 100,
        ACTION_PROF_BLACKSMITHING,
        ACTION_PROF_LEATHERWORKING,
        ACTION_PROF_ALCHEMY,
        ACTION_PROF_HERBALISM,
        ACTION_PROF_COOKING,
        ACTION_PROF_MINING,
        ACTION_PROF_TAILORING,
        ACTION_PROF_ENGINEERING,
        ACTION_PROF_ENCHANTING,
        ACTION_PROF_FISHING,
        ACTION_PROF_SKINNING,
        ACTION_PROF_JEWELCRAFTING,
        ACTION_PROF_INSCRIPTION,
        ACTION_PROF_ARCHAEOLOGY,
        ACTION_PROF_ALL
    };

    struct VipSpellGroup
    {
        char const* Name;
        uint32 Action;
        std::initializer_list<uint32> Spells;
        uint32 SkillId = 0;
    };

    VipSpellGroup const RidingGroup =
    {
        "Learn all riding and flying.",
        ACTION_LEARN_RIDING,
        { 33388, 33391, 34090, 34091, 54197, 90265, 90267, 115913 }
    };

    VipSpellGroup const WeaponGroup =
    {
        "Learn all weapon skills.",
        ACTION_LEARN_WEAPONS,
        { 196, 197, 198, 199, 200, 201, 202, 227, 256, 264, 266, 1180, 5009, 5011, 15590 }
    };

    VipSpellGroup const ArmorGroup =
    {
        "Learn armor and dual wield skills.",
        ACTION_LEARN_ARMOR,
        { 674, 750, 8737, 9116 }
    };

    VipSpellGroup const ProfessionGroups[] =
    {
        { "First Aid",      ACTION_PROF_FIRST_AID,      { 110406 }, 129 },
        { "Blacksmithing",  ACTION_PROF_BLACKSMITHING,  { 110396 }, 164 },
        { "Leatherworking", ACTION_PROF_LEATHERWORKING, { 110423 }, 165 },
        { "Alchemy",       ACTION_PROF_ALCHEMY,         { 105206 }, 171 },
        { "Herbalism",     ACTION_PROF_HERBALISM,       { 110413 }, 182 },
        { "Cooking",       ACTION_PROF_COOKING,         { 104381 }, 185 },
        { "Mining",        ACTION_PROF_MINING,          { 102161 }, 186 },
        { "Tailoring",     ACTION_PROF_TAILORING,       { 110426 }, 197 },
        { "Engineering",   ACTION_PROF_ENGINEERING,     { 110403 }, 202 },
        { "Enchanting",    ACTION_PROF_ENCHANTING,      { 110400 }, 333 },
        { "Fishing",       ACTION_PROF_FISHING,         { 110410 }, 356 },
        { "Skinning",      ACTION_PROF_SKINNING,        { 102216 }, 393 },
        { "Jewelcrafting", ACTION_PROF_JEWELCRAFTING,   { 110420 }, 755 },
        { "Inscription",   ACTION_PROF_INSCRIPTION,     { 110417 }, 773 },
        { "Archaeology",   ACTION_PROF_ARCHAEOLOGY,     { 110393 }, 794 }
    };

    void LearnSpells(Player* player, VipSpellGroup const& group)
    {
        for (uint32 spellId : group.Spells)
            if (!player->HasSpell(spellId))
                player->LearnSpell(spellId, false);

        if (group.SkillId && player->HasSkill(group.SkillId))
        {
            uint32 maxValue = player->GetMaxSkillValue(group.SkillId);
            if (maxValue < 600)
                maxValue = 600;

            player->SetSkill(group.SkillId, player->GetSkillStep(group.SkillId), maxValue, maxValue);
        }

        player->SetSaveTimer(1);
        ChatHandler(player->GetSession()).PSendSysMessage("VIP Utility Master: %s learned.", group.Name);
    }

    void ShowMainMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Browse free mount goods.", GOSSIP_SENDER_MAIN, ACTION_VENDOR);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Riding and flying.", GOSSIP_SENDER_MAIN, ACTION_MENU_RIDING);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Weapon and armor skills.", GOSSIP_SENDER_MAIN, ACTION_MENU_WEAPONS);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Professions.", GOSSIP_SENDER_MAIN, ACTION_MENU_PROFESSIONS);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
    }

    void ShowRidingMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, RidingGroup.Name, GOSSIP_SENDER_MAIN, ACTION_LEARN_RIDING);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Back.", GOSSIP_SENDER_MAIN, ACTION_BACK);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
    }

    void ShowWeaponMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, WeaponGroup.Name, GOSSIP_SENDER_MAIN, ACTION_LEARN_WEAPONS);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, ArmorGroup.Name, GOSSIP_SENDER_MAIN, ACTION_LEARN_ARMOR);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Back.", GOSSIP_SENDER_MAIN, ACTION_BACK);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
    }

    void ShowProfessionMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Learn all professions.", GOSSIP_SENDER_MAIN, ACTION_PROF_ALL);

        for (VipSpellGroup const& group : ProfessionGroups)
            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, group.Name, GOSSIP_SENDER_MAIN, group.Action);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Back.", GOSSIP_SENDER_MAIN, ACTION_BACK);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
    }

    VipSpellGroup const* FindProfessionGroup(uint32 action)
    {
        for (VipSpellGroup const& group : ProfessionGroups)
            if (group.Action == action)
                return &group;

        return nullptr;
    }
}

struct npc_vip_utility_master : public ScriptedAI
{
    npc_vip_utility_master(Creature* creature) : ScriptedAI(creature) { }

    bool OnGossipHello(Player* player) override
    {
        ShowMainMenu(player, me);
        return true;
    }

    bool OnGossipSelect(Player* player, uint32 /*menuId*/, uint32 gossipListId) override
    {
        uint32 const action = player->PlayerTalkClass->GetGossipOptionAction(gossipListId);

        switch (action)
        {
            case ACTION_VENDOR:
                player->GetSession()->SendListInventory(me->GetGUID());
                break;
            case ACTION_MENU_RIDING:
                ShowRidingMenu(player, me);
                break;
            case ACTION_MENU_WEAPONS:
                ShowWeaponMenu(player, me);
                break;
            case ACTION_MENU_PROFESSIONS:
                ShowProfessionMenu(player, me);
                break;
            case ACTION_BACK:
                ShowMainMenu(player, me);
                break;
            case ACTION_LEARN_RIDING:
                LearnSpells(player, RidingGroup);
                ShowRidingMenu(player, me);
                break;
            case ACTION_LEARN_WEAPONS:
                LearnSpells(player, WeaponGroup);
                ShowWeaponMenu(player, me);
                break;
            case ACTION_LEARN_ARMOR:
                LearnSpells(player, ArmorGroup);
                ShowWeaponMenu(player, me);
                break;
            case ACTION_PROF_ALL:
                for (VipSpellGroup const& group : ProfessionGroups)
                    LearnSpells(player, group);
                ShowProfessionMenu(player, me);
                break;
            default:
                if (VipSpellGroup const* group = FindProfessionGroup(action))
                {
                    LearnSpells(player, *group);
                    ShowProfessionMenu(player, me);
                }
                else
                    CloseGossipMenuFor(player);
                break;
        }

        return true;
    }
};

void AddSC_vip_utility_master()
{
    RegisterCreatureAI(npc_vip_utility_master);
}
