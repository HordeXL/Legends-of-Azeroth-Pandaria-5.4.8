#include "Config.h"
#include "MMapManager.h"
#include <iostream>

// Uses the real loader and a known local navigation tile, without changing data.
int main(int argc, char** argv)
{
    if (argc != 2)
        return 2;
    std::string error;
    if (!sConfigMgr->LoadInitial(argv[1], {}, error))
    {
        std::cerr << error << '\n';
        return 2;
    }

    MMAP::MMapManager manager;
    bool first = manager.loadMap(0, 31, 31);
    auto mesh = manager.GetNavMesh(0);
    auto count = manager.getLoadedTilesCount();
    bool repeated = manager.loadMap(0, 31, 31);
    bool unchanged = manager.GetNavMesh(0) == mesh && manager.getLoadedTilesCount() == count;
    bool missing = manager.loadMap(0, 63, 63);
    bool missingUnchanged = manager.getLoadedTilesCount() == count;
    bool unloaded = manager.unloadMap(0, 31, 31) && manager.getLoadedTilesCount() == 0;
    bool reloaded = manager.loadMap(0, 31, 31) && manager.getLoadedTilesCount() == count;
    std::cout << "first=" << first << " repeated=" << repeated
              << " unchanged=" << unchanged << " missing=" << missing
              << " missingUnchanged=" << missingUnchanged
              << " unloaded=" << unloaded << " reloaded=" << reloaded << '\n';
    return first && mesh && count == 1 && repeated && unchanged && !missing &&
        missingUnchanged && unloaded && reloaded ? 0 : 1;
}
