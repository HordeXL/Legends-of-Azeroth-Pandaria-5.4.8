#include "../../src/server/scripts/Commands/ClassSpellCommandPolicy.h"
#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

using Row = std::vector<std::uint32_t>;

static std::vector<Row> ReadDBC(std::string const& directory, char const* name)
{
    std::ifstream file(directory + "/" + name + ".dbc", std::ios::binary);
    std::uint32_t header[5] = {};
    file.read(reinterpret_cast<char*>(header), sizeof(header));
    if (!file || header[0] != 0x43424457 || header[3] != header[2] * 4)
        throw std::runtime_error(std::string("Invalid WDBC: ") + name);
    std::vector<Row> rows(header[1], Row(header[2]));
    for (auto& row : rows)
        file.read(reinterpret_cast<char*>(row.data()), header[3]);
    if (!file)
        throw std::runtime_error(std::string("Truncated WDBC: ") + name);
    return rows;
}

static unsigned checks = 0;
static void Check(bool passed, std::string const& message)
{
    ++checks;
    if (!passed)
        throw std::runtime_error(message);
}

int main(int argc, char** argv)
{
    try
    {
        if (argc != 2)
            throw std::runtime_error("Pass the local build-18414 DBC directory");
        std::string directory = argv[1];
        auto classes = ReadDBC(directory, "ChrClasses");
        auto talents = ReadDBC(directory, "Talent");
        auto abilities = ReadDBC(directory, "SkillLineAbility");
        auto specSpells = ReadDBC(directory, "SpecializationSpells");
        std::map<std::uint32_t, std::uint32_t> skillCategories, specClasses, owners, families, classFamilies;
        std::map<std::uint32_t, std::uint32_t> optionFamilies;
        std::set<std::uint32_t> protectedSpells;
        for (auto const& row : classes)
            classFamilies[row[0]] = row[7];
        for (auto const& row : ReadDBC(directory, "SkillLine"))
            skillCategories[row[0]] = row[1];
        for (auto const& row : ReadDBC(directory, "ChrSpecialization"))
            specClasses[row[0]] = row[2];
        for (auto const& row : ReadDBC(directory, "SpellClassOptions"))
            optionFamilies[row[0]] = row[6];
        for (auto const& row : ReadDBC(directory, "Spell"))
            families[row[0]] = optionFamilies[row[14]];
        for (auto const& row : abilities)
        {
            if (skillCategories[row[1]] == 7)
                owners[row[2]] |= row[4];
            else
                protectedSpells.insert(row[2]);
        }
        for (auto const& row : specSpells)
            if (auto owner = specClasses[row[1]])
                owners[row[2]] |= std::uint32_t(1) << (owner - 1);
        for (auto const& row : talents)
            owners[row[4]] |= std::uint32_t(1) << (row[8] - 1);
        for (auto const& row : ReadDBC(directory, "SpellEffect"))
            if (row[4] == 78 || row[2] == 74) // Mounted aura or glyph unlock.
                protectedSpells.insert(row[27]);

        auto selected = [&](std::uint32_t playerClass, std::uint32_t spell)
        {
            return ClassSpellCommandPolicy::Select(std::uint32_t(1) << (playerClass - 1),
                classFamilies.at(playerClass), families.at(spell), owners[spell], protectedSpells.count(spell) != 0);
        };

        Check(classes.size() == 11, "Expected all 11 MoP player classes");
        unsigned missingSpellRows = 0;
        for (auto const& cls : classes)
        {
            unsigned ownTalents = 0, specCount = 0;
            for (auto const& talent : talents)
            {
                bool own = talent[8] == cls[0];
                Check(selected(cls[0], talent[4]) == own, "Talent class leak: " + std::to_string(talent[4]));
                ownTalents += own;
            }
            Check(ownTalents == 18, "Expected 18 own-class talents");
            for (auto const& spell : specSpells)
                if (specClasses[spell[1]] == cls[0])
                {
                    // The core also skips specialization rows whose spell no
                    // longer exists (build 18414 contains stale ID 117197).
                    if (!families.count(spell[2]))
                    {
                        ++missingSpellRows;
                        continue;
                    }
                    Check(selected(cls[0], spell[2]) || protectedSpells.count(spell[2]),
                        "Missed specialization spell: " + std::to_string(spell[2]));
                    ++specCount;
                }
            // Shared skill lines must survive for every class, even if their
            // spell happens to have a matching family or class mask.
            for (auto spell : protectedSpells)
                if (families.count(spell))
                    Check(!selected(cls[0], spell), "Shared skill/glyph/mount selected: " + std::to_string(spell));
            std::cout << "Class " << cls[0] << ": 18 talents; " << specCount << " specialization rows checked\n";
        }

        // Real regressions missed by spell-family-only ownership.
        for (auto spell : {77801u, 93375u, 117198u, 131973u})
            Check(selected(9, spell), "Warlock generic-family ability omitted");
        Check(selected(6, 3714), "DK Path of Frost omitted");
        Check(!selected(6, 54729), "DK flying mount must survive");
        Check(selected(4, 31209), "Rogue Fleet Footed omitted");
        Check(selected(7, 116956), "Shaman Grace of Air omitted");
        Check(!selected(9, 109260), "Hunter Iron Hawk selected on Warlock");
        for (auto spell : {26297u, 7620u, 2550u, 2259u, 33388u, 56271u, 56301u, 63941u, 135560u})
            Check(!selected(9, spell), "Warlock shared skill/glyph protection failed");
        Check(!ClassSpellCommandPolicy::Select(256, 5, 0, 0, false), "Unknown generic spell must survive");
        Check(!ClassSpellCommandPolicy::Select(256, 5, 5, 4, false), "Explicit foreign ownership must beat family");
        Check(ClassSpellCommandPolicy::Select(256, 5, 5, 0, false), "Internal class-family fallback lost");
        std::cout << checks << " production-policy checks passed against local DBC data.\n";
        std::cout << missingSpellRows << " stale specialization rows skipped (missing Spell.dbc entry).\n";
        return 0;
    }
    catch (std::exception const& error)
    {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
