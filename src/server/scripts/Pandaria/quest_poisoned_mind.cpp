#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Vehicle.h"
#include "Map.h"

namespace PoisonedMind
{
    enum : uint32 { Quest = 31211, Daily = 31216, Flyer = 63675, Mantid = 63613, Kunchong = 63625 };

    uint32 ActiveQuest(Player* player)
    {
        if (player->GetQuestStatus(Quest) == QUEST_STATUS_INCOMPLETE)
            return Quest;
        if (player->GetQuestStatus(Daily) == QUEST_STATUS_INCOMPLETE)
            return Daily;
        return 0;
    }

    // Outdoor approach west of the Amber Womb; checked against installed terrain/vmaps.
    Position const Start = { -89.346f, 4603.535f, 80.673f, 1.570796f };
    Position const Circuit[] = {
        { -90.0f, 4650.0f, 0.0f, 0.0f },
        { -160.0f, 4650.0f, 0.0f, 0.0f },
        { -230.0f, 4650.0f, 0.0f, 0.0f }
    };
}

struct npc_poisoned_mind_flyer : public ScriptedAI
{
    npc_poisoned_mind_flyer(Creature* c) : ScriptedAI(c), summons(c) { }
    SummonList summons;
    ObjectGuid owner;
    Position home;
    uint32 lifetime = 20 * MINUTE * IN_MILLISECONDS;
    uint32 boardingTime = 10000;
    uint32 pause = 0;
    uint32 quest = 0, mantidObjective = 0, kunchongObjective = 0;
    uint32 initialMantid = 0, initialKunchong = 0;
    uint32 killedMantid = 0, killedKunchong = 0;
    std::set<ObjectGuid> credited;
    Position circuit[3];
    float cruiseHeight = 0.0f;
    bool launchPending = false;
    uint32 nextLeg = 0;
    uint8 waypoint = 0;
    bool boarded = false;
    bool targetsSpawned = false;
    bool finished = false;

    // Keep this AI active while the vehicle seat is charmed by its passenger.
    void OnCharmed(bool /*apply*/) override { }

    void IsSummonedBy(Unit* summoner) override
    {
        Player* player = summoner->ToPlayer();
        if (!player || !PoisonedMind::ActiveQuest(player))
        {
            me->DespawnOrUnsummon();
            return;
        }
        quest = PoisonedMind::ActiveQuest(player);
        mantidObjective = quest == PoisonedMind::Daily ? 268422 : 268421;
        kunchongObjective = quest == PoisonedMind::Daily ? 268882 : 268881;
        owner = player->GetGUID();
        home = player->GetPosition();
        initialMantid = player->GetQuestObjectiveCounter(mantidObjective);
        initialKunchong = player->GetQuestObjectiveCounter(kunchongObjective);
        std::copy(std::begin(PoisonedMind::Circuit), std::end(PoisonedMind::Circuit), circuit);
        me->SetFaction(player->GetFaction());
        me->SetReactState(REACT_PASSIVE);
        me->SetCanFly(true);
        me->SetDisableGravity(true);
        me->SetWalk(false);
        me->SetSpeed(MOVE_FLIGHT, 6.0f);
        me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC);
        me->RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);
    }

    void JustSummoned(Creature* summon) override { summons.Summon(summon); }
    void SummonedCreatureDespawn(Creature* summon) override { summons.Despawn(summon); }

    void Finish()
    {
        if (finished)
            return;
        finished = true;
        summons.DespawnAll();
        if (Player* player = ObjectAccessor::GetPlayer(*me, owner))
        {
            // Eject at the original safe ground position, including early exits.
            if (player->GetVehicleBase() == me)
                player->ExitVehicle();
            if (player->IsAlive())
                player->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(), home.GetOrientation());
        }
        me->DespawnOrUnsummon(1000);
    }

    void PassengerBoarded(Unit* passenger, int8 /*seat*/, bool apply) override
    {
        if (passenger->GetGUID() != owner)
            return;
        if (!apply)
        {
            // ExitVehicle is already in progress. UpdateAI performs cleanup next tick.
            boardingTime = 0;
            return;
        }
        boarded = true;
        if (Player* player = passenger->ToPlayer())
        {
            player->TalkedToCreature(62151, me->GetGUID());
            player->SetClientControl(me, false);
        }
        // Start next tick, after vehicle boarding movement/control has settled.
        launchPending = true;
    }

    void StartLeg(uint32 id, Position destination)
    {
        me->GetMotionMaster()->MovePoint(id, destination, false);
    }

    void SummonedCreatureDies(Creature* target, Unit* killer) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (finished || !player || player->GetVehicleBase() != me || !killer ||
            (killer != me && killer->GetCharmerOrOwnerPlayerOrPlayerItself() != player) ||
            player->GetQuestStatus(quest) != QUEST_STATUS_INCOMPLETE ||
            !credited.insert(target->GetGUID()).second)
            return;

        uint32 objective, expected, entry;
        if (target->GetEntry() == PoisonedMind::Mantid)
        {
            objective = mantidObjective; entry = PoisonedMind::Mantid;
            expected = std::min(200u, initialMantid + ++killedMantid);
        }
        else if (target->GetEntry() == PoisonedMind::Kunchong)
        {
            objective = kunchongObjective; entry = PoisonedMind::Kunchong;
            expected = std::min(3u, initialKunchong + ++killedKunchong);
        }
        else
            return;
        // Core rewards run before this callback. Fill only missing progress.
        uint32 current = player->GetQuestObjectiveCounter(objective);
        if (current < expected)
            player->KilledMonsterCredit(entry, ObjectGuid::Empty, expected - current);
    }

    bool SpawnTargets()
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player)
            return false;
        for (Position& center : circuit)
        {
            // Eighty mantid and one kunchong at each stop; actual kills grant credit.
            for (uint32 i = 0; i < 81; ++i)
            {
                float x = center.GetPositionX() + (int32(i % 9) - 4) * 2.0f;
                float y = center.GetPositionY() + (int32(i / 9) - 4) * 2.0f;
                float z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, 1000.0f, true, 1000.0f);
                if (z == INVALID_HEIGHT || z < 0.0f || z > 130.0f)
                    return false;
                center.m_positionZ = std::max(center.GetPositionZ(), z + 25.0f);
                Creature* target = me->SummonCreature(i == 80 ? PoisonedMind::Kunchong : PoisonedMind::Mantid,
                    Position{x, y, z, 0.0f}, TEMPSUMMON_MANUAL_DESPAWN, 0, 0, owner);
                if (!target)
                    return false;
                target->SetLootRecipient(player);
                target->LowerPlayerDamageReq(target->GetMaxHealth());
                target->SetFaction(14);
                target->SetReactState(REACT_PASSIVE);
                target->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_DISABLE_MOVE);
            }
        }
        // Keep the entire circuit above intervening terrain, not just its stops.
        float altitude = 0.0f;
        for (Position const& center : circuit)
            altitude = std::max(altitude, center.GetPositionZ());
        for (uint32 i = 0; i <= 30; ++i)
        {
            float fraction = float(i) / 30.0f;
            float x = circuit[0].GetPositionX() + fraction * (circuit[2].GetPositionX() - circuit[0].GetPositionX());
            float y = circuit[0].GetPositionY() + fraction * (circuit[2].GetPositionY() - circuit[0].GetPositionY());
            float ground = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, 1000.0f, true, 1000.0f);
            if (ground == INVALID_HEIGHT || ground < 0.0f || ground > 130.0f)
                return false;
            altitude = std::max(altitude, ground + 25.0f);
        }
        for (Position& center : circuit)
            center.m_positionZ = altitude;
        cruiseHeight = std::max(altitude, home.GetPositionZ() + 25.0f);
        return true;
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (finished || type != POINT_MOTION_TYPE)
            return;
        // Defer launching the next leg until the old movement generator finalizes.
        if (id == 10 || id == 11)
            nextLeg = id + 1;
        else if (id == 1 || id == 2)
            pause = 20000;
    }

    void SpellHit(Unit* /*caster*/, SpellInfo const* spell) override
    {
        if (spell->Id == 124206)
            Finish();
    }

    void UpdateAI(uint32 diff) override
    {
        if (finished)
            return;
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !player->IsAlive() ||
            player->GetQuestStatus(quest) != QUEST_STATUS_INCOMPLETE || lifetime <= diff)
        {
            Finish();
            return;
        }
        lifetime -= diff;
        if (player->GetVehicleBase() != me)
        {
            if (boarded || boardingTime <= diff)
                Finish();
            else
                boardingTime -= diff;
            return;
        }
        if (launchPending)
        {
            launchPending = false;
            targetsSpawned = true;
            if (!SpawnTargets()) { Finish(); return; }
            Position above = home;
            above.m_positionZ = cruiseHeight;
            StartLeg(10, above);
            return;
        }
        if (nextLeg)
        {
            uint32 leg = nextLeg;
            nextLeg = 0;
            if (leg == 11)
            {
                Position above = circuit[0];
                above.m_positionZ = cruiseHeight;
                StartLeg(11, above);
            }
            else
            {
                if (!targetsSpawned)
                {
                    targetsSpawned = true;
                    if (!SpawnTargets()) { Finish(); return; }
                }
                StartLeg(1, circuit[0]);
            }
            return;
        }
        if (pause)
        {
            if (pause > diff)
                pause -= diff;
            else
            {
                pause = 0;
                waypoint = (waypoint + 1) % 3;
                StartLeg(2, circuit[waypoint]);
            }
        }
    }
};

class npc_xaril_poisoned_mind : public CreatureScript
{
public:
    npc_xaril_poisoned_mind() : CreatureScript("npc_xaril_poisoned_mind") { }
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        player->PrepareQuestMenu(creature->GetGUID());
        if (player->IsAlive() && !player->IsInCombat() && !player->GetVehicle() &&
            PoisonedMind::ActiveQuest(player))
        {
            if (creature->GetDistance(PoisonedMind::Start) < 25.0f)
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "I am ready to fly.", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF);
            else
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, "Take me to the Amber Womb entrance.", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + 1);
        }
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }
    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        player->PlayerTalkClass->ClearMenus();
        player->CLOSE_GOSSIP_MENU();
        if (sender != GOSSIP_SENDER_MAIN ||
            (action != GOSSIP_ACTION_INFO_DEF && action != GOSSIP_ACTION_INFO_DEF + 1) ||
            !player->IsAlive() || player->IsInCombat() || player->GetVehicle() ||
            !creature->IsWithinDistInMap(player, INTERACTION_DISTANCE) ||
            !PoisonedMind::ActiveQuest(player))
            return true;
        if (player->GetMapId() != 870)
            return true;
        if (action == GOSSIP_ACTION_INFO_DEF + 1)
        {
            if (creature->GetDistance(PoisonedMind::Start) >= 25.0f)
                player->NearTeleportTo(PoisonedMind::Start.GetPositionX(), PoisonedMind::Start.GetPositionY(),
                    PoisonedMind::Start.GetPositionZ(), PoisonedMind::Start.GetOrientation());
            return true;
        }
        if (creature->GetDistance(PoisonedMind::Start) >= 25.0f)
            return true;
        std::list<Creature*> flyers;
        GetCreatureListWithEntryInGrid(flyers, player, PoisonedMind::Flyer, 100.0f);
        for (Creature* flyer : flyers)
            if (TempSummon* summon = flyer->ToTempSummon())
                if (summon->GetSummonerGUID() == player->GetGUID())
                    return true;
        if (Creature* flyer = player->SummonCreature(PoisonedMind::Flyer, player->GetPosition(),
            TEMPSUMMON_MANUAL_DESPAWN, 0, 156, player->GetGUID()))
            player->EnterVehicle(flyer, 0);
        return true;
    }
};

void AddSC_poisoned_mind()
{
    new npc_xaril_poisoned_mind();
    new creature_script<npc_poisoned_mind_flyer>("npc_poisoned_mind_flyer");
}
