#include "Map.h"
#include "VMapManager2.h"
#include "WorldModel.h"
#include <iostream>
#include <vector>
#include <cmath>
int main(){
 VMAP::VMapManager2 v; GridMap grid;
 char const* base="/home/server/World of Warcraft 5.4.8";
 std::string mapfile=std::string(base)+"/maps/0870_32_23.map";
 if(!grid.loadData(mapfile.data()))return 2;
 v.loadMap((std::string(base)+"/vmaps/").c_str(),870,32,23);
 struct P{float x,y,z,cx;};std::vector<P> targets;
 float altitude=0,low=1000;
 for(float cx:{-90.f,-160.f,-230.f})for(int i=0;i<81;++i){
  float x=cx+(i%9-4)*2, y=4650+(i/9-4)*2;
  float z=std::max(grid.getHeight(x,y),v.getHeight(870,x,y,1000,1000));
  if(z<0||z>130)return 3;
  targets.push_back({x,y,z,cx});altitude=std::max(altitude,z+25);low=std::min(low,z);
 }
 for(int i=0;i<=30;++i){float x=-90-140.f*i/30;float z=std::max(grid.getHeight(x,4650),v.getHeight(870,x,4650,1000,1000));altitude=std::max(altitude,z+25);}
 int blocked=0;float maxRange=0;
 for(auto p:targets){
  if(!v.isInLineOfSight(870,p.cx,4650,altitude,p.x,p.y,p.z+1,VMAP::ModelIgnoreFlags::Nothing))++blocked;
  maxRange=std::max(maxRange,std::sqrt((p.cx-p.x)*(p.cx-p.x)+(4650-p.y)*(4650-p.y)+(altitude-p.z)*(altitude-p.z)));
 }
 std::cout<<"targets="<<targets.size()<<" flight_z="<<altitude<<" lowest_ground="<<low<<" max_distance="<<maxRange<<" blocked_shots="<<blocked<<'\n';
 return blocked?1:0;
}
