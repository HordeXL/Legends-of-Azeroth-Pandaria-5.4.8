# -*- coding: utf-8 -*-
"""
DBC patch: quest 29907 "Chen and Li Li" summon spells permanent duration.

Spell.dbc 105835 (Summon Chen) / 105836 (Summon Li Li) -> SpellMiscId 81233/81234
(both exclusively owned). Their DurationIndex=25 (180000 ms = 3 min) makes the
summoned walking Chen/Li Li despawn mid-scene. Point DurationIndex to row 21
(duration = -1, permanent) so the NPCs persist after sitting down at the farm.

Usage: python patch_spell_105835_summon_duration.py --apply | --verify
Rollback: restore .bak files next to the DBCs.
"""
import struct, sys, shutil, os

DBC = r"F:/LOA-Pandaria-5.4.8-Release/Data/dbc"
STAMP = "20260927_29907"
TARGET = {81233: "misc_105835_summon_chen", 81234: "misc_105836_summon_lili"}
DUR_COL = 18          # SpellMisc.dbc DurationIndex
PERMANENT_IDX = 21    # SpellDuration row 21: duration = -1

def load(path):
    d = open(path, 'rb').read()
    magic, rc, fc, rs, sb = struct.unpack_from('<5I', d, 0)
    assert magic == 0x43424457, (path, hex(magic))
    return bytearray(d), rc, rs

def main(apply: bool):
    f = os.path.join(DBC, "SpellMisc.dbc")
    bak = f + f".bak_{STAMP}"
    data, rc, rs = load(f)
    n = rs // 4

    # locate rows
    hits = {}
    for i in range(rc):
        off = 20 + i * rs
        rid = struct.unpack_from('<i', data, off)[0]
        if rid in TARGET:
            hits[rid] = off
    assert len(hits) == len(TARGET), f"missing rows: {hits}"

    print(f"SpellMisc.dbc: {rc} rows, rec_size={rs}")
    for rid, off in hits.items():
        old = struct.unpack_from('<i', data, off + DUR_COL * 4)[0]
        print(f"  {TARGET[rid]} (MiscId {rid}): DurationIndex {old} -> {PERMANENT_IDX if apply else '(verify)'}")
        if apply:
            struct.pack_into('<i', data, off + DUR_COL * 4, PERMANENT_IDX)

    if apply:
        if not os.path.exists(bak):
            shutil.copy2(f, bak)
            print(f"backup written: {bak}")
        tmp = f + ".tmp"
        open(tmp, 'wb').write(bytes(data))
        os.replace(tmp, f)
        print("APPLIED, re-verifying from disk...")

    # verify by re-reading from disk
    data2, rc2, _ = load(f)
    ok = rc2 == rc
    for rid in hits:
        off = 20 + hits[rid]  # same offsets since size unchanged
        # offsets may shift if rows reordered -- re-locate to be safe
    hits2 = {}
    for i in range(rc2):
        off = 20 + i * rs
        rid = struct.unpack_from('<i', data2, off)[0]
        if rid in TARGET:
            hits2[rid] = off
    ok = ok and len(hits2) == len(TARGET)
    for rid, off in hits2.items():
        v = struct.unpack_from('<i', data2, off + DUR_COL * 4)[0]
        want = PERMANENT_IDX if apply else 25
        print(f"  verify {rid}: DurationIndex={v} expect={want} {'OK' if v == want else 'FAIL'}")
        ok = ok and v == want
    print("VERIFY PASSED" if ok else "VERIFY FAILED")
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main("--apply" in sys.argv)
