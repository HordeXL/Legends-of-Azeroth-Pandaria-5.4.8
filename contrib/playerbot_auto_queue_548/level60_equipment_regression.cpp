#include "../../modules/mod_playerbots/src/Factory/ManagedPveEquipmentPolicy.h"
#include <cassert>

int main()
{
    using namespace ManagedPveEquipmentPolicy;
    auto allowed = [](unsigned level, unsigned itemLevel, bool pve)
    {
        return itemLevel <= MaximumItemLevel(level, pve);
    };

    assert(allowed(60, 90, true));
    assert(!allowed(60, 91, true));
    // Observed low-RequiredLevel database templates must not bypass the cap.
    assert(!allowed(60, 450, true));
    assert(!allowed(60, 600, true));

    // Existing overpowered armor must not demand an impossible replacement
    // weapon above the new cap. Ordinary level-60 weapon floors stay intact.
    assert(WeaponFloor(450, 60, true) == WeaponFloor(90, 60, true));
    assert(WeaponFloor(600, 60, true) <= MaximumItemLevel(60, true));
    assert(WeaponFloor(80, 60, true) == 45);

    // Reproduce Celenia: a level-90 pool healer scaled down to 61, still
    // wearing an upgraded Cranewing Cloak and raid armor.
    assert(!IsLevelAppropriate(61, 608, 90, true));
    assert(!IsLevelAppropriate(61, 569, 90, true));
    assert(!IsLevelAppropriate(61, 105, 62, true));
    assert(IsLevelAppropriate(61, 105, 61, true));
    assert(IsLevelAppropriate(61, 85, 60, true));
    // Bad RequiredLevel=0/1 templates must not bypass leveling budgets.
    for (unsigned level = 1; level < 90; ++level)
    {
        assert(!IsLevelAppropriate(level, 608, 0, true));
        assert(!IsLevelAppropriate(level, 600, 1, true));
        assert(!IsLevelAppropriate(level, 1, level + 1, true));
        assert(WeaponFloor(608, level, true) <= MaximumItemLevel(level, true));
        if (level > 1)
            assert(MaximumItemLevel(level - 1, true) <= MaximumItemLevel(level, true));
    }
    assert(IsLevelAppropriate(70, 164, 70, true));
    assert(IsLevelAppropriate(80, 284, 80, true));
    assert(IsLevelAppropriate(85, 416, 85, true));
    assert(IsLevelAppropriate(89, 450, 89, true));
    assert(IsLevelAppropriate(90, 608, 90, true));

    // Preserve existing level-90 and PvP item-level budgets.
    assert(allowed(60, 600, false));
    assert(allowed(70, 164, true));
    assert(allowed(90, 600, true));
    assert(WeaponFloor(600, 90, true) == 565);
    assert(WeaponFloor(500, 90, true) == 559);
}
