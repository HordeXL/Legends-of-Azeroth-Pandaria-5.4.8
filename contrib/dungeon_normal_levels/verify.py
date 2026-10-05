#!/usr/bin/env python3
"""Verify the level migration against real before/after MariaDB batch exports."""
import argparse
import csv
import json
import math
from pathlib import Path


def read_rows(path, keys):
    with open(path, newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t", quoting=csv.QUOTE_NONE))
    result = {tuple(row[key] for key in keys): row for row in rows}
    assert len(result) == len(rows), f"Duplicate keys in {path}"
    return result


parser = argparse.ArgumentParser(description=__doc__)
for name in ("templates_before", "templates_after", "difficulty_before", "difficulty_after", "class_stats"):
    parser.add_argument(name)
args = parser.parse_args()
expected = json.loads(Path(__file__).with_name("expected.json").read_text())
before = read_rows(args.templates_before, ("entry",))
after = read_rows(args.templates_after, ("entry",))
diff_before = read_rows(args.difficulty_before, ("id", "difficulty"))
diff_after = read_rows(args.difficulty_after, ("id", "difficulty"))
stats = read_rows(args.class_stats, ("level", "class"))

# Only the eight explicitly listed base level pairs may change.
expected_templates = {key: dict(row) for key, row in before.items()}
for fix in expected:
    key = (str(fix["id"]),)
    original = before[key]
    assert (int(original["minlevel"]), int(original["maxlevel"])) == (fix["oldmin"], fix["oldmax"])
    if fix["mode"] == "template":
        expected_templates[key]["minlevel"] = str(fix["min"])
        expected_templates[key]["maxlevel"] = str(fix["max"])
        assert (key[0], "DUNGEON_HEROIC") in diff_before
assert after == expected_templates, "Unexpected template changes"

# Existing heroic, challenge, raid and battleground records must be byte-identical.
assert all(diff_after.get(key) == row for key, row in diff_before.items()), "Existing difficulty data changed"
normal_ids = {str(fix["id"]) for fix in expected if fix["mode"] == "normal_override"}
assert set(diff_after) - set(diff_before) == {(entry, "DUNGEON_NORMAL") for entry in normal_ids}

for fix in expected:
    entry = str(fix["id"])
    template = after[(entry,)]
    normal = diff_after.get((entry, "DUNGEON_NORMAL"))
    levels = (int(normal["level_min"]), int(normal["level_max"])) if normal else (int(template["minlevel"]), int(template["maxlevel"]))
    assert levels == (fix["min"], fix["max"]), (entry, levels)
    if fix["mode"] != "normal_override":
        continue

    assert template["exp"] == "4"
    base = stats[(str(fix["min"]), template["unit_class"])]
    assert float(base["basehp4"]) > 1, f"Missing normal health stats: {entry}"
    damage = float(base["damage_exp4"])
    expected_stats = {"health_mod": float(template["Health_mod"]), "damage_mod": float(template["dmg_multiplier"])}
    for field in ("attackpower", "mindmg", "maxdmg", "rangedattackpower", "minrangedmg", "maxrangedmg"):
        if not damage:
            expected_stats[field] = float(template[field])
        elif field in ("attackpower", "rangedattackpower"):
            expected_stats[field] = float(base[field])
        else:
            expected_stats[field] = damage * (1.5 if field in ("maxdmg", "maxrangedmg") else 1)
    for field, value in expected_stats.items():
        assert math.isclose(float(normal[field]), value, rel_tol=1e-5), (entry, field, normal[field], value)

print(f"PASS: {len(expected)} normal level corrections; all other template fields and existing difficulty rows preserved.")
