#!/usr/bin/env python3
"""Exercise production loot processing with deterministic rolls and small tables."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/game/Loot/LootMgr.cpp').read_text()
header = (root / 'src/server/game/Loot/LootMgr.h').read_text()

def function(signature):
    start = source.index(signature)
    opening = source.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]

policy_start = header.index('enum class LootRollPolicy')
policy = header[policy_start:header.index('};', policy_start) + 2]
selection_start = source.index('    LootRollPolicy policy = LootRollPolicy::Normal;')
selection_end = source.index('    tab->Process(', selection_start)
selection = ('LootRollPolicy SelectPolicy(Object* source, LootStore const& store) {\n'
             + source[selection_start:selection_end] + 'return policy; }\n')
methods = selection + '\n'.join(function(signature) for signature in (
    'LootStoreItem const* LootTemplate::LootGroup::Roll(',
    'void LootTemplate::LootGroup::Process(',
    'void LootTemplate::Process('))

with tempfile.TemporaryDirectory(prefix='aq40-loot-test-') as temp:
    temp = Path(temp)
    (temp / 'policy.inc').write_text(policy)
    (temp / 'methods.inc').write_text(methods)
    exe = temp / 'regression'
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    '-I', str(temp), str(Path(__file__).with_name('regression.cpp')),
                    '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
