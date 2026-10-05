#ifndef TEST_ITEM_FILTER_H
#define TEST_ITEM_FILTER_H

#include <cstdint>
#include <regex>
#include <string>

// Internal test/GM items and the retired custom VIP gear must not be stocked
// by AHBot if a future database import accidentally restores their templates.
inline bool IsInternalTestOrVipItem(std::uint32_t entry, std::string const& name)
{
    // Genuine quest/reward items whose names use "test" in its ordinary sense.
    if (entry == 8523 || entry == 8527 || entry == 19971 || entry == 69217)
        return false;
    if (entry == 17 || entry == 192 || entry == 23443 || entry == 24115)
        return true;
    if (entry >= 990000 && name.compare(0, 3, "VIP") == 0)
        return true;

    static std::regex const marker(
        "(^|[^a-z])(test(ing)?[0-9]*|debug|gamemaster|qatest|jefftest)([^a-z]|$)",
        std::regex::icase);
    return std::regex_search(name, marker);
}

#endif
