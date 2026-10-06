// The runner extracts the account-selection function from production source.
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
using uint32 = unsigned;
struct Config
{
    bool playerbotPoolEnabled = false;
    std::vector<uint32> playerbotPoolAccounts;
    std::vector<uint32> randomBotAccounts;
} config;
Config* sPlayerbotAIConfig = &config;
#include "account_pool_function.h"

unsigned checks = 0;
void Expect(char const* expected, char const* scenario)
{
    if (GetAutoQueueAccountSqlList() != expected)
    {
        std::cerr << "FAIL: " << scenario << '\n';
        std::exit(1);
    }
    ++checks;
}

int main()
{
    config.randomBotAccounts = { 10, 12, 97 };
    Expect("10,12,97", "disabled dedicated pool retains existing bots and excludes ID gaps");
    config.playerbotPoolAccounts = { 500, 502 };
    Expect("10,12,97", "disabled pool ignores stale dedicated account IDs");
    config.playerbotPoolEnabled = true;
    Expect("500,502", "enabled dedicated pool does not mix in random accounts");
    config.playerbotPoolAccounts.clear();
    Expect("", "empty enabled pool must not use unrelated accounts");
    config.playerbotPoolEnabled = false;
    config.randomBotAccounts.clear();
    Expect("", "empty fallback pool produces no SQL candidates");
    config.randomBotAccounts = { 42 };
    Expect("42", "single account has no extra delimiter");
    config.randomBotAccounts = { 97, 10, 12 };
    Expect("97,10,12", "non-sorted accounts still use exact IDs");
    std::cout << checks << " account-pool regression checks passed\n";
}
