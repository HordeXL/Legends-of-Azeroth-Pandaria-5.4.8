#include "DpsTargetValue.h"

#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "PlayerbotSpec.h"

namespace
{
Group* GetActiveGroup(Player* bot)
{
    Group* group = bot ? bot->GetGroup(GroupSlot::Instance) : nullptr;
    return group ? group : (bot ? bot->GetGroup() : nullptr);
}

Unit* GetGroupPveTankFocus(PlayerbotAI* botAI)
{
    Player* bot = botAI ? botAI->GetBot() : nullptr;
    Group* group = GetActiveGroup(bot);
    if (!bot || !group || !botAI->IsGroupPveActivity())
        return nullptr;

    GuidVector const attackers = botAI->GetAiObjectContext()
        ->GetValue<GuidVector>("attackers")->Get();
    auto isEngagedTarget = [&](Unit* target)
    {
        return target && target->IsAlive() && target->GetMap() == bot->GetMap() &&
            bot->IsValidAttackTarget(target) &&
            !target->HasBreakableByDamageCrowdControlAura() &&
            std::find(attackers.begin(), attackers.end(), target->GetGUID()) !=
                attackers.end();
    };

    // Prefer the real player's tank target. If the player is not the tank,
    // use the first living tank's active target. Only already-engaged enemies
    // qualify, so this cannot start a pull by itself.
    for (uint8 pass = 0; pass < 2; ++pass)
    {
        for (GroupReference* ref = group->GetFirstMember(); ref;
             ref = ref->next())
        {
            Player* member = ref->GetSource();
            PlayerbotAI* memberAI = member ? GET_PLAYERBOT_AI(member) : nullptr;
            if (!member || !member->IsAlive() || member->GetMap() != bot->GetMap() ||
                !PlayerBotSpec::IsTank(member, true) ||
                (pass == 0) != (memberAI == nullptr))
                continue;

            Unit* target = memberAI ? memberAI->GetAiObjectContext()
                ->GetValue<Unit*>("current target")->Get() :
                member->GetSelectedUnit();
            if (isEngagedTarget(target))
                return target;
        }
    }

    return nullptr;
}
}

class FindMaxThreatGapTargetStrategy : public FindTargetStrategy
{
public:
    FindMaxThreatGapTargetStrategy(PlayerbotAI* botAI) : FindTargetStrategy(botAI), minThreat(0) {}

    void CheckAttacker(Unit* attacker, ThreatManager* threatMgr) override
    {
        if (!attacker->IsAlive())
        {
            return;
        }
        if (foundHighPriority)
        {
            return;
        }
        if (IsHighPriority(attacker))
        {
            result = attacker;
            foundHighPriority = true;
            return;
        }
        Unit* victim = attacker->GetVictim();
        if (!result || CalcThreatGap(attacker, threatMgr) > CalcThreatGap(result, &result->GetThreatManager()))
            result = attacker;
    }
    float CalcThreatGap(Unit* attacker, ThreatManager* threatMgr)
    {
        Unit* victim = attacker->GetVictim();
        return threatMgr->getThreat(victim) - threatMgr->getThreat(attacker);
    }

protected:
    float minThreat;
};

// caster
class CasterFindTargetSmartStrategy : public FindTargetStrategy
{
public:
    CasterFindTargetSmartStrategy(PlayerbotAI* botAI, float dps)
        : FindTargetStrategy(botAI), dps_(dps), targetExpectedLifeTime(1000000)
    {
        result = nullptr;
    }

    void CheckAttacker(Unit* attacker, ThreatManager* threatMgr) override
    {
        if (Group* group = GetActiveGroup(botAI->GetBot()))
        {
            ObjectGuid guid = group->GetTargetIcon(4);
            if (guid && attacker->GetGUID() == guid)
                return;
        }
        if (!attacker->IsAlive())
        {
            return;
        }
        if (foundHighPriority)
        {
            return;
        }
        if (IsHighPriority(attacker))
        {
            result = attacker;
            foundHighPriority = true;
            return;
        }
        float expectedLifeTime = attacker->GetHealth() / dps_;
        // Unit* victim = attacker->GetVictim();
        if (!result || IsBetter(attacker, result))
        {
            targetExpectedLifeTime = expectedLifeTime;
            result = attacker;
        }
    }
    bool IsBetter(Unit* new_unit, Unit* old_unit)
    {
        float new_time = new_unit->GetHealth() / dps_;
        float old_time = old_unit->GetHealth() / dps_;
        // [5-30] > (5-0] > (20-inf)
        int new_level = GetIntervalLevel(new_unit);
        int old_level = GetIntervalLevel(old_unit);
        if (new_level != old_level)
        {
            return new_level > old_level;
        }
        int32_t level = new_level;
        if (level % 10 == 2 || level % 10 == 0)
        {
            return new_time < old_time;
        }
        // dont switch targets when all of them with low health
        Unit* currentTarget = botAI->GetAiObjectContext()->GetValue<Unit*>("current target")->Get();
        if (currentTarget == new_unit)
        {
            return true;
        }
        if (currentTarget == old_unit)
        {
            return false;
        }
        return new_time > old_time;
    }
    int32_t GetIntervalLevel(Unit* unit)
    {
        float time = unit->GetHealth() / dps_;
        float dis = unit->GetDistance(botAI->GetBot());
        float attackRange =
            PlayerBotSpec::IsRanged(botAI->GetBot()) ? sPlayerbotAIConfig->spellDistance : sPlayerbotAIConfig->meleeDistance;
        attackRange += 5.0f;
        int level = dis < attackRange ? 10 : 0;
        if (time >= 5 && time <= 30)
        {
            return level + 2;
        }
        if (time > 30)
        {
            return level;
        }
        return level + 1;
    }

protected:
    float dps_;
    float targetExpectedLifeTime;
};

// non caster
class NonCasterFindTargetSmartStrategy : public FindTargetStrategy
{
public:
    NonCasterFindTargetSmartStrategy(PlayerbotAI* botAI, float dps)
        : FindTargetStrategy(botAI), dps_(dps), targetExpectedLifeTime(1000000)
    {
    }

    void CheckAttacker(Unit* attacker, ThreatManager* threatMgr) override
    {
        if (Group* group = GetActiveGroup(botAI->GetBot()))
        {
            ObjectGuid guid = group->GetTargetIcon(4);
            if (guid && attacker->GetGUID() == guid)
                return;
        }
        if (!attacker->IsAlive())
        {
            return;
        }
        if (foundHighPriority)
        {
            return;
        }
        if (IsHighPriority(attacker))
        {
            result = attacker;
            foundHighPriority = true;
            return;
        }
        float expectedLifeTime = attacker->GetHealth() / dps_;
        // Unit* victim = attacker->GetVictim();
        if (!result || IsBetter(attacker, result))
        {
            targetExpectedLifeTime = expectedLifeTime;
            result = attacker;
        }
    }
    bool IsBetter(Unit* new_unit, Unit* old_unit)
    {
        float new_time = new_unit->GetHealth() / dps_;
        float old_time = old_unit->GetHealth() / dps_;
        // [5-20] > (5-0] > (20-inf)
        int new_level = GetIntervalLevel(new_unit);
        int old_level = GetIntervalLevel(old_unit);
        if (new_level != old_level)
        {
            return new_level > old_level;
        }
        // attack enemy in range and with lowest health
        int level = new_level;
        if (level == 10)
        {
            return new_time < old_time;
        }
        // all targets are far away, choose the closest one
        return botAI->GetBot()->GetDistance(new_unit) < botAI->GetBot()->GetDistance(old_unit);
    }
    int32_t GetIntervalLevel(Unit* unit)
    {
        float time = unit->GetHealth() / dps_;
        float dis = unit->GetDistance(botAI->GetBot());
        float attackRange =
            PlayerBotSpec::IsRanged(botAI->GetBot()) ? sPlayerbotAIConfig->spellDistance : sPlayerbotAIConfig->meleeDistance;
        attackRange += 5.0f;
        int level = dis < attackRange ? 10 : 0;
        return level;
    }

protected:
    float dps_;
    float targetExpectedLifeTime;
};

// combo
class ComboFindTargetSmartStrategy : public FindTargetStrategy
{
public:
    ComboFindTargetSmartStrategy(PlayerbotAI* botAI, float dps)
        : FindTargetStrategy(botAI), dps_(dps), targetExpectedLifeTime(1000000)
    {
    }

    void CheckAttacker(Unit* attacker, ThreatManager* threatMgr) override
    {
        if (Group* group = GetActiveGroup(botAI->GetBot()))
        {
            ObjectGuid guid = group->GetTargetIcon(4);
            if (guid && attacker->GetGUID() == guid)
                return;
        }
        if (!attacker->IsAlive())
        {
            return;
        }
        if (foundHighPriority)
        {
            return;
        }
        if (IsHighPriority(attacker))
        {
            result = attacker;
            foundHighPriority = true;
            return;
        }
        float expectedLifeTime = attacker->GetHealth() / dps_;
        // Unit* victim = attacker->GetVictim();
        if (!result || IsBetter(attacker, result))
        {
            targetExpectedLifeTime = expectedLifeTime;
            result = attacker;
        }
    }
    bool IsBetter(Unit* new_unit, Unit* old_unit)
    {
        float new_time = new_unit->GetHealth() / dps_;
        float old_time = old_unit->GetHealth() / dps_;
        // [5-20] > (5-0] > (20-inf)
        int new_level = GetIntervalLevel(new_unit);
        int old_level = GetIntervalLevel(old_unit);
        if (new_level != old_level)
        {
            return new_level > old_level;
        }
        // attack enemy in range and with lowest health
        int level = new_level;
        Player* bot = botAI->GetBot();
        if (level == 10)
        {
            Unit* combo_unit = bot->GetComboTarget();
            if (new_unit == combo_unit)
            {
                return true;
            }
            return new_time < old_time;
        }
        // all targets are far away, choose the closest one
        return bot->GetDistance(new_unit) < bot->GetDistance(old_unit);
    }
    int32_t GetIntervalLevel(Unit* unit)
    {
        float time = unit->GetHealth() / dps_;
        float dis = unit->GetDistance(botAI->GetBot());
        float attackRange =
            PlayerBotSpec::IsRanged(botAI->GetBot()) ? sPlayerbotAIConfig->spellDistance : sPlayerbotAIConfig->meleeDistance;
        attackRange += 5.0f;
        int level = dis < attackRange ? 10 : 0;
        return level;
    }

protected:
    float dps_;
    float targetExpectedLifeTime;
};

Unit* DpsTargetValue::Calculate()
{
    Unit* rti = RtiTargetValue::Calculate();
    if (rti)
        return rti;

    if (Unit* tankFocus = GetGroupPveTankFocus(botAI))
        return tankFocus;

    // FindLeastHpTargetStrategy strategy(botAI);
    Group* group = GetActiveGroup(bot);
    float dps = AI_VALUE(float, "estimated group dps");
    if (group && PlayerBotSpec::IsCaster(bot))
    {
        CasterFindTargetSmartStrategy strategy(botAI, dps);
        return TargetValue::FindTarget(&strategy);
    }
    else if (PlayerBotSpec::IsCombo(bot))
    {
        ComboFindTargetSmartStrategy strategy(botAI, dps);
        return TargetValue::FindTarget(&strategy);
    }
    NonCasterFindTargetSmartStrategy strategy(botAI, dps);
    return TargetValue::FindTarget(&strategy);
}

class FindMaxHpTargetStrategy : public FindTargetStrategy
{
public:
    FindMaxHpTargetStrategy(PlayerbotAI* botAI) : FindTargetStrategy(botAI), maxHealth(0) {}

    void CheckAttacker(Unit* attacker, ThreatManager* threatMgr) override
    {
        if (Group* group = GetActiveGroup(botAI->GetBot()))
        {
            ObjectGuid guid = group->GetTargetIcon(4);
            if (guid && attacker->GetGUID() == guid)
                return;
        }

        if (!result || result->GetHealth() < attacker->GetHealth())
            result = attacker;
    }

protected:
    float maxHealth;
};

Unit* DpsAoeTargetValue::Calculate()
{
    Unit* rti = RtiTargetValue::Calculate();
    if (rti)
        return rti;

    FindMaxHpTargetStrategy strategy(botAI);
    return TargetValue::FindTarget(&strategy);
}
