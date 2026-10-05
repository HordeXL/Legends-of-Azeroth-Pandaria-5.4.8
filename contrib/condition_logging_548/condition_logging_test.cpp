#include <cstdint>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
using uint32 = std::uint32_t;
#include "enums.inc"

struct ConditionMgr
{
    struct ConditionTypeInfo { char const* Name; bool v1, v2, v3; };
    static char const* const StaticSourceTypeData[CONDITION_SOURCE_TYPE_MAX];
    static ConditionTypeInfo const StaticConditionTypeData[CONDITION_MAX];
    static bool CanHaveSourceGroupSet(ConditionSourceType);
    static bool CanHaveSourceIdSet(ConditionSourceType);
};
struct Condition
{
    ConditionSourceType SourceType = CONDITION_SOURCE_TYPE_NONE;
    ConditionTypes ConditionType = CONDITION_NONE;
    uint32 SourceGroup = 17, SourceEntry = 1066, SourceId = 3;
    std::string ToString(bool ext = false) const;
};
#include "production.inc"

void Require(bool value, char const* message)
{
    if (!value) throw std::runtime_error(message);
}
int main()
{
    try
    {
        Condition condition;
        // Check for incomplete tables before streaming a null pointer: this
        // makes the original crash regression fail without crashing the test.
        for (uint32 type = 0; type < CONDITION_SOURCE_TYPE_MAX; ++type)
        {
            Require(ConditionMgr::StaticSourceTypeData[type] != nullptr, "Missing source name");
            condition.SourceType = ConditionSourceType(type);
            Require(condition.ToString().back() == ']', "Truncated source description");
        }
        condition.SourceType = CONDITION_SOURCE_TYPE_TERRAIN_SWAP;
        Require(condition.ToString().find("SourceType: 29 (Terrain Swap)") != std::string::npos,
            "Terrain-swap crash scenario must format correctly");
        for (uint32 type = 0; type < CONDITION_MAX; ++type)
        {
            condition.ConditionType = ConditionTypes(type);
            Require(condition.ToString(true).back() == ']', "Truncated condition description");
            if (!ConditionMgr::StaticConditionTypeData[type].Name)
                Require(condition.ToString(true).find("(Unknown)") != std::string::npos,
                    "Sparse/custom condition name must have a safe fallback");
        }
        for (uint32 type : {uint32(CONDITION_SOURCE_TYPE_MAX), uint32(-1)})
        {
            condition.SourceType = ConditionSourceType(type);
            Require(condition.ToString().find("(Unknown)") != std::string::npos, "Invalid source not guarded");
        }
        condition.SourceType = CONDITION_SOURCE_TYPE_NONE;
        for (uint32 type : {uint32(CONDITION_MAX), uint32(-1)})
        {
            condition.ConditionType = ConditionTypes(type);
            Require(condition.ToString(true).find("(Unknown)") != std::string::npos, "Invalid condition not guarded");
        }
        std::cout << "PASS: all condition/source names, terrain-swap logging and invalid indexes\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
