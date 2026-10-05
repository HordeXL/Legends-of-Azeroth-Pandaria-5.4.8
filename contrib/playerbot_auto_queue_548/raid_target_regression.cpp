#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>
#include <set>

using int32 = int32_t;
using uint32 = uint32_t;
using ObjectGuid = uint32;
using GuidVector = std::vector<ObjectGuid>;
class PlayerbotAI;
class AiObjectContext;

// QUALIFIED
void Qualified::Qualify(int qual) { qualifier = std::to_string(qual); }

// FACTORY

struct Unit
{
    std::string name;
    bool alive = true;
    bool inWorld = true;
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    std::string GetName() const { return name; }
};

struct UntypedValue { virtual ~UntypedValue() = default; };
template<class T> struct Value : UntypedValue { virtual T Get() = 0; };
struct GuidValue : Value<GuidVector>
{
    GuidVector guids;
    GuidVector Get() override { return guids; }
};

class UnitCalculatedValue : public Value<Unit*>
{
public:
    UnitCalculatedValue(PlayerbotAI* ai, std::string const&) : botAI(ai) {}
    Unit* Get() override
    {
        Unit* unit = Calculate();
        return unit && unit->IsInWorld() ? unit : nullptr;
    }
protected:
    PlayerbotAI* botAI;
    virtual Unit* Calculate() = 0;
};

// TARGET_CLASS

class ValueContext : public NamedObjectFactory<UntypedValue>
{
public:
    ValueContext() { // TARGET_REGISTRATION
    }
private:
    // TARGET_FACTORY
};

class AiObjectContext
{
public:
    ValueContext factory;
    GuidValue targets;
    bool missingTargets = false;
    std::unordered_map<std::string, std::unique_ptr<UntypedValue>> values;
    PlayerbotAI* ai = nullptr;

    template<class T> Value<T>* GetValue(std::string const& name)
    {
        if (name == "possible targets no los")
            return missingTargets ? nullptr : dynamic_cast<Value<T>*>(&targets);
        auto& value = values[name];
        if (!value)
            value.reset(factory.create(name, ai));
        return dynamic_cast<Value<T>*>(value.get());
    }
    template<class T> Value<T>* GetValue(std::string const& name, std::string const& param)
    {
        return GetValue<T>(name + "::" + param);
    }
};

class PlayerbotAI
{
public:
    AiObjectContext context;
    std::unordered_map<ObjectGuid, Unit*> units;
    bool tank = false;
    PlayerbotAI() { context.ai = this; }
    AiObjectContext* GetAiObjectContext() { return &context; }
    Unit* GetUnit(ObjectGuid guid)
    {
        auto it = units.find(guid);
        return it == units.end() ? nullptr : it->second;
    }
    bool IsTank(Unit*) const { return tank; }
};

// TARGET_CALCULATE

// AI_VALUE_MACRO
class RsBaltharusAvoidFrontTrigger
{
public:
    PlayerbotAI* botAI;
    AiObjectContext* context;
    Unit* bot;
    bool IsActive();
};
// TRIGGER_CALCULATE

int main()
{
    PlayerbotAI ai;
    Unit bot{"bot"}, boss{"Baltharus the Warborn"}, saviana{"Saviana Ragefire"};
    Unit deadBoss{"Baltharus the Warborn", false};
    ai.units = {{1, &boss}, {2, &saviana}, {3, &deadBoss}};
    auto* target = ai.context.GetValue<Unit*>("find target", "baltharus the warborn");
    assert(target); // This missing registration caused the production SIGSEGV.
    assert(dynamic_cast<Qualified*>(target)->getQualifier() == "baltharus the warborn");
    assert(!ai.context.GetValue<GuidVector>("find target", "baltharus the warborn"));
    RsBaltharusAvoidFrontTrigger trigger{&ai, &ai.context, &bot};

    assert(target->Get() == nullptr);
    assert(!trigger.IsActive()); // Bots entering the instance with no boss nearby.
    ai.context.targets.guids = {99, 3, 2, 1}; // Stale, dead, unrelated, live boss.
    assert(target->Get() == &boss);
    assert(trigger.IsActive());
    ai.tank = true;
    assert(!trigger.IsActive());
    ai.tank = false;
    boss.alive = false;
    assert(!trigger.IsActive());
    boss.alive = true;
    boss.inWorld = false;
    assert(!trigger.IsActive());
    boss.inWorld = true;
    ai.context.missingTargets = true;
    assert(!trigger.IsActive());
    ai.context.missingTargets = false;

    assert(ai.context.GetValue<Unit*>("find target", "SaViAnA RaGeFiRe")->Get() == &saviana);
    assert(ai.context.GetValue<Unit*>("find target", "halion")->Get() == nullptr);
    assert(ai.context.GetValue<Unit*>("find target", "")->Get() == nullptr);
    assert(ai.context.GetValue<Unit*>("find target")->Get() == nullptr);
    std::cout << "PASS: named raid target registration and Baltharus trigger\n";
}
