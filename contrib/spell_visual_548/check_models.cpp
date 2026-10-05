// Read-only archive inventory; does not modify or extract game assets.
#include "StormLib.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cctype>

int main(int argc, char** argv)
{
    if (argc != 3) { std::cerr << "Usage: check_models <client Data directory> <models.txt>\n"; return 2; }
    std::vector<HANDLE> archives;
    unsigned failed = 0;
    for (auto const& entry : std::filesystem::recursive_directory_iterator(argv[1]))
    {
        if (!entry.is_regular_file()) continue;
        std::string extension = entry.path().extension().string();
        std::transform(extension.begin(), extension.end(), extension.begin(), [](unsigned char c) { return char(std::tolower(c)); });
        if (extension != ".mpq") continue;
        HANDLE archive;
        if (SFileOpenArchive(entry.path().string().c_str(), 0, MPQ_OPEN_READ_ONLY, &archive))
            archives.push_back(archive);
        else { std::cerr << "Unreadable archive: " << entry.path().filename().string() << '\n'; ++failed; }
    }
    std::ifstream models(argv[2]);
    if (!models || archives.empty()) { std::cerr << "Missing model list or archives\n"; return 2; }
    unsigned checked = 0, missing = 0;
    for (std::string model; std::getline(models, model);)
    {
        if (!model.empty() && model.back() == '\r') model.pop_back();
        if (model.empty()) continue;
        ++checked;
        bool found = false;
        for (HANDLE archive : archives)
            if (SFileHasFile(archive, model.c_str())) { found = true; break; }
        if (!found) { ++missing; std::cout << "MISSING " << model << '\n'; }
    }
    for (HANDLE archive : archives) SFileCloseArchive(archive);
    std::cout << "Archives=" << archives.size() << " unreadable=" << failed
        << " models=" << checked << " absent_from_archive_indexes=" << missing << '\n';
    // Index presence alone cannot prove patched model/texture rendering.
    return missing || failed ? 1 : 0;
}
