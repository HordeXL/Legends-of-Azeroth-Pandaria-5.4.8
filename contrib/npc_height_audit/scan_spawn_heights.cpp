#include "Map.h"
#include "VMapManager2.h"
#include <fstream>
#include <iostream>
#include <iomanip>
#include <memory>
#include <cmath>
int main(int argc, char** argv) {
    if (argc != 3) return 2;
    std::ifstream input(argv[2]);
    VMAP::VMapManager2 vmap;
    std::unique_ptr<GridMap> grid;
    uint32 guid, entry, map, lastMap=~0u; int lastX=-1,lastY=-1;
    float x,y,z; bool terrainLoaded=false; int vmapStatus=0;
    std::cout << "guid\tentry\tmap\tx\ty\tz\tterrain_z\tvmap_below\tvmap_above\tvmap_status\n";
    while (input >> guid >> entry >> map >> x >> y >> z) {
        int gx=int(32-x/533.33333333f), gy=int(32-y/533.33333333f);
        if (map!=lastMap || gx!=lastX || gy!=lastY) {
            if (lastMap!=~0u) vmap.unloadMap(lastMap);
            grid.reset(new GridMap());
            char file[2048]; snprintf(file,sizeof(file),"%s/maps/%04u_%02u_%02u.map",argv[1],map,gx,gy);
            std::ifstream check(file); terrainLoaded=check.good() && grid->loadData(file);
            std::string vm=std::string(argv[1])+"/vmaps/";
            vmapStatus=vmap.loadMap(vm.c_str(),map,gx,gy);
            lastMap=map;lastX=gx;lastY=gy;
        }
        float terrain=terrainLoaded?grid->getHeight(x,y):-100000.f;
        float below=vmap.getHeight(map,x,y,z+0.5f,200.f);
        float above=vmap.getHeight(map,x,y,z+15.f,215.f);
        std::cout << guid << '\t' << entry << '\t' << map << '\t' << std::setprecision(9) << x << '\t' << y << '\t' << z << '\t' << terrain << '\t' << below << '\t' << above << '\t' << vmapStatus << '\n';
    }
}
