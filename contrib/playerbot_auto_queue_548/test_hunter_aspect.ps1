$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$source = Get-Content -Raw "$root/modules/mod_playerbots/src/strategy/Classes/hunter/HunterActions.cpp"
$body = [regex]::Match($source, 'bool CastAspectOfTheHawkAction::isUseful\(\)\s*\{[\s\S]*?\n\}').Value
if (!$body) { throw 'Production Hunter aspect method not found' }
# Compile the actual production method with only spell/aura availability stubbed.
$prefix = @'
#include <set>
#include <iostream>
#include <cstdlib>
using uint32 = unsigned int;
struct Player {
    std::set<uint32> spells, auras;
    bool HasSpell(uint32 id) { return spells.count(id) != 0; }
    bool HasAura(uint32 id) { return auras.count(id) != 0; }
};
struct CastSpellAction {
    bool available = true;
    bool isUseful() { return available; }
};
struct CastAspectOfTheHawkAction : CastSpellAction {
    Player* bot;
    bool isUseful();
};
'@
$suffix = @'
int main() {
    unsigned checks = 0;
    auto check = [&](bool ok) { ++checks; if (!ok) std::exit(1); };
    Player bot; CastAspectOfTheHawkAction action; action.bot = &bot;
    check(!action.isUseful());
    bot.spells = {13165}; check(action.isUseful());
    bot.auras = {13165}; check(!action.isUseful());
    bot.spells.insert(109260); check(action.isUseful());
    bot.auras = {109260}; check(!action.isUseful());
    for (int i = 0; i < 124; ++i) check(!action.isUseful());
    bot.auras.clear(); check(action.isUseful());
    action.available = false; check(!action.isUseful());
    action.available = true; bot.spells = {13165}; bot.auras = {109260};
    check(action.isUseful());
    std::cout << "Hunter aspect: " << checks << " checks passed\n";
}
'@
Push-Location $root
try {
    Set-Content -LiteralPath Build/hunter_aspect_regression.cpp -Value ($prefix + "`n" + $body + "`n" + $suffix) -Encoding UTF8
    & cl.exe /nologo /EHsc /std:c++17 Build/hunter_aspect_regression.cpp /Fo:Build/hunter_aspect_regression.obj /Fe:Build/hunter_aspect_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Hunter aspect test compilation failed' }
    & ./Build/hunter_aspect_regression.exe
    if ($LASTEXITCODE -ne 0) { throw 'Hunter aspect regression failed' }
} finally { Pop-Location }
