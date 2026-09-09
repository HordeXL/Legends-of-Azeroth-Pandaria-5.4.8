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
        std::map<std::uint32_t, std::uint32_t> levelRecords, spellLevels;
        std::map<std::uint32_t, std::set<std::uint32_t>> spellSpecs;
        std::set<std::uint32_t> talentIds;
        for (auto const& row : ReadDBC(directory, "SpellLevels"))
            levelRecords[row[0]] = row[5];
        for (auto const& row : ReadDBC(directory, "Spell"))
        {
            families[row[0]] = optionFamilies[row[14]];
            spellLevels[row[0]] = levelRecords[row[18]];
        }
        for (auto const& row : abilities)
        {
            if (skillCategories[row[1]] == 7)
                owners[row[2]] |= row[4];
            else
                protectedSpells.insert(row[2]);
        }
        for (auto const& row : specSpells)
            if (auto owner = specClasses[row[1]])
            {
                owners[row[2]] |= std::uint32_t(1) << (owner - 1);
                spellSpecs[row[2]].insert(row[1]);
            }
        for (auto const& row : talents)
        {
            owners[row[4]] |= std::uint32_t(1) << (row[8] - 1);
            talentIds.insert(row[4]);
        }
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

        // Exercise the actual learning policy separately: learn-my-spells must
        // not use GM learn-all-talents semantics. Drive it with each real spec,
        // including generic/level-zero abilities and talents listed as baseline
        // skills (Hunter Intimidation and Paladin Sacred Shield).
        auto learnable = [&](std::uint32_t cls, std::uint32_t spec, std::uint32_t level)
        {
            std::uint32_t mask = std::uint32_t(1) << (cls - 1);
            std::set<std::uint32_t> classSkills, baseline, active, result;
            for (auto const& row : abilities)
                if (skillCategories[row[1]] == 7 && (row[4] & mask))
                    classSkills.insert(row[1]);
            for (auto const& row : abilities)
                if (classSkills.count(row[1]) && (!row[4] || (row[4] & mask)))
                    baseline.insert(row[2]);
            for (auto const& row : specSpells)
                if (row[1] == spec)
                    active.insert(row[2]);
            auto candidates = baseline;
            candidates.insert(active.begin(), active.end());
            candidates.insert(talentIds.begin(), talentIds.end());
            for (auto spell : candidates)
                if (spellLevels.count(spell) && ClassSpellCommandPolicy::Learn(level, spellLevels[spell],
                    talentIds.count(spell) != 0, baseline.count(spell) != 0,
                    active.count(spell) != 0, !spellSpecs[spell].empty()))
                    result.insert(spell);
            return result;
        };
        unsigned playerSpecs = 0;
        for (auto const& spec : specClasses)
            if (classFamilies.count(spec.second))
            {
                ++playerSpecs;
                for (auto level : {1u, 10u, 90u})
                {
                    auto result = learnable(spec.second, spec.first, level);
                    for (auto talent : talentIds)
                        Check(!result.count(talent), "Learn-my-spells granted a talent: " + std::to_string(talent));
                    for (auto spell : result)
                    {
                        Check(spellLevels[spell] <= level, "Learned a spell above player level");
                        Check(spellSpecs[spell].empty() || spellSpecs[spell].count(spec.first), "Learned inactive-spec spell");
                    }
                }
            }
        Check(playerSpecs == 34, "Expected 34 player specializations");
        auto affliction = learnable(9, 265, 90);
        for (auto spell : {686u, 172u, 1454u, 980u, 30108u, 103103u, 1120u, 117198u, 131973u, 86091u})
            Check(affliction.count(spell) != 0, "Affliction restoration missed " + std::to_string(spell));
        for (auto spell : {116858u, 103958u, 109260u, 108415u})
            Check(!affliction.count(spell), "Affliction learned an off-spec/foreign/talent spell");
        Check(!learnable(3, 253, 90).count(19577), "Hunter Intimidation bypassed talent choice");
        Check(!learnable(2, 65, 90).count(20925), "Paladin Sacred Shield bypassed talent choice");
        auto noSpec = learnable(9, 0, 90);
        Check(noSpec.count(686) && !noSpec.count(103103), "No-spec character received specialization spells");
        std::cout << "Learn-my-spells checked for 34 specs at levels 1, 10 and 90.\n";
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
