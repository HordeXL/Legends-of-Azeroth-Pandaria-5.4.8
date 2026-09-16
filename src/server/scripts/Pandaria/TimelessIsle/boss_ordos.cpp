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

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
#include "ScriptMgr.h"
#include "Group.h"
#include "Log.h"
#include "timeless_isle.h"

enum Spells
{
    SPELL_ORDOS_ANCIENT_FLAME     = 144695,
    SPELL_ORDOS_BURNING_SOUL      = 144689,
    SPELL_BURNING_SOUL_EFF        = 144690,
    SPELL_ANCIENT_FLAME           = 144691,
    SPELL_ANCIENT_FLAME_EFF       = 144699,
    SPELL_ANCIENT_FLAME_SUMM      = 144695,
    SPELL_ORDOS_ETERNAL_AGONY     = 144696,
    SPELL_ORDOS_MAGMA_CRUSH       = 144688,
    SPELL_ORDOS_POOL_OF_FIRE      = 144692,
    SPELL_ORDOS_POOL_OF_FIRE_AURA = 144693,
};

enum Events
{
    EVENT_ORDOS_ANCIENT_FLAME = 1,
    EVENT_ORDOS_BURNING_SOUL,
    EVENT_ORDOS_POOL_OF_FIRE,
    EVENT_ORDOS_ETERNAL_AGONY,
    EVENT_ORDOS_MAGMA_CRUSH,
};

enum Creatures
{
    NPC_ANCIENT_FLAME = 72059,
};

enum Says
{
    SAY_ORDOS_AGGRO = 0,
    SAY_ORDOS_INTRO_1,
    SAY_ORDOS_INTRO_2,
    SAY_ORDOS_INTRO_3,
    SAY_ORDOS_DEATH,
    SAY_ORDOS_KILL,
    SAY_ORDOS_POOL_OF_FIRE,
    SAY_ORDOS_ANCIENT_FLAME,
    SAY_ORDOS_BURNING_SOUL,
    SAY_ORDOS_ETERNAL_AGONY
};

class boss_ordos : public CreatureScript
{
    public:
        boss_ordos() : CreatureScript("boss_ordos") { }

        struct boss_ordosAI : public ScriptedAI
        {
            boss_ordosAI(Creature* creature) : ScriptedAI(creature), summons(me) { }

            TaskScheduler scheduler;
            SummonList summons;
            EventMap events;

            void Reset() override
            {
                events.Reset();
                me->RemoveAllAreasTrigger();
                summons.DespawnAll();
                HandleDoor(me, GO_HEATET_DOOR, true);
                me->SetReactState(REACT_AGGRESSIVE);

                scheduler
                    .Schedule(Seconds(1), [this](TaskContext context)
                {
                    me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PACIFIED | UNIT_FLAG_NON_ATTACKABLE);
                });
            }

            void KilledUnit(Unit* victim) override
            {
                if (victim && victim->GetTypeId() == TYPEID_PLAYER)
                    Talk(SAY_ORDOS_KILL);
            }

            void JustSummoned(Creature* summon) override
            {
                summons.Summon(summon);
            }

            void JustEngagedWith(Unit* who) override
            {
                Talk(SAY_ORDOS_AGGRO);

                events.ScheduleEvent(EVENT_ORDOS_MAGMA_CRUSH, 9.5 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_ORDOS_POOL_OF_FIRE, 27 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_ORDOS_BURNING_SOUL, 20.5 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_ORDOS_ETERNAL_AGONY, 5 * MINUTE * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_ORDOS_ANCIENT_FLAME, 40 * IN_MILLISECONDS);

                if (Player* player = who->ToPlayer())
                {
                    std::function<bool(Player*)> eligibleForOrods = [this](Player* player)
                    {
                        return player->GetSession()->GetSecurity() >= SEC_GAMEMASTER || player->HasAchieved(7536) || player->HasItemCount(102245) || player->HasItemCount(102246) || player->HasItemCount(102247) || player->HasItemCount(102248) || player->HasItemCount(102249) || player->HasItemCount(102250);
                    };

                    if (Group* group = player->GetGroup())
                    {
                        for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
                            if (Player* member = itr->GetSource())
                                if (!eligibleForOrods(member))
                                    member->TeleportTo(870, -649.822f, -4891.033f, 2.05669f, 4.721636f);
                    }
                    else
                    {
                        if (!eligibleForOrods(player))
                            player->TeleportTo(870, -649.822f, -4891.033f, 2.05669f, 4.721636f);
                    }
                }

                HandleDoor(me, GO_HEATET_DOOR, false);
            }

            void EnterEvadeMode() override
            {
                ScriptedAI::EnterEvadeMode();
                summons.DespawnAll();
                events.Reset();
                me->RemoveAllAreasTrigger();
                me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PACIFIED | UNIT_FLAG_NON_ATTACKABLE);

                uint32 corpseDelay = me->GetCorpseDelay();
                uint32 respawnDelay = me->GetRespawnDelay();

                me->SetCorpseDelay(1);
                me->SetRespawnDelay(29);

                me->DespawnOrUnsummon();

                me->SetCorpseDelay(corpseDelay);
                me->SetRespawnDelay(respawnDelay);

                HandleDoor(me, GO_HEATET_DOOR, true);
            }

            void JustDied(Unit* /*killer*/) override
            {
                Talk(SAY_ORDOS_DEATH);
                me->RemoveAllAreasTrigger();
                summons.DespawnAll();
                HandleDoor(me, GO_HEATET_DOOR, true);
            }

            void UpdateAI(uint32 diff) override
            {
                scheduler.Update(diff);

                if (!UpdateVictim())
                    return;

                events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                switch (events.ExecuteEvent())
                {
                    case EVENT_ORDOS_MAGMA_CRUSH:
                    {
                        if (Unit* target = me->GetVictim())
                        {
                            if (target->GetTypeId() == TYPEID_PLAYER)
                                DoCast(target, SPELL_ORDOS_MAGMA_CRUSH);
                            else if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, [=](Unit const* conditionTarget) { return conditionTarget && conditionTarget->GetTypeId() == TYPEID_PLAYER && conditionTarget->GetExactDist2d(me) <= 10.0f; }))
                                DoCast(target, SPELL_ORDOS_MAGMA_CRUSH);
                        }

                        events.ScheduleEvent(EVENT_ORDOS_MAGMA_CRUSH, 15 * IN_MILLISECONDS);
                        break;
                    }
                    case EVENT_ORDOS_ANCIENT_FLAME:
                    {
                        DoCast(me, SPELL_ORDOS_ANCIENT_FLAME);
                        Talk(SAY_ORDOS_ANCIENT_FLAME);
                        events.ScheduleEvent(EVENT_ORDOS_ANCIENT_FLAME, 42 * IN_MILLISECONDS);
                        break;
                    }
                    case EVENT_ORDOS_BURNING_SOUL:
                    {
                        DoCast(me, SPELL_ORDOS_BURNING_SOUL);
                        Talk(SAY_ORDOS_BURNING_SOUL);
                        events.ScheduleEvent(EVENT_ORDOS_BURNING_SOUL, 29 * IN_MILLISECONDS);
                        break;
                    }
                    case EVENT_ORDOS_ETERNAL_AGONY:
                    {
                        DoCast(SPELL_ORDOS_ETERNAL_AGONY);
                        Talk(SAY_ORDOS_ETERNAL_AGONY);
                        break;
                    }
                    case EVENT_ORDOS_POOL_OF_FIRE:
                    {
                        if (Unit* target = me->GetVictim())
                        {
                            TC_LOG_INFO("server",
                                "Ordos Pool of Fire target=%s/%u position=(%.2f,%.2f,%.2f)",
                                target->GetName().c_str(),
                                target->GetGUID().GetCounter(),
                                target->GetPositionX(), target->GetPositionY(),
                                target->GetPositionZ());
                            me->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), SPELL_ORDOS_POOL_OF_FIRE, false);
                        }

                        Talk(SAY_ORDOS_POOL_OF_FIRE);
                        events.ScheduleEvent(EVENT_ORDOS_POOL_OF_FIRE, 31 * IN_MILLISECONDS);
                        break;
                    }
                    default:
                        break;
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new boss_ordosAI(creature);
        }
};

// Ancient Flame 72059
struct npc_ordos_ancient_flame : public ScriptedAI
{
    npc_ordos_ancient_flame(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        DoCast(me, SPELL_ANCIENT_FLAME);
    }

    void EnterEvadeMode() override { }
};

// Magma Crush - 144688
class spell_ordos_magma_crush : public SpellScript
{
    PrepareSpellScript(spell_ordos_magma_crush);

    bool Load() override
    {
        targetsCount = 1;
        return true;
    }

    void CountTargets(std::list<WorldObject*>& targets)
    {
        targetsCount = targets.size();
    }

    void SplitDamage(SpellEffIndex /*eff*/)
    {
        if (targetsCount > 1)
            SetHitDamage(int32(GetHitDamage() / targetsCount));
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ordos_magma_crush::CountTargets, EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
        OnEffectHitTarget += SpellEffectFn(spell_ordos_magma_crush::SplitDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }

    private:
        uint8 targetsCount;
};

// Burning Soul 144689
class spell_ordos_burning_soul : public AuraScript
{
    PrepareAuraScript(spell_ordos_burning_soul);

    void SendPlayerWarning(uint8 seconds)
    {
        Player* player = GetOwner()->ToPlayer();
        if (!player || !player->GetSession() || player->GetSession()->IsBot() ||
            lastWarningSecond == seconds)
            return;

        if (seconds == 1)
            player->GetSession()->SendNotification(
                "BURNING SOUL - RUN OUT OF THE RAID! 1 second");
        else
            player->GetSession()->SendNotification(
                "BURNING SOUL - RUN OUT OF THE RAID! %u seconds", seconds);

        // Interface\\RaidWarning.wav. Send it only to the affected human.
        player->PlayDirectSound(8959, player);
        lastWarningSecond = seconds;
    }

    bool IsOtherAffectedHuman(Player* candidate, Player* player) const
    {
        return candidate && candidate != player && candidate->IsAlive() &&
            candidate->GetSession() && !candidate->GetSession()->IsBot() &&
            candidate->HasAura(SPELL_ORDOS_BURNING_SOUL);
    }

    void EnsurePlayerMarker()
    {
        Player* player = GetOwner()->ToPlayer();
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;
        Group* group = player->GetGroup();
        if (!group)
            return;

        uint8 const crossIcon = 6;

        // Reuse this aura's assigned marker whenever possible. Role marker
        // automation may replace it between ticks; SetTargetIcon removes the
        // stale marker from this player while restoring the mechanic marker.
        if (burningSoulMarker < TARGETICONCOUNT)
        {
            if (group->GetTargetIcon(burningSoulMarker) == player->GetGUID())
                return;

            ObjectGuid const assignedTarget =
                group->GetTargetIcon(burningSoulMarker);
            Player* assignedPlayer = assignedTarget ?
                ObjectAccessor::FindPlayer(assignedTarget) : nullptr;
            if (!IsOtherAffectedHuman(assignedPlayer, player))
            {
                group->SetTargetIcon(burningSoulMarker, player->GetGUID(),
                    player->GetGUID(), 0);
                return;
            }
        }

        // Burning Soul can select several players at once. Reserve the red
        // cross for the first affected real player even if role automation
        // temporarily placed it on a bot; additional humans receive another
        // free icon.
        ObjectGuid const crossTarget = group->GetTargetIcon(crossIcon);
        Player* crossPlayer = crossTarget ?
            ObjectAccessor::FindPlayer(crossTarget) : nullptr;
        if (!IsOtherAffectedHuman(crossPlayer, player))
        {
            group->SetTargetIcon(crossIcon, player->GetGUID(),
                player->GetGUID(), 0);
            burningSoulMarker = crossIcon;
            return;
        }

        static uint8 const preferredIcons[TARGETICONCOUNT - 1] =
            { 0, 1, 2, 3, 4, 5, 7 };
        for (uint8 icon : preferredIcons)
        {
            ObjectGuid const iconTarget = group->GetTargetIcon(icon);
            Player* iconPlayer = iconTarget ?
                ObjectAccessor::FindPlayer(iconTarget) : nullptr;
            if (IsOtherAffectedHuman(iconPlayer, player))
                continue;

            group->SetTargetIcon(icon, player->GetGUID(),
                player->GetGUID(), 0);
            burningSoulMarker = icon;
            break;
        }
    }

    void HandleOnApply(AuraEffect const* /*aureff*/,
        AuraEffectHandleModes /*mode*/)
    {
        EnsurePlayerMarker();
        SendPlayerWarning(10);
    }

    void HandlePeriodic(AuraEffect const* aureff)
    {
        // Other bot/role systems can rewrite raid icons after aura apply.
        // Reassert the warning every damage tick so a real player keeps a
        // visible mechanic marker for the complete debuff.
        EnsurePlayerMarker();

        int32 const duration = aureff->GetBase()->GetDuration();
        uint8 const remaining = uint8(std::max<int32>(1,
            (duration + IN_MILLISECONDS - 1) / IN_MILLISECONDS));
        if (remaining == 5 || remaining == 3 || remaining == 2 ||
            remaining == 1)
            SendPlayerWarning(remaining);
    }

    void HandleOnRemove(AuraEffect const* /*aureff*/, AuraEffectHandleModes /*mode*/)
    {
        if (Unit* owner = GetOwner()->ToUnit())
        {
            if (burningSoulMarker < TARGETICONCOUNT)
                if (Player* player = owner->ToPlayer())
                    if (Group* group = player->GetGroup())
                        if (group->GetTargetIcon(burningSoulMarker) ==
                                player->GetGUID())
                            group->SetTargetIcon(burningSoulMarker,
                                player->GetGUID(), ObjectGuid::Empty, 0);

            owner->CastSpell(owner, SPELL_BURNING_SOUL_EFF, true);
        }
    }

    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_ordos_burning_soul::HandleOnApply, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_ordos_burning_soul::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        OnEffectRemove += AuraEffectRemoveFn(spell_ordos_burning_soul::HandleOnRemove, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
    }

private:
    uint8 burningSoulMarker = TARGETICONCOUNT;
    uint8 lastWarningSecond = 0;
};

// 1090 - Pool of Fire
class sat_ordos_pool_of_fire : public IAreaTriggerAura
{
    bool CheckTriggering(WorldObject* triggering)
    {
        return triggering && triggering->ToPlayer() && triggering->ToPlayer()->IsAlive() && m_caster->IsValidAttackTarget(triggering->ToPlayer(), m_spellInfo, m_target);
    }

    void OnTriggeringApply(WorldObject* triggering)
    {
        m_caster->AddAura(SPELL_ORDOS_POOL_OF_FIRE_AURA, triggering->ToUnit());
    }

    void OnTriggeringRemove(WorldObject* triggering)
    {
        triggering->ToUnit()->RemoveAura(SPELL_ORDOS_POOL_OF_FIRE_AURA, m_caster->GetGUID());
    }
};

void AddSC_boss_ordos()
{
    new boss_ordos();
    new creature_script<npc_ordos_ancient_flame>("npc_ordos_ancient_flame");

    new spell_script<spell_ordos_magma_crush>("spell_ordos_magma_crush");
    new aura_script<spell_ordos_burning_soul>("spell_ordos_burning_soul");
    new atrigger_script<sat_ordos_pool_of_fire>("sat_ordos_pool_of_fire");
}
