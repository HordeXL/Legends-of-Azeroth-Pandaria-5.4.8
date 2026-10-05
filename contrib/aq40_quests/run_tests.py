#!/usr/bin/env python3
"""Compile the actual item/reputation quest update methods in a small harness."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'src/server/game/Entities/Player/Player.cpp').read_text()

def method(name):
    start = source.index('void Player::' + name + '(')
    end = source.index('\n}', start) + 2
    return source[start:end]

with tempfile.TemporaryDirectory(prefix='aq40-quest-test-') as temp:
    temp = Path(temp)
    (temp / 'methods.inc').write_text('\n'.join(method(name) for name in (
        'ItemAddedQuestCheck', 'ReputationChangedQuestCheck')))
    executable = temp / 'regression'
    subprocess.run(['c++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    '-I', str(temp), str(Path(__file__).with_name('regression.cpp')),
                    '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
