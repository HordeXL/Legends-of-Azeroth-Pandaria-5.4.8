/*
 * Quest 29918 "A Test of Valor" (Valley of the Four Winds) - Custom AI for the Giant White Plainshawk
 *
 * Mechanism (kill-to-credit version, implemented in C++ to bypass SmartAI limitations):
 *   1. Player uses Rancher's Lariat (spell 105355, CONTROL_VEHICLE aura) -> player rides the hawk.
 *   2. Hawk dives straight down to the terrain below its current position.
 *   3. On landing (z within 8yd of terrain): passenger is ejected on the ground (zero fall damage),
 *      gravity is disabled-lock (hawk stays grounded), then the hawk engages the nearest non-GM player.
 *   4. Standard kill credit: killing the hawk counts via the normal KillRewarder path.
 *   5. On evade: hawk un-grounds, flies back to its original air home, fully reusable.
 *
 * Notes:
 *   - Random-fly is NOT started by this AI, so the hawk only moves when we tell it to.
 *   - SelectNearestPlayerNotGM is used, so GM-mode testers are never targeted.
 *   - Landing is verified by a periodic position check, immune to dive interruption (aggro mid-air).
 */

#include "ScriptPCH.h"

enum PlainshawkData
{
    NPC_GIANT_PLAINSHAWK      = 56171,
    SPELL_LASSO_GRAB          = 105355, // Rancher's Lariat, applies CONTROL_VEHICLE aura to the hawk
    SPELL_PLAINSHAWK_STRIKE   = 105373, // official combat ability 1 (was SAI entry-level row)
    SPELL_PLAINSHAWK_SHRIEK   = 105374, // official combat ability 2 (was SAI entry-level row)
    POINT_GROUND              = 1,      // dive landing point id
};

class npc_giant_plainshawk_29918 : public CreatureScript
{
public:
    npc_giant_plainshawk_29918() : CreatureScript("npc_giant_plainshawk_29918") { }

    struct npc_giant_plainshawk_29918AI : public CreatureAI
    {
        npc_giant_plainshawk_29918AI(Creature* creature) : CreatureAI(creature),
            _lassoed(false), _grounded(false),
            _landingCheckTimer(0), _engageTimer(0), _strikeTimer(0), _shriekTimer(0)
        {
            _homePos = me->GetHomePosition();
        }

        void Reset() override
        {
            _lassoed = false;
            _grounded = false;
            _landingCheckTimer = 0;
            _engageTimer = 0;
            _strikeTimer = 0;
            _shriekTimer = 0;
            me->SetDisableGravity(false);
            me->SetReactState(REACT_AGGRESSIVE);
            _homePos = me->GetHomePosition();
        }

        void SpellHit(Unit* /*caster*/, SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_LASSO_GRAB)
                return;

            if (_grounded)
            {
                // already on the ground: just engage immediately
                if (!me->IsInCombat())
                    if (Player* target = me->SelectNearestPlayerNotGM(100.0f))
                        AttackStart(target);
                return;
            }

            if (_lassoed || me->IsInCombat())
                return;

            // player just grabbed the hawk with the lasso -> dive to the ground below
            _lassoed = true;
            _landingCheckTimer = 500;
            StartDive();
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (type == POINT_MOTION_TYPE && id == POINT_GROUND)
                Land();
        }

        void AttackStart(Unit* victim) override
        {
            if (!victim || !me->Attack(victim, true))
                return;

            me->GetMotionMaster()->MoveChase(victim);
        }

        void EnterEvadeMode(EvadeReason /*why*/) override
        {
            // restore natural state: un-ground, fly back to the original air home
            _lassoed = false;
            _grounded = false;
            me->SetDisableGravity(false);
            me->SetHomePosition(_homePos);
            CreatureAI::EnterEvadeMode();
        }

        void UpdateAI(uint32 diff) override
        {
            // ---- dive / landing control (independent of combat state) ----
            if (_lassoed && !_grounded)
            {
                if (_landingCheckTimer <= diff)
                {
                    _landingCheckTimer = 500;
                    float groundZ = me->GetMap()->GetHeight(me->GetPhaseMask(),
                        me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), true, 300.0f);
                    if (groundZ > 0.0f && (me->GetPositionZ() - groundZ) <= 8.0f)
                        Land();
                    else if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != POINT_MOTION_TYPE)
                        StartDive(); // dive was interrupted (e.g. aggro mid-air), re-issue
                }
                else
                    _landingCheckTimer -= diff;
            }

            // ---- grounded but not yet in combat: look for the lassoer's target ----
            if (_grounded && !me->IsInCombat())
            {
                if (_engageTimer <= diff)
                {
                    _engageTimer = 1000;
                    if (Player* target = me->SelectNearestPlayerNotGM(100.0f))
                        AttackStart(target);
                }
                else
                    _engageTimer -= diff;
            }

            if (!UpdateVictim())
                return;

            if (_strikeTimer <= diff)
            {
                DoCastVictim(SPELL_PLAINSHAWK_STRIKE);
                _strikeTimer = urand(6000, 9000);
            }
            else
                _strikeTimer -= diff;

            if (_shriekTimer <= diff)
            {
                DoCastVictim(SPELL_PLAINSHAWK_SHRIEK);
                _shriekTimer = urand(11000, 16000);
            }
            else
                _shriekTimer -= diff;

            DoMeleeAttackIfReady();
        }

    private:
        void StartDive()
        {
            float x = me->GetPositionX();
            float y = me->GetPositionY();
            float groundZ = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, me->GetPositionZ(), true, 300.0f);
            if (groundZ <= 0.0f || groundZ >= me->GetPositionZ())
                groundZ = me->GetPositionZ() - 10.0f; // vmap hole fallback, landing check will refine
            me->GetMotionMaster()->MovePoint(POINT_GROUND, x, y, groundZ);
        }

        void Land()
        {
            _grounded = true;
            me->SetDisableGravity(true);                  // grounded lock: hawk can no longer drift upward
            me->SetHomePosition(me->GetPosition());       // defensive: home = landing spot
            me->GetMotionMaster()->Clear(false);
            me->GetMotionMaster()->MoveIdle();
            me->RemoveAurasDueToSpell(SPELL_LASSO_GRAB);  // eject passenger at ground level (zero fall damage)
            _engageTimer = 800;                           // let the player settle before combat starts
        }

        bool _lassoed;
        bool _grounded;
        uint32 _landingCheckTimer;
        uint32 _engageTimer;
        uint32 _strikeTimer;
        uint32 _shriekTimer;
        Position _homePos;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_giant_plainshawk_29918AI(creature);
    }
};

void AddSC_npc_giant_plainshawk_29918()
{
    new npc_giant_plainshawk_29918();
}
