/*
* This file is part of the Legends of Azeroth Pandaria Project. See THANKS file for Copyright information
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

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "ScriptedEscortAI.h"
#include "SpellScript.h"

enum eQuests
{
    QUEST_THE_TORCHES                      = 30787,
    QUEST_ORBISS_FADES                     = 30792,
    QUEST_THE_MOTIVES_OF_THE_MANTID        = 30921,
    QUEST_FALLEN_SENTINELS                 = 30953,
    QUEST_THE_SEARCH_OF_RESTLESS_LENG      = 31688,
    QUEST_RANGER_RESCUE                    = 30774,
    QUEST_WHAT_LIES_BENEATH                = 30827,
    QUEST_HATRED_BECOMES_US                = 30783,
    QUEST_ARCONISS                         = 30789,
    QUEST_MISTS_OPPORTUNITY                = 30793,
    QUEST_BACK_ON_THEIR_FEET               = 30892,
};

enum eCreatures
{
    NPC_TAI_HO_MOTIVES          = 61390,
    NPC_KRITHIK_BONESLICER      = 61376,
    NPC_KRITHIK_SCREAMER        = 61377,
    NPC_MANTID_FIRST_CLUE       = 61400,
    NPC_MANTID_SECOND_CLUE      = 61401,
    NPC_MANTID_THIRD_CLUE       = 61402,
    NPC_MANTID_FOURTH_CLUE      = 61403,
    NPC_WOUNDED_NIUZAO_SENTINEL = 61570,
    NPC_SENTINEL_HEALED_CREDIT  = 61569,
    NPC_SRATHIK_WAR_WAGON       = 61510,
    NPC_RESTLESS_LENG           = 65586,
    NPC_LONGYING_RANGER         = 60730,
    NPC_LONGYING_RANGER_HELPER  = 60763,
    NPC_SUNA_SILENTSTRIKE       = 60901,
    NPC_MIST_SHAMANS_TORCH      = 60698,
    NPC_SUNA_SILENTSTRIKE_2     = 61055,
    NPC_YALIA_SAGEWHISPER       = 60864,
    NPC_TOTEM_OF_KINDNESS       = 60933,
    NPC_TOTEM_OF_TRANQUILITY    = 60990,
    NPC_TOTEM_OF_SERENITY       = 60991,
    NPC_RITUAL_YALIA            = 61015,
    NPC_RITUAL_SEETHING_HATRED  = 61024,
    NPC_SPEAK_TO_YALIA_CREDIT   = 65256,
    NPC_CRAZED_SHADO_PAN_RANGER = 61050,
    NPC_HATRED_BECOMES_US_SHA   = 61054,
    NPC_TOTEM_OF_HARMONY        = 61062,
    NPC_ARCONISS                = 60764,
    NPC_JAHESH_OF_OSUL          = 60802,
    NPC_ORBISS_MISTS_EVENT      = 60622,
    NPC_GOLGOSS_MISTS_EVENT     = 60881,
    NPC_ARCONISS_MISTS_EVENT    = 60882,
    NPC_INJURED_GAO_RAN_BLACKGUARD = 61692,
};

enum eMisc
{
    AREA_KRIVESS                           = 6205,
    SPELL_SUMMON_TAI_HO                    = 119061,
    OBJECTIVE_SIKTHIK_CAGES_SEARCHED       = 268906,
    QUEST_OBJECTIVE_LONGYIN_RANGER_RESCUED = 263418,
    QUEST_OBJECTIVE_FREE_LIN_SILENTSTRIKE  = 263419,
    GO_DRYWOOD_CAGE                        = 211511,
    OBJECTIVE_SPEAK_TO_YALIA               = 265825,
    OBJECTIVE_TOTEM_OF_KINDNESS            = 265826,
    OBJECTIVE_TOTEM_OF_TRANQUILITY         = 265827,
    OBJECTIVE_TOTEM_OF_SERENITY            = 265828,
    OBJECTIVE_RITUAL_COMPLETED              = 268776,
    OBJECTIVE_CRAZED_RANGERS_PURIFIED       = 263553,
};

// Tai Ho - 61390; companion for The Motives of the Mantid - 30921
struct npc_tai_ho_motives : public ScriptedAI
{
    npc_tai_ho_motives(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        if (Player* player = summoner->ToPlayer())
        {
            _ownerGuid = player->GetGUID();
            me->SetReactState(REACT_PASSIVE);
            me->GetMotionMaster()->MoveFollow(player, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
            Talk(0, player);
        }
    }

    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        _corpseGuid = guid;
    }

    void DoAction(int32 /*action*/) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, _ownerGuid);
        if (!player || player->GetQuestStatus(QUEST_THE_MOTIVES_OF_THE_MANTID) != QUEST_STATUS_INCOMPLETE)
            return;

        if (Creature* corpse = ObjectAccessor::GetCreature(*me, _corpseGuid))
            me->SetFacingToObject(corpse);
        me->HandleEmoteCommand(EMOTE_ONESHOT_KNEEL);

        // Retail did not find a clue on every corpse. Preserve that behavior,
        // but cap the dry streak so a finite camp population always suffices.
        if (++_killsSinceClue < 3 && !roll_chance_i(40))
        {
            Talk(10, player);
            return;
        }

        _killsSinceClue = 0;
        uint32 clueEntry = 0;
        uint8 firstTextGroup = 0;
        if (!player->GetQuestObjectiveCounter(267743))
        {
            clueEntry = NPC_MANTID_FIRST_CLUE;
            firstTextGroup = 1;
        }
        else if (!player->GetQuestObjectiveCounter(267744))
        {
            clueEntry = NPC_MANTID_SECOND_CLUE;
            firstTextGroup = 3;
        }
        else if (!player->GetQuestObjectiveCounter(267745))
        {
            clueEntry = NPC_MANTID_THIRD_CLUE;
            firstTextGroup = 5;
        }
        else if (!player->GetQuestObjectiveCounter(267746))
        {
            clueEntry = NPC_MANTID_FOURTH_CLUE;
            firstTextGroup = 7;
        }

        if (!clueEntry)
            return;

        player->KilledMonsterCredit(clueEntry);
        Talk(firstTextGroup, player);

        ObjectGuid ownerGuid = _ownerGuid;
        me->m_Events.Schedule(1200, [this, ownerGuid, firstTextGroup]()
        {
            if (Player* owner = ObjectAccessor::GetPlayer(*me, ownerGuid))
                Talk(firstTextGroup + 1, owner);
        });

        if (clueEntry == NPC_MANTID_FOURTH_CLUE)
            me->m_Events.Schedule(2400, [this, ownerGuid]()
            {
                if (Player* owner = ObjectAccessor::GetPlayer(*me, ownerGuid))
                    Talk(9, owner);
            });
    }

    void UpdateAI(uint32 diff) override
    {
        if (_ownerCheckTimer > diff)
        {
            _ownerCheckTimer -= diff;
            return;
        }

        _ownerCheckTimer = 1000;
        Player* player = ObjectAccessor::GetPlayer(*me, _ownerGuid);
        if (!player || player->GetQuestStatus(QUEST_THE_MOTIVES_OF_THE_MANTID) != QUEST_STATUS_INCOMPLETE || player->GetAreaId() != AREA_KRIVESS)
            me->DespawnOrUnsummon();
    }

private:
    ObjectGuid _ownerGuid;
    ObjectGuid _corpseGuid;
    uint32 _ownerCheckTimer = 1000;
    uint8 _killsSinceClue = 0;
};

class player_motives_of_the_mantid : public PlayerScript
{
public:
    player_motives_of_the_mantid() : PlayerScript("player_motives_of_the_mantid") { }

    void OnQuestAdded(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() == QUEST_THE_MOTIVES_OF_THE_MANTID)
            EnsureCompanion(player);
    }

    void OnUpdateZone(Player* player, uint32 /*newZone*/, uint32 newArea) override
    {
        if (newArea == AREA_KRIVESS)
            EnsureCompanion(player);
    }

    void OnCreatureKill(Player* killer, Creature* killed) override
    {
        if (killer->GetQuestStatus(QUEST_THE_MOTIVES_OF_THE_MANTID) != QUEST_STATUS_INCOMPLETE ||
            killer->GetAreaId() != AREA_KRIVESS ||
            (killed->GetEntry() != NPC_KRITHIK_BONESLICER && killed->GetEntry() != NPC_KRITHIK_SCREAMER))
            return;

        Creature* taiHo = GetCompanion(killer);
        if (!taiHo)
        {
            EnsureCompanion(killer);
            taiHo = GetCompanion(killer);
        }

        if (taiHo)
        {
            taiHo->AI()->SetGUID(killed->GetGUID());
            taiHo->AI()->DoAction(0);
        }
    }

private:
    static Creature* GetCompanion(Player* player)
    {
        std::list<Creature*> companions;
        GetCreatureListWithEntryInGrid(companions, player, NPC_TAI_HO_MOTIVES, 120.0f);
        for (Creature* companion : companions)
            if (TempSummon* summon = companion->ToTempSummon())
                if (summon->IsAlive() && summon->GetSummonerGUID() == player->GetGUID())
                    return summon;
        return nullptr;
    }

    static void EnsureCompanion(Player* player)
    {
        if (player->IsAlive() && player->GetAreaId() == AREA_KRIVESS &&
            player->GetQuestStatus(QUEST_THE_MOTIVES_OF_THE_MANTID) == QUEST_STATUS_INCOMPLETE && !GetCompanion(player))
            player->CastSpell(player, SPELL_SUMMON_TAI_HO, true);
    }
};

enum eLithIkSpells
{
    SPELL_BLADE_FURY       = 125370,
    SPELL_TORNADO          = 125398,
    SPELL_TORNADO_DMG      = 131693,
    SPELL_WINDSONG         = 125373,
};

enum eLithIkEvents
{
    EVENT_BLADE_FURY       = 1,
    EVENT_TORNADO          = 2,
    EVENT_WINDSONG         = 3,
};

class npc_lith_ik : public CreatureScript
{
    public:
        npc_lith_ik() : CreatureScript("npc_lith_ik") { }

        struct npc_lith_ikAI : public ScriptedAI
        {
            npc_lith_ikAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;

            void Reset() override
            {
                events.Reset();

                events.ScheduleEvent(EVENT_TORNADO,       5000);
                events.ScheduleEvent(EVENT_BLADE_FURY,   25000);
                events.ScheduleEvent(EVENT_WINDSONG,     30000);
            }

            void JustSummoned(Creature* summon) override
            {
                if (summon->GetEntry() == 64267)
                {
                    summon->DespawnOrUnsummon(15000);
                    summon->AddAura(SPELL_TORNADO_DMG, summon);
                    summon->SetReactState(REACT_PASSIVE);
                    summon->GetMotionMaster()->MoveRandom(20.0f);
                }

            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                events.Update(diff);

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_TORNADO:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_TORNADO, false);
                            events.ScheduleEvent(EVENT_TORNADO,      70000);
                            break;
                        case EVENT_BLADE_FURY:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_BLADE_FURY, false);
                            events.ScheduleEvent(EVENT_BLADE_FURY,      30000);
                            break;
                        case EVENT_WINDSONG:
                            me->CastSpell(me, SPELL_WINDSONG, false);
                            events.ScheduleEvent(EVENT_WINDSONG,      25000);
                            break;
                        default:
                            break;
                    }
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_lith_ikAI(creature);
        }
};

enum eDarkwoodsFaerieSpells
{
    SPELL_DISGUISE         = 121308,
    SPELL_FAE_SPIRIT       = 122567,
    SPELL_NIGHT_SKY        = 123318,
    SPELL_STARSURGE        = 123330,
};

enum eDarkwoodsFaerieEvents
{
    EVENT_DISGUISE          = 1,
    EVENT_FAE_SPIRIT        = 2,
    EVENT_NIGHT_SKY         = 3,
    EVENT_STARSURGE         = 4,
};

class npc_darkwoods_faerie : public CreatureScript
{
    public:
        npc_darkwoods_faerie() : CreatureScript("npc_darkwoods_faerie") { }

        struct npc_darkwoods_faerieAI : public ScriptedAI
        {
            npc_darkwoods_faerieAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;

            void Reset() override
            {
                events.Reset();

                events.ScheduleEvent(EVENT_DISGUISE,       5000);
                events.ScheduleEvent(EVENT_FAE_SPIRIT,    15000);
                events.ScheduleEvent(EVENT_NIGHT_SKY,     22000);
                events.ScheduleEvent(EVENT_STARSURGE,     30000);
            }

            void JustSummoned(Creature* summon) override
            {
                if (summon->GetEntry() == 64267)
                {
                    summon->DespawnOrUnsummon(15000);
                    summon->AddAura(SPELL_TORNADO_DMG, summon);
                    summon->SetReactState(REACT_PASSIVE);
                    summon->GetMotionMaster()->MoveRandom(20.0f);
                }

            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                events.Update(diff);

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_DISGUISE:
                            if (SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(me, SPELL_DISGUISE, false);
                            events.ScheduleEvent(EVENT_DISGUISE,      70000);
                            break;
                        case EVENT_FAE_SPIRIT:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_FAE_SPIRIT, false);
                            events.ScheduleEvent(EVENT_FAE_SPIRIT,      15000);
                            break;
                        case EVENT_NIGHT_SKY:
                            me->CastSpell(me, SPELL_NIGHT_SKY, false);
                            events.ScheduleEvent(EVENT_NIGHT_SKY,      22000);
                            break;
                        case EVENT_STARSURGE:
                            me->CastSpell(me, SPELL_STARSURGE, false);
                            events.ScheduleEvent(EVENT_STARSURGE,      30000);
                            break;
                        default:
                            break;
                    }
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_darkwoods_faerieAI(creature);
        }
};

enum eHeiFengSpells
{
    SPELL_DEEP_BREATH          = 125030,
    SPELL_SERPENT_SWEEP        = 125063,
    SPELL_SHADOW_DETONATION    = 124956,
};

enum eHeiFengEvents
{
    EVENT_DEEP_BREATH          = 1,
    EVENT_SERPENT_SWEEP        = 2,
    EVENT_SHADOW_DETONATION    = 3,
};

class npc_hei_feng : public CreatureScript
{
    public:
        npc_hei_feng() : CreatureScript("npc_hei_feng") { }

        struct npc_hei_fengAI : public ScriptedAI
        {
            npc_hei_fengAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;

            void Reset() override
            {
                events.Reset();

                events.ScheduleEvent(EVENT_DEEP_BREATH,       5000);
                events.ScheduleEvent(EVENT_SERPENT_SWEEP,    15000);
                events.ScheduleEvent(EVENT_SHADOW_DETONATION,     22000);
            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                events.Update(diff);

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_DEEP_BREATH:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_DEEP_BREATH, false);
                            events.ScheduleEvent(EVENT_DEEP_BREATH,      30000);
                            break;
                        case EVENT_SERPENT_SWEEP:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_SERPENT_SWEEP, false);
                            events.ScheduleEvent(EVENT_SERPENT_SWEEP,      15000);
                            break;
                        case EVENT_SHADOW_DETONATION:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_SHADOW_DETONATION, false);
                            events.ScheduleEvent(EVENT_SHADOW_DETONATION,      22000);
                            break;
                        default:
                            break;
                    }
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_hei_fengAI(creature);
        }
};

enum eCreatureSpells
{
    SPELL_CLAW_ATTACK          = 124839,
    SPELL_CORROSIVE_STING      = 124859,
    SPELL_DOUBLE_BLADE_LUNGE_1 = 125286,
    SPELL_DOUBLE_BLADE_LUNGE_2 = 125288,
    SPELL_TIMBERHUSK           = 122134,
    SPELL_BROKEN_SHELL         = 126035,
    SPELL_PROTECTIVE_SHELL     = 130728,
    SPELL_RANK_BITE            = 125353,
    SPELL_BLOOD_RAGE           = 124019,
    SPELL_GORED                = 124015,
    SPELL_SPITBALING           = 125358,
    SPELL_BELLY_FLOP           = 125384,
    SPELL_KNOCKBACK            = 118458,
    SPELL_CONSUMING_HATE       = 124683,
    SPELL_PURE_HATE            = 124690,
    SPELL_ARC_NOVA             = 149180,
    SPELL_LIGHTNING_BREATH     = 149178,
};

enum eCreatureEvents
{
    EVENT_CLAW_ATTACK = 1,
    EVENT_CORROSIVE_STING,
    EVENT_DOUBLE_BLADE_LUNGE,
    EVENT_TIMBERHUSK,
    EVENT_PROTECTIVE_SHELL,
    EVENT_RANK_BITE,
    EVENT_GORED,
    EVENT_BLOOD_RAGE,
    EVENT_SPITBALING,
    EVENT_BELLY_FLOP,
    EVENT_KNOCKBACK,
    EVENT_CONSUMING_HATE,
    EVENT_PURE_HATE,
    EVENT_ARC_NOVA,
    EVENT_LIGHTNING_BREATH,
};

// Seething Flashripper 61299
struct npc_seething_flashripper : public ScriptedAI
{
    npc_seething_flashripper(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;
    ObjectGuid targetGUID;
    uint32 delay;

    void Reset() override
    {
        events.Reset();
        delay      = 0;
        targetGUID = ObjectGuid::Empty;
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_CORROSIVE_STING, urand(3.5 * IN_MILLISECONDS, 6 * IN_MILLISECONDS));
        events.ScheduleEvent(EVENT_CLAW_ATTACK, 8.5 * IN_MILLISECONDS);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_CORROSIVE_STING:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, SPELL_CORROSIVE_STING);

                    events.ScheduleEvent(EVENT_CORROSIVE_STING, urand(10.5 * IN_MILLISECONDS, 13 * IN_MILLISECONDS));
                    break;
                case EVENT_CLAW_ATTACK:
                    if (Unit* target = me->GetVictim())
                    {
                        targetGUID = target->GetGUID();
                        me->PrepareChanneledCast(me->GetAngle(target), SPELL_CLAW_ATTACK);

                        delay = 0;
                        me->m_Events.Schedule(delay += 2000, 3, [this]()
                        {
                            me->RemoveChanneledCast(targetGUID);
                        });
                    }
                    events.ScheduleEvent(EVENT_CLAW_ATTACK, urand(12 * IN_MILLISECONDS, 19 * IN_MILLISECONDS));
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Kor`thik Timberhusk 61355
struct npc_korthik_timberhusk : public ScriptedAI
{
    npc_korthik_timberhusk(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_DOUBLE_BLADE_LUNGE, urand(4 * IN_MILLISECONDS, 15 * IN_MILLISECONDS));
        events.ScheduleEvent(EVENT_TIMBERHUSK, 6 * IN_MILLISECONDS);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_DOUBLE_BLADE_LUNGE:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, urand(0, 1) ? SPELL_DOUBLE_BLADE_LUNGE_1 : SPELL_DOUBLE_BLADE_LUNGE_2);

                    events.ScheduleEvent(EVENT_DOUBLE_BLADE_LUNGE, urand(6 * IN_MILLISECONDS, 17 * IN_MILLISECONDS));
                    break;
                case EVENT_TIMBERHUSK:
                    DoCast(me, SPELL_TIMBERHUSK);
                    events.ScheduleEvent(EVENT_TIMBERHUSK, urand(15 * IN_MILLISECONDS, 25 * IN_MILLISECONDS));
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Rankbite Ancient 66462
struct npc_rankbite_ancient : public ScriptedAI
{
    npc_rankbite_ancient(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_PROTECTIVE_SHELL, urand(12 * IN_MILLISECONDS, 18 * IN_MILLISECONDS));
        events.ScheduleEvent(EVENT_RANK_BITE, urand(3.5 * IN_MILLISECONDS, 11.5 * IN_MILLISECONDS));
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_PROTECTIVE_SHELL:
                    DoCast(me, SPELL_PROTECTIVE_SHELL);
                    events.ScheduleEvent(EVENT_PROTECTIVE_SHELL, urand(18 * IN_MILLISECONDS, 24 * IN_MILLISECONDS));
                    break;
                case EVENT_RANK_BITE:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, SPELL_RANK_BITE);

                    events.ScheduleEvent(EVENT_RANK_BITE, urand(3.5 * IN_MILLISECONDS, 11.5 * IN_MILLISECONDS));
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Deadtalker Crusher 62844
struct npc_deadtalker_crusher : public ScriptedAI
{
    npc_deadtalker_crusher(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_GORED, 7.5 * IN_MILLISECONDS);
        events.ScheduleEvent(EVENT_BLOOD_RAGE, 4.5 * IN_MILLISECONDS);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_GORED:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, SPELL_GORED);

                    events.ScheduleEvent(EVENT_GORED, 15 * IN_MILLISECONDS);
                    break;
                case EVENT_BLOOD_RAGE:
                    DoCast(me, SPELL_BLOOD_RAGE);
                    events.ScheduleEvent(EVENT_BLOOD_RAGE, urand(16 * IN_MILLISECONDS, 27 * IN_MILLISECONDS));
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Longshadow Mushan 61618
struct npc_longshadow_mushan : public ScriptedAI
{
    npc_longshadow_mushan(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;
    ObjectGuid targetGUID;
    uint32 delay;

    void Reset() override
    {
        events.Reset();
        delay = 0;
        targetGUID = ObjectGuid::Empty;
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_SPITBALING, urand(8.5 * IN_MILLISECONDS, 18 * IN_MILLISECONDS));
        events.ScheduleEvent(EVENT_BELLY_FLOP, 10 * IN_MILLISECONDS);
    }

    void CastInterrupted(SpellInfo const* /*spell*/) override
    {
        me->RemoveChanneledCast(targetGUID);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_BELLY_FLOP:
                    DoCast(me, SPELL_BELLY_FLOP);
                    events.ScheduleEvent(EVENT_BELLY_FLOP, urand(12.5 * IN_MILLISECONDS, 25 * IN_MILLISECONDS));
                    break;
                case EVENT_SPITBALING:
                    if (Unit* target = me->GetVictim())
                    {
                        targetGUID = target->GetGUID();
                        me->PrepareChanneledCast(me->GetAngle(target), SPELL_SPITBALING);

                        delay = 0;
                        me->m_Events.Schedule(delay += 6000, 3, [this]()
                        {
                            me->RemoveChanneledCast(targetGUID);
                        });
                    }
                    events.ScheduleEvent(EVENT_SPITBALING, urand(12 * IN_MILLISECONDS, 19 * IN_MILLISECONDS));
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Seething Hatred 61054, 61092
struct npc_seething_hatred : public ScriptedAI
{
    npc_seething_hatred(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;
    ObjectGuid targetGUID;
    uint32 delay;

    void Reset() override
    {
        events.Reset();
        delay = 0;
        targetGUID = ObjectGuid::Empty;
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_PURE_HATE, urand(3.5 * IN_MILLISECONDS, 7 * IN_MILLISECONDS));
        events.ScheduleEvent(EVENT_CONSUMING_HATE, 10 * IN_MILLISECONDS);
    }

    void CastInterrupted(SpellInfo const* /*spell*/) override
    {
        me->RemoveChanneledCast(targetGUID);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_PURE_HATE:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, SPELL_PURE_HATE);
                
                    events.ScheduleEvent(EVENT_PURE_HATE, urand(8.5 * IN_MILLISECONDS, 15 * IN_MILLISECONDS));
                    events.ScheduleEvent(EVENT_KNOCKBACK, 2.5 * IN_MILLISECONDS);
                    break;
                case EVENT_CONSUMING_HATE:
                    if (Unit* target = me->GetVictim())
                    {
                        targetGUID = target->GetGUID();
                        me->PrepareChanneledCast(me->GetAngle(target), SPELL_CONSUMING_HATE);
                
                        delay = 0;
                        me->m_Events.Schedule(delay += 6500, 4, [this]()
                        {
                            me->RemoveChanneledCast(targetGUID);
                        });
                    }
                    events.ScheduleEvent(EVENT_CONSUMING_HATE, urand(12 * IN_MILLISECONDS, 19 * IN_MILLISECONDS));
                    break;
                case EVENT_KNOCKBACK:
                    if (Unit* target = me->GetVictim())
                        DoCast(target, SPELL_KNOCKBACK);
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Gnathus 66467
struct npc_gnathus : public customCreatureAI
{
    npc_gnathus(Creature* creature) : customCreatureAI(creature) { }

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        events.ScheduleEvent(EVENT_ARC_NOVA, 12 * IN_MILLISECONDS);
        events.ScheduleEvent(EVENT_LIGHTNING_BREATH, urand(4.5 * IN_MILLISECONDS, 9 * IN_MILLISECONDS));
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            ExecuteTargetEvent(SPELL_LIGHTNING_BREATH, 10 * IN_MILLISECONDS, EVENT_LIGHTNING_BREATH, eventId, PRIORITY_CHANNELED);
            ExecuteTargetEvent(SPELL_ARC_NOVA, urand(15 * IN_MILLISECONDS, 20 * IN_MILLISECONDS), EVENT_ARC_NOVA, eventId, PRIORITY_SELF);
            break;
        }

        DoMeleeAttackIfReady();
    }
};

enum eEshelonSpells
{
    SPELL_RAIN_DANCE    = 124860,
    SPELL_TORRENT       = 124935,
    SPELL_WATER_BOLT    = 124854
};

enum eEshelonEvents
{
    EVENT_RAIN_DANCE        = 1,
    EVENT_TORRENT           = 2,
    EVENT_WATER_BOLT        = 3
};

class npc_eshelon : public CreatureScript
{
    public:
        npc_eshelon() : CreatureScript("npc_eshelon") { }

        struct npc_eshelonAI : public ScriptedAI
        {
            npc_eshelonAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;

            void Reset() override
            {
                events.Reset();

                events.ScheduleEvent(EVENT_RAIN_DANCE,   5000);
                events.ScheduleEvent(EVENT_TORRENT,     15000);
                events.ScheduleEvent(EVENT_WATER_BOLT,  25000);
            }

            void JustDied(Unit* /*killer*/) override { }

            void JustSummoned(Creature* summon) override
            {
                summon->DespawnOrUnsummon(12000);
            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                events.Update(diff);


                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_RAIN_DANCE:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_RAIN_DANCE, false);
                            events.ScheduleEvent(EVENT_RAIN_DANCE,       5000);
                            break;
                        case EVENT_TORRENT:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_TORRENT, false);
                            events.ScheduleEvent(EVENT_TORRENT, 15000);
                            break;
                        case EVENT_WATER_BOLT:
                            if (Unit* target = SelectTarget(SELECT_TARGET_TOPAGGRO))
                                me->CastSpell(target, SPELL_WATER_BOLT, false);
                            events.ScheduleEvent(EVENT_WATER_BOLT, 25000);
                            break;
                        default:
                            break;
                    }
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_eshelonAI(creature);
        }
};

// Peat Mound - 211515; quest Arconiss (30789)
class go_arconiss_peat_mound : public GameObjectScript
{
public:
    go_arconiss_peat_mound() : GameObjectScript("go_arconiss_peat_mound") { }

    bool OnGossipHello(Player* player, GameObject* /*go*/) override
    {
        if (player->GetQuestStatus(QUEST_ARCONISS) != QUEST_STATUS_INCOMPLETE ||
            player->GetQuestObjectiveCounter(262034))
            return true;

        Position spawnPosition = { 1793.68f, 2978.13f, 291.937f, 4.53491f };
        if (Creature* arconiss = player->SummonCreature(NPC_ARCONISS, spawnPosition,
            TEMPSUMMON_TIMED_DESPAWN, 60000, 0, player->GetGUID()))
        {
            arconiss->SetReactState(REACT_PASSIVE);
            arconiss->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_NPC);
            arconiss->HandleEmoteCommand(EMOTE_ONESHOT_ROAR);
            player->KilledMonsterCredit(NPC_ARCONISS);
        }

        return true;
    }
};

class go_sikthik_cage : public GameObjectScript
{
    public:
        go_sikthik_cage() : GameObjectScript("go_sikthik_cage") { }

        bool OnGossipHello(Player* player, GameObject* go) override
        {
            // If counter is 7 (script is called before counting) max is 8
            if (player->GetQuestObjectiveCounter(OBJECTIVE_SIKTHIK_CAGES_SEARCHED) == 7 && player->GetQuestStatus(QUEST_THE_SEARCH_OF_RESTLESS_LENG) == QUEST_STATUS_INCOMPLETE)
            {
                if (Creature* leng = player->SummonCreature(NPC_RESTLESS_LENG, player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), 0, TEMPSUMMON_TIMED_DESPAWN, 20000))
                {
                    ObjectGuid playerGuid = player->GetGUID();

                    uint32 delay = 0;
                    leng->m_Events.Schedule(delay += 2000, [leng]()             { leng->AI()->Talk(0); });
                    leng->m_Events.Schedule(delay += 2000, [leng]()             { leng->SetStandState(UNIT_STAND_STATE_STAND); });
                    leng->m_Events.Schedule(delay += 3000, [leng]()             { leng->AI()->Talk(1); });
                    leng->m_Events.Schedule(delay += 6000, [leng, playerGuid]() { if (Player* player = ObjectAccessor::GetPlayer(*leng, playerGuid)) leng->AI()->Talk(2, player); });
                }
                player->KilledMonsterCredit(NPC_RESTLESS_LENG);
            }

            ObjectGuid goGuid = go->GetGUID();
            uint32 delay = 0;
            player->m_Events.Schedule(delay += 8000, [player, goGuid]()
            {
                if (GameObject* cage = ObjectAccessor::GetGameObject(*player, goGuid))
                    cage->ForcedDespawn();
            });

            return false;
        }
};

enum BackOnTheirFeetActions
{
    ACTION_TREAT_INJURED_BLACKGUARD = 1,
};

// Injured Gao-Ran Blackguard - 61692; Back on Their Feet - 30892
struct npc_injured_gao_ran_blackguard : public ScriptedAI
{
    npc_injured_gao_ran_blackguard(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _treated = false;
        _bandageCaster.Clear();
        me->SetReactState(REACT_PASSIVE);
        me->setRegeneratingHealth(false);
        me->SetHealth(me->CountPctFromMaxHealth(10));
        me->SetStandState(UNIT_STAND_STATE_DEAD);
    }

    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        _bandageCaster = guid;
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_TREAT_INJURED_BLACKGUARD)
            return;

        Treat(ObjectAccessor::GetPlayer(*me, _bandageCaster));
    }

    void HealReceived(Unit* healer, uint32& heal) override
    {
        if (_treated || !healer || !me->HealthAbovePctHealed(50, heal))
            return;

        Treat(healer->GetCharmerOrOwnerPlayerOrPlayerItself());
    }

private:
    void Treat(Player* player)
    {
        if (_treated || !player ||
            player->GetQuestStatus(QUEST_BACK_ON_THEIR_FEET) != QUEST_STATUS_INCOMPLETE)
            return;

        _treated = true;
        player->KilledMonsterCredit(NPC_INJURED_GAO_RAN_BLACKGUARD);
        me->SetStandState(UNIT_STAND_STATE_STAND);
        me->HandleEmoteCommand(EMOTE_ONESHOT_SALUTE);
        me->DespawnOrUnsummon(4000);
    }

    bool _treated = false;
    ObjectGuid _bandageCaster;
};

// Citron-Infused Bandages - 120573; Back on Their Feet - 30892
class spell_item_cintron_infused_bandage : public SpellScriptLoader
{
    public:
        spell_item_cintron_infused_bandage() : SpellScriptLoader("spell_item_cintron_infused_bandage") { }

        class spell_item_cintron_infused_bandage_AuraScript : public AuraScript
        {
            PrepareAuraScript(spell_item_cintron_infused_bandage_AuraScript);

            void OnRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
            {
                if (!GetCaster())
                    return;

                if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
                    if (auto target = GetTarget()->ToCreature())
                        if (target->GetEntry() == NPC_INJURED_GAO_RAN_BLACKGUARD)
                            if (auto player = GetCaster()->ToPlayer())
                            {
                                target->AI()->SetGUID(player->GetGUID());
                                target->AI()->DoAction(ACTION_TREAT_INJURED_BLACKGUARD);
                            }
            }

            void Register() override
            {
                AfterEffectRemove += AuraEffectRemoveFn(spell_item_cintron_infused_bandage_AuraScript::OnRemove, EFFECT_0, SPELL_AURA_OBS_MOD_HEALTH, AURA_EFFECT_HANDLE_REAL);
            }
        };

        AuraScript* GetAuraScript() const override
        {
            return new spell_item_cintron_infused_bandage_AuraScript();
        }
};

// Dust to Dust quest
class spell_item_shado_pan_torch : public SpellScriptLoader
{
public:
    spell_item_shado_pan_torch() : SpellScriptLoader("spell_item_shado_pan_torch") { }

    class spell_item_shado_pan_torch_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_item_shado_pan_torch_AuraScript);

        void OnRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
                if (auto target = GetTarget()->ToCreature())
                    if (target->GetEntry() == 60925)
                    {
                        target->RemoveAurasDueToSpell(106246);
                        target->DespawnOrUnsummon();
                    }
        }

        void OnApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            auto caster = GetCaster();
            auto target = GetTarget();
            if (!caster || !target)
                return;

            if (target->GetTypeId() == TYPEID_UNIT && target->GetEntry() == 60925 && !target->HasAura(106246))
            {
                if (auto player = caster->ToPlayer())
                    player->KilledMonsterCredit(target->GetEntry());
                target->CastSpell(target, 106246, true);
            }
        }

        void Register() override
        {
            AfterEffectRemove += AuraEffectRemoveFn(spell_item_shado_pan_torch_AuraScript::OnRemove, EFFECT_1, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
            AfterEffectApply += AuraEffectApplyFn(spell_item_shado_pan_torch_AuraScript::OnApply, EFFECT_1, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_item_shado_pan_torch_AuraScript();
    }
};

// Quest: What Lies Beneath (30827)
enum WhatLiesBeneath
{
    SPELL_SHA_EMERGE                        = 127653,

    EVENT_RITUAL_PURE_HATE                  = 1,
    EVENT_RITUAL_CONSUMING_HATE             = 2,
};

Position const WhatLiesBeneathShaPosition = { 1740.10f, 2346.28f, 377.524f, 5.36966f };

class npc_yalia_what_lies_beneath : public CreatureScript
{
public:
    npc_yalia_what_lies_beneath() : CreatureScript("npc_yalia_what_lies_beneath") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PrepareQuestMenu(creature->GetGUID());

        if (player->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) == QUEST_STATUS_INCOMPLETE &&
            !player->GetQuestObjectiveCounter(OBJECTIVE_SPEAK_TO_YALIA))
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "I am ready. Let us begin the exorcism.",
                GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);

        player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        player->PlayerTalkClass->ClearMenus();

        if (sender == GOSSIP_SENDER_MAIN && action == GOSSIP_ACTION_INFO_DEF + 1 &&
            player->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) == QUEST_STATUS_INCOMPLETE &&
            !player->GetQuestObjectiveCounter(OBJECTIVE_SPEAK_TO_YALIA))
        {
            player->KilledMonsterCredit(NPC_SPEAK_TO_YALIA_CREDIT);
            creature->SetFacingToObject(player);
            creature->HandleEmoteCommand(EMOTE_ONESHOT_BOW);
        }

        player->CLOSE_GOSSIP_MENU();
        return true;
    }
};

class npc_what_lies_beneath_totem : public CreatureScript
{
public:
    npc_what_lies_beneath_totem() : CreatureScript("npc_what_lies_beneath_totem") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (player->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) != QUEST_STATUS_INCOMPLETE ||
            !player->GetQuestObjectiveCounter(OBJECTIVE_SPEAK_TO_YALIA))
            return true;

        bool canActivate = false;
        char const* option = "Activate the totem.";

        switch (creature->GetEntry())
        {
            case NPC_TOTEM_OF_KINDNESS:
                canActivate = !player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS);
                break;
            case NPC_TOTEM_OF_TRANQUILITY:
                canActivate = player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS) &&
                    !player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_TRANQUILITY);
                break;
            case NPC_TOTEM_OF_SERENITY:
                canActivate = player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS) &&
                    player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_TRANQUILITY) &&
                    !player->GetQuestObjectiveCounter(OBJECTIVE_RITUAL_COMPLETED);
                if (player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_SERENITY))
                    option = "Continue the exorcism.";
                break;
            default:
                break;
        }

        if (canActivate)
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, option, GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);

        player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        player->PlayerTalkClass->ClearMenus();

        if (sender != GOSSIP_SENDER_MAIN || action != GOSSIP_ACTION_INFO_DEF + 1 ||
            player->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) != QUEST_STATUS_INCOMPLETE ||
            !player->GetQuestObjectiveCounter(OBJECTIVE_SPEAK_TO_YALIA))
            return true;

        switch (creature->GetEntry())
        {
            case NPC_TOTEM_OF_KINDNESS:
                if (!player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS))
                    player->KilledMonsterCredit(NPC_TOTEM_OF_KINDNESS);
                break;
            case NPC_TOTEM_OF_TRANQUILITY:
                if (player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS) &&
                    !player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_TRANQUILITY))
                    player->KilledMonsterCredit(NPC_TOTEM_OF_TRANQUILITY);
                break;
            case NPC_TOTEM_OF_SERENITY:
                if (player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_KINDNESS) &&
                    player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_TRANQUILITY) &&
                    !player->GetQuestObjectiveCounter(OBJECTIVE_RITUAL_COMPLETED))
                {
                    if (!player->GetQuestObjectiveCounter(OBJECTIVE_TOTEM_OF_SERENITY))
                        player->KilledMonsterCredit(NPC_TOTEM_OF_SERENITY);

                    // A player-owned summon keeps simultaneous rituals isolated.
                    bool hasOwnSha = false;
                    std::list<Creature*> shaCreatures;
                    GetCreatureListWithEntryInGrid(shaCreatures, player, NPC_RITUAL_SEETHING_HATRED, 80.0f);
                    for (Creature* sha : shaCreatures)
                        if (TempSummon* summon = sha->ToTempSummon())
                            if (summon->IsAlive() && summon->GetSummonerGUID() == player->GetGUID())
                            {
                                hasOwnSha = true;
                                break;
                            }

                    if (!hasOwnSha)
                        player->SummonCreature(NPC_RITUAL_SEETHING_HATRED, WhatLiesBeneathShaPosition,
                            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 120000, 0, player->GetGUID());
                }
                break;
            default:
                break;
        }

        creature->HandleEmoteCommand(EMOTE_ONESHOT_SPELL_CAST);
        player->CLOSE_GOSSIP_MENU();
        return true;
    }

    struct npc_what_lies_beneath_totemAI : public ScriptedAI
    {
        npc_what_lies_beneath_totemAI(Creature* creature) : ScriptedAI(creature) { }
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        // Suppress the obsolete SmartAI gossip-credit action bound in the DB.
        return new npc_what_lies_beneath_totemAI(creature);
    }
};

struct npc_what_lies_beneath_sha : public ScriptedAI
{
    npc_what_lies_beneath_sha(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        Player* player = summoner->ToPlayer();
        if (!player || player->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) != QUEST_STATUS_INCOMPLETE)
        {
            me->DespawnOrUnsummon();
            return;
        }

        _ownerGuid = player->GetGUID();
        me->SetFaction(16);
        me->SetReactState(REACT_AGGRESSIVE);
        me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_NON_ATTACKABLE);
        DoCast(me, SPELL_SHA_EMERGE, true);
        AttackStart(player);
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        _events.ScheduleEvent(EVENT_RITUAL_PURE_HATE, urand(3500, 7000));
        _events.ScheduleEvent(EVENT_RITUAL_CONSUMING_HATE, 10000);
    }

    void JustDied(Unit* /*killer*/) override
    {
        if (Player* owner = ObjectAccessor::GetPlayer(*me, _ownerGuid))
            if (owner->GetQuestStatus(QUEST_WHAT_LIES_BENEATH) == QUEST_STATUS_INCOMPLETE &&
                !owner->GetQuestObjectiveCounter(OBJECTIVE_RITUAL_COMPLETED))
                owner->KilledMonsterCredit(NPC_RITUAL_YALIA);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_RITUAL_PURE_HATE:
                    DoCastVictim(SPELL_PURE_HATE);
                    _events.ScheduleEvent(EVENT_RITUAL_PURE_HATE, urand(8500, 15000));
                    break;
                case EVENT_RITUAL_CONSUMING_HATE:
                    DoCastVictim(SPELL_CONSUMING_HATE);
                    _events.ScheduleEvent(EVENT_RITUAL_CONSUMING_HATE, urand(12000, 19000));
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    EventMap _events;
    ObjectGuid _ownerGuid;
};

// Quest: Mists' Opportunity (30793)
enum MistsOpportunity
{
    SPELL_JAHESH_BASTION_OF_POWER           = 117809,
    SPELL_JAHESH_CHAIN_LIGHTNING             = 79913,
    SPELL_JAHESH_BEAM_SHIELD                 = 117820,
    SPELL_MISTLURKER_COSMETIC_DEATH          = 117940,

    EVENT_MISTS_CHAIN_LIGHTNING              = 1,
    EVENT_MISTS_ENOUGH_TORCHES               = 2,
    EVENT_MISTS_ELEMENTS_SHIELD              = 3,
    EVENT_MISTS_KILL_GOLGOSS                 = 4,
    EVENT_MISTS_KILL_ARCONISS                = 5,
    EVENT_MISTS_FIND_ORBISS                  = 6,
    EVENT_MISTS_SEE_ORBISS                   = 7,
    EVENT_MISTS_STRIKE_ORBISS                = 8,
    EVENT_MISTS_ORBISS_WILL_1                = 9,
    EVENT_MISTS_ORBISS_WILL_2                = 10,
    EVENT_MISTS_ORBISS_WILL_3                = 11,
    EVENT_MISTS_BREAK_SHIELD                 = 12,
};

Position const MistsOpportunityGolgossPosition = { 1773.47f, 2688.56f, 304.30f, 5.65f };
Position const MistsOpportunityArconissPosition = { 1770.70f, 2690.94f, 304.38f, 5.65f };

struct npc_jahesh_mists_opportunity : public ScriptedAI
{
    npc_jahesh_mists_opportunity(Creature* creature) : ScriptedAI(creature), _summons(me) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _playerGuid.Clear();
        _orbissGuid.Clear();
        _golgossGuid.Clear();
        _arconissGuid.Clear();
        _bastionPhase = false;
        _bastionBroken = false;
        me->RemoveAurasDueToSpell(SPELL_JAHESH_BASTION_OF_POWER);
        me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE);
        me->SetReactState(REACT_AGGRESSIVE);
    }

    void JustEngagedWith(Unit* who) override
    {
        Player* player = who->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (player && player->GetQuestStatus(QUEST_MISTS_OPPORTUNITY) == QUEST_STATUS_INCOMPLETE)
        {
            _playerGuid = player->GetGUID();
            Talk(0, player);
            SummonMistlurkers();
        }

        _events.ScheduleEvent(EVENT_MISTS_CHAIN_LIGHTNING, urand(9000, 13000));
    }

    void JustSummoned(Creature* summon) override
    {
        _summons.Summon(summon);
        summon->SetReactState(REACT_AGGRESSIVE);
        summon->AI()->AttackStart(me);

        if (summon->GetEntry() == NPC_GOLGOSS_MISTS_EVENT)
            _golgossGuid = summon->GetGUID();
        else if (summon->GetEntry() == NPC_ARCONISS_MISTS_EVENT)
            _arconissGuid = summon->GetGUID();
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage) override
    {
        if (_bastionPhase)
        {
            damage = 0;
            return;
        }

        if (!_bastionBroken && !_playerGuid.IsEmpty() && me->HealthBelowPctDamaged(40, damage))
        {
            damage = 0;
            StartBastionPhase();
        }
    }

    void UpdateAI(uint32 diff) override
    {
        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_MISTS_CHAIN_LIGHTNING:
                    if (!_bastionPhase && me->GetVictim())
                        DoCastVictim(SPELL_JAHESH_CHAIN_LIGHTNING);
                    _events.ScheduleEvent(EVENT_MISTS_CHAIN_LIGHTNING, urand(19000, 22000));
                    break;
                case EVENT_MISTS_ENOUGH_TORCHES:
                    Talk(2);
                    break;
                case EVENT_MISTS_ELEMENTS_SHIELD:
                    Talk(3);
                    break;
                case EVENT_MISTS_KILL_GOLGOSS:
                    Talk(4);
                    KillMistlurker(_golgossGuid, 0);
                    break;
                case EVENT_MISTS_KILL_ARCONISS:
                    Talk(5);
                    KillMistlurker(_arconissGuid, 0);
                    break;
                case EVENT_MISTS_FIND_ORBISS:
                    Talk(6);
                    break;
                case EVENT_MISTS_SEE_ORBISS:
                    Talk(7);
                    break;
                case EVENT_MISTS_STRIKE_ORBISS:
                    Talk(8);
                    if (Creature* orbiss = ObjectAccessor::GetCreature(*me, _orbissGuid))
                        DoCast(orbiss, SPELL_JAHESH_CHAIN_LIGHTNING, true);
                    break;
                case EVENT_MISTS_ORBISS_WILL_1:
                    if (Creature* orbiss = ObjectAccessor::GetCreature(*me, _orbissGuid))
                        orbiss->AI()->Talk(0);
                    break;
                case EVENT_MISTS_ORBISS_WILL_2:
                    if (Creature* orbiss = ObjectAccessor::GetCreature(*me, _orbissGuid))
                        orbiss->AI()->Talk(1);
                    break;
                case EVENT_MISTS_ORBISS_WILL_3:
                    if (Creature* orbiss = ObjectAccessor::GetCreature(*me, _orbissGuid))
                    {
                        orbiss->AI()->Talk(2);
                        orbiss->CastSpell(me, SPELL_JAHESH_BEAM_SHIELD, true);
                    }
                    break;
                case EVENT_MISTS_BREAK_SHIELD:
                    BreakBastion();
                    break;
                default:
                    break;
            }
        }

        if (_bastionPhase || !UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }

private:
    void SummonMistlurkers()
    {
        if (Creature* orbiss = GetClosestCreatureWithEntry(me, NPC_ORBISS_MISTS_EVENT, 60.0f, true))
        {
            _orbissGuid = orbiss->GetGUID();
            orbiss->SetReactState(REACT_DEFENSIVE);
            orbiss->AI()->AttackStart(me);
        }

        me->SummonCreature(NPC_GOLGOSS_MISTS_EVENT, MistsOpportunityGolgossPosition,
            TEMPSUMMON_CORPSE_TIMED_DESPAWN, 30000);
        me->SummonCreature(NPC_ARCONISS_MISTS_EVENT, MistsOpportunityArconissPosition,
            TEMPSUMMON_CORPSE_TIMED_DESPAWN, 30000);
    }

    void StartBastionPhase()
    {
        _bastionPhase = true;
        me->AttackStop();
        me->SetReactState(REACT_PASSIVE);
        DoCast(me, SPELL_JAHESH_BASTION_OF_POWER, true);
        Talk(1);

        _events.ScheduleEvent(EVENT_MISTS_ENOUGH_TORCHES, 1500);
        _events.ScheduleEvent(EVENT_MISTS_ELEMENTS_SHIELD, 3000);
        _events.ScheduleEvent(EVENT_MISTS_KILL_GOLGOSS, 5000);
        _events.ScheduleEvent(EVENT_MISTS_KILL_ARCONISS, 7500);
        _events.ScheduleEvent(EVENT_MISTS_FIND_ORBISS, 9500);
        _events.ScheduleEvent(EVENT_MISTS_SEE_ORBISS, 11500);
        _events.ScheduleEvent(EVENT_MISTS_STRIKE_ORBISS, 13500);
        _events.ScheduleEvent(EVENT_MISTS_ORBISS_WILL_1, 15000);
        _events.ScheduleEvent(EVENT_MISTS_ORBISS_WILL_2, 16500);
        _events.ScheduleEvent(EVENT_MISTS_ORBISS_WILL_3, 18000);
        _events.ScheduleEvent(EVENT_MISTS_BREAK_SHIELD, 20000);
    }

    void KillMistlurker(ObjectGuid guid, uint8 textGroup)
    {
        if (Creature* mistlurker = ObjectAccessor::GetCreature(*me, guid))
        {
            mistlurker->AI()->Talk(textGroup);
            DoCast(mistlurker, SPELL_JAHESH_CHAIN_LIGHTNING, true);
            mistlurker->CastSpell(mistlurker, SPELL_MISTLURKER_COSMETIC_DEATH, true);
            me->Kill(mistlurker);
        }
    }

    void BreakBastion()
    {
        me->RemoveAurasDueToSpell(SPELL_JAHESH_BASTION_OF_POWER);
        Talk(9);
        _bastionPhase = false;
        _bastionBroken = true;
        me->SetReactState(REACT_AGGRESSIVE);

        if (Player* player = ObjectAccessor::GetPlayer(*me, _playerGuid))
            AttackStart(player);
    }

    EventMap _events;
    SummonList _summons;
    ObjectGuid _playerGuid;
    ObjectGuid _orbissGuid;
    ObjectGuid _golgossGuid;
    ObjectGuid _arconissGuid;
    bool _bastionPhase = false;
    bool _bastionBroken = false;
};

// Quest: Hatred Becomes Us (30783)
enum HatredBecomesUs
{
    SPELL_CONSUMED_BY_HATRED                = 118406,
    SPELL_HARMONY                           = 118332,

    ACTION_EXORCISE_RANGER                  = 1,
    ACTION_RANGER_PURIFIED                  = 2,
    ACTION_EXORCISM_FAILED                  = 3,

    DATA_EXORCISM_ACTIVE                    = 1,

    EVENT_TOTEM_EXORCISE                    = 1,
    EVENT_RANGER_SERRATED_SLASH             = 1,
    EVENT_RANGER_SNAP_KICK                  = 2,
    EVENT_HATRED_PURE_HATE                  = 1,
    EVENT_HATRED_CONSUMING_HATE             = 2,
    EVENT_HATRED_KNOCKBACK                  = 3,
};

// Crazed Shado-Pan Ranger - 61050
struct npc_crazed_shado_pan_ranger : public ScriptedAI
{
    npc_crazed_shado_pan_ranger(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _events.Reset();
        _ownerGuid.Clear();
        _hatredGuid.Clear();
        _exorcismActive = false;
        me->SetFaction(7); // Neutral while possessed.
        me->SetReactState(REACT_DEFENSIVE);
        DoCast(me, SPELL_CONSUMED_BY_HATRED, true);
    }

    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        _ownerGuid = guid;
    }

    uint32 GetData(uint32 type) const override
    {
        return type == DATA_EXORCISM_ACTIVE && _exorcismActive;
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_EXORCISE_RANGER)
        {
            if (_exorcismActive)
                return;

            Player* player = ObjectAccessor::GetPlayer(*me, _ownerGuid);
            if (!player || player->GetQuestStatus(QUEST_HATRED_BECOMES_US) != QUEST_STATUS_INCOMPLETE)
                return;

            _exorcismActive = true;
            me->RemoveAurasDueToSpell(SPELL_CONSUMED_BY_HATRED);
            me->CombatStop(true);
            me->SetFaction(35);
            me->SetReactState(REACT_DEFENSIVE);

            Position position = me->GetRandomNearPosition(3.0f);
            if (Creature* hatred = player->SummonCreature(NPC_HATRED_BECOMES_US_SHA, position,
                TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 120000, 0, player->GetGUID()))
            {
                _hatredGuid = hatred->GetGUID();
                hatred->AI()->SetGUID(me->GetGUID());
                me->Attack(hatred, true);
            }
            else
                DoAction(ACTION_EXORCISM_FAILED);
        }
        else if (action == ACTION_RANGER_PURIFIED)
        {
            _exorcismActive = false;
            _events.Reset();
            me->CombatStop(true);
            me->SetFaction(35);
            me->SetReactState(REACT_PASSIVE);
            me->HandleEmoteCommand(EMOTE_ONESHOT_BOW);
            me->DespawnOrUnsummon(5000);
        }
        else if (action == ACTION_EXORCISM_FAILED)
        {
            _events.Reset();
            me->CombatStop(true);
            Reset();
        }
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        _events.ScheduleEvent(EVENT_RANGER_SERRATED_SLASH, urand(6000, 9000));
        _events.ScheduleEvent(EVENT_RANGER_SNAP_KICK, urand(9000, 13000));
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_RANGER_SERRATED_SLASH:
                    DoCastVictim(87395);
                    _events.ScheduleEvent(EVENT_RANGER_SERRATED_SLASH, urand(16000, 19000));
                    break;
                case EVENT_RANGER_SNAP_KICK:
                    DoCastVictim(46182);
                    _events.ScheduleEvent(EVENT_RANGER_SNAP_KICK, urand(16000, 19000));
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    EventMap _events;
    ObjectGuid _ownerGuid;
    ObjectGuid _hatredGuid;
    bool _exorcismActive = false;
};

// Player-placed Totem of Harmony - 61062
struct npc_totem_of_harmony_30783 : public ScriptedAI
{
    npc_totem_of_harmony_30783(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        Player* player = summoner->ToPlayer();
        if (!player || player->GetQuestStatus(QUEST_HATRED_BECOMES_US) != QUEST_STATUS_INCOMPLETE)
            return;

        _ownerGuid = player->GetGUID();
        me->SetReactState(REACT_PASSIVE);
        me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
        me->CombatStop(true);
        DoCast(me, SPELL_HARMONY, true);
        _events.ScheduleEvent(EVENT_TOTEM_EXORCISE, 4000);
    }

    bool CanAIAttack(Unit const* /*target*/) const override
    {
        return false;
    }

    void UpdateAI(uint32 diff) override
    {
        _events.Update(diff);
        if (_events.ExecuteEvent() != EVENT_TOTEM_EXORCISE)
            return;

        Player* player = ObjectAccessor::GetPlayer(*me, _ownerGuid);
        if (!player || player->GetQuestStatus(QUEST_HATRED_BECOMES_US) != QUEST_STATUS_INCOMPLETE)
            return;

        std::list<Creature*> rangers;
        GetCreatureListWithEntryInGrid(rangers, me, NPC_CRAZED_SHADO_PAN_RANGER, 12.0f);
        rangers.sort(Trinity::ObjectDistanceOrderPred(me));
        for (Creature* ranger : rangers)
        {
            if (!ranger->IsAlive() || ranger->AI()->GetData(DATA_EXORCISM_ACTIVE))
                continue;

            ranger->AI()->SetGUID(player->GetGUID());
            ranger->AI()->DoAction(ACTION_EXORCISE_RANGER);
            return;
        }
    }

private:
    EventMap _events;
    ObjectGuid _ownerGuid;
};

// Ranger-bound Seething Hatred - 61054
struct npc_hatred_becomes_us_sha : public ScriptedAI
{
    npc_hatred_becomes_us_sha(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        if (Player* player = summoner->ToPlayer())
        {
            _ownerGuid = player->GetGUID();
            _creditBefore = player->GetQuestObjectiveCounter(OBJECTIVE_CRAZED_RANGERS_PURIFIED);
            me->SetLootRecipient(player);
            me->SetReactState(REACT_AGGRESSIVE);
            me->AddThreat(player, 1.0f);
            AttackStart(player);
        }
    }

    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        _rangerGuid = guid;
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        _events.ScheduleEvent(EVENT_HATRED_PURE_HATE, urand(3500, 7000));
        _events.ScheduleEvent(EVENT_HATRED_CONSUMING_HATE, 10000);
    }

    void JustDied(Unit* /*killer*/) override
    {
        // Normal kill reward happens before JustDied. Supply the same credit
        // only when the allied ranger landed too much of the damage for the
        // core's normal tap/damage threshold to reward the owner.
        if (Player* owner = ObjectAccessor::GetPlayer(*me, _ownerGuid))
            if (owner->GetQuestStatus(QUEST_HATRED_BECOMES_US) == QUEST_STATUS_INCOMPLETE &&
                owner->GetQuestObjectiveCounter(OBJECTIVE_CRAZED_RANGERS_PURIFIED) == _creditBefore)
                owner->KilledMonsterCredit(NPC_HATRED_BECOMES_US_SHA);

        if (Creature* ranger = ObjectAccessor::GetCreature(*me, _rangerGuid))
            ranger->AI()->DoAction(ACTION_RANGER_PURIFIED);
    }

    void EnterEvadeMode() override
    {
        if (Creature* ranger = ObjectAccessor::GetCreature(*me, _rangerGuid))
            ranger->AI()->DoAction(ACTION_EXORCISM_FAILED);
        me->DespawnOrUnsummon();
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_HATRED_PURE_HATE:
                    DoCastVictim(SPELL_PURE_HATE);
                    _events.ScheduleEvent(EVENT_HATRED_PURE_HATE, urand(8500, 15000));
                    _events.ScheduleEvent(EVENT_HATRED_KNOCKBACK, 2500);
                    break;
                case EVENT_HATRED_CONSUMING_HATE:
                    DoCastVictim(SPELL_CONSUMING_HATE);
                    _events.ScheduleEvent(EVENT_HATRED_CONSUMING_HATE, urand(12000, 19000));
                    break;
                case EVENT_HATRED_KNOCKBACK:
                    DoCastVictim(SPELL_KNOCKBACK);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    EventMap _events;
    ObjectGuid _ownerGuid;
    ObjectGuid _rangerGuid;
    uint32 _creditBefore = 0;
};

// Quest: Ranger Rescue (30774)
enum RangerRescue
{
    SPELL_SUMMON_LONGYING_RANGER            = 117670,
    SPELL_STEALTH                           = 1784,

    EVENT_SUNA_ARRIVE                       = 1,
    EVENT_SUNA_KNEEL_TALK                   = 2,
    EVENT_SUNA_TALK_2                       = 3,
    EVENT_SUNA_TALK_3                       = 4,
    EVENT_SUNA_TALK_4                       = 5,
    EVENT_SUNA_TALK_5                       = 6,
    EVENT_SUNA_LEAVE                        = 7
};

class go_drywood_cage : public GameObjectScript
{
    public:
        go_drywood_cage() : GameObjectScript("go_drywood_cage") { }

        bool OnGossipHello(Player* player, GameObject* go) override
        {
            if (player->GetQuestStatus(QUEST_RANGER_RESCUE) == QUEST_STATUS_INCOMPLETE
                && player->GetQuestObjectiveCounter(QUEST_OBJECTIVE_LONGYIN_RANGER_RESCUED) < 4)
            {
                if (auto ranger = GetClosestCreatureWithEntry(player, NPC_LONGYING_RANGER, 10.f))
                {
                    go->SetGoState(GO_STATE_ACTIVE);

                    // QuestObjectiveSatisfy expects the objective's objectId (60730),
                    // not its database objective id (263418).
                    player->KilledMonsterCredit(NPC_LONGYING_RANGER);
                    player->CastSpell(player, SPELL_SUMMON_LONGYING_RANGER, true);

                    if (auto rangerHelper = GetClosestCreatureWithEntry(player, NPC_LONGYING_RANGER_HELPER, 10.f))
                        rangerHelper->AI()->Talk(0, player);

                    ranger->DisappearAndDie();
                }
            }

            return true;
        }
};

class npc_longying_ranger : public CreatureScript
{
    public:
        npc_longying_ranger() : CreatureScript("npc_longying_ranger") { }

        struct npc_longying_ranger_AI : public ScriptedAI
        {
            npc_longying_ranger_AI(Creature* creature) : ScriptedAI(creature) { }

            void JustAppeared() override
            {
                if (GameObject* cage = GetClosestGameObjectWithEntry(me, GO_DRYWOOD_CAGE, 10.f))
                    cage->SetGoState(GO_STATE_READY);
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_longying_ranger_AI(creature);
        }
};

// Player-owned Longying Ranger - 60763
struct npc_longying_ranger_helper : public ScriptedAI
{
    npc_longying_ranger_helper(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        Player* player = summoner->ToPlayer();
        if (!player)
            return;

        _ownerGuid = player->GetGUID();
        me->SetReactState(REACT_DEFENSIVE);

        // These rescued Shado-Pan are intentionally powerful quest allies.
        // Creature level normalization reduced their melee to roughly one fifth
        // of the intended value, so restore that strength only on player summons.
        me->SetModifierValue(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT, 5.0f);
        me->UpdateDamagePhysical(BASE_ATTACK);
        me->GetMotionMaster()->MoveFollow(player, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
    }

    bool CanAIAttack(Unit const* target) const override
    {
        Player* owner = ObjectAccessor::GetPlayer(*me, _ownerGuid);
        if (!owner || !target || !target->IsWithinDistInMap(owner, 35.0f))
            return false;

        return target == owner->GetVictim() || target->GetVictim() == owner || target->GetVictim() == me;
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        Player* owner = ObjectAccessor::GetPlayer(*me, _ownerGuid);
        if (!owner)
            return;

        if (!UpdateVictim())
        {
            Unit* target = owner->GetVictim();
            if (!target)
                for (Unit* attacker : owner->getAttackers())
                    if (CanAIAttack(attacker))
                    {
                        target = attacker;
                        break;
                    }

            if (target && CanAIAttack(target))
                AttackStart(target);
            else if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
                me->GetMotionMaster()->MoveFollow(owner, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
            return;
        }

        if (!CanAIAttack(me->GetVictim()))
        {
            EnterEvadeMode();
            me->GetMotionMaster()->MoveFollow(owner, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
            return;
        }

        DoMeleeAttackIfReady();
    }

private:
    ObjectGuid _ownerGuid;
};

class npc_lin_silentstrike : public CreatureScript
{
    public:
        npc_lin_silentstrike() : CreatureScript("npc_lin_silentstrike") { }

        bool OnGossipHello(Player* player, Creature* creature) override
        {
            if (player->GetQuestStatus(QUEST_RANGER_RESCUE) == QUEST_STATUS_INCOMPLETE
                && !player->GetQuestObjectiveCounter(QUEST_OBJECTIVE_FREE_LIN_SILENTSTRIKE))
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "Examine the body.", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);

            player->SEND_GOSSIP_MENU(player->GetGossipTextId(creature), creature->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
        {
            player->PlayerTalkClass->ClearMenus();
            if (action == GOSSIP_ACTION_INFO_DEF + 1 &&
                player->GetQuestStatus(QUEST_RANGER_RESCUE) == QUEST_STATUS_INCOMPLETE &&
                !player->GetQuestObjectiveCounter(QUEST_OBJECTIVE_FREE_LIN_SILENTSTRIKE))
            {
                // The objective's objectId is 60899; 263419 is only its database id.
                player->KilledMonsterCredit(creature->GetEntry());

                Position spawnPosition = { 2659.59f, 3268.618f, 425.33f, 5.56f };
                player->SummonCreature(NPC_SUNA_SILENTSTRIKE, spawnPosition,
                    TEMPSUMMON_TIMED_DESPAWN, 34000, 0, player->GetGUID());

                // Reveal what Lin is clutching while Suna runs toward him.
                player->SEND_GOSSIP_MENU(19747, creature->GetGUID());
            }

            return true;
        }

        // Keep Lin's obsolete SmartAI gossip hook from also casting spell 117974;
        // the source spell has no target-position row and would duplicate the scene.
        struct npc_lin_silentstrikeAI : public ScriptedAI
        {
            npc_lin_silentstrikeAI(Creature* creature) : ScriptedAI(creature) { }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_lin_silentstrikeAI(creature);
        }
};

// Suna Silentstrike - 60901; private grief scene summoned for Ranger Rescue
struct npc_suna_ranger_rescue_scene : public ScriptedAI
{
    npc_suna_ranger_rescue_scene(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        if (Player* player = summoner->ToPlayer())
            _ownerGuid = player->GetGUID();

        me->SetReactState(REACT_PASSIVE);
        me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_NPC);
        me->GetMotionMaster()->MovePoint(1, 2674.21f, 3257.52f, 426.31f);

        events.ScheduleEvent(EVENT_SUNA_ARRIVE, 3000);
        events.ScheduleEvent(EVENT_SUNA_KNEEL_TALK, 6000);
        events.ScheduleEvent(EVENT_SUNA_TALK_2, 10000);
        events.ScheduleEvent(EVENT_SUNA_TALK_3, 14000);
        events.ScheduleEvent(EVENT_SUNA_TALK_4, 18000);
        events.ScheduleEvent(EVENT_SUNA_TALK_5, 22000);
        events.ScheduleEvent(EVENT_SUNA_LEAVE, 26000);
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        while (uint32 eventId = events.ExecuteEvent())
        {
            Player* owner = ObjectAccessor::GetPlayer(*me, _ownerGuid);
            switch (eventId)
            {
                case EVENT_SUNA_ARRIVE:
                    Talk(0, owner);
                    break;
                case EVENT_SUNA_KNEEL_TALK:
                    me->SetStandState(UNIT_STAND_STATE_KNEEL);
                    Talk(1, owner);
                    break;
                case EVENT_SUNA_TALK_2:
                    Talk(2, owner);
                    break;
                case EVENT_SUNA_TALK_3:
                    Talk(3, owner);
                    break;
                case EVENT_SUNA_TALK_4:
                    Talk(4, owner);
                    break;
                case EVENT_SUNA_TALK_5:
                    Talk(5, owner);
                    break;
                case EVENT_SUNA_LEAVE:
                    me->SetStandState(UNIT_STAND_STATE_STAND);
                    DoCast(me, SPELL_STEALTH, true);
                    me->DespawnOrUnsummon(2000);
                    break;
                default:
                    break;
            }
        }
    }

private:
    EventMap events;
    ObjectGuid _ownerGuid;
};

// Osul Mist-Shaman 60697
class npc_osul_mist_shaman : public CreatureScript
{
    public:
        npc_osul_mist_shaman() : CreatureScript("npc_osul_mist_shaman") { }

        enum eSpells
        {
            SPELL_DESECRATION      = 117464, // cosmetic blue hands + cosmetic casting
            SPELL_CAPACITOR_TOTEM  = 125720,
            SPELL_LIGHTNING_BOLT   = 79085,
        };

        enum eEvents
        {
            EVENT_LIGHTNING_BOLT   = 1,
            EVENT_CAPACITOR_TOTEM  = 2,
        };

        struct npc_osul_mist_shamanAI : public ScriptedAI
        {
            npc_osul_mist_shamanAI(Creature* creature) : ScriptedAI(creature) { }

            ObjectGuid TorchGUID;
            EventMap events;

            void Reset() override
            {
                Unit* Torch = ObjectAccessor::GetUnit(*me, TorchGUID);

                if (!Torch)
                {
                    Position pos = me->GetRandomNearPosition(4.5f);

                    if (TempSummon* Torch = me->SummonCreature(NPC_MIST_SHAMANS_TORCH, pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), urand(0, 2 * M_PI), TEMPSUMMON_MANUAL_DESPAWN))
                        TorchGUID = Torch->GetGUID();
                }

                me->CastSpell(me, SPELL_DESECRATION, false);
                events.Reset();
            }

            void JustEngagedWith(Unit* who) override
            {
                events.ScheduleEvent(EVENT_LIGHTNING_BOLT, urand(1500, 3000));
                events.ScheduleEvent(EVENT_CAPACITOR_TOTEM, urand(4000, 6000));
            }

            void JustDied(Unit* killer) override 
            {
                if (Unit* Torch = ObjectAccessor::GetUnit(*me, TorchGUID))
                {
                    if (killer && killer->ToPlayer() && killer->ToPlayer()->GetQuestStatus(QUEST_THE_TORCHES) == QUEST_STATUS_INCOMPLETE)
                        Torch->SetFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);

                    Torch->ToCreature()->DespawnOrUnsummon(10 * IN_MILLISECONDS);
                }
            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_LIGHTNING_BOLT:
                            if (Unit* victim = me->GetVictim())
                                me->CastSpell(victim, SPELL_LIGHTNING_BOLT, false);

                            events.ScheduleEvent(EVENT_LIGHTNING_BOLT, urand(1500, 3000));
                            break;
                        case EVENT_CAPACITOR_TOTEM:
                            if (Unit* victim = me->GetVictim())
                                me->CastSpell(victim, SPELL_CAPACITOR_TOTEM, false);

                            events.ScheduleEvent(EVENT_CAPACITOR_TOTEM, 12 * IN_MILLISECONDS);
                            break;
                    }
                }
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_osul_mist_shamanAI(creature);
        }
};

// Gather Steam 117901
class spell_gather_steam : public SpellScript
{
    PrepareSpellScript(spell_gather_steam);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        targets.remove_if([=](WorldObject* obj) { return obj->ToPlayer()->GetQuestStatus(QUEST_ORBISS_FADES) != QUEST_STATUS_INCOMPLETE; });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        if (Unit* caster = GetCaster())
            if (caster->ToCreature())
                caster->ToCreature()->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_gather_steam::FilterTargets, EFFECT_0, TARGET_UNIT_DEST_AREA_ENTRY);
        OnEffectHitTarget += SpellEffectFn(spell_gather_steam::HandleDummy, EFFECT_0, SPELL_EFFECT_KILL_CREDIT2);
    }
};

// Suna Silentstrike 61055
class npc_suna_silentstrike : public CreatureScript
{
    public:
        npc_suna_silentstrike() : CreatureScript("npc_suna_silentstrike") { }

        enum Spells
        {
            SPELL_INNER_PEACE          = 128814,
            SPELL_CONSUMED_BY_HATRED_1 = 128813, // only visual
            SPELL_CONSUMED_BY_HATRED_2 = 127470,
            SPELL_ROUNDHOUSE_KICK      = 128305,
            SPELL_UNLEASH_HATE         = 127474,
        };

        enum Yells
        {
            SAY_SUNA_ON_SPELLHIT = 0,
            SAY_SUNA_AGGRO       = 1,
            SAY_SUNA_END         = 2,
        };

        enum Events
        {
            EVENT_ROUNDHOUSE_KICK = 1,
            EVENT_UNLEASH_HATE    = 2,
        };

        struct npc_suna_silentstrikeAI : public ScriptedAI
        {
            npc_suna_silentstrikeAI(Creature* creature) : ScriptedAI(creature) { }

            EventMap events;
            bool sayOnHit;

            void SpellHit(Unit* /*caster*/, const SpellInfo* spell) override
            {
                if (spell->Id == SPELL_INNER_PEACE && !sayOnHit)
                {
                    Talk(SAY_SUNA_ON_SPELLHIT);
                    sayOnHit = true;
                }
            }

            void DamageTaken(Unit* who, uint32& damage) override
            {
                if (damage >= me->GetHealth())
                {
                    damage = 0;

                    events.Reset();
                    me->RemoveAura(SPELL_CONSUMED_BY_HATRED_2);
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);

                    Talk(SAY_SUNA_END);
                    me->SetStandState(UNIT_STAND_STATE_KNEEL);
                    if (who->GetTypeId() == TYPEID_PLAYER)
                        who->ToPlayer()->KilledMonsterCredit(NPC_SUNA_SILENTSTRIKE_2);
                    else if (Player* player = who->GetCharmerOrOwnerPlayerOrPlayerItself())
                        player->KilledMonsterCredit(NPC_SUNA_SILENTSTRIKE_2);

                    Creature* suna = me;

                    uint32 delay = 0;
                    suna->m_Events.Schedule(delay += 5000, [suna]() { suna->SetStandState(UNIT_STAND_STATE_STAND); });
                    suna->m_Events.Schedule(delay += 5000, [suna]() { suna->setDeathState(JUST_DIED);              });
                    suna->m_Events.Schedule(delay += 5000, [suna]() { suna->DespawnOrUnsummon();                   });
                }
            }

            void Reset() override
            {
                sayOnHit = false;

                me->AddAura(SPELL_CONSUMED_BY_HATRED_1, me);
                me->RemoveAura(SPELL_CONSUMED_BY_HATRED_2);
            }

            void JustEngagedWith(Unit* who) override
            {
                Talk(SAY_SUNA_AGGRO);
                me->CastSpell(me, SPELL_CONSUMED_BY_HATRED_2);
                events.ScheduleEvent(EVENT_ROUNDHOUSE_KICK, urand(8000, 10000));
                events.ScheduleEvent(EVENT_UNLEASH_HATE, 20000);
            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_ROUNDHOUSE_KICK:
                            if (Unit* victim = me->GetVictim())
                                me->CastSpell(victim, SPELL_ROUNDHOUSE_KICK, false);
                            events.ScheduleEvent(EVENT_ROUNDHOUSE_KICK, urand(10000, 12000));
                            break;
                        case EVENT_UNLEASH_HATE:
                            if (Unit* victim = me->GetVictim())
                                me->CastSpell(me, SPELL_UNLEASH_HATE, false);
                            events.ScheduleEvent(EVENT_UNLEASH_HATE, 20000);
                            break;
                    }
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_suna_silentstrikeAI(creature);
        }
};

// Wounded Niuzao Sentinel 61570
class npc_wounded_niuzao_sentinel : public CreatureScript
{
    public:
        npc_wounded_niuzao_sentinel() : CreatureScript("npc_wounded_niuzao_sentinel") { }

        struct npc_wounded_niuzao_sentinelAI : public ScriptedAI
        {
            npc_wounded_niuzao_sentinelAI(Creature* creature) : ScriptedAI(creature) { }

            bool HasHealed;

            void Reset() override
            {
                me->setRegeneratingHealth(false);
                me->SetHealth((uint32)me->GetMaxHealth() * 0.1f);
                me->SetStandState(UNIT_STAND_STATE_DEAD);
                HasHealed = false;
            }

            void HealReceived(Unit* healer, uint32& heal) override
            {
                if (me->HealthAbovePct(50) && !HasHealed)
                {
                    HasHealed = true;

                    if (Player* pItr = healer->ToPlayer())
                        if (pItr->GetQuestStatus(QUEST_FALLEN_SENTINELS) == QUEST_STATUS_INCOMPLETE)
                            pItr->KilledMonsterCredit(NPC_SENTINEL_HEALED_CREDIT);

                    me->SetStandState(UNIT_STAND_STATE_STAND);

                    uint32 delay = 0;
                    me->m_Events.Schedule(delay += 1500, 1, [this]()
                    {
                        me->HandleEmoteCommand(EMOTE_ONESHOT_BOW);
                        me->DespawnOrUnsummon(3 * IN_MILLISECONDS);
                    });
                }
            }

        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_wounded_niuzao_sentinelAI(creature);
        }
};

// spells data is missed
const std::map <uint32, Position> invCaskType =
{
    { 61363, { 2525.40f, 3896.17f, 282.68f, 0.86f } }, // weapons
    { 61364, { 2488.04f, 3828.55f, 284.02f, 2.63f } }, // Eggs
};

// Gunpowder Cask 61362
struct npc_townlong_gunpowder_cask : public ScriptedAI
{
    npc_townlong_gunpowder_cask(Creature* creature) : ScriptedAI(creature) { }

    TaskScheduler scheduler;
    ObjectGuid summonerGUID;

    void IsSummonedBy(Unit* summoner) override
    {
        summonerGUID = summoner->GetGUID();

        scheduler
            .Schedule(Milliseconds(3000), [this](TaskContext context)
        {
            if (Player* owner = ObjectAccessor::GetPlayer(*me, summonerGUID))
            {
                for (auto&& itr : invCaskType)
                    if (me->GetExactDist2d(itr.second.GetPositionX(), itr.second.GetPositionY()) < 8.5f)
                        owner->KilledMonsterCredit(itr.first);
            }

            DoCast(me, 105380); // wrong spellId (or not?)
            me->DespawnOrUnsummon();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }
};

class spell_q30959 : public SpellScript
{
    PrepareSpellScript(spell_q30959);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        targets.remove_if([=](WorldObject* obj) { return obj->GetEntry() != NPC_SRATHIK_WAR_WAGON; });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_q30959::FilterTargets, EFFECT_ALL, TARGET_UNIT_DEST_AREA_ENTRY);
    }
};

// Protective Shell 130728
class spell_protective_shell : public AuraScript
{
    PrepareAuraScript(spell_protective_shell);

    void OnAuraEffectRemove(AuraEffect const* aurEff, AuraEffectHandleModes mode)
    {
        if (Creature* owner = GetOwner()->ToCreature())
            owner->CastSpell(owner, SPELL_BROKEN_SHELL, true);
    }

    void Register() override
    {
        OnEffectRemove += AuraEffectRemoveFn(spell_protective_shell::OnAuraEffectRemove, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL);
    }
};

class cond_burn_mantid_corpse : public ConditionScript
{
    public:
        cond_burn_mantid_corpse() : ConditionScript("cond_burn_mantid_corpse") { }

        bool OnConditionCheck(const Condition* cond, ConditionSourceInfo& source) override
        {
            Player* player = source.mConditionTargets[0]->ToPlayer();
            if (!player)
                return false;

            Unit* unit = ObjectAccessor::GetUnit(*player, player->GetTarget());
            if (!unit)
                return false;

            if (unit->GetEntry() != 62128)
                return false;

            if (unit->IsAlive())
                return false;

            if (unit->HasAura(122523))
                return false;

            return true;
        }
};

enum LonTheBull
{
    SAY_LONBULL_AGGRO       = 0,

    EVENT_BELLOWING_RAGE    = 1,
    EVENT_EMPOWERING_FLAMES = 2,
    EVENT_HOOF_STOMP        = 3,
    EVENT_RUSHING_CHARGE    = 4,

    SPELL_BELLOWING_RAGE    = 124297,
    SPELL_EMPOWERING_FLAMES = 130388,
    SPELL_HOOF_STOMP        = 124289,
    SPELL_RUSHING_CHARGE    = 124302,
};

// Lon the Bull - 50333
struct npc_lon_the_bull : public ScriptedAI
{
    npc_lon_the_bull(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        Talk(SAY_LONBULL_AGGRO);

        events.ScheduleEvent(EVENT_BELLOWING_RAGE, 20000);
        events.ScheduleEvent(EVENT_EMPOWERING_FLAMES, 15000);
        events.ScheduleEvent(EVENT_HOOF_STOMP, 10000);
        events.ScheduleEvent(EVENT_RUSHING_CHARGE, 10000);
    }

    void JustSummoned(Creature* summon) override
    {
        summon->DespawnOrUnsummon(12000);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_BELLOWING_RAGE:
                    DoCastVictim(SPELL_BELLOWING_RAGE, false);
                    events.ScheduleEvent(EVENT_BELLOWING_RAGE, 30000);
                    break;
                case EVENT_EMPOWERING_FLAMES:
                    DoCastVictim(SPELL_EMPOWERING_FLAMES, false);
                    events.ScheduleEvent(EVENT_EMPOWERING_FLAMES, 15000);
                    break;
                case EVENT_HOOF_STOMP:
                    DoCastVictim(SPELL_HOOF_STOMP, false);
                    events.ScheduleEvent(EVENT_HOOF_STOMP, 15000);
                    break;
                case EVENT_RUSHING_CHARGE:
                    DoCastVictim(SPELL_RUSHING_CHARGE, false);
                    events.ScheduleEvent(EVENT_RUSHING_CHARGE, 10000);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

enum Norlaxx
{
    SAY_NORLAXX_AGGRO = 0,

    EVENT_SHADOWBOLT  = 1,
    EVENT_VOIDCLOUD   = 2,

    SPELL_SHADOWBOLT  = 125212,
    SPELL_VOIDCLOUD   = 125241,
};

// Norlaxx - 50344
struct npc_norlaxx : public ScriptedAI
{
    npc_norlaxx(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        Talk(SAY_NORLAXX_AGGRO);

        events.ScheduleEvent(EVENT_SHADOWBOLT, 5000);
        events.ScheduleEvent(EVENT_VOIDCLOUD, 15000);
    };

    void JustSummoned(Creature* summon) override
    {
        summon->DespawnOrUnsummon(12000);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_SHADOWBOLT:
                    DoCastVictim(SPELL_SHADOWBOLT);
                    events.ScheduleEvent(EVENT_SHADOWBOLT, 5000);
                    break;
                case EVENT_VOIDCLOUD:
                    DoCastVictim(SPELL_VOIDCLOUD);
                    events.ScheduleEvent(EVENT_VOIDCLOUD, 15000);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

enum SilitrissSharpener
{
    SAY_SILTRISS_AGGRO   = 0,

    EVENT_GRAPPLING_HOOK = 1,
    EVENT_VANISH         = 2,
    EVENT_SMOKED_BLADE   = 3,
    EVENT_VICIOUS_REND   = 4,

    SPELL_GRAPPLING_HOOK = 125623,
    SPELL_VANISH         = 125632,
    SPELL_SMOKED_BLADE   = 125633,
    SPELL_VICIOUS_REND   = 125624,
};

// Siltriss the Sharpener - 50791
struct npc_siltriss_sharpener : public ScriptedAI
{
    npc_siltriss_sharpener(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();

        events.ScheduleEvent(EVENT_GRAPPLING_HOOK, 17000);
        events.ScheduleEvent(EVENT_VANISH, 12000);
        events.ScheduleEvent(EVENT_VICIOUS_REND, 7000);
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        Talk(SAY_SILTRISS_AGGRO);
    };

    void JustSummoned(Creature* summon) override
    {
        summon->DespawnOrUnsummon(12000);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_GRAPPLING_HOOK:
                    DoCastVictim(SPELL_GRAPPLING_HOOK);
                    events.ScheduleEvent(EVENT_GRAPPLING_HOOK, 5000);
                    break;
                case EVENT_VANISH:
                    DoCastVictim(SPELL_VANISH);
                    events.ScheduleEvent(EVENT_VANISH, 30000);
                    events.ScheduleEvent(EVENT_SMOKED_BLADE, urand(0, 8000));
                    break;
                case EVENT_SMOKED_BLADE:
                    DoCastVictim(SPELL_SMOKED_BLADE);
                    events.ScheduleEvent(EVENT_SMOKED_BLADE, 31500);
                case EVENT_VICIOUS_REND:
                    DoCastVictim(SPELL_VICIOUS_REND);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

enum YulWildpaw
{
    SAY_YUL_AGGRO             = 0,

    EVENT_CHI_BURST           = 1,
    EVENT_HEALING_MIST        = 2,
    EVENT_SPINNING_CRANE_KICK = 3,

    SPELL_CHI_BURST           = 125817,
    SPELL_HEALING_MIST        = 125802,
    SPELL_SPINNING_CRANE_KICK = 125799,
};

// Yul Wildpaw - 50820
struct npc_yul_wildpaw : public ScriptedAI
{
    npc_yul_wildpaw(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
    }
    void JustEngagedWith(Unit* /*who*/) override
    {
        Talk(SAY_YUL_AGGRO);

        events.ScheduleEvent(EVENT_CHI_BURST, 10000);
        events.ScheduleEvent(EVENT_HEALING_MIST, 15000);
        events.ScheduleEvent(EVENT_SPINNING_CRANE_KICK, 5000);
    };

    void JustSummoned(Creature* summon) override
    {
        summon->DespawnOrUnsummon(12000);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_CHI_BURST:
                    DoCastVictim(SPELL_CHI_BURST);
                    events.ScheduleEvent(EVENT_CHI_BURST, 5000);
                    break;
                case EVENT_HEALING_MIST:
                    DoCastVictim(SPELL_HEALING_MIST);
                    events.ScheduleEvent(EVENT_HEALING_MIST, 35000);
                    break;
                case EVENT_SPINNING_CRANE_KICK:
                    DoCastVictim(SPELL_SPINNING_CRANE_KICK);
                    events.ScheduleEvent(EVENT_SPINNING_CRANE_KICK, 15000);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// Shado-Pan Spike Trap Eff 119391
class spell_townlong_shado_pan_spike_trap_eff : public SpellScript
{
    PrepareSpellScript(spell_townlong_shado_pan_spike_trap_eff);

    void HandleEffectHitTarget(SpellEffIndex eff_idx)
    {
        if (Player* target = GetHitPlayer())
            PreventHitDamage();
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_townlong_shado_pan_spike_trap_eff::HandleEffectHitTarget, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

void AddSC_townlong_steppes()
{
    // Rare mobs
    new npc_lith_ik();
    new npc_eshelon();
    new creature_script<npc_lon_the_bull>("npc_lon_the_bull");
    new creature_script<npc_norlaxx>("npc_norlaxx");
    new creature_script<npc_siltriss_sharpener>("npc_siltriss_sharpener");
    new creature_script<npc_yul_wildpaw>("npc_yul_wildpaw");
    // Elite mobs
    new npc_darkwoods_faerie();
    new npc_hei_feng();
    // Standard Mobs
    new creature_script<npc_seething_flashripper>("npc_seething_flashripper");
    new creature_script<npc_korthik_timberhusk>("npc_korthik_timberhusk");
    new creature_script<npc_rankbite_ancient>("npc_rankbite_ancient");
    new creature_script<npc_deadtalker_crusher>("npc_deadtalker_crusher");
    new creature_script<npc_longshadow_mushan>("npc_longshadow_mushan");
    new creature_script<npc_seething_hatred>("npc_seething_hatred");
    new creature_script<npc_gnathus>("npc_gnathus");
    // Quests
    new go_arconiss_peat_mound();
    new go_sikthik_cage();
    new creature_script<npc_injured_gao_ran_blackguard>("npc_injured_gao_ran_blackguard");
    new npc_yalia_what_lies_beneath();
    new npc_what_lies_beneath_totem();
    new creature_script<npc_what_lies_beneath_sha>("npc_what_lies_beneath_sha");
    new creature_script<npc_jahesh_mists_opportunity>("npc_jahesh_mists_opportunity");
    new creature_script<npc_crazed_shado_pan_ranger>("npc_crazed_shado_pan_ranger");
    new creature_script<npc_totem_of_harmony_30783>("npc_totem_of_harmony_30783");
    new creature_script<npc_hatred_becomes_us_sha>("npc_hatred_becomes_us_sha");
    new spell_item_cintron_infused_bandage();
    new spell_item_shado_pan_torch();
    new go_drywood_cage();
    new npc_longying_ranger();
    new creature_script<npc_longying_ranger_helper>("npc_longying_ranger_helper");
    new npc_lin_silentstrike();
    new creature_script<npc_suna_ranger_rescue_scene>("npc_suna_ranger_rescue_scene");
    new npc_osul_mist_shaman();
    new spell_script<spell_gather_steam>("spell_gather_steam");
    new npc_suna_silentstrike();
    new npc_wounded_niuzao_sentinel();
    new creature_script<npc_tai_ho_motives>("npc_tai_ho_motives");
    new player_motives_of_the_mantid();
    new creature_script<npc_townlong_gunpowder_cask>("npc_townlong_gunpowder_cask");
    new spell_script<spell_q30959>("spell_q30959");
    new aura_script<spell_protective_shell>("spell_protective_shell");
    new cond_burn_mantid_corpse();
    new spell_script<spell_townlong_shado_pan_spike_trap_eff>("spell_townlong_shado_pan_spike_trap_eff");
}
