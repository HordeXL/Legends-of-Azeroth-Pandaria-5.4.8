#!/usr/bin/env python3
"""Exercise production CalculatePath with non-unit owners and loaded navigation."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/game/Movement/PathGenerator.cpp').read_text()
method = source[source.index('bool PathGenerator::CalculatePath('):source.index('dtPolyRef PathGenerator::GetPathPolyByPosition(')]
fixture = r'''
#include <cassert>
#include <cmath>
#define TC_LOG_DEBUG(...) ((void)0)
namespace G3D { struct Vector3 { Vector3(float, float, float) {} }; }
namespace Trinity { bool IsValidMapCoord(float x, float y, float z) {
    return std::isfinite(x) && std::isfinite(y) && std::isfinite(z);
} }
struct Position {
    Position(float, float, float, float) {}
    float GetExactDist2d(float, float) { return 100; }
};
enum { UNIT_STATE_IGNORE_PATHFINDING, PATHFIND_NORMAL = 1, PATHFIND_NOT_USING_PATH = 2 };
using PathType = int;
struct Unit {
    bool VisualizePathfinding = false;
    bool HasUnitState(int) const { return false; }
};
struct WorldObject {
    Unit* unit = nullptr;
    void GetPosition(float& x, float& y, float& z) const { x = y = z = 1; }
    void UpdateAllowedPositionZ(float, float, float&) const {}
    int GetMapId() const { return 870; }
    Unit const* ToUnit() const { return unit; }
};
struct PathGenerator {
    WorldObject const* _source;
    bool _forceDestination = false, _navMesh = true, _navMeshQuery = true;
    int _type = 0, paths = 0, shortcuts = 0, visualizations = 0;
    explicit PathGenerator(WorldObject const* owner) : _source(owner) {}
    void SetEndPosition(G3D::Vector3) {}
    void SetStartPosition(G3D::Vector3) {}
    bool HaveTile(G3D::Vector3) { return true; }
    void BuildShortcut() { ++shortcuts; }
    void UpdateFilter() {}
    void BuildPolyPath(G3D::Vector3, G3D::Vector3) { ++paths; }
    void VisualizePath(int) { ++visualizations; }
    void VisualizeNavmesh(int) { ++visualizations; }
    bool CalculatePath(float, float, float, bool = false, bool = false, bool = false);
};
// METHOD
int main() {
    WorldObject tower;
    PathGenerator goPath(&tower);
    assert(goPath.CalculatePath(8, 0, 1));
    assert(goPath.paths == 1 && goPath.visualizations == 0);
    goPath._navMesh = false;
    assert(goPath.CalculatePath(8, 0, 1));
    assert(goPath.shortcuts == 1);
    assert(!goPath.CalculatePath(NAN, 0, 1));
    Unit unit;
    WorldObject creature;
    creature.unit = &unit;
    PathGenerator unitPath(&creature);
    assert(unitPath.CalculatePath(8, 0, 1));
    assert(unitPath.paths == 1 && unitPath.visualizations == 0);
    unit.VisualizePathfinding = true;
    assert(unitPath.CalculatePath(8, 0, 1));
    assert(unitPath.paths == 2 && unitPath.visualizations == 2);
}
'''
with tempfile.TemporaryDirectory(prefix='kypari-path-') as directory:
    cpp = Path(directory) / 'test.cpp'
    binary = Path(directory) / 'test'
    cpp.write_text(fixture.replace('// METHOD', method))
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror',
                    '-Wno-unused-parameter', '-fsanitize=undefined',
                    '-fno-sanitize-recover=all', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
print('PASS: GameObject and Unit path owners, navigation fallback, invalid coordinates, visualization')
