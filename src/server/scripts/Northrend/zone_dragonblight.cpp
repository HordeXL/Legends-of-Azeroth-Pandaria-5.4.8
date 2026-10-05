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
SDName: Dragonblight
SD%Complete: 100
SDComment:
SDCategory: Dragonblight
EndScriptData */

/* ContentData
npc_alexstrasza_wr_gate
EndContentData */

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellScript.h"
#include "SpellAuraEffects.h"
#include "ScriptedEscortAI.h"
#include "Vehicle.h"
#include "CombatAI.h"
#include "Player.h"

enum AlexstraszaWrGate
{
    // Quest
    QUEST_RETURN_TO_AG_A    = 12499,
    QUEST_RETURN_TO_AG_H    = 12500,

    // Movie
    MOVIE_ID_GATES          = 14
};

#define GOSSIP_ITEM_WHAT_HAPPENED   "Alexstrasza, can you show me what happened here?"

class npc_alexstrasza_wr_gate : public CreatureScript
{
public:
    npc_alexstrasza_wr_gate() : CreatureScript("npc_alexstrasza_wr_gate") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (creature->IsQuestGiver())
            player->PrepareQuestMenu(creature->GetGUID());

        if (player->GetQuestRewardStatus(QUEST_RETURN_TO_AG_A) || player->GetQuestRewardStatus(QUEST_RETURN_TO_AG_H))
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, GOSSIP_ITEM_WHAT_HAPPENED, GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF+1);

        player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        player->PlayerTalkClass->ClearMenus();
        if (action == GOSSIP_ACTION_INFO_DEF+1)
        {
            player->CLOSE_GOSSIP_MENU();
            player->SendMovieStart(MOVIE_ID_GATES);
        }

        return true;
    }
};

enum FromDepthsOfAzjolNerubData
{
    QUEST_FROM_DEPTHS_OF_AZJOL_NERUB       = 12036,
    OBJECTIVE_PIT_OF_NARJUN_EXPLORED       = 257501,
    MAP_NORTHREND                          = 571,
    MAP_AZJOL_NERUB                        = 601
};

enum InSearchOfTheRubyLilacData
{
    QUEST_IN_SEARCH_OF_THE_RUBY_LILAC = 12102,
    ITEM_RUBY_LILAC                   = 36803
};

// The 5.4.8 chest-loot path does not reliably expose the WotLK quest-only
// loot row. Give the flower through the normal inventory API when it is used.
class go_ruby_lilac_12102 : public GameObjectScript
{
    public:
        go_ruby_lilac_12102() : GameObjectScript("go_ruby_lilac_12102") { }

        bool OnGossipHello(Player* player, GameObject* gameObject) override
        {
            if (player->GetQuestStatus(QUEST_IN_SEARCH_OF_THE_RUBY_LILAC) != QUEST_STATUS_INCOMPLETE ||
                player->HasItemCount(ITEM_RUBY_LILAC, 1, true))
                return true;

            ItemPosCountVec destination;
            InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination,
                ITEM_RUBY_LILAC, 1);
            if (result != EQUIP_ERR_OK)
            {
                player->SendEquipError(result, nullptr, nullptr);
                return true;
            }

            if (Item* item = player->StoreNewItem(destination, ITEM_RUBY_LILAC, true))
            {
                player->SendNewItem(item, 1, true, false);
                gameObject->SetLootState(GO_JUST_DEACTIVATED);
            }

            return true;
        }
};

// Entering the Azjol-Nerub dungeon is sufficient to explore the Pit of Narjun.
// Credit the objective on the map transition and retain an update fallback for
// players already inside when scripts are reloaded.
class player_from_depths_of_azjol_nerub : public PlayerScript
{
    public:
        player_from_depths_of_azjol_nerub() : PlayerScript("player_from_depths_of_azjol_nerub") { }

        void OnMapChanged(Player* player) override
        {
            CreditDungeonEntry(player);
        }

        void OnUpdate(Player* player, uint32 /*diff*/) override
        {
            CreditDungeonEntry(player);
        }

    private:
        static void CreditDungeonEntry(Player* player)
        {
            if (player->GetQuestStatus(QUEST_FROM_DEPTHS_OF_AZJOL_NERUB) != QUEST_STATUS_INCOMPLETE)
                return;

            // Retail credit is reached while descending through the Pit, just
            // before the instance portal. The tunnel is much longer than the
            // old 70-yard approximation; also accept an actual dungeon entry.
            bool const insideDungeon = player->GetMapId() == MAP_AZJOL_NERUB;
            bool const insidePit = player->GetMapId() == MAP_NORTHREND &&
                player->GetPositionZ() < 60.0f &&
                player->GetExactDist2d(3684.76f, 2154.15f) < 180.0f;
            if (insideDungeon || insidePit)
                player->CreditQuestAreaTriggerObjective(QUEST_FROM_DEPTHS_OF_AZJOL_NERUB,
                    OBJECTIVE_PIT_OF_NARJUN_EXPLORED);
        }
};

enum ReturnOfTheHighChiefData
{
    QUEST_RETURN_OF_THE_HIGH_CHIEF = 12069,
    SPELL_ANUBAR_PRISON_KEY        = 47412,
    NPC_UNDER_KING_ANUBETKAN       = 26608,
    NPC_ANUBAR_PRISON              = 26656
};

Position const UnderKingGroundPosition =
    { 4088.68f, 2219.45f, 150.405f, 3.30f };

// Return of the High Chief: using the prison key must start the missing
// encounter. The original spawn waits immune above the village for this
// transition, so bring it to the arena and make it hostile to the player.
class npc_anubar_prison_q12069 : public CreatureScript
{
    public:
        npc_anubar_prison_q12069() : CreatureScript("npc_anubar_prison_q12069") { }

        struct npc_anubar_prison_q12069AI : public ScriptedAI
        {
            npc_anubar_prison_q12069AI(Creature* creature) : ScriptedAI(creature) { }

            void SpellHit(Unit* caster, SpellInfo const* spell) override
            {
                Player* player = caster ? caster->ToPlayer() : nullptr;
                if (!player || !spell || spell->Id != SPELL_ANUBAR_PRISON_KEY ||
                    player->GetQuestStatus(QUEST_RETURN_OF_THE_HIGH_CHIEF) != QUEST_STATUS_INCOMPLETE)
                    return;

                Creature* underKing = me->FindNearestCreature(
                    NPC_UNDER_KING_ANUBETKAN, 200.0f, true);
                if (!underKing || underKing->IsInCombat())
                    return;

                std::list<Creature*> prisons;
                GetCreatureListWithEntryInGrid(prisons, me, NPC_ANUBAR_PRISON, 40.0f);
                for (Creature* prison : prisons)
                    prison->DespawnOrUnsummon(1000);

                underKing->CombatStop(true);
                underKing->NearTeleportTo(UnderKingGroundPosition.GetPositionX(),
                    UnderKingGroundPosition.GetPositionY(),
                    UnderKingGroundPosition.GetPositionZ(),
                    UnderKingGroundPosition.GetOrientation());
                underKing->SetHomePosition(UnderKingGroundPosition);
                underKing->SetFullHealth();
                underKing->RemoveFlag(UNIT_FIELD_FLAGS,
                    UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC |
                    UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_ATTACKABLE_1 |
                    UNIT_FLAG_NON_ATTACKABLE_2);
                underKing->SetReactState(REACT_AGGRESSIVE);
                underKing->AI()->AttackStart(player);
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_anubar_prison_q12069AI(creature);
        }
};

enum AllHailRoanaukData
{
    QUEST_ALL_HAIL_ROANAUK = 12140,
    NPC_ROANAUK_ICEMIST    = 26810,
    ACTION_BEGIN_OATH      = GOSSIP_ACTION_INFO_DEF + 1,
    EVENT_OATH_READING     = 1,
    EVENT_OATH_LINE_1,
    EVENT_OATH_LINE_2,
    EVENT_OATH_LINE_3,
    EVENT_OATH_COMPLETE
};

#define GOSSIP_ROANAUK_OATH "Greetings High Chief. Would you do me the honor of accepting my invitation to join the Horde as an official member and leader of the Taunka?"

// All Hail Roanauk!: the DB contains the complete Blood Oath dialogue, but no
// handler starts it or awards the initiation objective.
class npc_roanauk_all_hail : public CreatureScript
{
    public:
        npc_roanauk_all_hail() : CreatureScript("npc_roanauk_all_hail") { }

        struct npc_roanauk_all_hailAI : public ScriptedAI
        {
            npc_roanauk_all_hailAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;
            ObjectGuid participant;

            void Reset() override
            {
                events.Reset();
                participant = ObjectGuid::Empty;
            }

            void BeginOath(Player* player)
            {
                if (!player || !participant.IsEmpty() ||
                    player->GetQuestStatus(QUEST_ALL_HAIL_ROANAUK) != QUEST_STATUS_INCOMPLETE)
                    return;

                participant = player->GetGUID();
                Talk(0, player);
                events.ScheduleEvent(EVENT_OATH_READING, 2500);
            }

            void UpdateAI(uint32 diff) override
            {
                events.Update(diff);
                while (uint32 eventId = events.ExecuteEvent())
                {
                    Player* player = ObjectAccessor::GetPlayer(*me, participant);
                    if (!player || player->GetQuestStatus(QUEST_ALL_HAIL_ROANAUK) != QUEST_STATUS_INCOMPLETE)
                    {
                        Reset();
                        return;
                    }

                    switch (eventId)
                    {
                        case EVENT_OATH_READING:
                            Talk(1, player);
                            events.ScheduleEvent(EVENT_OATH_LINE_1, 3500);
                            break;
                        case EVENT_OATH_LINE_1:
                            Talk(2, player);
                            events.ScheduleEvent(EVENT_OATH_LINE_2, 6000);
                            break;
                        case EVENT_OATH_LINE_2:
                            Talk(3, player);
                            events.ScheduleEvent(EVENT_OATH_LINE_3, 6000);
                            break;
                        case EVENT_OATH_LINE_3:
                            Talk(4, player);
                            events.ScheduleEvent(EVENT_OATH_COMPLETE, 6000);
                            break;
                        case EVENT_OATH_COMPLETE:
                            Talk(5, player);
                            player->KilledMonsterCredit(NPC_ROANAUK_ICEMIST);
                            participant = ObjectGuid::Empty;
                            break;
                        default:
                            break;
                    }
                }
            }
        };

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            player->PlayerTalkClass->ClearMenus();
            if (player->GetQuestStatus(QUEST_ALL_HAIL_ROANAUK) == QUEST_STATUS_INCOMPLETE)
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, GOSSIP_ROANAUK_OATH,
                    GOSSIP_SENDER_MAIN, ACTION_BEGIN_OATH);

            player->SEND_GOSSIP_MENU(12721, creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature,
            uint32 /*sender*/, uint32 action) override
        {
            player->PlayerTalkClass->ClearMenus();
            player->CLOSE_GOSSIP_MENU();
            if (action == ACTION_BEGIN_OATH)
                if (npc_roanauk_all_hailAI* ai = CAST_AI(npc_roanauk_all_hailAI, creature->AI()))
                    ai->BeginOath(player);
            return true;
        }

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_roanauk_all_hailAI(creature);
        }
};

enum SarathstraQuestData
{
    QUEST_SARATHSTRA_SCOURGE_OF_THE_NORTH = 12097,
    NPC_SARATHSTRA                        = 26858,
    ACTION_CALL_SARATHSTRA                = GOSSIP_ACTION_INFO_DEF + 1
};

#define GOSSIP_CALL_SARATHSTRA "I am ready. Call Sarathstra down."

Position const SarathstraCombatPosition =
    { 4400.0f, 960.0f, 88.5f, 3.20f };

// Sarathstra, Scourge of the North: Rokhan's DB gossip menu has no option or
// event handler. Call the existing frostwyrm down to the hunters' clearing,
// with a temporary replacement as a fallback if the static spawn is absent.
class npc_rokhan_sarathstra : public CreatureScript
{
    public:
        npc_rokhan_sarathstra() : CreatureScript("npc_rokhan_sarathstra") { }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            player->PlayerTalkClass->ClearMenus();
            if (player->GetQuestStatus(QUEST_SARATHSTRA_SCOURGE_OF_THE_NORTH) == QUEST_STATUS_INCOMPLETE)
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, GOSSIP_CALL_SARATHSTRA,
                    GOSSIP_SENDER_MAIN, ACTION_CALL_SARATHSTRA);

            player->SEND_GOSSIP_MENU(12701, creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature,
            uint32 /*sender*/, uint32 action) override
        {
            player->PlayerTalkClass->ClearMenus();
            player->CLOSE_GOSSIP_MENU();
            if (action != ACTION_CALL_SARATHSTRA ||
                player->GetQuestStatus(QUEST_SARATHSTRA_SCOURGE_OF_THE_NORTH) != QUEST_STATUS_INCOMPLETE)
                return true;

            Creature* sarathstra = creature->FindNearestCreature(
                NPC_SARATHSTRA, 600.0f, true);
            if (!sarathstra)
                sarathstra = creature->SummonCreature(NPC_SARATHSTRA,
                    SarathstraCombatPosition, TEMPSUMMON_TIMED_OR_DEAD_DESPAWN,
                    10 * MINUTE * IN_MILLISECONDS);

            if (!sarathstra || sarathstra->IsInCombat())
                return true;

            sarathstra->CombatStop(true);
            sarathstra->NearTeleportTo(SarathstraCombatPosition.GetPositionX(),
                SarathstraCombatPosition.GetPositionY(),
                SarathstraCombatPosition.GetPositionZ(),
                SarathstraCombatPosition.GetOrientation());
            sarathstra->SetHomePosition(SarathstraCombatPosition);
            sarathstra->SetFullHealth();
            sarathstra->RemoveFlag(UNIT_FIELD_FLAGS,
                UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC |
                UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_ATTACKABLE_1 |
                UNIT_FLAG_NON_ATTACKABLE_2);
            sarathstra->SetReactState(REACT_AGGRESSIVE);
            sarathstra->AI()->AttackStart(player);
            return true;
        }
};

enum CanyonChaseData
{
    QUEST_CANYON_CHASE_ALLIANCE = 12143,
    QUEST_CANYON_CHASE_HORDE    = 12145,
    NPC_DUANE                    = 26978,
    NPC_KONTOKANIS              = 26979,
    NPC_CHILLTUSK_FORAGER        = 27171,
    NPC_ICEFIST_FORAGER          = 27123,
    ACTION_RESTART_CANYON_CHASE  = GOSSIP_ACTION_INFO_DEF + 1
};

#define GOSSIP_RESTART_CANYON_CHASE "Send out another group of foragers. I will follow them."

Position const ChilltuskDestination =
    { 4532.0f, -417.0f, 81.5f, 0.0f };
Position const IcefistDestination =
    { 4111.0f, 1238.0f, 57.1f, 0.0f };

// Canyon Chase (Alliance/Horde): retail spawns a group of snobold foragers
// when the quest is accepted. They flee down the canyon and lead the player
// to Chilltusk or Icefist. The event was missing completely for Horde and the
// static Alliance foragers never moved.
class npc_canyon_chase_questgiver : public CreatureScript
{
    public:
        npc_canyon_chase_questgiver() : CreatureScript("npc_canyon_chase_questgiver") { }

        bool OnQuestAccept(Player* player, Creature* creature, Quest const* quest) override
        {
            if (quest->GetQuestId() == QUEST_CANYON_CHASE_ALLIANCE ||
                quest->GetQuestId() == QUEST_CANYON_CHASE_HORDE)
                StartChase(player, creature, quest->GetQuestId());

            return true;
        }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            player->PlayerTalkClass->ClearMenus();
            if (creature->IsQuestGiver())
                player->PrepareQuestMenu(creature->GetGUID());

            uint32 const questId = GetQuestFor(creature);
            if (questId && player->GetQuestStatus(questId) == QUEST_STATUS_INCOMPLETE)
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, GOSSIP_RESTART_CANYON_CHASE,
                    GOSSIP_SENDER_MAIN, ACTION_RESTART_CANYON_CHASE);

            player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature,
            uint32 /*sender*/, uint32 action) override
        {
            player->PlayerTalkClass->ClearMenus();
            player->CLOSE_GOSSIP_MENU();

            uint32 const questId = GetQuestFor(creature);
            if (action == ACTION_RESTART_CANYON_CHASE && questId &&
                player->GetQuestStatus(questId) == QUEST_STATUS_INCOMPLETE)
                StartChase(player, creature, questId);

            return true;
        }

    private:
        static uint32 GetQuestFor(Creature* creature)
        {
            if (creature->GetEntry() == NPC_DUANE)
                return QUEST_CANYON_CHASE_ALLIANCE;
            if (creature->GetEntry() == NPC_KONTOKANIS)
                return QUEST_CANYON_CHASE_HORDE;
            return 0;
        }

        static void StartChase(Player* player, Creature* creature, uint32 questId)
        {
            uint32 const foragerEntry = questId == QUEST_CANYON_CHASE_ALLIANCE ?
                NPC_CHILLTUSK_FORAGER : NPC_ICEFIST_FORAGER;
            Position const& destination = questId == QUEST_CANYON_CHASE_ALLIANCE ?
                ChilltuskDestination : IcefistDestination;

            // Do not create another pack while this player's pack is still
            // close to the start. The gossip option remains useful after the
            // original group has run out of sight or despawned.
            std::list<Creature*> nearbyForagers;
            GetCreatureListWithEntryInGrid(nearbyForagers, creature, foragerEntry, 100.0f);
            for (Creature* forager : nearbyForagers)
                if (TempSummon* summon = forager->ToTempSummon())
                    if (summon->GetSummonerGUID() == player->GetGUID())
                        return;

            for (uint8 i = 0; i < 3; ++i)
            {
                float const angle = creature->GetOrientation() + (float(i) - 1.0f) * 0.35f;
                float const distance = 3.0f + float(i);
                Position const spawnPosition = creature->GetNearPosition(distance, angle);

                if (Creature* forager = player->SummonCreature(foragerEntry,
                    spawnPosition, TEMPSUMMON_TIMED_DESPAWN, 3 * MINUTE * IN_MILLISECONDS))
                {
                    forager->SetFaction(35);
                    forager->SetReactState(REACT_PASSIVE);
                    forager->SetWalk(false);
                    forager->GetMotionMaster()->MovePoint(1, destination);
                }
            }
        }
};

/*######
## Quest Strengthen the Ancients (12096|12092)
######*/

enum StrengthenAncientsMisc
{
    SAY_WALKER_FRIENDLY         = 0,
    SAY_WALKER_ENEMY            = 1,
    SAY_LOTHALOR                = 0,

    SPELL_CREATE_ITEM_BARK      = 47550,
    SPELL_CONFUSED              = 47044,

    NPC_LOTHALOR                = 26321,

    FACTION_WALKER_ENEMY        = 14,
};

class spell_q12096_q12092_dummy : public SpellScriptLoader // Strengthen the Ancients: On Interact Dummy to Woodlands Walker
{
public:
    spell_q12096_q12092_dummy() : SpellScriptLoader("spell_q12096_q12092_dummy") { }

    class spell_q12096_q12092_dummy_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_q12096_q12092_dummy_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            uint32 roll = rand() % 2;

            Creature* tree = GetHitCreature();
            Player* player = GetCaster()->ToPlayer();

            if (!tree || !player)
                return;

            tree->RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);

            if (roll == 1) // friendly version
            {
                tree->CastSpell(player, SPELL_CREATE_ITEM_BARK);
                tree->AI()->Talk(SAY_WALKER_FRIENDLY, player);
                tree->DespawnOrUnsummon(1000);
            }
            else if (roll == 0) // enemy version
            {
                tree->AI()->Talk(SAY_WALKER_ENEMY, player);
                tree->SetFaction(FACTION_WALKER_ENEMY);
                tree->Attack(player, true);
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_q12096_q12092_dummy_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_q12096_q12092_dummy_SpellScript();
    }
};

class spell_q12096_q12092_bark : public SpellScriptLoader // Bark of the Walkers
{
public:
    spell_q12096_q12092_bark() : SpellScriptLoader("spell_q12096_q12092_bark") { }

    class spell_q12096_q12092_bark_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_q12096_q12092_bark_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            Creature* lothalor = GetHitCreature();
            if (!lothalor || lothalor->GetEntry() != NPC_LOTHALOR)
                return;

            lothalor->AI()->Talk(SAY_LOTHALOR);
            lothalor->RemoveAura(SPELL_CONFUSED);
            lothalor->DespawnOrUnsummon(4000);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_q12096_q12092_bark_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_q12096_q12092_bark_SpellScript();
    }
};

/*######
## Quest: Defending Wyrmrest Temple ID: 12372
######*/

enum WyrmDefenderEnum
{
    // Quest data
    QUEST_DEFENDING_WYRMREST_TEMPLE          = 12372,
    GOSSIP_TEXTID_DEF1                       = 12899,

    // Gossip data
    GOSSIP_TEXTID_DEF2                       = 12900,

    // Spells data
    SPELL_CHARACTER_SCRIPT                   = 49213,
    SPELL_DEFENDER_ON_LOW_HEALTH_EMOTE       = 52421, // ID - 52421 Wyrmrest Defender: On Low Health Boss Emote to Controller - Random /self/
    SPELL_RENEW                              = 49263, // casted to heal drakes
    SPELL_WYRMREST_DEFENDER_MOUNT            = 49256,

    // Texts data
    WHISPER_MOUNTED                        = 0,
    BOSS_EMOTE_ON_LOW_HEALTH               = 2
};

#define GOSSIP_ITEM_1      "We need to get into the fight. Are you ready?"

class npc_wyrmrest_defender : public CreatureScript
{
    public:
        npc_wyrmrest_defender() : CreatureScript("npc_wyrmrest_defender") { }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            if (player->GetQuestStatus(QUEST_DEFENDING_WYRMREST_TEMPLE) == QUEST_STATUS_INCOMPLETE)
            {
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, GOSSIP_ITEM_1, GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF+1);
                player->SEND_GOSSIP_MENU(GOSSIP_TEXTID_DEF1, creature->GetGUID());
            }
            else
                player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());

            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
        {
            player->PlayerTalkClass->ClearMenus();
            if (action == GOSSIP_ACTION_INFO_DEF+1)
            {
                player->SEND_GOSSIP_MENU(GOSSIP_TEXTID_DEF2, creature->GetGUID());
                // Makes player cast trigger spell for 49207 on self
                player->CastSpell(player, SPELL_CHARACTER_SCRIPT, true);
                // The gossip should not auto close
            }

            return true;
        }

        struct npc_wyrmrest_defenderAI : public VehicleAI
        {
            npc_wyrmrest_defenderAI(Creature* creature) : VehicleAI(creature) { }

            bool hpWarningReady;
            bool renewRecoveryCanCheck;

            uint32 RenewRecoveryChecker;

            void Reset() override
            {
                hpWarningReady = true;
                renewRecoveryCanCheck = false;

                RenewRecoveryChecker = 0;
            }

            void UpdateAI(uint32 diff) override
            {
                // Check system for Health Warning should happen first time whenever get under 30%,
                // after it should be able to happen only after recovery of last renew is fully done (20 sec),
                // next one used won't interfere
                if (hpWarningReady && me->GetHealthPct() <= 30.0f)
                {
                    me->CastSpell(me, SPELL_DEFENDER_ON_LOW_HEALTH_EMOTE);
                    hpWarningReady = false;
                }

                if (renewRecoveryCanCheck)
                {
                    if (RenewRecoveryChecker <= diff)
                    {
                        renewRecoveryCanCheck = false;
                        hpWarningReady = true;
                    }
                    else RenewRecoveryChecker -= diff;
                }
            }

            void SpellHit(Unit* /*caster*/, SpellInfo const* spell) override
            {
                switch (spell->Id)
                {
                    case SPELL_WYRMREST_DEFENDER_MOUNT:
                        Talk(WHISPER_MOUNTED, me->GetCharmerOrOwner());
                        me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
                        me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PVP_ATTACKABLE);
                        break;
                    // Both below are for checking low hp warning
                    case SPELL_DEFENDER_ON_LOW_HEALTH_EMOTE:
                        Talk(BOSS_EMOTE_ON_LOW_HEALTH, me->GetCharmerOrOwner());
                        break;
                    case SPELL_RENEW:
                        if (!hpWarningReady && RenewRecoveryChecker <= 100)
                        {
                            RenewRecoveryChecker = 20000;
                        }
                        renewRecoveryCanCheck = true;
                        break;
                }
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_wyrmrest_defenderAI(creature);
        }
};

void AddSC_dragonblight()
{
    new npc_alexstrasza_wr_gate;
    new go_ruby_lilac_12102;
    new player_from_depths_of_azjol_nerub;
    new npc_anubar_prison_q12069;
    new npc_roanauk_all_hail;
    new npc_rokhan_sarathstra;
    new npc_canyon_chase_questgiver;
    new spell_q12096_q12092_dummy;
    new spell_q12096_q12092_bark;
    new npc_wyrmrest_defender;
}
