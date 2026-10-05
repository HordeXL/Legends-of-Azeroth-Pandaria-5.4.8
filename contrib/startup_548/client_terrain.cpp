// Read-only comparison with the same patched MPQ chain as map_extractor.
#define NOMINMAX
#include "StormLib.h"
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>

static unsigned U32(std::vector<char> const& b, size_t p)
{
    unsigned v; std::memcpy(&v, b.data() + p, 4); return v;
}
static float F32(std::vector<char> const& b, size_t p)
{
    float v; std::memcpy(&v, b.data() + p, 4); return v;
}
static bool Read(HANDLE mpq, std::string const& name, std::vector<char>& bytes)
{
    HANDLE file;
    if (!SFileOpenFileEx(mpq, name.c_str(), SFILE_OPEN_PATCHED_FILE, &file)) return false;
    DWORD size = SFileGetFileSize(file, nullptr), read = 0;
    bytes.resize(size);
    bool ok = SFileReadFile(file, bytes.data(), size, &read, nullptr) && read == size;
    SFileCloseFile(file);
    return ok;
}
int main(int argc, char** argv)
{
    if (argc != 3) return 2;
    std::filesystem::path data(argv[1]);
    HANDLE mpq;
    if (!SFileOpenArchive((data / "world.MPQ").string().c_str(), 0, MPQ_OPEN_READ_ONLY, &mpq)) return 2;
    auto patch = [&](std::filesystem::path const& path) {
        if (!SFileOpenPatchArchive(mpq, path.string().c_str(), "", 0)) {
            std::cerr << "Cannot open patch " << path.filename().string() << '\n'; return false;
        }
        return true;
    };
    for (auto name : {"model.MPQ", "misc.MPQ", "expansion1.MPQ", "expansion2.MPQ", "expansion3.MPQ", "expansion4.MPQ"})
        if (!patch(data / name)) return 2;
    unsigned const builds[] = {16016,16048,16057,16309,16357,16516,16650,16844,16965,17116,17266,17325,17345,17538,17645,17688,17898,18273};
    for (unsigned build : builds)
        if (!patch(data / ("wow-update-base-" + std::to_string(build) + ".MPQ"))) return 2;
    for (unsigned build : builds) {
        auto path = data / "Cache" / ("patch-base-" + std::to_string(build) + ".MPQ");
        if (std::filesystem::exists(path) && !patch(path)) return 2;
    }
    std::map<unsigned, std::string> names{{0,"Azeroth"},{530,"Expansion01"},{571,"Northrend"},{974,"DarkmoonFaire"},{1064,"MoguIslandDailyArea"}};
    std::ifstream input(argv[2]);
    if (!input) return 2;
    std::cout << "map,gx,gy,wdt_flags,adt_readable,chunks,min_height,max_height\n";
    unsigned map, gx, gy;
    while (input >> map >> gx >> gy) {
        if (gx >= 64 || gy >= 64 || !names.count(map)) return 2;
        auto name = names.at(map), base = "World\\Maps\\" + name + "\\" + name;
        std::vector<char> wdt, adt;
        if (!Read(mpq, base + ".wdt", wdt)) return 2;
        unsigned flags = ~0u;
        for (size_t p = 0; p + 8 <= wdt.size();) {
            unsigned size = U32(wdt, p + 4);
            if (size > wdt.size() - p - 8) return 2;
            if (!std::memcmp(wdt.data() + p, "NIAM", 4) && size >= 64 * 64 * 8)
                flags = U32(wdt, p + 8 + (gx * 64 + gy) * 8);
            p += 8 + size;
        }
        if (flags == ~0u) return 2;
        bool readable = Read(mpq, base + "_" + std::to_string(gy) + "_" + std::to_string(gx) + ".adt", adt);
        unsigned chunks = 0; float low = 1e9f, high = -1e9f;
        if (readable) for (size_t p = 0; p + 8 <= adt.size();) {
            unsigned size = U32(adt, p + 4);
            if (size > adt.size() - p - 8) return 2;
            if (!std::memcmp(adt.data() + p, "KNCM", 4) && size >= 128) {
                ++chunks;
                // Matches adt_MCNK::ypos and the nested-chunk scan in adt.cpp.
                float z = F32(adt, p + 8 + 112);
                bool heights = false;
                for (size_t sub = p + 8 + 128; sub + 8 <= p + 8 + size;) {
                    unsigned subSize = U32(adt, sub + 4);
                    if (subSize > p + 8 + size - sub - 8) return 2;
                    if (!std::memcmp(adt.data() + sub, "TVCM", 4)) {
                        if (subSize < 145 * 4) return 2;
                        for (unsigned i = 0; i < 145; ++i) {
                            float height = z + F32(adt, sub + 8 + i * 4);
                            low = std::min(low, height); high = std::max(high, height);
                        }
                        heights = true;
                        break;
                    }
                    sub += 8 + subSize;
                }
                if (!heights) { low = std::min(low, z); high = std::max(high, z); }
            }
            p += 8 + size;
        }
        std::cout << map << ',' << gx << ',' << gy << ',' << flags << ',' << readable << ',' << chunks << ',';
        if (chunks) std::cout << low;
        std::cout << ',';
        if (chunks) std::cout << high;
        std::cout << '\n';
        if ((flags & 1) && !readable) return 1;
    }
    SFileCloseArchive(mpq);
    return 0;
}
