#include "AhnQirajStrategy.h"
#include "AhnQirajPolicy.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"
#include "Group.h"
#include "InstanceScript.h"
#include "ObjectAccessor.h"
#include "SpellAuraEffects.h"
#include "ThreatManager.h"
#include "Config.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace AhnQirajStrategy
{
namespace
{
using namespace AhnQirajPolicy;

Group* Raid(Player* bot)
{
    Group* group = bot->GetGroup(GroupSlot::Instance);
    return group ? group : bot->GetGroup();
}

Creature* Twin(Player* bot, unsigned entry)
{
    InstanceScript* instance = bot->GetInstanceScript();
    return instance ? ObjectAccessor::GetCreature(*bot, instance->GetGuidData(entry)) : nullptr;
}

unsigned Phase(Player* bot)
{
    return bot->GetInstanceScript() ? bot->GetInstanceScript()->GetData(12) : 0;
}

unsigned Role(Player* player)
{
    if (PlayerBotSpec::IsTank(player, true)) return 0;
    if (PlayerBotSpec::IsHeal(player, true)) return 1;
    if (PlayerBotSpec::IsCaster(player, true)) return 2;
    return 3;
}

std::vector<Player*> Members(Player* bot)
{
    std::vector<Player*> members;
    if (Group* group = Raid(bot))
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* player = ref->GetSource())
                if (player->IsInWorld() && player->GetMap() == bot->GetMap())
                    members.push_back(player);
    std::sort(members.begin(), members.end(), [](Player* a, Player* b)
    {
        return a->GetGUID() < b->GetGUID();
    });
    return members;
}

unsigned Rank(Player* bot, std::vector<Player*> const& members, bool byRole)
{
    unsigned rank = 0;
    for (Player* member : members)
    {
        if (member == bot) break;
        if (!byRole || Role(member) == Role(bot)) ++rank;
    }
    return rank;
}

bool Valid(Player* bot, Unit const* target)
{
    return target && target->IsInWorld() && target->IsAlive() && target->GetMap() == bot->GetMap() &&
        bot->IsValidAttackTarget(target);
}

void PositionAt(Plan& plan, Player* bot, float x, float y, float z, float tolerance = 2.5f)
{
    plan.destination.Relocate(x, y, z);
    plan.move = bot->GetExactDist2d(x, y) > tolerance;
}

void Around(Plan& plan, Player* bot, WorldObject* center, float radius, float angle)
{
    PositionAt(plan, bot, center->GetPositionX() + radius * std::cos(angle),
        center->GetPositionY() + radius * std::sin(angle), center->GetPositionZ());
}

Plan Twins(Player* bot)
{
    Plan plan;
    Creature* melee = Twin(bot, Veknilash);
    Creature* caster = Twin(bot, Veklor);
    if (!melee || !caster) return plan;

    auto const members = Members(bot);
    unsigned const role = Role(bot);
    unsigned const rank = Rank(bot, members, true);
    unsigned const side = TwinSide(role, rank);
    Position const& home = *(side ? caster : melee);
    Position const& other = *(side ? melee : caster);
    float const inward = std::atan2(other.GetPositionY() - home.GetPositionY(),
        other.GetPositionX() - home.GetPositionX());
    Creature* local = melee->GetExactDist2d(&home) < caster->GetExactDist2d(&home) ? melee : caster;
    bool const magicSide = local == caster;
    Player* owner = nullptr;
    unsigned ownerRank = 0;
    for (Player* member : members)
    {
        if (Role(member) != (magicSide ? 2u : 0u)) continue;
        if (TwinSide(Role(member), ownerRank++) == side && member->IsAlive() && !owner) owner = member;
    }

    // Follow the matching emperor after his normal teleport. The imported
    // stationary-boss modification is deliberately not used on this server.
    float radius = 26.0f;
    float angle = inward + (int((role >= 2 ? rank : rank / 2) % 5) - 2) * 0.22f;
    if (owner == bot)
    {
        radius = magicSide ? 12.0f : 0.0f;
        angle = inward;
    }
    else if (role == 3 && !magicSide)
        radius = PlayerBotSpec::IsRanged(bot, true) ? 24.0f : 5.0f;
    else if (role == 0)
        radius = magicSide ? 20.0f : 5.0f;

    PositionAt(plan, bot, home.GetPositionX() + radius * std::cos(angle),
        home.GetPositionY() + radius * std::sin(angle), home.GetPositionZ());
    plan.emergency = magicSide && bot->GetExactDist2d(caster) < 10.0f;

    if (Valid(bot, local) && role != 1 &&
        CanDamageTwin(role == 2, local->GetEntry()))
    {
        // Veklor needs a ranged threat owner on each side. Other casters
        // wait until that player is in position and has a threat lead.
        bool const ready = owner && owner->GetExactDist2d(&home) < 35.0f &&
            local->GetVictim() == owner;
        bool const threatSafe = !magicSide || owner == bot ||
            (ready &&
             local->GetThreatManager().getThreat(bot) <
                local->GetThreatManager().getThreat(owner) * 0.8f);
        if (owner == bot || (ready && threatSafe)) plan.target = local;
    }

    // Mutated/exploding bugs are real encounter adds; never pull neutral bugs
    // or let an idle team cross the room to assist the opposite emperor.
    if (!plan.target && role != 1)
        for (unsigned entry : {15316u, 15317u})
        {
            std::list<Creature*> bugs;
            bot->GetCreatureListWithEntryInGrid(bugs, entry, 35.0f);
            for (Creature* bug : bugs)
                if (Valid(bot, bug) && bug->IsInCombat() && bug->GetExactDist2d(&home) < 35.0f &&
                    (bug->HasAura(802) || bug->HasAura(804)))
                {
                    if (!plan.target || bot->GetExactDist2d(bug) < bot->GetExactDist2d(plan.target))
                        plan.target = bug;
                }
        }
    if (plan.target && plan.target != local && !PlayerBotSpec::IsRanged(bot, true))
        Around(plan, bot, plan.target, std::max(2.0f, bot->GetMeleeRange(plan.target) - 1.0f), inward);
    return plan;
}

Plan Cthun(Player* bot)
{
    Plan plan;
    unsigned const phase = Phase(bot);
    auto const members = Members(bot);
    unsigned const rank = Rank(bot, members, false);
    bool const stomach = bot->GetPositionZ() < 0.0f;
    bool const ranged = PlayerBotSpec::IsRanged(bot, true) || Role(bot) == 1;

    if (stomach)
    {
        Creature* flesh = bot->FindNearestCreature(Flesh, 150.0f, true);
        if (!Valid(bot, flesh)) flesh = nullptr;
        Aura* acid = bot->GetAura(Acid);
        if (LeaveStomach(acid ? acid->GetStackAmount() : 0, bot->GetHealthPct(), flesh != nullptr))
        {
            // The encounter checks this pad every four seconds and performs
            // the exit itself. Never teleport bots or remove the acid here.
            PositionAt(plan, bot, -8545.0f, 1984.0f, -96.0f, 4.0f);
            plan.emergency = true;
            return plan;
        }
        plan.target = flesh;
        if (!bot->IsWithinCombatRange(flesh, ranged ? 20.0f : 2.0f) || !bot->IsWithinLOSInMap(flesh))
        {
            // Approach from the north, away from the exit pad's 15-yard
            // trigger circle, especially for the eastern flesh tentacle.
            PositionAt(plan, bot, flesh->GetPositionX(), flesh->GetPositionY() + (ranged ? 18.0f : 3.0f),
                flesh->GetPositionZ(), 2.0f);
        }
        return plan;
    }

    Creature* eye = bot->FindNearestCreature(Eye, 300.0f, true);
    Creature* body = bot->FindNearestCreature(Body, 300.0f, true);
    Creature* center = phase <= 2 ? eye : body;
    if (!center) return plan;

    if (phase == 2 && NeedsGlareDodge(center->GetAngle(bot), center->GetOrientation()))
    {
        float const radius = std::max(18.0f, std::min(38.0f, bot->GetExactDist2d(center)));
        Around(plan, bot, center, radius, GlareStep(center->GetAngle(bot), center->GetOrientation()));
        plan.emergency = true;
        return plan;
    }

    auto const slot = SpreadSlot(rank);
    Position spread;
    spread.Relocate(center->GetPositionX() + slot.radius * std::cos(slot.angle),
        center->GetPositionY() + slot.radius * std::sin(slot.angle), center->GetPositionZ());

    // The eye has no melee tank requirement. Give each tentacle one melee
    // responder, selected from stable spread slots, instead of collapsing all
    // tanks and melee onto one target inside Green Beam's ten-yard jumps.
    auto ownsTentacle = [&](Creature* add)
    {
        Player* owner = nullptr;
        float best = 40.0f;
        for (unsigned i = 0; i < members.size(); ++i)
        {
            Player* member = members[i];
            if (!member->IsAlive() || PlayerBotSpec::IsRanged(member, true) ||
                Role(member) == 1 || member->GetPositionZ() < 0.0f)
                continue;
            auto const memberSlot = SpreadSlot(i);
            float const distance = add->GetExactDist2d(
                center->GetPositionX() + memberSlot.radius * std::cos(memberSlot.angle),
                center->GetPositionY() + memberSlot.radius * std::sin(memberSlot.angle));
            if (distance < best)
            {
                best = distance;
                owner = member;
            }
        }
        return owner == bot;
    };

    // Nearby eye tentacles can chain-beam the raid. Prioritize these before
    // claws, but use the exposed body's short vulnerability window fully.
    if (phase == 5 && Valid(bot, body)) plan.target = body;
    if (!plan.target && phase != 3)
        for (unsigned entry : {15334u, 15726u, 15728u, 15725u})
        {
            std::list<Creature*> adds;
            bot->GetCreatureListWithEntryInGrid(adds, entry, 60.0f);
            for (Creature* add : adds)
                if (Valid(bot, add) && (ranged || phase > 2 || ownsTentacle(add)) &&
                    std::fabs(add->GetPositionZ() - bot->GetPositionZ()) < 20.0f &&
                    (!plan.target || bot->GetExactDist2d(add) < bot->GetExactDist2d(plan.target)))
                    plan.target = add;
            if (plan.target) break;
        }
    if (!plan.target && ranged && phase <= 2 && Valid(bot, eye)) plan.target = eye;

    // Leave room for navigation's arrival error without chaining Green Beam
    // or continually interrupting the healers for tiny position corrections.
    if (!ranged && plan.target)
    {
        unsigned meleeRank = 0, meleeCount = 0;
        for (Player* member : members)
            if (!PlayerBotSpec::IsRanged(member, true) && Role(member) != 1)
            {
                if (member->GetGUID() < bot->GetGUID()) ++meleeRank;
                ++meleeCount;
            }
        float const reach = std::max(2.0f, bot->GetMeleeRange(plan.target) - 1.0f);
        float const meleeAngle = phase <= 2 ? plan.target->GetAngle(&spread) :
            2.0f * Pi * float(meleeRank) / std::max(1u, meleeCount);
        Around(plan, bot, plan.target, reach, meleeAngle);
        if (phase <= 2)
        {
            bool crowded = false;
            for (Player* member : members)
                if (member != bot && member->IsAlive() &&
                    std::fabs(member->GetPositionZ() - plan.destination.GetPositionZ()) < 20.0f &&
                    member->GetExactDist2d(&plan.destination) < 11.0f)
                    crowded = true;
            if (crowded)
            {
                plan.target = nullptr;
                plan.destination = spread;
            }
            plan.move = bot->GetExactDist2d(&plan.destination) > SpreadTolerance;
        }
    }
    else
        PositionAt(plan, bot, spread.GetPositionX(), spread.GetPositionY(), spread.GetPositionZ(), SpreadTolerance);

    if (phase == 1 && plan.move)
        for (Player* member : members)
            if (member != bot && member->IsAlive() && bot->GetExactDist2d(member) < 10.0f &&
                std::fabs(member->GetPositionZ() - bot->GetPositionZ()) < 20.0f)
                plan.emergency = true;

    // Do not let normal formation movement return a safe bot to the beam.
    // Normal damage/healing may continue from its current safe position.
    if (phase == 2) plan.move = false;
    return plan;
}
}

bool IsActive(Player* bot)
{
    if (!bot || !bot->IsInWorld() || !bot->IsAlive() || !bot->IsInCombat() ||
        bot->GetMapId() != MapId || !Raid(bot)) return false;
    unsigned const phase = Phase(bot);
    if (phase >= 1 && phase <= 5)
    {
        // Quarantine the new C'Thun planner after live GetBaseMap assertions.
        // Keep Twin Emperors independent and let ordinary combat AI handle
        // C'Thun until a live stack trace establishes the failing call path.
        if (!sConfigMgr->GetBoolDefault("Playerbots.AQ40.EnableCthunStrategy", false))
            return false;
        return bot->FindNearestCreature(Eye, 300.0f, true) ||
            bot->FindNearestCreature(Body, 300.0f, true);
    }
    Creature* melee = Twin(bot, Veknilash);
    Creature* caster = Twin(bot, Veklor);
    return melee && caster && melee->IsAlive() && caster->IsAlive() &&
        (melee->IsInCombat() || caster->IsInCombat()) &&
        (bot->GetExactDist2d(melee) < 200.0f || bot->GetExactDist2d(caster) < 200.0f);
}

Plan BuildPlan(Player* bot)
{
    if (!IsActive(bot)) return Plan();
    unsigned const phase = Phase(bot);
    return phase >= 1 && phase <= 5 ? Cthun(bot) : Twins(bot);
}

bool AllowsTarget(Player* bot, Unit const* target)
{
    if (!IsActive(bot)) return true;
    return target && BuildPlan(bot).target == target;
}
}
