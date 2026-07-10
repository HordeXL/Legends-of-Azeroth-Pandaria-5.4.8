/*
 * Classic Scarlet Monastery (map 189): Herod and Scarlet Trainees.
 * Restored from TrinityCore's 5.4.8-era implementation.  This project uses
 * its instance_scarlet_monastery script for MoP map 1004, so the classic
 * Herod encounter intentionally uses ScriptedAI instead of that BossAI.
 */

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedEscortAI.h"

enum HerodTexts
{
    SAY_AGGRO = 0,
    SAY_WHIRLWIND = 1,
    SAY_ENRAGE = 2,
    SAY_KILL = 3,
    EMOTE_ENRAGE = 4
};

enum HerodSpells
{
    SPELL_RUSHING_CHARGE = 8260,
    SPELL_CLEAVE = 15496,
    SPELL_WHIRLWIND = 8989,
    SPELL_FRENZY = 8269
};

enum HerodEvents
{
    EVENT_CLEAVE = 1,
    EVENT_WHIRLWIND
};

uint32 const NPC_SCARLET_TRAINEE = 6575;
Position const ScarletTraineeSpawn = { 1939.18f, -431.58f, 17.09f, 6.22f };

class boss_herod : public CreatureScript
{
public:
    boss_herod() : CreatureScript("boss_herod") { }

    struct boss_herodAI : public ScriptedAI
    {
        boss_herodAI(Creature* creature) : ScriptedAI(creature), _enraged(false) { }

        void Reset() override
        {
            events.Reset();
            _enraged = false;
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            Talk(SAY_AGGRO);
            DoCast(me, SPELL_RUSHING_CHARGE);
            events.ScheduleEvent(EVENT_CLEAVE, 12000);
            events.ScheduleEvent(EVENT_WHIRLWIND, 60000);
        }

        void KilledUnit(Unit* /*victim*/) override
        {
            Talk(SAY_KILL);
        }

        void JustDied(Unit* /*killer*/) override
        {
            for (uint8 i = 0; i < 20; ++i)
                me->SummonCreature(NPC_SCARLET_TRAINEE, ScarletTraineeSpawn, TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 600000);
        }

        void DamageTaken(Unit* /*attacker*/, uint32& damage) override
        {
            if (!_enraged && me->HealthBelowPctDamaged(30, damage))
            {
                Talk(EMOTE_ENRAGE);
                Talk(SAY_ENRAGE);
                DoCast(me, SPELL_FRENZY);
                _enraged = true;
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
                    case EVENT_CLEAVE:
                        DoCastVictim(SPELL_CLEAVE);
                        events.ScheduleEvent(EVENT_CLEAVE, 12000);
                        break;
                    case EVENT_WHIRLWIND:
                        Talk(SAY_WHIRLWIND);
                        DoCastVictim(SPELL_WHIRLWIND);
                        events.ScheduleEvent(EVENT_WHIRLWIND, 30000);
                        break;
                }
            }

            DoMeleeAttackIfReady();
        }

    private:
        EventMap events;
        bool _enraged;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new boss_herodAI(creature);
    }
};

class npc_scarlet_trainee : public CreatureScript
{
public:
    npc_scarlet_trainee() : CreatureScript("npc_scarlet_trainee") { }

    struct npc_scarlet_traineeAI : public npc_escortAI
    {
        npc_scarlet_traineeAI(Creature* creature) : npc_escortAI(creature), _startTimer(urand(1000, 6000)) { }

        void Reset() override { }
        void WaypointReached(uint32 /*waypointId*/) override { }

        void UpdateAI(uint32 diff) override
        {
            if (_startTimer)
            {
                if (_startTimer <= diff)
                {
                    Start(true, true);
                    _startTimer = 0;
                }
                else
                    _startTimer -= diff;
            }

            npc_escortAI::UpdateAI(diff);
        }

    private:
        uint32 _startTimer;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_scarlet_traineeAI(creature);
    }
};

void AddSC_boss_herod()
{
    new boss_herod();
    new npc_scarlet_trainee();
}
