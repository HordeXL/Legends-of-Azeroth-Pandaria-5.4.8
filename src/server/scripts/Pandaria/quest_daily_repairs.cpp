#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellScript.h"
#include "SpellAuraEffects.h"
#include "Player.h"

namespace DailyRepairs
{
    bool IsQuarry(uint32 entry)
    {
        return entry == 67436 || entry == 67438 || entry == 67439 || entry == 67498 || entry == 67508;
    }

    uint32 QuarryItem(uint32 entry)
    {
        if (entry == 67436) return 91834;
        if (entry == 67438 || entry == 67498) return 91835;
        return 91836;
    }

    bool Active(Player* player, uint32 quest)
    {
        return player && player->IsAlive() && player->GetQuestStatus(quest) == QUEST_STATUS_INCOMPLETE;
    }
}

struct npc_daily_repair_targetAI : public ScriptedAI
{
    npc_daily_repair_targetAI(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid captor;
    uint32 releaseTimer = 0;

    void Reset() override
    {
        captor = ObjectGuid::Empty;
        releaseTimer = 0;
        if (DailyRepairs::IsQuarry(me->GetEntry()))
        {
            me->SetFaction(14);
            me->RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_QUESTGIVER);
            me->SetStandState(UNIT_STAND_STATE_STAND);
            me->SetReactState(REACT_AGGRESSIVE);
        }
    }

    ObjectGuid GetGUID(int32 = 0) const override { return captor; }

    void DamageTaken(Unit* attacker, uint32& damage) override
    {
        if (!DailyRepairs::IsQuarry(me->GetEntry())) return;
        if (captor) { damage = 0; return; }
        Player* player = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!player || !me->HealthBelowPctDamaged(20, damage)) return;
        // Capture the animal alive. Only the player who subdued it gets its menu.
        damage = 0;
        captor = player->GetGUID();
        releaseTimer = 120000;
        me->SetHealth(std::max(1u, me->CountPctFromMaxHealth(20)));
        me->CombatStop(true);
        me->DeleteThreatList();
        me->SetFaction(35);
        me->SetReactState(REACT_PASSIVE);
        me->SetStandState(UNIT_STAND_STATE_SIT);
        me->SetFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_QUESTGIVER);
    }

    void SpellHit(Unit* caster, SpellInfo const* spell) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || !player->IsAlive() || !me->IsAlive()) return;
        if (me->GetEntry() == 33308 && spell->Id == 62990 && DailyRepairs::Active(player, 13627) &&
            player->HasItemCount(45046, 1) && !player->HasItemCount(45045, 12))
        {
            if (player->AddItem(45045, 2)) me->DespawnOrUnsummon();
        }
        else if (me->GetEntry() == 67285 && spell->Id == 135422 && DailyRepairs::Active(player, 32446) &&
            player->HasItemCount(93180, 1) && !player->HasItemCount(93179, 6))
        {
            if (player->AddItem(93179, 1)) player->Kill(me);
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (releaseTimer)
        {
            if (releaseTimer <= diff) me->DespawnOrUnsummon();
            else releaseTimer -= diff;
            return;
        }
        if (UpdateVictim()) DoMeleeAttackIfReady();
    }
};

class npc_daily_repair_interaction : public CreatureScript
{
public:
    npc_daily_repair_interaction() : CreatureScript("npc_daily_repair_interaction") { }
    CreatureAI* GetAI(Creature* creature) const override { return new npc_daily_repair_targetAI(creature); }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        if (!player->IsAlive() || !creature->IsWithinDistInMap(player, INTERACTION_DISTANCE)) return true;
        uint32 entry = creature->GetEntry();
        if (DailyRepairs::IsQuarry(entry))
        {
            if (creature->AI()->GetGUID() != player->GetGUID()) return true;
            player->PrepareQuestMenu(creature->GetGUID());
            player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        }
        else if (entry == 68700 && DailyRepairs::Active(player, 32156) && !player->HasItemCount(93009, 7))
        {
            if (player->AddItem(93009, 1)) creature->DespawnOrUnsummon();
        }
        else if (DailyRepairs::Active(player, 32133))
        {
            uint32 spell = entry == 67742 ? 133536 : entry == 67743 ? 133543 : entry == 67744 ? 133544 : 0;
            if (spell) player->CastSpell(player, spell, true);
        }
        if (DailyRepairs::Active(player, 32143))
        {
            uint32 spell = entry == 67544 ? 133245 : entry == 67546 ? 133257 : entry == 67547 ? 133337 : 0;
            if (spell) player->CastSpell(player, spell, true);
        }
        return true;
    }

    bool OnQuestAccept(Player* player, Creature* creature, Quest const* quest) override
    {
        if (DailyRepairs::IsQuarry(creature->GetEntry()) && creature->AI()->GetGUID() == player->GetGUID() &&
            quest->GetQuestId() >= 32181 && quest->GetQuestId() <= 32186)
            creature->DespawnOrUnsummon(1000);
        return true;
    }
};

class npc_daily_scout : public CreatureScript
{
public:
    npc_daily_scout() : CreatureScript("npc_daily_scout") { }
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (creature->IsWithinDistInMap(player, INTERACTION_DISTANCE))
        {
            if (creature->GetEntry() == 67985 && DailyRepairs::Active(player, 32523))
                player->KilledMonsterCredit(67985);
            if (creature->GetEntry() == 67998 && DailyRepairs::Active(player, 32567))
                player->KilledMonsterCredit(67998);
        }
        player->PrepareGossipMenu(creature, player->GetDefaultGossipMenuForSource(creature));
        player->SendPreparedGossip(creature);
        return true;
    }
};

class npc_daily_torch_keeper : public CreatureScript
{
public:
    npc_daily_torch_keeper() : CreatureScript("npc_daily_torch_keeper") { }
    bool OnQuestAccept(Player* player, Creature*, Quest const* quest) override
    {
        if (quest->GetQuestId() == 31492) player->CastSpell(player, 126656, true);
        return true;
    }
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        player->PrepareQuestMenu(creature->GetGUID());
        if (DailyRepairs::Active(player, 31492) && !player->IsMounted())
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "I need another Torch of Strength.", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }
    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        player->CLOSE_GOSSIP_MENU();
        if (sender == GOSSIP_SENDER_MAIN && action == GOSSIP_ACTION_INFO_DEF &&
            creature->IsWithinDistInMap(player, INTERACTION_DISTANCE) && DailyRepairs::Active(player, 31492) && !player->IsMounted())
            player->CastSpell(player, 126656, true);
        return true;
    }
};

class go_daily_strong_brazier : public GameObjectScript
{
public:
    go_daily_strong_brazier() : GameObjectScript("go_daily_strong_brazier") { }
    bool OnGossipHello(Player* player, GameObject* go) override
    {
        if (go->IsWithinDistInMap(player, INTERACTION_DISTANCE) && DailyRepairs::Active(player, 31492) &&
            player->HasAura(126656) && !player->IsMounted())
            player->CastSpell(player, 131051, true);
        return true;
    }
};

class spell_daily_burn_out : public SpellScript
{
    PrepareSpellScript(spell_daily_burn_out);
    void HandleAfterCast()
    {
        Player* player = GetCaster()->ToPlayer();
        WorldLocation const* dest = GetExplTargetDest();
        if (!DailyRepairs::Active(player, 32154) || !dest || !player->HasItemCount(93187, 1)) return;
        for (uint32 entry : { 68784u, 68785u, 68786u })
            if (Creature* marker = player->FindNearestCreature(entry, 60.0f, true))
                if (marker->GetDistance(*dest) <= 12.0f)
                    player->KilledMonsterCredit(entry);
    }
    void Register() override { AfterCast += SpellCastFn(spell_daily_burn_out::HandleAfterCast); }
};

void AddSC_daily_quest_repairs()
{
    new npc_daily_repair_interaction();
    new npc_daily_scout();
    new npc_daily_torch_keeper();
    new go_daily_strong_brazier();
    new spell_script<spell_daily_burn_out>("spell_daily_burn_out");
}
