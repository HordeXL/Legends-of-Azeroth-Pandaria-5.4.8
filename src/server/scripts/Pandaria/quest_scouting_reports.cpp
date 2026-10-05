#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Player.h"
#include "ObjectAccessor.h"
#include "Vehicle.h"
#include "Map.h"
#include "GameObject.h"

namespace ScoutingReports
{
    uint32 const HostileNatives = 29730;
    uint32 const FriendOfMyEnemy = 29823;
    uint32 const JinyuInABarrel = 29824;
    uint32 const PrivateReportPhase = 65536;
    uint32 const OriginalPhaseData = 1;

    bool UsesPrivatePhase(uint32 quest)
    {
        return quest == HostileNatives || quest == FriendOfMyEnemy || quest == JinyuInABarrel;
    }

    struct Report
    {
        uint32 quest;
        uint32 actor;
        uint32 giver;
        Position start;
        Position home;
        char const* option;
    };

    // Gorrok starts eight yards west of the warning sign, outside its collision.
    // Other positions are taken from existing spawns on this server.
    Report const Reports[] =
    {
        { 29730, 55671, 55648, {1456.87f,-1341.66f,247.242f,0.0f},
            {1444.61f,-545.21f,353.218f,0.0f}, "Go on, Riko. Tell me about Gorrok." },
        { 29823, 55686, 55648, {352.178f,-2027.27f,58.7399f,1.5f},
            {1444.61f,-545.21f,353.218f,0.0f}, "Go on, Riko. Tell me how you helped Kiryn." },
        { 29824, 55702, 55647, {-124.97f,-2931.21f,23.5433f,0.0f},
            {1447.21f,-547.82f,352.815f,0.0f}, "Let's hear the rest of your report, Shokia." }
    };

    Report const* Find(uint32 quest)
    {
        for (auto const& report : Reports)
            if (report.quest == quest)
                return &report;
        return nullptr;
    }

    Player* Pilot(Unit* actor)
    {
        if (!actor || !actor->GetVehicleKit())
            return nullptr;
        Unit* passenger = actor->GetVehicleKit()->GetPassenger(1);
        return passenger ? passenger->ToPlayer() : nullptr;
    }

    bool Playing(Player* player, uint32 quest, uint32 actor)
    {
        Unit* base = player->GetVehicleBase();
        return player->GetQuestStatus(quest) == QUEST_STATUS_INCOMPLETE && base &&
            base->GetEntry() == actor && Pilot(base) == player;
    }

    void Board(ObjectGuid guid, uint32 quest, uint32 originalPhaseMask, uint32 attempt = 0)
    {
        Player* player = ObjectAccessor::FindPlayer(guid);
        Report const* report = Find(quest);
        if (!player || !report || !player->IsAlive() || player->GetVehicle() ||
            player->GetQuestStatus(quest) != QUEST_STATUS_INCOMPLETE)
        {
            if (player && player->GetPhaseMask() == PrivateReportPhase)
                player->SetPhaseMask(originalPhaseMask, true);
            return;
        }
        if (player->IsBeingTeleported())
        {
            if (attempt < 20)
                player->m_Events.Schedule(500, [guid, quest, originalPhaseMask, attempt]()
                    { Board(guid, quest, originalPhaseMask, attempt + 1); });
            else if (player->GetPhaseMask() == PrivateReportPhase)
                player->SetPhaseMask(originalPhaseMask, true);
            return;
        }
        if (player->GetMapId() != 870 || player->GetDistance(report->start) > 15.0f)
        {
            if (player->GetPhaseMask() == PrivateReportPhase)
                player->SetPhaseMask(originalPhaseMask, true);
            return;
        }
        auto returnHome = [player, report]()
        {
            Position const& home = report->home;
            player->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(), home.GetOrientation());
        };
        if (TempSummon* actor = player->SummonCreature(report->actor, player->GetPosition(),
            TEMPSUMMON_TIMED_DESPAWN, 15 * MINUTE * IN_MILLISECONDS, 238, guid))
        {
            actor->AI()->SetData(OriginalPhaseData, originalPhaseMask);
            player->UpdateVisibilityOf(actor);
            if (!actor->GetVehicleKit() || !player->HaveAtClient(actor))
            {
                actor->DespawnOrUnsummon();
                player->SetPhaseMask(originalPhaseMask, false);
                returnHome();
                return;
            }
            player->EnterVehicle(actor, 1);
            if (player->GetVehicleBase() != actor)
            {
                actor->DespawnOrUnsummon();
                player->SetPhaseMask(originalPhaseMask, false);
                returnHome();
            }
        }
        else
        {
            player->SetPhaseMask(originalPhaseMask, false);
            returnHome();
        }
    }

    void Begin(Player* player, uint32 quest)
    {
        Report const* report = Find(quest);
        if (!report || !player->IsAlive() || player->IsInCombat() || player->GetVehicle() ||
            player->IsBeingTeleported() || player->GetQuestStatus(quest) != QUEST_STATUS_INCOMPLETE)
            return;
        player->Dismount();
        uint32 originalPhaseMask = player->GetPhaseMask() == PrivateReportPhase
            ? PHASEMASK_NORMAL : player->GetPhaseMask();
        // TeleportTo performs the visibility rebuild. Scheduling one here as
        // well races grid loading and can insert the same object twice.
        player->SetPhaseMask(PrivateReportPhase, false);
        Position pos = report->start;
        if (quest == 29730 && player->GetMapId() == 870)
        {
            float ground = player->GetMap()->GetHeight(pos.GetPositionX(), pos.GetPositionY(),
                pos.GetPositionZ() + 5.0f, true, 20.0f);
            if (ground > INVALID_HEIGHT)
                pos.m_positionZ = ground + 0.1f;
        }
        if (player->TeleportTo(870, pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), pos.GetOrientation()))
        {
            ObjectGuid guid = player->GetGUID();
            player->m_Events.Schedule(500, [guid, quest, originalPhaseMask]()
                { Board(guid, quest, originalPhaseMask); });
        }
        else
            player->SetPhaseMask(originalPhaseMask, true);
    }

    void Recover(ObjectGuid guid, uint32 attempt = 0)
    {
        Player* player = ObjectAccessor::FindPlayer(guid);
        if (!player || !player->IsAlive() || player->GetVehicle())
            return;
        if (player->IsBeingTeleported())
        {
            if (attempt < 20)
                player->m_Events.Schedule(500, [guid, attempt]() { Recover(guid, attempt + 1); });
            return;
        }
        if (player->GetMapId() != 870)
            return;
        // A disconnect during the private Riko scene must not leave the player
        // stranded in its otherwise empty visibility phase.
        if (player->GetPhaseMask() == PrivateReportPhase)
            player->SetPhaseMask(PHASEMASK_NORMAL, false);
        for (auto const& report : Reports)
        {
            QuestStatus status = player->GetQuestStatus(report.quest);
            if ((status == QUEST_STATUS_INCOMPLETE || status == QUEST_STATUS_COMPLETE) &&
                player->GetDistance(report.start) < 250.0f)
            {
                Position const& home = report.home;
                player->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(), home.GetOrientation());
                return;
            }
        }
        // Kiryn's report uses its existing separate actor implementation.
        QuestStatus status = player->GetQuestStatus(29731);
        if ((status == QUEST_STATUS_INCOMPLETE || status == QUEST_STATUS_COMPLETE) &&
            player->GetDistance(Position{761.766f,-1633.19f,58.359f,0.0f}) < 250.0f)
            player->NearTeleportTo(1443.3f,-548.747f,352.87f,0.0f);
    }
}

class player_jade_forest_report_recovery : public PlayerScript
{
public:
    player_jade_forest_report_recovery() : PlayerScript("player_jade_forest_report_recovery") { }
    void OnLogin(Player* player) override
    {
        ObjectGuid guid = player->GetGUID();
        player->m_Events.Schedule(500, [guid]() { ScoutingReports::Recover(guid); });
    }
};

class npc_jade_forest_scouting_report : public CreatureScript
{
public:
    npc_jade_forest_scouting_report() : CreatureScript("npc_jade_forest_scouting_report") { }

    struct ReportGiverAI : public ScriptedAI
    {
        ReportGiverAI(Creature* creature) : ScriptedAI(creature) { }
        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
            me->CombatStop(true);
        }
        void OnQuestAccept(Player* player, Quest const* quest) override
        {
            if (auto report = ScoutingReports::Find(quest->GetQuestId()))
                if (report->giver == me->GetEntry())
                    ScoutingReports::Begin(player, report->quest);
        }
        void AttackStart(Unit*) override { }
        void UpdateAI(uint32) override { }
    };

    CreatureAI* GetAI(Creature* creature) const override { return new ReportGiverAI(creature); }

    bool OnQuestAccept(Player* player, Creature* creature, Quest const* quest) override
    {
        if (auto report = ScoutingReports::Find(quest->GetQuestId()))
            if (report->giver == creature->GetEntry())
                ScoutingReports::Begin(player, report->quest);
        return true;
    }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PrepareQuestMenu(creature->GetGUID());
        for (auto const& report : ScoutingReports::Reports)
            if (report.giver == creature->GetEntry() && player->GetQuestStatus(report.quest) == QUEST_STATUS_INCOMPLETE)
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, report.option, GOSSIP_SENDER_MAIN, report.quest);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        player->CLOSE_GOSSIP_MENU();
        auto report = ScoutingReports::Find(action);
        if (sender == GOSSIP_SENDER_MAIN && report && report->giver == creature->GetEntry() &&
            player->IsWithinDistInMap(creature, INTERACTION_DISTANCE))
            ScoutingReports::Begin(player, action);
        return true;
    }
};

struct npc_jade_forest_scouting_actor : public ScriptedAI
{
    npc_jade_forest_scouting_actor(Creature* creature) : ScriptedAI(creature), summons(creature)
    {
        for (auto const& value : ScoutingReports::Reports)
            if (value.actor == me->GetEntry())
                report = &value;
    }

    ScoutingReports::Report const* report = nullptr;
    SummonList summons;
    std::set<ObjectGuid> targets;
    ObjectGuid kirynGuid;
    ObjectGuid rikoGuid;
    ObjectGuid statueGuid;
    ObjectGuid widowGuid;
    bool boarded = false;
    bool closing = false;
    bool spawnFailed = false;
    uint32 checkTimer = 500;
    uint32 stage = 0;
    uint32 escapeElapsed = 0;
    uint32 originalPhaseMask = PHASEMASK_NORMAL;

    void OnCharmed(bool) override { }
    void Reset() override
    {
        boarded = false;
        closing = false;
        spawnFailed = false;
        checkTimer = 500;
        stage = 0;
        escapeElapsed = 0;
        originalPhaseMask = PHASEMASK_NORMAL;
        targets.clear();
        kirynGuid.Clear();
        rikoGuid.Clear();
        statueGuid.Clear();
        widowGuid.Clear();
        me->SetReactState(REACT_PASSIVE);
    }

    void SetData(uint32 type, uint32 data) override
    {
        if (type == ScoutingReports::OriginalPhaseData)
            originalPhaseMask = data;
    }

    void DamageTaken(Unit* attacker, uint32& damage) override
    {
        // Only this player's private report targets may hurt the controlled
        // actor. Public creatures from overlapping world content (notably the
        // Lurking Tigers) must not participate in this scene.
        if (!attacker || !targets.count(attacker->GetGUID()))
        {
            damage = 0;
            if (attacker)
                attacker->AttackStop();
        }
    }

    void JustSummoned(Creature* summon) override { summons.Summon(summon); }
    void SummonedCreatureDespawn(Creature* summon) override
    {
        // A vanished living target must not advance a wave or stall the report.
        if (targets.erase(summon->GetGUID()))
            spawnFailed = true;
        summons.Despawn(summon);
    }
    void SummonedCreatureDies(Creature* summon, Unit*) override { targets.erase(summon->GetGUID()); }
    void JustDied(Unit*) override { summons.DespawnAll(); }

    Creature* Spawn(uint32 entry, Position const& pos, bool target = false)
    {
        Player* pilot = ScoutingReports::Pilot(me);
        if (!pilot)
            return nullptr;
        Creature* summon = me->SummonCreature(entry, pos, TEMPSUMMON_TIMED_DESPAWN,
            20 * MINUTE * IN_MILLISECONDS, 0, pilot->GetGUID());
        if (!summon)
        {
            spawnFailed = true;
            return nullptr;
        }
        summon->SetReactState(REACT_PASSIVE);
        if (target)
        {
            summon->SetFaction(14);
            targets.insert(summon->GetGUID());
            if (report->quest == 29823)
            {
                summon->SetMaxHealth(entry == 55693 ? 140000 : 80000);
                summon->SetHealth(summon->GetMaxHealth());
                summon->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, 2000.0f);
                summon->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, 3000.0f);
                summon->UpdateDamagePhysical(BASE_ATTACK);
                summon->AI()->AttackStart(me);
            }
        }
        else
        {
            summon->SetFaction(35);
            summon->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
        }
        return summon;
    }

    void Finish(uint32 credit)
    {
        if (closing)
            return;
        if (Player* pilot = ScoutingReports::Pilot(me))
            pilot->KilledMonsterCredit(credit);
        closing = true;
        checkTimer = 2000;
    }

    void DoAction(int32 action) override
    {
        if (action == 1 && report && report->quest == 29730)
        {
            closing = true;
            checkTimer = 2000;
        }
    }

    void PassengerBoarded(Unit* passenger, int8, bool apply) override
    {
        Player* player = passenger->ToPlayer();
        if (!player || !report)
            return;
        boarded = apply;
        if (apply)
        {
            if (report->quest == 29730)
            {
                if (Creature* statue = Spawn(55378, {1502.18f,-1260.24f,244.135f,0.0f}))
                    statueGuid = statue->GetGUID();
                if (Creature* widow = Spawn(55381, {1503.43f,-1302.06f,249.613f,3.0f}))
                    widowGuid = widow->GetGUID();
                me->Say("Inspect the warning sign, then the jade statue. Ask the widow what happened here.", LANG_UNIVERSAL, player);
            }
            else if (report->quest == 29823)
            {
                me->SetMaxHealth(400000);
                me->SetHealth(400000);
                if (Creature* kiryn = Spawn(55688, {352.144f,-2007.82f,64.3974f,4.5f}))
                    kirynGuid = kiryn->GetGUID();
                me->Say("Kiryn needs help! Use Uppercut and Fling Filth to keep the attackers away.", LANG_UNIVERSAL, player);
                RikoWave();
            }
            else
            {
                if (Creature* kiryn = Spawn(55667, {-102.21f,-2995.11f,18.5783f,0.0f}))
                    kirynGuid = kiryn->GetGUID();
                me->Say("Select a guard and use Sniper Shot. Clear each group so Kiryn can move, then shoot her barrels.", LANG_UNIVERSAL, player);
                ShokiaWave();
            }
            return;
        }
        targets.clear();
        summons.DespawnAll();
        ObjectGuid guid = player->GetGUID();
        Position home = report->home;
        uint32 phaseMask = originalPhaseMask;
        player->m_Events.Schedule(100, [guid, home, phaseMask]()
        {
            if (Player* pilot = ObjectAccessor::FindPlayer(guid))
                if (pilot->IsAlive() && !pilot->IsBeingTeleported() && pilot->GetMapId() == 870 && !pilot->GetVehicle())
                {
                    if (pilot->GetPhaseMask() == ScoutingReports::PrivateReportPhase)
                        pilot->SetPhaseMask(phaseMask, false);
                    pilot->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(), home.GetOrientation());
                }
        });
        me->DespawnOrUnsummon(500);
    }

    void RikoWave()
    {
        if (stage < 2)
        {
            // Small waves on the saved scene positions keep both attacks useful.
            Spawn(55692, {372.072f,-2003.43f,61.8612f,3.0f}, true);
            Spawn(55692, {373.928f,-2006.06f,61.6249f,3.0f}, true);
        }
        else if (stage == 2)
        {
            me->Say("An Alliance scout! They are helping the jinyu!", LANG_UNIVERSAL);
            Spawn(55693, {352.144f,-2007.82f,64.3974f,4.5f}, true);
        }
        else
        {
            if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                kiryn->Say("You saved me, Riko. Now we must warn the others.", LANG_UNIVERSAL);
            Finish(55693);
        }
    }

    void ShokiaWave()
    {
        Position const positions[] =
        {
            {-80.5588f,-2891.55f,20.8435f,3.0f},
            {-80.5588f,-2975.35f,26.0051f,3.0f},
            {-102.21f,-2995.11f,18.5783f,3.0f}
        };
        if (stage < 2)
            for (auto const& pos : positions)
                Spawn(stage ? 55710 : 55709, pos, true);
        else if (stage == 2)
        {
            if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                kiryn->Say("The explosives are ready. Shoot the barrels!", LANG_UNIVERSAL);
            for (auto const& pos : positions)
                Spawn(55784, pos, true);
        }
        else if (stage == 3)
        {
            if (Creature* riko = Spawn(55704, {-102.21f,-2995.11f,18.5783f,0.0f}))
                rikoGuid = riko->GetGUID();
            if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                kiryn->Say("Riko is coming to help! Cover our escape!", LANG_UNIVERSAL);
            for (auto const& pos : positions)
                Spawn(55711, pos, true);
        }
        else
        {
            if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                kiryn->Say("The route is clear. Let's get back to camp.", LANG_UNIVERSAL);
            if (Creature* riko = me->GetMap()->GetCreature(rikoGuid))
                riko->GetMotionMaster()->MovePoint(1, report->start);
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!boarded || !report)
            return;
        if (checkTimer > diff)
        {
            checkTimer -= diff;
            return;
        }
        checkTimer = 500;
        Player* pilot = ScoutingReports::Pilot(me);
        if (!pilot)
        {
            summons.DespawnAll();
            me->DespawnOrUnsummon();
            return;
        }
        if (closing || spawnFailed || !pilot->IsAlive() || pilot->GetQuestStatus(report->quest) != QUEST_STATUS_INCOMPLETE)
        {
            pilot->ExitVehicle();
            return;
        }
        if (me->GetDistance(report->start) > 250.0f)
        {
            pilot->ExitVehicle();
            return;
        }
        // Use the controlled actor's position for all investigation steps.
        // Keep the objectives ordered and use only this player's scene NPCs.
        if (report->quest == 29730)
        {
            Creature* statue = me->GetMap()->GetCreature(statueGuid);
            Creature* widow = me->GetMap()->GetCreature(widowGuid);
            if (!statue || !widow)
            {
                pilot->ExitVehicle();
                return;
            }
            if (!pilot->GetQuestObjectiveCounter(264502))
            {
                if (GameObject* sign = me->FindNearestGameObject(209615, INTERACTION_DISTANCE))
                {
                    pilot->KillCreditGO(209615, sign->GetGUID());
                    me->Say("No visitors? We should examine those statues.", LANG_UNIVERSAL, pilot);
                }
            }
            else if (!pilot->GetQuestObjectiveCounter(264503))
            {
                if (me->IsWithinDistInMap(statue, INTERACTION_DISTANCE))
                {
                    pilot->KilledMonsterCredit(55378);
                    me->Say("This looks like a person turned to jade. Where is the widow?", LANG_UNIVERSAL, pilot);
                }
            }
            else if (!pilot->GetQuestObjectiveCounter(264504) && me->IsWithinDistInMap(widow, INTERACTION_DISTANCE))
            {
                widow->Say("Another visitor for my collection!", LANG_UNIVERSAL, pilot);
                me->SetDisplayId(43669);
                Finish(55381);
            }
            return;
        }
        if (report->quest == 29824 && stage == 4)
        {
            if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                if (kiryn->GetDistance(report->start) < 6.0f)
                {
                    Finish(55667);
                    return;
                }
            escapeElapsed += 500;
            if (escapeElapsed >= 30000)
                pilot->ExitVehicle();
            return;
        }
        if (report->quest != 29730 && targets.empty())
        {
            ++stage;
            if (report->quest == 29823)
                RikoWave();
            else
            {
                if (Creature* kiryn = me->GetMap()->GetCreature(kirynGuid))
                {
                    Position const steps[] =
                    {
                        {-102.21f,-2995.11f,18.5783f,0.0f},
                        {-80.5588f,-2975.35f,26.0051f,0.0f},
                        {-80.5588f,-2891.55f,20.8435f,0.0f},
                        {-124.97f,-2931.21f,23.5433f,0.0f}
                    };
                    kiryn->GetMotionMaster()->MovePoint(stage, steps[std::min(stage, uint32(3))]);
                }
                ShokiaWave();
            }
            checkTimer = closing ? 2000 : 1500;
        }
    }
};

// Keep normal combat on unrelated static spawns. Only scene targets are private.
struct npc_jade_forest_report_attacker : public ScriptedAI
{
    npc_jade_forest_report_attacker(Creature* creature) : ScriptedAI(creature) { }
    void UpdateAI(uint32) override
    {
        if (UpdateVictim())
            DoMeleeAttackIfReady();
    }
};

class go_jade_forest_report_warning : public GameObjectScript
{
public:
    go_jade_forest_report_warning() : GameObjectScript("go_jade_forest_report_warning") { }
    bool OnGossipHello(Player* player, GameObject* go) override
    {
        if (!ScoutingReports::Playing(player, 29730, 55671))
            return false;
        if (!player->IsWithinDistInMap(go, INTERACTION_DISTANCE))
            return true;
        if (!player->GetQuestObjectiveCounter(264502))
        {
            player->KillCreditGO(209615, go->GetGUID());
            player->GetVehicleBase()->Say("No visitors? We should examine those statues.", LANG_UNIVERSAL, player);
        }
        return true;
    }
};

class npc_jade_forest_report_investigation : public CreatureScript
{
public:
    npc_jade_forest_report_investigation() : CreatureScript("npc_jade_forest_report_investigation") { }
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        // Preserve the existing SmartAI interactions for the Alliance report.
        if (player->GetQuestStatus(29730) != QUEST_STATUS_INCOMPLETE)
            return false;
        player->CLOSE_GOSSIP_MENU();
        if (!ScoutingReports::Playing(player, 29730, 55671) ||
            !player->IsWithinDistInMap(creature, INTERACTION_DISTANCE))
            return true;
        Unit* gorrok = player->GetVehicleBase();
        if (!player->GetQuestObjectiveCounter(264502))
        {
            gorrok->Say("We should read the warning sign first.", LANG_UNIVERSAL, player);
            return true;
        }
        if (creature->GetEntry() == 55378)
        {
            if (creature->GetPrivateObjectOwner() == player->GetGUID() && !player->GetQuestObjectiveCounter(264503))
            {
                player->KilledMonsterCredit(55378);
                gorrok->Say("This looks like a person turned to jade. Where is the widow?", LANG_UNIVERSAL, player);
            }
        }
        else if (creature->GetPrivateObjectOwner() == player->GetGUID() && player->GetQuestObjectiveCounter(264503))
        {
            creature->Say("Another visitor for my collection!", LANG_UNIVERSAL, player);
            gorrok->SetDisplayId(43669);
            player->KilledMonsterCredit(55381);
            if (Creature* actor = gorrok->ToCreature())
                actor->AI()->DoAction(1);
        }
        return true;
    }
};

class spell_jade_forest_report_shooting : public SpellScript
{
    PrepareSpellScript(spell_jade_forest_report_shooting);
    ObjectGuid actorGuid;
    ObjectGuid targetGuid;
    bool controlledCast = false;

    Creature* GetShokiaActor()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return nullptr;
        if (caster->GetEntry() == 55702)
            return caster->ToCreature();
        if (Player* player = caster->ToPlayer())
            if (Unit* base = player->GetVehicleBase())
                if (base->GetEntry() == 55702)
                    return base->ToCreature();
        return nullptr;
    }

    SpellCastResult CheckTarget()
    {
        // This native impact spell is also triggered by Kiryn's Smoke Bomb
        // on a tiger. Only override the controlled Shokia cast.
        Creature* actor = GetShokiaActor();
        if (!actor)
            return SPELL_CAST_OK;
        controlledCast = true;
        Player* pilot = ScoutingReports::Pilot(actor);
        if (!pilot || !ScoutingReports::Playing(pilot, 29824, 55702))
            return SPELL_FAILED_BAD_TARGETS;
        Creature* target = pilot->GetSelectedUnit() ? pilot->GetSelectedUnit()->ToCreature() : nullptr;
        if (!target || !target->IsAlive() || target->GetPrivateObjectOwner() != pilot->GetGUID() ||
            !actor->IsWithinDistInMap(target, 150.0f) ||
            (target->GetEntry() != 55709 && target->GetEntry() != 55710 &&
             target->GetEntry() != 55711 && target->GetEntry() != 55784))
            return SPELL_FAILED_BAD_TARGETS;
        TempSummon* summon = target->ToTempSummon();
        if (!summon || summon->GetSummonerGUID() != actor->GetGUID())
            return SPELL_FAILED_BAD_TARGETS;
        actorGuid = actor->GetGUID();
        targetGuid = target->GetGUID();
        return SPELL_CAST_OK;
    }

    void Suppress(SpellEffIndex index)
    {
        if (controlledCast)
            PreventHitDefaultEffect(index);
    }
    void Shoot()
    {
        Map* map = GetCaster()->GetMap();
        Creature* actor = map->GetCreature(actorGuid);
        Creature* target = map->GetCreature(targetGuid);
        if (actor && target)
        {
            actor->HandleEmoteCommand(EMOTE_ONESHOT_ATTACK_RIFLE);
            actor->DealDamage(target, target->GetHealth(), nullptr, DIRECT_DAMAGE,
                SPELL_SCHOOL_MASK_NORMAL, GetSpellInfo(), false);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_jade_forest_report_shooting::CheckTarget);
        OnEffectHitTarget += SpellEffectFn(spell_jade_forest_report_shooting::Suppress, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterCast += SpellCastFn(spell_jade_forest_report_shooting::Shoot);
    }
};

class spell_jade_forest_report_riko_attack : public SpellScript
{
    PrepareSpellScript(spell_jade_forest_report_riko_attack);
    SpellCastResult CheckTarget()
    {
        Player* pilot = ScoutingReports::Pilot(GetCaster());
        if (!pilot || !ScoutingReports::Playing(pilot, 29823, 55686))
            return SPELL_FAILED_BAD_TARGETS;
        Unit* target = GetExplTargetUnit();
        TempSummon* summon = target && target->ToCreature() ? target->ToCreature()->ToTempSummon() : nullptr;
        return summon && summon->IsAlive() && summon->GetPrivateObjectOwner() == pilot->GetGUID() &&
            summon->GetSummonerGUID() == GetCaster()->GetGUID() &&
            (summon->GetEntry() == 55692 || summon->GetEntry() == 55693)
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_jade_forest_report_riko_attack::CheckTarget);
    }
};

void AddSC_scouting_reports()
{
    new player_jade_forest_report_recovery();
    new npc_jade_forest_scouting_report();
    new creature_script<npc_jade_forest_scouting_actor>("npc_jade_forest_scouting_actor");
    new creature_script<npc_jade_forest_report_attacker>("npc_jade_forest_report_attacker");
    new go_jade_forest_report_warning();
    new npc_jade_forest_report_investigation();
    new spell_script<spell_jade_forest_report_shooting>("spell_jade_forest_report_shooting");
    new spell_script<spell_jade_forest_report_riko_attack>("spell_jade_forest_report_riko_attack");
}
