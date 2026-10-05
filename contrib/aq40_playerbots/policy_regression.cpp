#include "../../modules/mod_playerbots/src/AI/AhnQirajPolicy.h"
#include <cstdlib>
#include <iostream>

using namespace AhnQirajPolicy;
unsigned checks = 0;
void Check(bool value, char const* message)
{
    ++checks;
    if (!value) { std::cerr << "FAIL: " << message << '\n'; std::exit(1); }
}
int main()
{
    for (unsigned role = 0; role < 4; ++role)
    {
        unsigned counts[2] = {};
        for (unsigned rank = 0; rank < 10; ++rank) ++counts[Side(rank)];
        Check(counts[0] == 5 && counts[1] == 5, "each role split between both sides");
    }
    for (unsigned rank = 0; rank < 20; ++rank)
    {
        Check(TwinSide(2, rank) == 1, "every magic DPS uses Veklor's platform");
        Check(TwinSide(3, rank) == 0, "every physical DPS uses Veknilash's platform");
        Check(TwinSide(1, rank) == rank % 2, "healers cover both platforms");
    }
    Check(CanDamageTwin(false, Veknilash) && !CanDamageTwin(false, Veklor), "physical immunity respected");
    Check(CanDamageTwin(true, Veklor) && !CanDamageTwin(true, Veknilash), "magic immunity respected");
    for (unsigned a = 0; a < 40; ++a)
        for (unsigned b = a + 1; b < 40; ++b)
        {
            auto x = SpreadSlot(a), y = SpreadSlot(b);
            float dx = x.radius * std::cos(x.angle) - y.radius * std::cos(y.angle);
            float dy = x.radius * std::sin(x.angle) - y.radius * std::sin(y.angle);
            Check(std::hypot(dx, dy) - 2 * SpreadTolerance > 10.0f,
                "40-player slots stay beyond beam jumps even with arrival error on both players");
        }
    // Check both rotation directions, including the wrap at +/- pi.
    for (float facing : {-Pi, -0.1f, 0.0f, Pi - 0.1f})
        for (float offset : {-1.3f, -0.2f, 0.0f, 0.2f, 1.3f})
        {
            float bearing = facing + offset;
            Check(NeedsGlareDodge(bearing, facing), "danger cone detected");
            float next = GlareStep(bearing, facing);
            Check(std::fabs(AngleDelta(next - facing)) > std::fabs(AngleDelta(bearing - facing)),
                "dodge increases angular clearance");
            Check(std::cos(AngleDelta(next - bearing) / 2) > 0.98f,
                "short arc chord cannot cross the boss centre");
        }
    Check(!NeedsGlareDodge(Pi, 0), "safe rear permits casting");
    Check(!LeaveStomach(7, 80, true), "healthy swallowed bot kills tentacles");
    Check(LeaveStomach(8, 80, true), "acid threshold triggers exit");
    Check(LeaveStomach(1, 30, true), "low health triggers exit");
    Check(LeaveStomach(1, 80, false), "empty stomach triggers exit");
    std::cout << "AQ40 policy: " << checks << " checks passed\n";
}
