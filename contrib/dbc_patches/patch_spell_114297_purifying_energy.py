#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务 30502《灵玉之心》——让"天神灵玉"真正削弱邪煞残影

背景
----
物品 80074「天神灵玉(Celestial Jade)」使用后施放法术 114297「纯净能量」
（描述：可以用来削弱邪煞残影）。但 114297 在 DBC 里只是一个
SPELL_AURA_DUMMY 光环（BasePoints=5），核心源码没有任何处理器，
所以使用灵玉毫无效果，是彻底的死代码。

本补丁把 114297 的假光环改成真实削弱效果：
  * EffectApplyAuraName : 4 (DUMMY)            -> 87 (MOD_DAMAGE_PERCENT_TAKEN)
  * EffectBasePoints    : 5                    -> 100   （受到的伤害提高 100%）
  * EffectMiscValue     : 0                    -> 127   （SPELL_SCHOOL_MASK_ALL）
  * SpellMisc.DurationIndex: 27 (3 秒)         -> 3 (60 秒)
  * SpellMisc.AttributesEx : 清除 0x4 (SPELL_ATTR1_CHANNELED_1)
    —— 原法术为引导型，引导时长=duration；清除后瞬发施放，60 秒纯 debuff，
       玩家扔完灵玉立即可跑位/战斗，不再出现"引导 60 秒被打死"的问题。
    （施法时间本身是 CastTimes idx 1 = 0ms 瞬发，长引导完全来自该引导位。）

安全性
------
* SpellMiscId=87414 经全表扫描确认只被法术 114297 引用，改时长不波及其它法术。
* 114297 在 SpellEffect.dbc 中只有 1 条效果行，且没有任何法术触发它。
* 注意：59454 / 59455 只是与生物 entry 撞号，实为战士技能「致死打击」，
  本补丁绝不触碰。

用法
----
  python patch_spell_114297_purifying_energy.py --apply    # 应用
  python patch_spell_114297_purifying_energy.py --verify   # 仅校验

回滚: 把 SpellEffect.dbc / SpellMisc.dbc 换回 *.bak_20260925_q30502 即可。
改动需重启 worldserver 生效（DBC 只在启动时加载）。
"""

import os
import struct
import sys

DBC_DIR = r"F:/LOA-Pandaria-5.4.8-Release/Data/dbc"

SPELL_ID = 114297
NEW_AURA = 87        # SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN
NEW_BASE_POINTS = 100
NEW_MISC_VALUE = 127  # SPELL_SCHOOL_MASK_ALL
NEW_DURATION_INDEX = 3  # SpellDuration.dbc: 60000ms

# SpellEffectEntry
F_EFFECT_AURA = 4
F_BASE_POINTS = 6
F_MISC_VALUE = 13
F_SPELL_ID = 27
F_EFFECT_INDEX = 28

# SpellMiscEntry
F_MISC_DURATION_INDEX = 18
F_ATTR_EX = 4               # SpellMisc.AttributesEx
CHANNEL_BIT = 0x00000004    # SPELL_ATTR1_CHANNELED_1 —— 清除后瞬发施放

# SpellEntry
F_SPELL_MISC_ID = 24


def load(path):
    with open(path, "rb") as fh:
        data = bytearray(fh.read())
    magic, rec_count, field_count, rec_size, str_size = struct.unpack_from("<5I", data, 0)
    return data, rec_count, rec_size, rec_size // 4


def row_at(data, index, rec_size, fields):
    return list(struct.unpack_from("<%di" % fields, data, 20 + index * rec_size))


def find_rows(data, rec_count, rec_size, fields, field_index, value):
    for i in range(rec_count):
        row = row_at(data, i, rec_size, fields)
        if row[field_index] == value:
            yield i, row


def main():
    mode = "--verify" if "--verify" in sys.argv else "--apply"

    # ---- Spell.dbc: 拿到 114297 的 SpellMiscId ----
    sdata, src, srs, sf = load(os.path.join(DBC_DIR, "Spell.dbc"))
    misc_id = None
    for i, row in find_rows(sdata, src, srs, sf, 0, SPELL_ID):
        misc_id = row[F_SPELL_MISC_ID]
        break
    if misc_id is None:
        raise SystemExit("Spell.dbc 中找不到法术 %d" % SPELL_ID)

    # ---- SpellEffect.dbc ----
    edata, erc, ers, ef = load(os.path.join(DBC_DIR, "SpellEffect.dbc"))
    effect_idx = None
    for i, row in find_rows(edata, erc, ers, ef, F_SPELL_ID, SPELL_ID):
        effect_idx = i
        print("  [改前] SpellEffect Id=%d Idx=%d Effect=%d Aura=%d BasePts=%d MiscVal=%d"
              % (row[0], row[F_EFFECT_INDEX], row[2], row[F_EFFECT_AURA],
                 row[F_BASE_POINTS], row[F_MISC_VALUE]))
        if mode == "--apply":
            row[F_EFFECT_AURA] = NEW_AURA
            row[F_BASE_POINTS] = NEW_BASE_POINTS
            row[F_MISC_VALUE] = NEW_MISC_VALUE
            struct.pack_into("<%di" % ef, edata, 20 + i * ers, *row)
        break
    if effect_idx is None:
        raise SystemExit("SpellEffect.dbc 中找不到法术 %d 的效果行" % SPELL_ID)

    # ---- SpellMisc.dbc ----
    mdata, mrc, mrs, mf = load(os.path.join(DBC_DIR, "SpellMisc.dbc"))
    misc_hit = False
    for i, row in find_rows(mdata, mrc, mrs, mf, 0, misc_id):
        misc_hit = True
        print("  [改前] SpellMisc Id=%d DurationIndex=%d AttributesEx=0x%X"
              % (row[0], row[F_MISC_DURATION_INDEX], row[F_ATTR_EX]))
        if mode == "--apply":
            row[F_MISC_DURATION_INDEX] = NEW_DURATION_INDEX
            row[F_ATTR_EX] &= ~CHANNEL_BIT
            struct.pack_into("<%di" % mf, mdata, 20 + i * mrs, *row)
        break
    if not misc_hit:
        raise SystemExit("SpellMisc.dbc 中找不到 Id=%d" % misc_id)

    if mode == "--apply":
        with open(os.path.join(DBC_DIR, "SpellEffect.dbc"), "wb") as fh:
            fh.write(edata)
        with open(os.path.join(DBC_DIR, "SpellMisc.dbc"), "wb") as fh:
            fh.write(mdata)
        print("已写入。")

    # ---- 回读校验 ----
    edata, erc, ers, ef = load(os.path.join(DBC_DIR, "SpellEffect.dbc"))
    mdata, mrc, mrs, mf = load(os.path.join(DBC_DIR, "SpellMisc.dbc"))
    for i, row in find_rows(edata, erc, ers, ef, F_SPELL_ID, SPELL_ID):
        print("  [改后] SpellEffect Id=%d Idx=%d Effect=%d Aura=%d BasePts=%d MiscVal=%d TargetA=%d"
              % (row[0], row[F_EFFECT_INDEX], row[2], row[F_EFFECT_AURA],
                 row[F_BASE_POINTS], row[F_MISC_VALUE], row[25]))
        assert row[F_EFFECT_AURA] == NEW_AURA
        assert row[F_BASE_POINTS] == NEW_BASE_POINTS
        assert row[F_MISC_VALUE] == NEW_MISC_VALUE
        break
    for i, row in find_rows(mdata, mrc, mrs, mf, 0, misc_id):
        print("  [改后] SpellMisc Id=%d DurationIndex=%d AttributesEx=0x%X"
              % (row[0], row[F_MISC_DURATION_INDEX], row[F_ATTR_EX]))
        assert row[F_MISC_DURATION_INDEX] == NEW_DURATION_INDEX
        assert row[F_ATTR_EX] & CHANNEL_BIT == 0
        break

    # 完整性：行数不变、字符串块原样保留
    print("  SpellEffect 行数=%d  SpellMisc 行数=%d" % (erc, mrc))
    print("校验通过。")


if __name__ == "__main__":
    main()
