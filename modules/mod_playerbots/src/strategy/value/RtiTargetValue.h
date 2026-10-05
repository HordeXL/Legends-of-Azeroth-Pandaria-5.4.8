#ifndef _PLAYERBOT_RTITARGETVALUE_H
#define _PLAYERBOT_RTITARGETVALUE_H

#include "TargetValue.h"

class PlayerbotAI;
class Unit;

class RtiTargetValue : public TargetValue
{
public:
    // WoW raid target icon indices.  Older playerbots raid strategies use
    // these symbolic names directly.
    static constexpr uint8 starIndex = 0;
    static constexpr uint8 circleIndex = 1;
    static constexpr uint8 diamondIndex = 2;
    static constexpr uint8 triangleIndex = 3;
    static constexpr uint8 moonIndex = 4;
    static constexpr uint8 squareIndex = 5;
    static constexpr uint8 crossIndex = 6;
    static constexpr uint8 skullIndex = 7;

    RtiTargetValue(PlayerbotAI* botAI, std::string const type = "rti", std::string const name = "rti target")
        : TargetValue(botAI, name), type(type)
    {
    }

    static int32 GetRtiIndex(std::string const rti);
    Unit* Calculate() override;

private:
    std::string const type;
};

class RtiCcTargetValue : public RtiTargetValue
{
public:
    RtiCcTargetValue(PlayerbotAI* botAI, std::string const name = "rti cc target")
        : RtiTargetValue(botAI, "rti cc", name)
    {
    }
};

#endif
